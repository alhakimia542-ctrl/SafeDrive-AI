// =====================================================
// SafeDrive AI - Driver Drowsiness Alert System
// =====================================================

const int relayPin = 13;
const int buzzerPin = 12;

int sleepCounter = 0;

const int threshold = 15;
const long maxGapTime = 1000;

unsigned long lastSignalTime = 0;

void setup() {
  Serial.begin(9600);

  pinMode(relayPin, OUTPUT);
  pinMode(buzzerPin, OUTPUT);

  digitalWrite(relayPin, LOW);
  digitalWrite(buzzerPin, LOW);
}

void loop() {

  // Reset counter if signal stream stops
  if (sleepCounter > 0 && (millis() - lastSignalTime > maxGapTime)) {
    sleepCounter = 0;
  }

  // Read Bluetooth data
  if (Serial.available() > 0) {

    char data = Serial.read();

    // Drowsiness detected
    if (data == '1') {

      sleepCounter++;
      lastSignalTime = millis();

      // Trigger alert after continuous signals
      if (sleepCounter >= threshold) {

        for (int i = 0; i < 5; i++) {

          digitalWrite(relayPin, HIGH);
          digitalWrite(buzzerPin, HIGH);
          delay(500);

          digitalWrite(relayPin, LOW);
          digitalWrite(buzzerPin, LOW);
          delay(500);
        }

        sleepCounter = 0;
      }
    }

    // Driver awake
    else if (data == '0') {

      sleepCounter = 0;

      digitalWrite(relayPin, LOW);
      digitalWrite(buzzerPin, LOW);
    }
  }
}