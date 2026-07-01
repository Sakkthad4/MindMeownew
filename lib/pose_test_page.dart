/*import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseTestPage extends StatefulWidget {
  const PoseTestPage({super.key});

  @override
  State<PoseTestPage> createState() => _PoseTestPageState();
}

class _PoseTestPageState extends State<PoseTestPage> {
  CameraController? _cameraController;
  late final PoseDetector _poseDetector;

  bool _isBusy = false;
  Pose? _pose;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    // แนะนำใช้กล้องหน้าเวลาเล่น Stretch
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Android ส่วนใหญ่จะเป็น yuv420
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  InputImageRotation _rotationFromCamera(CameraDescription camera) {
    // แบบง่าย: ใช้ sensorOrientation
    // ถ้าต้องแม่นกว่านี้ค่อยทำ mapping ตาม device orientation เพิ่ม
    final rotation = camera.sensorOrientation;
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  /// แปลง CameraImage (YUV420) -> NV21 (Android)
  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final Uint8List nv21 = Uint8List(width * height + (width * height ~/ 2));

    // copy Y
    int index = 0;
    for (int y = 0; y < height; y++) {
      final int yRow = yPlane.bytesPerRow * y;
      for (int x = 0; x < width; x++) {
        nv21[index++] = yPlane.bytes[yRow + x];
      }
    }

    // interleave VU
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;

    for (int y = 0; y < uvHeight; y++) {
      final int uRow = uPlane.bytesPerRow * y;
      final int vRow = vPlane.bytesPerRow * y;

      for (int x = 0; x < uvWidth; x++) {
        final int uIndex = uRow + x * uPlane.bytesPerPixel!;
        final int vIndex = vRow + x * vPlane.bytesPerPixel!;
        nv21[index++] = vPlane.bytes[vIndex]; // V
        nv21[index++] = uPlane.bytes[uIndex]; // U
      }
    }

    return nv21;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _cameraController == null) return;
    _isBusy = true;

    try {
      final camera = _cameraController!.description;
      final rotation = _rotationFromCamera(camera);

      late Uint8List bytes;
      late InputImageFormat format;
      late int bytesPerRow;

      if (Platform.isAndroid) {
        // ML Kit commons รองรับ nv21 บน Android :contentReference[oaicite:3]{index=3}
        bytes = _yuv420ToNv21(image);
        format = InputImageFormat.nv21;
        bytesPerRow = image.width; // สำหรับ nv21 ให้ใช้ width เป็น bytesPerRow
      } else if (Platform.isIOS) {
        // iOS ส่วนใหญ่ camera จะให้ bgra8888 ถ้าไม่ได้ให้ ให้ลองปรับ imageFormatGroup
        bytes = _concatenatePlanes(image.planes);
        format = InputImageFormat.bgra8888;
        bytesPerRow = image.planes.first.bytesPerRow;
      } else {
        // เผื่อ platform อื่น ๆ
        bytes = _concatenatePlanes(image.planes);
        format = InputImageFormat.yuv420; // อาจไม่รองรับ แต่กันพัง
        bytesPerRow = image.planes.first.bytesPerRow;
      }

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      ); // ใช้ metadata ตาม API ใหม่ :contentReference[oaicite:4]{index=4}

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        if (mounted) setState(() => _pose = poses.first);
      } else {
        if (mounted) setState(() => _pose = null);
      }
    } catch (_) {
      // เงียบไว้สำหรับ test (ถ้าจะ debug ค่อย print)
    } finally {
      _isBusy = false;
    }
  }

  double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);

    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final magAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    final magCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy);

    final cosv = (dot / (magAB * magCB)).clamp(-1.0, 1.0);
    return acos(cosv) * 180 / pi;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double? leftElbowAngle;
    if (_pose != null) {
      final s = _pose!.landmarks[PoseLandmarkType.leftShoulder];
      final e = _pose!.landmarks[PoseLandmarkType.leftElbow];
      final w = _pose!.landmarks[PoseLandmarkType.leftWrist];
      if (s != null && e != null && w != null) {
        leftElbowAngle = _angle(s, e, w);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Pose Detection Test")),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            left: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 153),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                leftElbowAngle == null
                    ? "No pose"
                    : "Left Elbow: ${leftElbowAngle.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
