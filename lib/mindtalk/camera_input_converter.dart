import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraInputConverter {
  static InputImage fromCameraImage(
    CameraImage image, {
    required CameraDescription camera,
  }) {
    // รวม bytes ทุก plane แบบไม่ใช้ WriteBuffer
    final bytes = _concatenatePlanes(image.planes);

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // ✅ ใช้ metadata แบบที่รองรับกว้าง (ไม่มี planeData)
    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final total = planes.fold<int>(0, (sum, p) => sum + p.bytes.length);
    final out = Uint8List(total);
    var offset = 0;
    for (final p in planes) {
      out.setRange(offset, offset + p.bytes.length, p.bytes);
      offset += p.bytes.length;
    }
    return out;
  }
}
