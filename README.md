# SafeDrive AI

SafeDrive AI is a real-time driver drowsiness detection system that I built using Flutter, Google ML Kit, Arduino, and Bluetooth communication.

The idea behind the project is simple: monitor the driver’s eyes using the phone’s front camera and detect dangerous eye closure in real time. If the system determines that the driver may be falling asleep, it sends a wireless signal to an Arduino-based alert system connected to a buzzer and vehicle warning lights.

I wanted this project to combine multiple areas that I’m interested in, including:

- Mobile Development
- Artificial Intelligence
- Computer Vision
- Embedded Systems
- Real-time Processing

instead of building a normal standalone AI model.

---

# How the System Works

The Flutter application continuously captures image frames from the phone’s front camera using the `camera` package.

Each frame is processed using Google ML Kit Face Detection. The AI model analyzes the driver’s face and calculates the probability of both eyes being open.

The system uses:

- `leftEyeOpenProbability`
- `rightEyeOpenProbability`

If both values fall below a specific threshold, the application considers the eyes closed and sends a signal through Bluetooth to the Arduino system.

To avoid false alarms caused by normal blinking, the Arduino uses a timing and counter-based filtering algorithm. The alert is only triggered after receiving multiple continuous sleep signals within a limited time window.

Once the condition is confirmed, the Arduino activates:

- A buzzer alarm
- Vehicle warning lights using a relay module

This creates both an audio and visual warning system.

---

# Technologies Used

## Mobile Application
- Flutter
- Dart

## AI & Computer Vision
- Google ML Kit Face Detection

## Hardware
- Arduino Uno
- HC-05 Bluetooth Module
- Relay Module
- Buzzer

## Communication
- Bluetooth Serial Communication

---

# Main Files Included

This repository contains the main core files used in the project:

- `main.dart`
- `build.gradle.kts`
- `app_build.gradle.kts`
- `SafeDrive_Arduino.ino`

---

# Features

- Real-time eye monitoring
- Drowsiness detection using AI
- Wireless communication between phone and Arduino
- Smart filtering to reduce false positives
- Audio and light alert system
- Real-time camera processing

---

# Build APK

The release APK was generated using:

```bash
flutter build apk --release
```

The project also includes Gradle configuration files required for Flutter Android builds.

---

# Demo Video

YouTube Demo:
https://youtu.be/uoXS8Cu0Rs4?si=LazIkaRiVDLrga2_

---

# LinkedIn Post

Project Post:
https://www.linkedin.com/posts/%D8%A7%D8%AD%D9%85%D8%AF-%D8%A7%D9%84%D8%AD%D9%83%D9%8A%D9%85%D9%8A-833380344_computervision-flutter-artificialintelligence-ugcPost-7463650859915046912-4-Cj

---

# Notes

This project was built as a practical learning experience to better understand how AI models can interact with embedded systems and real-world hardware in real time.

The main focus was not only detecting drowsiness, but also building a complete end-to-end system that combines software, AI, and electronics together.
