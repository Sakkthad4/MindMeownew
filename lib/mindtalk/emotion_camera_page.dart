// lib/mindtalk/emotion_camera_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_input_converter.dart';

/// =======================
/// Emotion model (simple)
/// =======================
enum DetectedEmotion { neutral, happy, sad }

class CameraEmotionObservation {
  const CameraEmotionObservation({
    required this.emotion,
    required this.confidence,
  });

  final DetectedEmotion emotion;
  final double confidence;
}

extension DetectedEmotionX on DetectedEmotion {
  String get labelTH {
    switch (this) {
      case DetectedEmotion.happy:
        return "ดีใจ";
      case DetectedEmotion.sad:
        return "เศร้า";
      case DetectedEmotion.neutral:
        return "ปกติ";
    }
  }

  // ✅ ไม่มี mqttCmd แล้ว (กันสับสน!)
}

/// =======================
/// Camera + Emotion Page
/// =======================
class EmotionCameraPage extends StatefulWidget {
  final ValueChanged<CameraEmotionObservation>? onEmotionDetected;

  const EmotionCameraPage({super.key, this.onEmotionDetected});

  @override
  State<EmotionCameraPage> createState() => _EmotionCameraPageState();
}

class _EmotionCameraPageState extends State<EmotionCameraPage> {
  CameraController? _controller;
  late FaceDetector _faceDetector;

  DetectedEmotion? _lastEmotion;
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
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
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

      // Keep the original three-state behavior used by MindTalk. The "sad"
      // result is a facial-expression estimate based on a very low smile
      // probability, not a clinical assessment of the user's emotion.
      final DetectedEmotion emotion;
      final double confidence;
      if (smile > 0.75) {
        emotion = DetectedEmotion.happy;
        confidence = smile;
      } else if (smile < 0.20) {
        emotion = DetectedEmotion.sad;
        confidence = (1 - smile).clamp(0.55, 0.90);
      } else {
        emotion = DetectedEmotion.neutral;
        final distanceFromBoundary = math.min(smile - 0.20, 0.75 - smile);
        confidence = (0.50 + distanceFromBoundary).clamp(0.50, 0.80);
      }

      if (emotion != _lastEmotion) {
        _lastEmotion = emotion;
        widget.onEmotionDetected?.call(
          CameraEmotionObservation(emotion: emotion, confidence: confidence),
        );
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
