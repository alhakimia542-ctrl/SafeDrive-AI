import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: DriverSafetyScreen(cameras: cameras),
    ),
  );
}

class DriverSafetyScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const DriverSafetyScreen({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  State<DriverSafetyScreen> createState() =>
      _DriverSafetyScreenState();
}

class _DriverSafetyScreenState
    extends State<DriverSafetyScreen> {
  // ==============================
  // Camera & AI
  // ==============================

  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  bool _isProcessing = false;

  // ==============================
  // Bluetooth
  // ==============================

  BluetoothConnection? _bluetoothConnection;

  List<BluetoothDevice> _devicesList = [];

  BluetoothDevice? _selectedDevice;

  bool _isBluetoothConnected = false;

  // ==============================
  // UI & Logic
  // ==============================

  String _statusText = "جاري تهيئة النظام...";

  bool _isDrowsy = false;

  String _lastSignal = '';

  // ==============================
  // Init
  // ==============================

  @override
  void initState() {
    super.initState();

    _initializeFaceDetector();

    _initializeCamera();

    _getBluetoothDevices();
  }

  // ==============================
  // Face Detector Initialization
  // ==============================

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    );

    _faceDetector = FaceDetector(options: options);
  }

  // ==============================
  // Camera Initialization
  // ==============================

  void _initializeCamera() async {
    try {
      final frontCamera = widget.cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      await _cameraController!.startImageStream(
        (CameraImage image) {
          if (!_isProcessing) {
            _isProcessing = true;
            _processCameraImage(image);
          }
        },
      );

      setState(() {
        _statusText =
            "الكاميرا جاهزة، اختر جهاز البلوتوث";
      });
    } catch (e) {
      setState(() {
        _statusText = "فشل تشغيل الكاميرا ❌";
      });

      debugPrint("Camera Error: $e");
    }
  }

  // ==============================
  // Get Bluetooth Devices
  // ==============================

  void _getBluetoothDevices() async {
    try {
      final devices =
          await FlutterBluetoothSerial.instance
              .getBondedDevices();

      setState(() {
        _devicesList = devices;
      });
    } catch (e) {
      debugPrint("Bluetooth Devices Error: $e");

      setState(() {
        _statusText =
            "فشل جلب أجهزة البلوتوث ❌";
      });
    }
  }

  // ==============================
  // Bluetooth Connection
  // ==============================

  void _connectToBluetooth() async {
    if (_selectedDevice == null) return;

    try {
      setState(() {
        _statusText =
            "جاري الاتصال بـ ${_selectedDevice!.name}...";
      });

      BluetoothConnection connection =
          await BluetoothConnection.toAddress(
        _selectedDevice!.address,
      );

      setState(() {
        _bluetoothConnection = connection;

        _isBluetoothConnected = true;

        _statusText =
            "تم الاتصال بالبلوتوث بنجاح ✅";
      });

      // مراقبة قطع الاتصال
      connection.input?.listen(null).onDone(() {
        if (mounted) {
          setState(() {
            _isBluetoothConnected = false;

            _statusText =
                "تم قطع اتصال البلوتوث ❌";
          });
        }
      });
    } catch (e) {
      debugPrint("Bluetooth Connection Error: $e");

      setState(() {
        _isBluetoothConnected = false;

        _statusText =
            "فشل الاتصال بالبلوتوث ❌";
      });
    }
  }

  // ==============================
  // Image Processing
  // ==============================

  void _processCameraImage(
    CameraImage image,
  ) async {
    try {
      final WriteBuffer allBytes =
          WriteBuffer();

      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }

      final bytes =
          allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(
                image.format.raw,
              ) ??
              InputImageFormat.nv21;

      final planeData = image.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation:
            InputImageRotation.rotation270deg,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        inputImageData: inputImageData,
      );

      final faces =
          await _faceDetector!.processImage(
        inputImage,
      );

      // ==============================
      // No Face Detected
      // ==============================

      if (faces.isEmpty) {
        _sendDataToArduino('0');

        _updateStatus(
          "لم يتم اكتشاف وجه السائق",
          false,
        );
      } else {
        for (Face face in faces) {
          if (face.leftEyeOpenProbability !=
                  null &&
              face.rightEyeOpenProbability !=
                  null) {
            double leftEye =
                face.leftEyeOpenProbability!;

            double rightEye =
                face.rightEyeOpenProbability!;

            // ==============================
            // Drowsiness Detection
            // ==============================

            if (leftEye < 0.3 &&
                rightEye < 0.3) {
              _sendDataToArduino('1');

              _updateStatus(
                "⚠️ تحذير: تم رصد إغلاق العين!",
                true,
              );
            } else {
              _sendDataToArduino('0');

              _updateStatus(
                "السائق مستيقظ والوضع آمن ✅",
                false,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("ML Processing Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // ==============================
  // Send Bluetooth Data
  // ==============================

  void _sendDataToArduino(String signal) async {
    // منع إرسال نفس الإشارة بشكل متكرر
    if (signal == _lastSignal) return;

    _lastSignal = signal;

    try {
      if (_bluetoothConnection != null &&
          _bluetoothConnection!.isConnected) {
        _bluetoothConnection!.output.add(
          utf8.encode(signal),
        );

        await _bluetoothConnection!
            .output
            .allSent;
      }
    } catch (e) {
      debugPrint("Send Data Error: $e");
    }
  }

  // ==============================
  // Update UI
  // ==============================

  void _updateStatus(
    String text,
    bool drowsy,
  ) {
    if (!mounted) return;

    setState(() {
      _statusText = text;

      _isDrowsy = drowsy;
    });
  }

  // ==============================
  // Dispose
  // ==============================

  @override
  void dispose() {
    _cameraController?.dispose();

    _faceDetector?.close();

    _bluetoothConnection?.dispose();

    super.dispose();
  }

  // ==============================
  // UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SafeDrive AI System",
        ),
        centerTitle: true,
      ),

      backgroundColor: _isDrowsy
          ? Colors.red[900]
          : Colors.grey[900],

      body: Column(
        children: [
          // ==============================
          // Bluetooth Panel
          // ==============================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            color: Colors.black54,
            child: Row(
              children: [
                Expanded(
                  child:
                      DropdownButton<
                          BluetoothDevice>(
                    dropdownColor:
                        Colors.black87,

                    isExpanded: true,

                    hint: const Text(
                      "اختر جهاز البلوتوث",
                    ),

                    value: _selectedDevice,

                    items:
                        _devicesList.map(
                      (device) {
                        return DropdownMenuItem<
                            BluetoothDevice>(
                          value: device,
                          child: Text(
                            device.name ??
                                "Unknown Device",
                          ),
                        );
                      },
                    ).toList(),

                    onChanged: (device) {
                      setState(() {
                        _selectedDevice =
                            device;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed:
                      _connectToBluetooth,

                  child: const Text(
                    "اتصال",
                  ),
                ),
              ],
            ),
          ),

          // ==============================
          // Camera Preview
          // ==============================

          Expanded(
            child:
                _cameraController != null &&
                        _cameraController!
                            .value
                            .isInitialized
                    ? CameraPreview(
                        _cameraController!,
                      )
                    : const Center(
                        child:
                            CircularProgressIndicator(),
                      ),
          ),

          // ==============================
          // Status Bar
          // ==============================

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(20),

            color: Colors.black,

            child: Text(
              _statusText,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}