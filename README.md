SafeDrive AI 

SafeDrive AI is a real-time driver drowsiness detection system that I built using Flutter, Google ML Kit, Arduino, and Bluetooth communication.

The main idea behind the project is to monitor the driver’s eyes using the phone’s front camera. If the system detects that the driver’s eyes are closed for a dangerous amount of time, it sends a wireless signal to an Arduino-based alert system connected to a buzzer and vehicle warning lights.

I wanted this project to combine multiple areas that I’m interested in:

Mobile Development
Artificial Intelligence
Computer Vision
Embedded Systems
Real-time Processing

instead of building a normal standalone AI model.

 Demo & Project Links
YouTube Demo

Watch the Project Demo

LinkedIn Project Post

View the LinkedIn Project Post

 Mobile Application Side

The mobile application was developed using Flutter.

The app uses the smartphone’s front camera and continuously processes image frames in real time instead of recording traditional video.

Using:

startImageStream()

the camera feed is converted into live frames that are processed directly by the AI engine.

Each frame is transformed into an InputImage object and passed to Google ML Kit Face Detection.

The system analyzes:

facial landmarks
eye positions
eye opening probability

The core logic depends on:

leftEyeOpenProbability
rightEyeOpenProbability

The values range between:

0.0 → fully closed eye
1.0 → fully open eye

If both eyes remain mostly closed:

if(leftEye < 0.3 && rightEye < 0.3)

the application considers the situation as possible drowsiness and sends a warning signal.

If no face is detected, the app automatically resets the warning state to reduce false detections.

 AI & Computer Vision Logic

The project uses Google ML Kit’s face detection system, which internally relies on deep learning models trained for facial analysis and eye classification.

The AI model estimates whether the eyes are:

open
partially closed
fully closed

This allows the application to make real-time decisions directly on the phone without needing cloud processing.

One thing I focused on was keeping the processing lightweight enough to run continuously on a mobile device while still maintaining stable detection performance.

 Bluetooth Communication

The application communicates wirelessly with an HC-05 Bluetooth module using:

flutter_bluetooth_serial

The connection works as a serial communication channel between the phone and the Arduino.

The app sends:

'1' → drowsiness detected
'0' → driver is awake

These values are transmitted through Bluetooth and received by the Arduino board in real time.

 Arduino Side

The Arduino continuously listens for incoming serial data from the HC-05 module.

One important challenge in this project was avoiding false alarms caused by normal eye blinking.

A normal human blink only lasts for a fraction of a second, so activating the alarm immediately after receiving one warning signal would create many false positives.

To solve this, I implemented a filtering mechanism using:

a counter
timing validation

The Arduino only triggers the alarm after receiving multiple continuous warning signals within a short period of time.

This makes the system significantly more stable and practical for real-world usage.

 Alert & Hardware System

When the warning threshold is reached:

the buzzer activates
the relay turns on
external warning lights can flash

The hardware side was designed with protection in mind using:

relay isolation
diode protection
fused vehicle power input

The warning system can also be connected to vehicle hazard lights safely without interfering with the original electrical wiring.

 Vehicle Electrical Integration

To safely control both left and right vehicle indicators, the project uses a dual-diode isolation setup.

This prevents electrical feedback between both signal lines and protects the original vehicle wiring system.

I used high-current diodes such as:

1N5408

to ensure safe current flow toward both indicators without back-feeding current into the opposite direction.

 APK Build Process

The Android APK was generated using:

flutter build apk --release

The release build compiles Dart code into optimized native ARM binaries for smoother real-time performance and lower latency during camera processing.

 Android Permissions

The application requires access to:

Camera
Bluetooth
Nearby devices

Main permissions include:

android.permission.CAMERA
android.permission.BLUETOOTH_CONNECT
android.permission.BLUETOOTH_ADMIN
 Technologies Used
Mobile Development
Flutter
Dart
AI & Computer Vision
Google ML Kit Face Detection
Embedded Systems
Arduino Uno
HC-05 Bluetooth Module
Relay Module
Piezoelectric Buzzer
Electrical Components
1N5408 Diodes
Fuse Protection
Vehicle 12V Integration
 Flutter Packages
camera: ^0.10.5
google_mlkit_face_detection: ^0.11.0
flutter_bluetooth_serial: ^0.4.0
 Files Included
main.dart
build.gradle.kts
safedrive_arduino.ino
README.md
 Features
Real-time driver monitoring
AI-based eye-state detection
Real-time camera frame processing
Bluetooth communication with Arduino
Hardware-based alert system
False-alarm filtering logic
Relay and buzzer activation
Vehicle warning light integration
 Future Improvements

Some improvements I would like to work on in the future:

TensorFlow Lite custom models
Head pose estimation
Night vision support
GPS emergency notifications
Fatigue analytics dashboard
Edge AI optimization
 About Me

I’m an Artificial Intelligence Engineering student interested in:

Computer Vision
Embedded Systems
Robotics
AI-powered mobile applications

I enjoy building projects that combine software and hardware into practical real-world systems.
