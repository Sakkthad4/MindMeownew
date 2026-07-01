// lib/mindtalk/emotion_camera_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_input_converter.dart';

/// =======================
/// Emotion model (simple)
/// =======================
enum DetectedEmotion { neutral, happy, sad }

extension DetectedEmotionX on DetectedEmotion {
  String get labelTH {
    switch (this) {
      case DetectedEmotion.happy:
        return "ดีใจ";
      case DetectedEmotion.sad:
        return "เศร้า";
      case DetectedEmotion.neutral:
      default:
        return "ปกติ";
    }
  }
  // ✅ ไม่มี mqttCmd แล้ว (กันสับสน!)
}

/// =======================
/// Camera + Emotion Page
/// =======================
class EmotionCameraPage extends StatefulWidget {
  final ValueChanged<DetectedEmotion>? onEmotionDetected;

  const EmotionCameraPage({super.key, this.onEmotionDetected});

  @override
  State<EmotionCameraPage> createState() => _EmotionCameraPageState();
}

class _EmotionCameraPageState extends State<EmotionCameraPage> {
  CameraController? _controller;
  late FaceDetector _faceDetector;

  DetectedEmotion _lastEmotion = DetectedEmotion.neutral;
  DateTime _lastDetect = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processFrame);

    if (mounted) setState(() {});
  }

  bool _canDetect() {
    final now = DateTime.now();
    if (now.difference(_lastDetect).inMilliseconds > 800) {
      _lastDetect = now;
      return true;
    }
    return false;
  }

  Future<void> _processFrame(CameraImage image) async {
    if (!_canDetect()) return;
    if (_controller == null) return;
    if (_busy) return;

    _busy = true;
    try {
      final inputImage = CameraInputConverter.fromCameraImage(
        image,
        camera: _controller!.description,
      );

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return;

      final face = faces.first;
      final smile = face.smilingProbability ?? 0.0;

      DetectedEmotion emotion;
      if (smile > 0.75) {
        emotion = DetectedEmotion.happy;
      } else if (smile < 0.2) {
        emotion = DetectedEmotion.sad;
      } else {
        emotion = DetectedEmotion.neutral;
      }

      if (emotion != _lastEmotion) {
        _lastEmotion = emotion;
        widget.onEmotionDetected?.call(emotion); // ✅ ส่งขึ้นไปให้ UI โชว์
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    try {
      _controller?.stopImageStream();
    } catch (_) {}
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CameraPreview(_controller!),
    );
  }
}
