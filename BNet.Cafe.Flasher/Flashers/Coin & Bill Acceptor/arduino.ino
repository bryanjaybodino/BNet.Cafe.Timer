#include <Keyboard.h>
#if defined(ARDUINO_ARCH_RP2040)
  #include "hardware/watchdog.h"   // scratch registers survive a reset (cleared only on full power-on)
#endif

// Portable fast pin read: Pico SDK on RP2040, standard Arduino elsewhere (Leonardo/AVR)
#if defined(ARDUINO_ARCH_RP2040)
  #define readPin(p) gpio_get(p)
#else
  #define readPin(p) digitalRead(p)
#endif

// =====================================================================
//  COIN ACCEPTOR + BILL ACCEPTOR
//  Split from the Coin + Bill + Changer sketch (hopper removed).
// =====================================================================
// Works on any board with native USB keyboard support (Leonardo, Micro, Pro Micro, Pico, ...).
// Check your board's logic level: Pico = 3.3V ONLY, Leonardo = 5V.
//
// Leonardo only has external interrupts on pins 0,1,2,3,7. If billPin has none,
// it is read by a 1 kHz timer poll instead (automatic, see below).
// With billPin = 3 (as below) a real hardware interrupt is used.
//
// Serial commands (single chars, instant):
//   L = lock    U = unlock    x = test anti-static alert    i = print diagnostics

// ---- Coin acceptor: pin 1 (coinPin), pin 2 (inhibitPin) ----
const int coinPin    = 1;
const int inhibitPin = 2;
const bool INHIBIT_ACTIVE_LOW = true;   // only used when COIN_USE_RELAY = false (direct wire to acceptor)

// A relay module needs the pin DRIVEN (HIGH or LOW). A floating (INPUT) pin can never switch a relay.
const bool COIN_USE_RELAY            = true;  // true = pin 2 goes to a relay module
const bool COIN_RELAY_ACTIVE_LOW     = false; // REVERSED: relay clicks ON when pin is HIGH
                                              // (true = relay clicks ON when pin is LOW)
const bool COIN_RELAY_ON_WHEN_UNLOCKED = true; // true = 'U' turns relay ON, 'L' turns it OFF
                                               // false = reverse (relay ON while locked)

// ---- Bill acceptor: pin 3 (billPin), pin 4 (billInhibitPin) ----
const int billPin         = 3;
const int billInhibitPin  = 4;
const bool BILL_INHIBIT_ACTIVE_LOW = true;   // only used when BILL_USE_RELAY = false (direct wire)

const bool BILL_USE_RELAY              = true;  // true = billInhibitPin goes to a relay module
const bool BILL_RELAY_ACTIVE_LOW       = true;  // false = relay ON when pin is HIGH
                                                // true  = relay ON when pin is LOW
const bool BILL_RELAY_ON_WHEN_UNLOCKED = true;  // true = 'U' turns relay ON, 'L' turns it OFF

// ---- Settings ----
const bool DEBUG = true;

// Coin
const unsigned long coinTimeoutMs = 100;       // ms gap = coin finished
const unsigned long minPulseUs    = 10000UL;   // reject pulses < 10ms
const unsigned long minGapMs      = 10;        // min gap between accepted pulses
const unsigned long settleMs      = 500;       // ignore after lock/unlock

// Bill (bill pulses are usually ~50ms wide with ~50-100ms gaps)
const unsigned long billTimeoutMs    = 500;      // gap = bill finished (>= 3x acceptor pulse period)
const unsigned long billMinPulseUs   = 20000UL;  // reject pulses < 20ms
const unsigned long billMaxPulseUs   = 200000UL; // reject pulses > 200ms (stuck line / noise burst)
const unsigned long billDebounceUs   = 2000UL;   // ignore edges < 2ms after the previous accepted edge
const int           BILL_CHUNK       = 10;       // bill credit is sent in steps of 10
const unsigned long BILL_SEND_GAP_MS = 100;      // pause between each "10" so the PC can keep up

// ---- Anti-static alert (sends "0" + Enter to the PC when a spark/ESD is detected) ----
const unsigned long STATIC_SEND_GAP_MS  = 100;   // pause between each anti-static "0"+Enter
const uint8_t       STATIC_PENDING_MAX  = 10;    // cap so a long static burst can't flood the PC
const unsigned long STATIC_COALESCE_MS  = 30;    // one spark = a burst of spikes -> count it once (0 = off)
const unsigned long BOOT_ALERT_DELAY_MS = 3000;  // wait for the USB keyboard to re-enumerate on the PC

// ---- Coin shared with ISR ----
volatile int pulseCount = 0;
volatile unsigned long lastPulseTime = 0;
volatile unsigned long ignoreUntil = 0;
volatile unsigned long fallUs = 0;
volatile bool pulseActive = false;
volatile bool lockedISR = true;

// Alert counter set by the ISR, consumed by loop(). Independent of DEBUG and Serial.
volatile uint8_t staticPending = 0;
volatile unsigned long lastStaticQueueMs = 0;
bool abnormalBoot = false;                 // Pico: restarted without losing power (static/ESD reset)
// Diagnostics: type 'i' in the serial monitor to print, 'x' to force a test alert
volatile unsigned long isrCalls = 0;       // total coin interrupts seen
volatile unsigned long glitchCount = 0;    // spikes too fast to see the falling edge
volatile unsigned long staticSent = 0;     // alerts actually sent to the PC

// ---- Bill shared with ISR ----
volatile int billPulseCount = 0;
volatile unsigned long billLastPulseTime = 0;
volatile unsigned long billLastEdgeUs = 0;
volatile unsigned long billFallUs = 0;
volatile bool billPulseActive = false;

// Used only if billPin has no hardware interrupt (polled instead)
bool billPolled = false;
volatile bool billLastLevel = true;

bool locked = true;

// ---- Event log ring buffer ----
enum EvType : uint8_t {
  EV_FALL, EV_ACCEPT, EV_REJ_SHORT, EV_REJ_LOCKED, EV_REJ_SETTLE, EV_REJ_GAP,
  EV_BILL_FALL, EV_BILL_ACCEPT, EV_BILL_REJ_SHORT, EV_BILL_REJ_LONG
};
struct Event { uint8_t type; unsigned long ms; unsigned long widthUs; };
const uint8_t LOG_SIZE = 32;
volatile Event logBuf[LOG_SIZE];
volatile uint8_t logHead = 0, logTail = 0;

void logEvent(uint8_t type, unsigned long widthUs) {
  uint8_t next = (logHead + 1) % LOG_SIZE;
  if (next == logTail) return;
  logBuf[logHead].type = type;
  logBuf[logHead].ms = millis();
  logBuf[logHead].widthUs = widthUs;
  logHead = next;
}

// Called from the ISR when an anti-static condition is detected.
// Does NOT depend on DEBUG, the log buffer, or the serial port.
inline void queueStaticAlert() {
  unsigned long now = millis();
  if (now - lastStaticQueueMs < STATIC_COALESCE_MS) return;   // same spark, already queued
  lastStaticQueueMs = now;
  if (staticPending < STATIC_PENDING_MAX) staticPending++;
}

void flushLog() {
  // Always pop events so the ring buffer can never get stuck full. On Leonardo/AVR,
  // Serial.print BLOCKS when the PC isn't reading the port, so only print when there
  // is room (otherwise the log line is dropped). Keyboard output is NOT done here.
  while (logTail != logHead) {
    Event e;
    e.type = logBuf[logTail].type;
    e.ms = logBuf[logTail].ms;
    e.widthUs = logBuf[logTail].widthUs;
    logTail = (logTail + 1) % LOG_SIZE;

    if (Serial.availableForWrite() < 48) continue;   // drop log line, keep draining

    Serial.print(F("LOG "));
    Serial.print(e.ms);
    Serial.print(F("ms "));
    switch (e.type) {
      case EV_FALL:        Serial.println(F("COIN pin went LOW")); break;
      case EV_ACCEPT:      Serial.print(F("COIN ACCEPTED pulse, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_SHORT:   Serial.print(F("COIN REJECTED too short (noise/spark), width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_LOCKED:  Serial.print(F("COIN rejected: locked, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_SETTLE:  Serial.print(F("COIN rejected: settle window, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_GAP:     Serial.print(F("COIN rejected: gap too small, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;

      case EV_BILL_FALL:        Serial.println(F("BILL pin went LOW")); break;
      case EV_BILL_ACCEPT:      Serial.print(F("BILL ACCEPTED pulse, width="));
                                Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_BILL_REJ_SHORT:   Serial.print(F("BILL REJECTED too short (noise), width="));
                                Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_BILL_REJ_LONG:    Serial.print(F("BILL REJECTED too long (stuck/noise), width="));
                                Serial.print(e.widthUs); Serial.println(F("us")); break;
    }
  }
}

void applyLockState() {
  // ---- Coin inhibit ----
  // In relay mode the pin is ALWAYS an OUTPUT and is driven HIGH or LOW.
  if (COIN_USE_RELAY) {
    bool relayOn = COIN_RELAY_ON_WHEN_UNLOCKED ? !locked : locked;
    // active-LOW board: ON = LOW, OFF = HIGH.  active-HIGH board: ON = HIGH, OFF = LOW.
    bool level = (relayOn == COIN_RELAY_ACTIVE_LOW) ? LOW : HIGH;
    digitalWrite(inhibitPin, level);   // set level first so the relay does not glitch...
    pinMode(inhibitPin, OUTPUT);       // ...then make it an output
    if (DEBUG) {
      Serial.print(F("LOG coin relay pin"));
      Serial.print(inhibitPin);
      Serial.print(F(" = "));
      Serial.print(level ? F("HIGH") : F("LOW"));
      Serial.println(relayOn ? F(" (relay ON)") : F(" (relay OFF)"));
    }
  } else {
    // Direct-wire behavior (acceptor inhibit wire straight to inhibitPin)
    bool pinHigh = INHIBIT_ACTIVE_LOW ? !locked : locked;
    if (pinHigh) {
      pinMode(inhibitPin, INPUT);
    } else {
      pinMode(inhibitPin, OUTPUT);
      digitalWrite(inhibitPin, LOW);
    }
  }

  // ---- Bill inhibit ----
  if (BILL_USE_RELAY) {
    bool billRelayOn = BILL_RELAY_ON_WHEN_UNLOCKED ? !locked : locked;
    bool billLevel = (billRelayOn == BILL_RELAY_ACTIVE_LOW) ? LOW : HIGH;
    digitalWrite(billInhibitPin, billLevel);
    pinMode(billInhibitPin, OUTPUT);
    if (DEBUG) {
      Serial.print(F("LOG bill relay pin"));
      Serial.print(billInhibitPin);
      Serial.print(F(" = "));
      Serial.print(billLevel ? F("HIGH") : F("LOW"));
      Serial.println(billRelayOn ? F(" (relay ON)") : F(" (relay OFF)"));
    }
  } else {
    // Direct-wire behavior (acceptor inhibit wire straight to billInhibitPin)
    bool billPinHigh = BILL_INHIBIT_ACTIVE_LOW ? !locked : locked;
    if (billPinHigh) {
      pinMode(billInhibitPin, INPUT);
    } else {
      pinMode(billInhibitPin, OUTPUT);
      digitalWrite(billInhibitPin, LOW);
    }
  }

  noInterrupts();
  pulseCount = 0;
  pulseActive = false;
  lockedISR = locked;
  ignoreUntil = millis() + settleMs;
  // Bill state is intentionally NOT cleared or ignored here: a bill already
  // feeding must still be counted so the money is never lost.
  interrupts();

  if (DEBUG) {
    Serial.print(F("LOG state: "));
    Serial.println(locked ? F("LOCKED") : F("UNLOCKED"));
  }
}

// ---- Coin ISR: fires on both edges. Pulse = LOW period; width checked on RISING. ----
void coinISR() {
  unsigned long nowUs = micros();
  bool level = readPin(coinPin);
  isrCalls++;

  if (!level) {                               // FALLING
    fallUs = nowUs;
    pulseActive = true;
    if (DEBUG) logEvent(EV_FALL, 0);
    return;
  }

  // RISING
  unsigned long nowMs = millis();
  if (!pulseActive) {
    // The pin already went LOW->HIGH before this ISR could read it, so the falling edge
    // was never seen. A real coin pulse is ms long and is never missed, so this is a
    // static spike.
    if (nowMs >= ignoreUntil) {          // skip the relay-click window after lock/unlock
      glitchCount++;
      queueStaticAlert();
      if (DEBUG) logEvent(EV_REJ_SHORT, 0);
    }
    return;
  }
  pulseActive = false;
  unsigned long width = nowUs - fallUs;

  if (lockedISR)                  { queueStaticAlert(); if (DEBUG) logEvent(EV_REJ_LOCKED, width); return; }
  if (nowMs < ignoreUntil)        { if (DEBUG) logEvent(EV_REJ_SETTLE, width); return; }
  if (width < minPulseUs)         { queueStaticAlert(); if (DEBUG) logEvent(EV_REJ_SHORT, width);  return; }
  if (pulseCount > 0 && nowMs - lastPulseTime < minGapMs)
                                  { if (DEBUG) logEvent(EV_REJ_GAP, width);    return; }

  pulseCount++;
  lastPulseTime = nowMs;
  if (DEBUG) logEvent(EV_ACCEPT, width);
}

// ---- Bill ISR: debounced, counts every valid pulse (even while locked) ----
void billISR() {
  unsigned long nowUs = micros();
  if (nowUs - billLastEdgeUs < billDebounceUs) return;   // bounce / glitch
  bool level = readPin(billPin);

  if (!level) {                               // FALLING
    if (billPulseActive) return;              // already low -> ignore duplicate
    billLastEdgeUs = nowUs;
    billFallUs = nowUs;
    billPulseActive = true;
    if (DEBUG) logEvent(EV_BILL_FALL, 0);
    return;
  }

  // RISING
  if (!billPulseActive) return;
  billLastEdgeUs = nowUs;
  billPulseActive = false;
  unsigned long width = nowUs - billFallUs;

  if (width < billMinPulseUs) { if (DEBUG) logEvent(EV_BILL_REJ_SHORT, width); return; }
  if (width > billMaxPulseUs) { if (DEBUG) logEvent(EV_BILL_REJ_LONG, width);  return; }

  // No lock/settle rejection: never discard real money pulses.
  billPulseCount++;
  billLastPulseTime = millis();
  if (DEBUG) logEvent(EV_BILL_ACCEPT, width);
}

int evaluateCoin(int pulses) {
  switch (pulses) {
    case 1: case 5: case 10: case 20: return pulses;
    default: return 0;
  }
}

// Map bill pulse count -> peso value. EDIT THIS to match your acceptor's
// pulse settings (check its DIP switches / manual).
int evaluateBill(int pulses) {
  switch (pulses) {
    case 2:   return 20;
    case 5:   return 50;
    case 10:  return 100;
    case 20:  return 200;
    case 50:  return 500;
    case 100: return 1000;
    default:  return 0;
  }
}

// ---- Pin polling for billPin if it has no hardware interrupt ----
// Edge-detects the pin and calls the same ISR logic. Runs from a 1 kHz timer on AVR,
// or from loop() on other boards. Only active if billPolled = true.
void pollInputs() {
  if (billPolled) {
    bool lv = digitalRead(billPin);
    if (lv != billLastLevel) { billLastLevel = lv; billISR(); }
  }
}

#if defined(ARDUINO_ARCH_AVR)
SIGNAL(TIMER0_COMPA_vect) { pollInputs(); }   // piggy-back on Arduino's Timer0 (~1 kHz)
#endif

void printDiagnostics() {
  Serial.print(F("coin ISR calls: ")); Serial.println(isrCalls);
  Serial.print(F("fast glitches : ")); Serial.println(glitchCount);
  Serial.print(F("alerts sent   : ")); Serial.println(staticSent);
  Serial.print(F("coin pin now  : ")); Serial.println(digitalRead(coinPin) ? F("HIGH") : F("LOW"));
  Serial.print(F("bill pin now  : ")); Serial.println(digitalRead(billPin) ? F("HIGH") : F("LOW"));
}

// ---- Serial commands (instant single chars) ----
void handleSerial() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if ((c == 'L' || c == 'l') && !locked)      { locked = true;  applyLockState(); }
    else if ((c == 'U' || c == 'u') && locked)  { locked = false; applyLockState(); }
    else if (c == 'x' || c == 'X') {
      queueStaticAlert();                       // test: keyboard path only, no pin needed
      Serial.println(F("TEST: static alert queued"));
    }
    else if (c == 'i' || c == 'I') printDiagnostics();
  }
}

void attachInput(int pin, void (*isr)(), bool &polled) {
  if (digitalPinToInterrupt(pin) != NOT_AN_INTERRUPT) {
    attachInterrupt(digitalPinToInterrupt(pin), isr, CHANGE);   // CHANGE used directly: its type differs per core (int on AVR, PinStatus on Pico)
  } else {
    polled = true;
  }
}

void setup() {
  #if defined(ARDUINO_ARCH_RP2040)
    // Reset detection: the magic is written on every boot. If it is still there at the
    // next boot, the chip was reset (ESD/spark) without a full power cycle.
    const uint32_t BOOT_MAGIC = 0xA5C0FFEE;
    if (watchdog_hw->scratch[0] == BOOT_MAGIC) abnormalBoot = true;
    watchdog_hw->scratch[0] = BOOT_MAGIC;
  #endif
  Serial.begin(115200);
  Keyboard.begin();
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  pinMode(coinPin, INPUT_PULLUP);
  pinMode(billPin, INPUT_PULLUP);

  unsigned long t0 = millis();
  while (!Serial && millis() - t0 < 2000) delay(10);

  applyLockState();                 // boots LOCKED -> both relays set to their "locked" state
  billLastLevel = digitalRead(billPin);
  bool coinPolled = false;
  attachInput(coinPin, coinISR, coinPolled);   // must be interrupt-capable (Leonardo pin 1 is)
  if (coinPolled) Serial.println(F("WARNING: coinPin has no hardware interrupt on this board!"));
  attachInput(billPin, billISR, billPolled);
  #if defined(ARDUINO_ARCH_AVR)
    if (billPolled) {
      OCR0A = 0x80;
      TIMSK0 |= _BV(OCIE0A);       // enable Timer0 compare-A interrupt for polling
    }
  #endif
  if (DEBUG) {
    Serial.println(F("LOG ready"));
    if (abnormalBoot) Serial.println(F("LOG abnormal restart detected (static/ESD?)"));
  }
}

void loop() {
  handleSerial();

  #if !defined(ARDUINO_ARCH_AVR)
    pollInputs();
  #endif

  if (DEBUG) flushLog();

  // ---- After an abnormal restart (Pico), send the anti-static message once ----
  static bool bootAlertDone = false;
  if (abnormalBoot && !bootAlertDone && millis() > BOOT_ALERT_DELAY_MS) {
    bootAlertDone = true;
    queueStaticAlert();
  }

  // ---- Anti-static alert -> "0" + Enter to the PC ----
  // Runs every loop, no dependency on DEBUG / Serial / log buffer.
  static unsigned long lastStaticSendMs = 0;
  if (staticPending > 0 && millis() - lastStaticSendMs >= STATIC_SEND_GAP_MS) {
    noInterrupts();
    if (staticPending > 0) staticPending--;
    interrupts();
    Keyboard.write('0');
    Keyboard.write(KEY_RETURN);
    staticSent++;
    lastStaticSendMs = millis();
  }

  // ---- Coin ----
  int count = 0;
  noInterrupts();
  if (pulseCount > 0 && millis() - lastPulseTime > coinTimeoutMs) {
    count = pulseCount;
    pulseCount = 0;
  }
  interrupts();

  if (count > 0) {
    int value = evaluateCoin(count);
    if (DEBUG) {
      Serial.print(F("LOG coin finished: pulses="));
      Serial.print(count);
      Serial.print(F(" value="));
      Serial.println(value);
    }
    if (value > 0 && !locked) {
      Keyboard.print(value);
      Keyboard.write(KEY_RETURN);
    }
  }

  // ---- Bill ----
  static int pendingBillValue = 0;     // credit held if the bill finished while locked
  int billCount = 0;
  noInterrupts();
  if (billPulseCount > 0 && !billPulseActive &&
      millis() - billLastPulseTime > billTimeoutMs) {
    billCount = billPulseCount;
    billPulseCount = 0;
  }
  interrupts();

  if (billCount > 0) {
    int billValue = evaluateBill(billCount);
    if (DEBUG) {
      Serial.print(F("LOG bill finished: pulses="));
      Serial.print(billCount);
      Serial.print(F(" value="));
      Serial.println(billValue);
    }
    if (billValue == 0) {
      Serial.print(F("WARNING: unknown bill pulse count ("));
      Serial.print(billCount);
      Serial.println(F(") - check mapping/noise/wiring!"));
    } else {
      pendingBillValue += billValue;
    }
  }

  // Send bill credit in steps of 10 (e.g. 50 -> 10,10,10,10,10), one per BILL_SEND_GAP_MS
  static unsigned long lastBillSendMs = 0;
  if (pendingBillValue > 0 && !locked && millis() - lastBillSendMs >= BILL_SEND_GAP_MS) {
    int chunk = (pendingBillValue < BILL_CHUNK) ? pendingBillValue : BILL_CHUNK;
    Keyboard.print(chunk);
    Keyboard.write(KEY_RETURN);
    pendingBillValue -= chunk;
    lastBillSendMs = millis();
  }
}
