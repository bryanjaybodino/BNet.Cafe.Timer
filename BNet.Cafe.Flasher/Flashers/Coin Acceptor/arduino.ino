#include <Keyboard.h>

// COIN ACCEPTOR ONLY  (aligned with the Coin + Bill + Changer sketch)
// Works on any board with native USB keyboard support (Leonardo, Micro, Pro Micro, Pico, ...).
// Check your board's logic level: Pico = 3.3V ONLY, Leonardo = 5V.
// coinPin MUST be interrupt-capable (Leonardo: pins 0,1,2,3,7).

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

// ---- Settings ----
const bool DEBUG = true;

// Coin
const unsigned long coinTimeoutMs = 100;       // ms gap = coin finished
const unsigned long minPulseUs    = 10000UL;   // reject pulses < 10ms
const unsigned long minGapMs      = 10;        // min gap between accepted pulses
const unsigned long settleMs      = 500;       // ignore after lock/unlock

// ---- Coin shared with ISR ----
volatile int pulseCount = 0;
volatile unsigned long lastPulseTime = 0;
volatile unsigned long ignoreUntil = 0;
volatile unsigned long fallUs = 0;
volatile bool pulseActive = false;
volatile bool lockedISR = true;

bool locked = true;

// ---- Event log ring buffer ----
enum EvType : uint8_t {
  EV_FALL, EV_ACCEPT, EV_REJ_SHORT, EV_REJ_LOCKED, EV_REJ_SETTLE, EV_REJ_GAP
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
      case EV_REJ_SHORT:   Serial.print(F("COIN REJECTED too short (noise/spark), width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_LOCKED:  Serial.print(F("COIN rejected: locked, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_SETTLE:  Serial.print(F("COIN rejected: settle window, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
      case EV_REJ_GAP:     Serial.print(F("COIN rejected: gap too small, width="));
                           Serial.print(e.widthUs); Serial.println(F("us")); break;
    }
  }
}

void applyLockState() {
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

  noInterrupts();
  pulseCount = 0;
  pulseActive = false;
  lockedISR = locked;
  ignoreUntil = millis() + settleMs;
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

int evaluateCoin(int pulses) {
  switch (pulses) {
    case 1: case 5: case 10: case 20: return pulses;
    default: return 0;
  }
}

// ---- Serial commands (instant single chars): L = lock, U = unlock ----
void handleSerial() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if ((c == 'L' || c == 'l') && !locked)      { locked = true;  applyLockState(); }
    else if ((c == 'U' || c == 'u') && locked)  { locked = false; applyLockState(); }
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

  unsigned long t0 = millis();
  while (!Serial && millis() - t0 < 2000) delay(10);

  applyLockState();                 // boots LOCKED -> coin relay set to its "locked" state
  bool coinPolled = false;
  attachInput(coinPin, coinISR, coinPolled);   // must be interrupt-capable (Leonardo pin 1 is)
  if (coinPolled) Serial.println(F("WARNING: coinPin has no hardware interrupt on this board!"));

  if (DEBUG) Serial.println(F("LOG ready"));
}

void loop() {
  handleSerial();

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
}
