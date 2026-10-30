/*
  COIN HOPPER DISPENSER - Raspberry Pi Pico (Arduino IDE, arduino-pico core)
  v2: glitch filter + lockout to stop false/double coin counts

  Pins:  GP8 = COIN SIGNAL   |   GP9 = HOPPER RELAY
  Serial Monitor: 115200 baud, newline enabled.

  Commands:
    5   -> dispense 5 coins
    s   -> stop
    t   -> stats
    d   -> DIAGNOSTIC toggle (relay OFF, prints every raw pulse width/gap)
    r   -> DIAGNOSTIC with relay ON (motor running, no counting limit)

  TUNING (watch the 'd' output):
    GLITCH_MS     = pulse must stay active this long to count
    MIN_COIN_GAP_MS = ignore new pulses this soon after a counted coin
                      (set a bit below your real coin spacing ~110 ms)
*/

const uint8_t COIN_PIN  = 8;
const uint8_t RELAY_PIN = 9;

// ---------------- SETTINGS ----------------
#define RELAY_ACTIVE_LEVEL  HIGH     // LOW if relay board is active-LOW
#define COIN_ACTIVE_LEVEL   LOW      // level when coin passes (LOW for typical opto). HIGH if opposite.
#define COIN_PIN_MODE       INPUT_PULLUP

const uint32_t GLITCH_MS         = 3;     // pulse must be stable this long (raise to 5-10 if still noisy)
const uint32_t MIN_COIN_GAP_MS   = 70;    // lockout after a counted coin (real spacing ~110 ms)
const uint32_t STARTUP_MS        = 1500;
const uint32_t NO_COIN_TIMEOUT_MS= 2000;
const float    TIMEOUT_FACTOR    = 1.5;
const uint8_t  STOP_EARLY_COINS  = 0;

float msPerCoin = 110.0;   // starting estimate

// ---------------- STATE ----------------
uint32_t coinCount = 0;
uint32_t lastCoinMs = 0;
uint32_t pulseIntervalMs = 0;
uint32_t rejectedCount = 0;

bool dispensing = false;
uint32_t targetCoins = 0, startMs = 0, totalTimeout = 0, expectedMs = 0;
uint8_t diagMode = 0;      // 0 off, 1 relay off, 2 relay on

// pulse tracker
bool     inPulse = false;      // currently counted/active pulse
uint32_t activeSince = 0;      // when line went active (0 = inactive)
uint32_t pulseStartMs = 0;
uint32_t lastPulseEndMs = 0;

void relayOn()  { digitalWrite(RELAY_PIN, RELAY_ACTIVE_LEVEL); }
void relayOff() { digitalWrite(RELAY_PIN, !RELAY_ACTIVE_LEVEL); }

// ---------------- COIN SIGNAL (polled, filtered) ----------------
void readCoin() {
  uint32_t now = millis();
  bool active = (digitalRead(COIN_PIN) == COIN_ACTIVE_LEVEL);

  if (active) {
    if (activeSince == 0) activeSince = now;

    if (!inPulse && (now - activeSince) >= GLITCH_MS) {
      inPulse = true;
      pulseStartMs = activeSince;

      bool gapOk = (coinCount == 0) || (now - lastCoinMs >= MIN_COIN_GAP_MS);

      if (diagMode) {
        Serial.print("[PULSE start] gap since last: ");
        Serial.print(now - lastPulseEndMs); Serial.print(" ms  ");
        Serial.println(gapOk ? "-> counts" : "-> REJECTED (too close)");
      }

      if (dispensing) {
        if (gapOk) {
          pulseIntervalMs = now - lastCoinMs;
          lastCoinMs = now;
          coinCount++;
        } else {
          rejectedCount++;
        }
      } else if (gapOk) {
        lastCoinMs = now;   // keep gap logic alive in diag mode
        coinCount++;
      }
    }
  } else {
    if (inPulse) {
      lastPulseEndMs = now;
      if (diagMode) {
        Serial.print("[PULSE end]   width: ");
        Serial.print(now - pulseStartMs); Serial.println(" ms");
      }
    } else if (activeSince != 0 && diagMode) {
      Serial.print("[GLITCH ignored] ");
      Serial.print(now - activeSince); Serial.println(" ms");
    }
    inPulse = false;
    activeSince = 0;
  }
}

// ---------------- DISPENSE ----------------
void startDispense(uint32_t coins) {
  if (dispensing) { Serial.println("Busy."); return; }
  if (coins == 0) return;
  diagMode = 0;

  targetCoins  = coins;
  expectedMs   = (uint32_t)(coins * msPerCoin);
  totalTimeout = (uint32_t)(expectedMs * TIMEOUT_FACTOR) + STARTUP_MS;

  coinCount = 0; rejectedCount = 0;
  startMs = millis(); lastCoinMs = startMs;

  Serial.print("Dispense "); Serial.print(coins);
  Serial.print(" coins | expected "); Serial.print(expectedMs);
  Serial.print(" ms | timeout "); Serial.print(totalTimeout); Serial.println(" ms");

  dispensing = true;
  relayOn();
}

void stopDispense(const char* reason) {
  relayOff();
  dispensing = false;

  // keep reading ~300 ms to catch any coin dropped while motor coasts
  uint32_t t = millis();
  while (millis() - t < 300) readCoin();

  uint32_t finalCount = coinCount;
  uint32_t elapsed = millis() - startMs - 300;

  Serial.print("STOP: "); Serial.println(reason);
  Serial.print("  Coins out : "); Serial.print(finalCount);
  Serial.print(" / "); Serial.println(targetCoins);
  Serial.print("  Rejected noise pulses: "); Serial.println(rejectedCount);
  Serial.print("  Time      : "); Serial.print(elapsed); Serial.println(" ms");

  if (finalCount >= targetCoins && finalCount > 1 && rejectedCount == 0) {
    float measured = (float)elapsed / finalCount;
    msPerCoin = msPerCoin * 0.7 + measured * 0.3;
    Serial.print("  Measured  : "); Serial.print(measured, 1); Serial.println(" ms/coin");
    Serial.print("  New avg   : "); Serial.print(msPerCoin, 1); Serial.println(" ms/coin");
  }
}

void handleDispense() {
  if (!dispensing) return;
  uint32_t now = millis();
  uint32_t cnt = coinCount;

  uint32_t goal = (targetCoins > STOP_EARLY_COINS) ? targetCoins - STOP_EARLY_COINS : targetCoins;
  if (cnt >= goal) { stopDispense("DONE"); return; }

  uint32_t allowed = (cnt == 0) ? (STARTUP_MS + NO_COIN_TIMEOUT_MS) : NO_COIN_TIMEOUT_MS;
  if (now - lastCoinMs > allowed) { stopDispense("ERROR: NO COIN SIGNAL (empty/jam)"); return; }
  if (now - startMs > totalTimeout) { stopDispense("ERROR: TOTAL TIMEOUT"); return; }
}

// ---------------- SERIAL ----------------
void handleSerial() {
  if (!Serial.available()) return;
  String in = Serial.readStringUntil('\n');
  in.trim();
  if (in.length() == 0) return;

  if (in == "s" || in == "S") {
    if (dispensing) stopDispense("MANUAL STOP");
    relayOff(); diagMode = 0;
  } else if (in == "t" || in == "T") {
    Serial.print("ms/coin: "); Serial.println(msPerCoin, 1);
    Serial.print("coins/sec: "); Serial.println(1000.0 / msPerCoin, 2);
  } else if (in == "d" || in == "D") {
    diagMode = diagMode ? 0 : 1; relayOff();
    Serial.println(diagMode ? "DIAG ON (relay OFF). Move sensor / drop coin by hand. 'd' again to exit." : "DIAG OFF");
  } else if (in == "r" || in == "R") {
    if (diagMode == 2) { diagMode = 0; relayOff(); Serial.println("DIAG OFF"); }
    else { diagMode = 2; relayOn(); Serial.println("DIAG ON (relay ON, motor running). 'r' or 's' to stop."); }
  } else {
    long n = in.toInt();
    if (n > 0) startDispense((uint32_t)n);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  relayOff();
  pinMode(COIN_PIN, COIN_PIN_MODE);
  delay(1500);
  Serial.println("Coin hopper ready. Number = dispense, s stop, t stats, d/r diagnostic.");
}

void loop() {
  readCoin();
  handleSerial();
  handleDispense();

  static uint32_t lastShown = 0;
  if (dispensing && coinCount != lastShown) {
    lastShown = coinCount;
    Serial.print("Coin "); Serial.print(lastShown);
    Serial.print(" | interval "); Serial.print(pulseIntervalMs); Serial.println(" ms");
  }
  if (!dispensing) lastShown = 0;
}
