#include <Keyboard.h>

// Works on any board with native USB keyboard support (Leonardo, Micro, Pro Micro, Pico, ...).
// Check your board's logic level: Pico = 3.3V ONLY, Leonardo = 5V.
//
// Leonardo only has external interrupts on pins 0,1,2,3,7. Pin 4 (bill) has none,
// so it is read by a 1 kHz timer poll instead (automatic, see below).
// The coin hopper is polled from loop(), so it works on any pin.
// ---- Coin acceptor: pin 1 (coinPin), pin 2 (inhibitPin) ----
const int coinPin    = 1;
const int inhibitPin = 2;
const bool INHIBIT_ACTIVE_LOW = true;   // only used when COIN_USE_RELAY = false (direct wire to acceptor)


// A relay module needs the pin DRIVEN (HIGH or LOW). The old code left pin 2 floating
// (INPUT) on 'U', which can never switch a relay.
const bool COIN_USE_RELAY            = true;  // true = pin 2 goes to a relay module
const bool COIN_RELAY_ACTIVE_LOW     = false; // REVERSED: relay clicks ON when pin is HIGH
                                              // (true = relay clicks ON when pin is LOW)
const bool COIN_RELAY_ON_WHEN_UNLOCKED = true; // true = 'U' turns relay ON, 'L' turns it OFF
                                               // false = reverse (relay ON while locked)
// ---- Bill acceptor: pin 4 (billPin), pin 5 (billInhibitPin) ----
const int billPin         = 3;
const int billInhibitPin  = 4;
const bool BILL_INHIBIT_ACTIVE_LOW = true;   // only used when BILL_USE_RELAY = false (direct wire)


const bool BILL_USE_RELAY              = true;  // true = pin 5 goes to a relay module
const bool BILL_RELAY_ACTIVE_LOW       = true; // false = relay ON when pin is HIGH (same as coin relay)
                                                // true  = relay ON when pin is LOW
const bool BILL_RELAY_ON_WHEN_UNLOCKED = true;  // true = 'U' turns relay ON, 'L' turns it OFF

// ---- Coin Hopper Dispenser: pin 8 (coin pulse in), pin 9 (relay out) ----
const uint8_t HOPPER_COIN_PIN  = 8;
const uint8_t HOPPER_RELAY_PIN = 9;


// ---- Settings ----
const bool DEBUG = true;

// Coin Hopper Dispenser Settings
#define RELAY_ACTIVE_LEVEL  HIGH     // LOW if relay board is active-LOW
#define COIN_ACTIVE_LEVEL   HIGH     // HIGH for NC switch (pin goes HIGH when switch opens)
#define COIN_PIN_MODE       INPUT_PULLUP

const uint32_t GLITCH_MS         = 8;     // Filter mechanical microswitch bounce
const uint32_t MIN_COIN_GAP_MS   = 70;    // Lockout after a counted coin
const uint32_t STARTUP_MS        = 1500;
const uint32_t NO_COIN_TIMEOUT_MS= 2000;
const float    TIMEOUT_FACTOR    = 1.5;
const uint8_t  STOP_EARLY_COINS  = 0;
const uint32_t COIN_VALUE        = 5;     // Value per hopper coin (e.g. D10 -> 10 / 5 = 2 coins)

float msPerCoin = 110.0;   // Starting estimate

// Coin
const unsigned long coinTimeoutMs = 100;       // ms gap = coin finished
const unsigned long minPulseUs    = 10000UL;  // reject pulses < 10ms
const unsigned long minGapMs      = 10;       // min gap between accepted pulses
const unsigned long settleMs      = 500;      // ignore after lock/unlock

// Bill (bill pulses are usually ~50ms wide with ~50-100ms gaps)
const unsigned long billTimeoutMs    = 500;      // gap = bill finished (>= 3x acceptor pulse period)
const unsigned long billMinPulseUs   = 20000UL;  // reject pulses < 20ms
const unsigned long billMaxPulseUs   = 200000UL; // reject pulses > 200ms (stuck line / noise burst)
const unsigned long billDebounceUs   = 2000UL;   // ignore edges < 2ms after the previous accepted edge
const int           BILL_CHUNK       = 10;       // bill credit is sent in steps of 10
const unsigned long BILL_SEND_GAP_MS = 100;      // pause between each "10" so the PC can keep up

// ---- Coin shared with ISR ----
volatile int pulseCount = 0;
volatile unsigned long lastPulseTime = 0;
volatile unsigned long ignoreUntil = 0;
volatile unsigned long fallUs = 0;
volatile bool pulseActive = false;
volatile bool lockedISR = true;

// ---- Bill shared with ISR ----
volatile int billPulseCount = 0;
volatile unsigned long billLastPulseTime = 0;
volatile unsigned long billLastEdgeUs = 0;
volatile unsigned long billFallUs = 0;
volatile bool billPulseActive = false;

bool locked = true;

// ---- Hopper Dispenser State (polled from loop, no ISR) ----
uint32_t hopperCoinCount = 0;
uint32_t lastHopperCoinMs = 0;
uint32_t pulseIntervalMs = 0;
uint32_t rejectedCount = 0;

bool dispensing = false;
uint32_t targetCoins = 0, startMs = 0, totalTimeout = 0, expectedMs = 0;
uint8_t diagMode = 0;      // 0 off, 1 relay off (manual test)

bool     inPulse = false;
uint32_t activeSince = 0;
uint32_t pulseStartMs = 0;
uint32_t lastPulseEndMs = 0;

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

void flushLog() {
  // On Leonardo/AVR, Serial.print BLOCKS when the PC isn't reading the port (the web page
  // only writes, never reads). Only print when there is room, so the loop never stalls.
  while (logTail != logHead && Serial.availableForWrite() >= 48) {
    Event e;
    e.type = logBuf[logTail].type;
    e.ms = logBuf[logTail].ms;
    e.widthUs = logBuf[logTail].widthUs;
    logTail = (logTail + 1) % LOG_SIZE;

    Serial.print(F("LOG "));
    Serial.print(e.ms);
    Serial.print(F("ms "));
    switch (e.type) {
      case EV_FALL:        Serial.println(F("COIN pin went LOW")); break;
      case EV_ACCEPT:      Serial.print(F("COIN ACCEPTED pulse, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_SHORT:   
                           Serial.print(F("COIN REJECTED too short (noise/spark), width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); 
          
                           Keyboard.write('0');
                           Keyboard.write(KEY_RETURN);
                           break;

      case EV_REJ_LOCKED:  Serial.print(F("COIN rejected: locked, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); 
                           
                           Keyboard.write('0');
                           Keyboard.write(KEY_RETURN);
                           break;
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

  //  in relay mode the pin is ALWAYS an OUTPUT and is driven HIGH or LOW.
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
    // Original direct-wire behavior (acceptor inhibit wire straight to pin 2)
    bool pinHigh = INHIBIT_ACTIVE_LOW ? !locked : locked;
    if (pinHigh) {
      pinMode(inhibitPin, INPUT);
    } else {
      pinMode(inhibitPin, OUTPUT);
      digitalWrite(inhibitPin, LOW);
    }
  }

  // in relay mode the pin is ALWAYS an OUTPUT and is driven HIGH or LOW.
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
    // Original direct-wire behavior (acceptor inhibit wire straight to pin 5)
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
  bool level = digitalRead(coinPin);

  if (!level) {                               // FALLING
    fallUs = nowUs;
    pulseActive = true;
    if (DEBUG) logEvent(EV_FALL, 0);
    return;
  }

  // RISING
  if (!pulseActive) return;
  pulseActive = false;
  unsigned long width = nowUs - fallUs;
  unsigned long nowMs = millis();

  if (lockedISR)                  { if (DEBUG) logEvent(EV_REJ_LOCKED, width); return; }
  if (nowMs < ignoreUntil)        { if (DEBUG) logEvent(EV_REJ_SETTLE, width); return; }
  if (width < minPulseUs)         { if (DEBUG) logEvent(EV_REJ_SHORT, width);  return; }
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
  bool level = digitalRead(billPin);

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

// ---- Pin polling for pins without a hardware interrupt (e.g. Leonardo pin 4) ----
// Edge-detects the pin and calls the same ISR logic. Runs from a 1 kHz timer on AVR,
// or from loop() on other boards.
bool billPolled = false;
volatile bool billLastLevel = true;

void pollInputs() {
  if (billPolled) {
    bool lv = digitalRead(billPin);
    if (lv != billLastLevel) { billLastLevel = lv; billISR(); }
  }
}

#if defined(ARDUINO_ARCH_AVR)
SIGNAL(TIMER0_COMPA_vect) { pollInputs(); }   // piggy-back on Arduino's Timer0 (~1 kHz)
#endif

// ---- Hopper Dispenser Functions (polled, works on Leonardo and Pico) ----
void relayOn()  { digitalWrite(HOPPER_RELAY_PIN, RELAY_ACTIVE_LEVEL); }
void relayOff() { digitalWrite(HOPPER_RELAY_PIN, !RELAY_ACTIVE_LEVEL); }

// Don't let a Serial.print stall the loop while the hopper is running (Leonardo blocks
// when the PC isn't reading the port). Missing a coin pulse would over-dispense.
bool canPrint() { return Serial.availableForWrite() >= 48; }

void readHopperCoin() {
  uint32_t now = millis();
  bool active = (digitalRead(HOPPER_COIN_PIN) == COIN_ACTIVE_LEVEL);

  if (active) {
    if (activeSince == 0) activeSince = now;

    if (!inPulse && (now - activeSince) >= GLITCH_MS) {
      inPulse = true;
      pulseStartMs = activeSince;

      bool gapOk = (hopperCoinCount == 0) || (now - lastHopperCoinMs >= MIN_COIN_GAP_MS);

      if (diagMode) {
        Serial.print(F("[PULSE start] gap since last: "));
        Serial.print(now - lastPulseEndMs); Serial.print(F(" ms  "));
        Serial.println(gapOk ? F("-> counts") : F("-> REJECTED (too close)"));
      }

      if (dispensing) {
        if (gapOk) {
          pulseIntervalMs = now - lastHopperCoinMs;
          lastHopperCoinMs = now;
          hopperCoinCount++;
        } else {
          rejectedCount++;
        }
      } else if (gapOk) {
        lastHopperCoinMs = now;
        hopperCoinCount++;
      }
    }
  } else {
    if (inPulse) {
      lastPulseEndMs = now;
      if (diagMode) {
        Serial.print(F("[PULSE end]   width: "));
        Serial.print(now - pulseStartMs); Serial.println(F(" ms"));
      }
    } else if (activeSince != 0 && diagMode) {
      Serial.print(F("[GLITCH ignored] "));
      Serial.print(now - activeSince); Serial.println(F(" ms"));
    }
    inPulse = false;
    activeSince = 0;
  }
}

void startDispense(uint32_t coins) {
  if (dispensing) { Serial.println(F("Busy.")); return; }
  if (coins == 0) return;
  diagMode = 0;

  targetCoins  = coins;
  expectedMs   = (uint32_t)(coins * msPerCoin);
  totalTimeout = (uint32_t)(expectedMs * TIMEOUT_FACTOR) + STARTUP_MS;

  hopperCoinCount = 0; rejectedCount = 0;
  startMs = millis(); lastHopperCoinMs = startMs;

  Serial.print(F("Dispense ")); Serial.print(coins);
  Serial.print(F(" coins | expected ")); Serial.print(expectedMs);
  Serial.print(F(" ms | timeout ")); Serial.print(totalTimeout); Serial.println(F(" ms"));

  dispensing = true;
  relayOn();
}

void stopDispense(const __FlashStringHelper* reason) {
  relayOff();
  dispensing = false;

  uint32_t t = millis();
  while (millis() - t < 300) readHopperCoin();   // catch coins still falling after relay off

  uint32_t finalCount = hopperCoinCount;
  uint32_t elapsed = millis() - startMs - 300;

  Serial.print(F("STOP: ")); Serial.println(reason);
  Serial.print(F("  Coins out : ")); Serial.print(finalCount);
  Serial.print(F(" / ")); Serial.println(targetCoins);
  Serial.print(F("  Rejected noise pulses: ")); Serial.println(rejectedCount);
  Serial.print(F("  Time      : ")); Serial.print(elapsed); Serial.println(F(" ms"));

  if (finalCount >= targetCoins && finalCount > 1 && rejectedCount == 0) {
    float measured = (float)elapsed / finalCount;
    msPerCoin = msPerCoin * 0.7 + measured * 0.3;
    Serial.print(F("  Measured  : ")); Serial.print(measured, 1); Serial.println(F(" ms/coin"));
    Serial.print(F("  New avg   : ")); Serial.print(msPerCoin, 1); Serial.println(F(" ms/coin"));
  }
}

void handleDispense() {
  if (!dispensing) return;
  uint32_t now = millis();
  uint32_t cnt = hopperCoinCount;

  uint32_t goal = (targetCoins > STOP_EARLY_COINS) ? targetCoins - STOP_EARLY_COINS : targetCoins;
  if (cnt >= goal) { stopDispense(F("DONE")); return; }

  uint32_t allowed = (cnt == 0) ? (STARTUP_MS + NO_COIN_TIMEOUT_MS) : NO_COIN_TIMEOUT_MS;
  if (now - lastHopperCoinMs > allowed) { stopDispense(F("ERROR: NO COIN SIGNAL (empty/jam)")); return; }
  if (now - startMs > totalTimeout) { stopDispense(F("ERROR: TOTAL TIMEOUT")); return; }
}

// ---- Serial commands ----
// Instant single chars:  L = lock, U = unlock
// Lines (end with \n, or just stop sending for 30 ms):
//   D<amount>  dispense <amount> pesos of change      s = stop hopper
//   t = show ms/coin                                  d = toggle hopper diagnostic
void handleCommand(char *line) {
  if (line[0] == 0) return;

  if (!strcmp(line, "s") || !strcmp(line, "S")) {
    if (dispensing) stopDispense(F("MANUAL STOP"));
    relayOff(); diagMode = 0;
    Serial.println(F("Hopper stopped."));
  } else if (!strcmp(line, "t") || !strcmp(line, "T")) {
    Serial.print(F("ms/coin: ")); Serial.println(msPerCoin, 1);
    Serial.print(F("coins/sec: ")); Serial.println(1000.0 / msPerCoin, 2);
  } else if (!strcmp(line, "d")) {
    diagMode = diagMode ? 0 : 1; relayOff();
    Serial.println(diagMode ? F("DIAG ON (relay OFF). Test by hand.") : F("DIAG OFF"));
  } else if (line[0] == 'D' || line[0] == 'd') {
    long amount = atol(line + 1);
    if (amount > 0) {
      if (locked) {
        Serial.println(F("LOG: dispense rejected: LOCKED"));
        return;
      }
      uint32_t coinsToDispense = (uint32_t)(amount / COIN_VALUE);
      if (coinsToDispense == 0) coinsToDispense = 1;
      startDispense(coinsToDispense);
    } else {
      Serial.println(F("Invalid amount for D command."));
    }
  }
}

void handleSerial() {
  static char buf[16];
  static uint8_t len = 0;
  static unsigned long lastCharMs = 0;

  while (Serial.available() > 0) {
    char c = Serial.read();
    lastCharMs = millis();
    bool isLU = (c == 'L' || c == 'l' || c == 'U' || c == 'u');

    if (c == '\n' || c == '\r') {                    // end of line
      buf[len] = 0; len = 0;
      handleCommand(buf);
      continue;
    }
    if (isLU) {
      if (len > 0) { buf[len] = 0; len = 0; handleCommand(buf); }  // finish pending "D<amount>"
      if ((c == 'L' || c == 'l') && !locked)      { locked = true;  applyLockState(); }
      else if ((c == 'U' || c == 'u') && locked)  { locked = false; applyLockState(); }
      continue;
    }
    if (len < sizeof(buf) - 1) buf[len++] = c;
  }

  // Command sent without a newline: run it once the line has been idle for 30 ms
  if (len > 0 && millis() - lastCharMs > 30) {
    buf[len] = 0; len = 0;
    handleCommand(buf);
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
  Serial.begin(115200);
  Keyboard.begin();
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  pinMode(coinPin, INPUT_PULLUP);
  pinMode(billPin, INPUT_PULLUP);
  pinMode(HOPPER_RELAY_PIN, OUTPUT);
  relayOff();                       // hopper OFF at boot
  pinMode(HOPPER_COIN_PIN, COIN_PIN_MODE);

  unsigned long t0 = millis();
  while (!Serial && millis() - t0 < 2000) delay(10);

  applyLockState();                 // boots LOCKED -> coin relay set to its "locked" state
  billLastLevel = digitalRead(billPin);
  bool coinPolled = false;
  attachInput(coinPin, coinISR,   coinPolled);   // must be interrupt-capable (Leonardo pin 1 is)
  if (coinPolled) Serial.println(F("WARNING: coinPin has no hardware interrupt on this board!"));
  attachInput(billPin, billISR,   billPolled);
  #if defined(ARDUINO_ARCH_AVR)
    OCR0A = 0x80;
    TIMSK0 |= _BV(OCIE0A);       // enable Timer0 compare-A interrupt for polling
  #endif
  if (DEBUG) Serial.println(F("LOG ready"));
}

void loop() {
  handleSerial();

  #if !defined(ARDUINO_ARCH_AVR)
    pollInputs();
  #endif

  // Hopper routines
  readHopperCoin();
  handleDispense();

  if (DEBUG) flushLog();

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

  // Hopper status reporting
  static uint32_t lastShown = 0;
  if (dispensing && hopperCoinCount != lastShown) {
    lastShown = hopperCoinCount;
    if (canPrint()) {
      Serial.print(F("Hopper Coin ")); Serial.print(lastShown);
      Serial.print(F(" | interval ")); Serial.print(pulseIntervalMs); Serial.println(F(" ms"));
    }
  }
  if (!dispensing) lastShown = 0;
}
