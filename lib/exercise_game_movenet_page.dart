import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'dart:math' as math;

class MindExercisesPage extends StatefulWidget {
  const MindExercisesPage({super.key});

  @override
  State<MindExercisesPage> createState() => _MindExercisesPageState();
}

// ====================== DATA ======================

class _NKp {
  final double x; // normalized [0,1]
  final double y;
  final double likelihood;
  const _NKp(this.x, this.y, this.likelihood);
}

class StretchPose {
  final String title;
  final String instruction;
  final IconData icon;
  final Color color;
  final bool Function(Map<PoseLandmarkType, _NKp>) check;
  const StretchPose({
    required this.title,
    required this.instruction,
    required this.icon,
    required this.color,
    required this.check,
  });
}

// ====================== PAGE ======================

class _MindExercisesPageState extends State<MindExercisesPage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;

  bool _isDetecting = false;
  bool _isCounting = false;
  bool _isCompleted = false;
  int _countdown = 0;
  int _frameCount = 0;

  int _score = 0;
  int _currentPoseIndex = 0;
  int _stableFrames = 0;
  static const int _requiredStableFrames = 2;

  Map<PoseLandmarkType, _NKp> _lastKeypoints = {};
  final bool _showDebugOverlay = true;
  String? _cameraError;

  late final List<StretchPose> _poses;

  StretchPose get _currentPose => _poses[_currentPoseIndex];
  int get _totalPoses => _poses.length;
  double get _progressPercent => _currentPoseIndex / _totalPoses;

  bool get _cameraReady =>
      _cameraController != null &&
      _cameraController!.value.isInitialized &&
      _cameraError == null;

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _poses = _buildRoutine();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
    _init();
  }

  void _init() {
    unawaited(
      _initCamera().catchError((e, st) {
        debugPrint('❌ Camera init: $e\n$st');
        if (mounted) setState(() => _cameraError = e.toString());
      }),
    );
  }

  @override
  void dispose() {
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  // ====================== ROUTINE ======================
  List<StretchPose> _buildRoutine() => [
    StretchPose(
      title: 'ARMS UP',
      instruction: 'RAISE BOTH ARMS STRAIGHT ABOVE YOUR HEAD',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFFB347),
      check: _checkArmsUp,
    ),
    StretchPose(
      title: 'T-POSE',
      instruction: 'OPEN BOTH ARMS SIDEWAYS LIKE A LETTER T',
      icon: Icons.airplanemode_active,
      color: const Color(0xFF8ED1FF),
      check: _checkTPose,
    ),
    StretchPose(
      title: 'NECK STRETCH RIGHT',
      instruction: 'TILT YOUR HEAD GENTLY TO THE RIGHT',
      icon: Icons.arrow_forward_rounded,
      color: const Color(0xFFB5EAD7),
      check: _checkHeadTiltRight,
    ),
    StretchPose(
      title: 'NECK STRETCH LEFT',
      instruction: 'TILT YOUR HEAD GENTLY TO THE LEFT',
      icon: Icons.arrow_back_rounded,
      color: const Color(0xFFB5EAD7),
      check: _checkHeadTiltLeft,
    ),
    StretchPose(
      title: 'SIDE BEND RIGHT',
      instruction: 'BEND YOUR UPPER BODY TO THE RIGHT',
      icon: Icons.accessibility_new_rounded,
      color: const Color(0xFFFFD1DC),
      check: _checkLeanRight,
    ),
    StretchPose(
      title: 'SIDE BEND LEFT',
      instruction: 'BEND YOUR UPPER BODY TO THE LEFT',
      icon: Icons.accessibility_new_rounded,
      color: const Color(0xFFFFD1DC),
      check: _checkLeanLeft,
    ),
  ];

  // ====================== CAMERA ======================
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw 'ไม่พบกล้องบนเครื่องนี้';
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      // MLKit ต้องการ nv21 บน Android, bgra8888 บน iOS
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_processCameraImage);
    if (mounted) setState(() {});
  }

  // ====================== FRAME LOOP ======================
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _isCounting || _isCompleted) return;
    if (_poseDetector == null) return;

    _frameCount++;
    if (_frameCount % 3 != 0) return;

    _isDetecting = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);

      Map<PoseLandmarkType, _NKp> keypoints = {};
      if (poses.isNotEmpty) {
        keypoints = _normalize(poses.first, image);
      }

      if (kDebugMode && _frameCount % 30 == 0) {
        debugPrint('🦴 ${keypoints.length}/33 landmarks');
      }

      if (_showDebugOverlay && mounted) {
        setState(() => _lastKeypoints = keypoints);
      }

      if (_currentPose.check(keypoints)) {
        _stableFrames++;
        if (_stableFrames >= _requiredStableFrames) {
          _stableFrames = 0;
          _startCountdown();
        }
      } else {
        _stableFrames = 0;
      }
    } catch (e, st) {
      debugPrint('❌ Detect: $e\n$st');
    } finally {
      _isDetecting = false;
    }
  }

  // ====================== CameraImage → InputImage ======================
  InputImage? _toInputImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotComp = _orientations[_cameraController!.value.deviceOrientation];
      if (rotComp == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotComp = (sensorOrientation + rotComp) % 360;
      } else {
        rotComp = (sensorOrientation - rotComp + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotComp);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Map<PoseLandmarkType, _NKp> _normalize(Pose pose, CameraImage image) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final result = <PoseLandmarkType, _NKp>{};
    pose.landmarks.forEach((type, lm) {
      if (lm.likelihood > 0.3) {
        result[type] = _NKp(lm.x / w, lm.y / h, lm.likelihood);
      }
    });
    return result;
  }

  // ====================== POSE CHECKS ======================
  bool _checkArmsUp(Map<PoseLandmarkType, _NKp> p) {
    final lw = p[PoseLandmarkType.leftWrist];
    final rw = p[PoseLandmarkType.rightWrist];
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (lw == null || rw == null || ls == null || rs == null) return false;

    // วัด angle และความสูงเพื่อความสมจริง
    double leftElbowAngle = _calculateAngle(
      ls,
      p[PoseLandmarkType.leftElbow],
      lw,
    );
    double rightElbowAngle = _calculateAngle(
      rs,
      p[PoseLandmarkType.rightElbow],
      rw,
    );

    final wristsAboveHead = lw.y < ls.y - 0.05 && rw.y < rs.y - 0.05;
    final elbowsStraight = leftElbowAngle > 150 && rightElbowAngle > 150;

    return wristsAboveHead && elbowsStraight;
  }

  double _calculateAngle(_NKp? a, _NKp? b, _NKp? c) {
    if (a == null || b == null || c == null) return 0;
    final abx = a.x - b.x;
    final aby = a.y - b.y;
    final cbx = c.x - b.x;
    final cby = c.y - b.y;
    final dot = abx * cbx + aby * cby;
    final mag1 = math.sqrt(abx * abx + aby * aby);
    final mag2 = math.sqrt(cbx * cbx + cby * cby);
    if (mag1 == 0 || mag2 == 0) return 0;
    return math.acos((dot / (mag1 * mag2)).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  bool _checkTPose(Map<PoseLandmarkType, _NKp> p) {
    final lw = p[PoseLandmarkType.leftWrist];
    final rw = p[PoseLandmarkType.rightWrist];
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (lw == null || rw == null || ls == null || rs == null) return false;
    final lFlat = (lw.y - ls.y).abs() < 0.12;
    final rFlat = (rw.y - rs.y).abs() < 0.12;
    final shoulderW = (ls.x - rs.x).abs();
    final wristW = (lw.x - rw.x).abs();
    return lFlat && rFlat && wristW > shoulderW * 1.4;
  }

  bool _checkHeadTiltRight(Map<PoseLandmarkType, _NKp> p) {
    final n = p[PoseLandmarkType.nose];
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (n == null || ls == null || rs == null) return false;
    final midX = (ls.x + rs.x) / 2;
    return n.x < midX - 0.03;
  }

  bool _checkHeadTiltLeft(Map<PoseLandmarkType, _NKp> p) {
    final n = p[PoseLandmarkType.nose];
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (n == null || ls == null || rs == null) return false;
    final midX = (ls.x + rs.x) / 2;
    return n.x > midX + 0.03;
  }

  bool _checkLeanRight(Map<PoseLandmarkType, _NKp> p) {
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (ls == null || rs == null) return false;
    return rs.y > ls.y + 0.04;
  }

  bool _checkLeanLeft(Map<PoseLandmarkType, _NKp> p) {
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (ls == null || rs == null) return false;
    return ls.y > rs.y + 0.04;
  }

  // ====================== COUNTDOWN ======================
  Future<void> _startCountdown() async {
    if (_isCounting) return;
    setState(() {
      _isCounting = true;
      _countdown = 5;
      _score += 10;
    });
    while (_countdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _countdown--);
    }
    setState(() {
      _score += 50;
      _currentPoseIndex++;
      _isCounting = false;
    });
    if (_currentPoseIndex >= _totalPoses) {
      setState(() => _isCompleted = true);
    }
  }

  void _restart() => setState(() {
    _currentPoseIndex = 0;
    _score = 0;
    _isCompleted = false;
    _stableFrames = 0;
  });

  void _retryInit() {
    setState(() => _cameraError = null);
    _init();
  }

  // ====================== UI ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: _isCompleted ? _buildCompletedView() : _buildGameView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 32),
      const SizedBox(width: 8),
      const Text(
        'Morning Stretch',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      Container(
        width: 180,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FractionallySizedBox(
          widthFactor: _progressPercent.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        '$_currentPoseIndex / $_totalPoses',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: 24),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              '$_score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildCameraStack() {
    if (_cameraError != null) {
      return Container(
        color: Colors.red.shade900,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              'เปิดกล้องไม่สำเร็จ',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _cameraError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryInit,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }

    if (!_cameraReady) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 12),
            Text('กำลังเปิดกล้อง...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        if (_showDebugOverlay)
          CustomPaint(painter: _PosePainter(_lastKeypoints)),
        Positioned(
          top: 16,
          left: 16,
          child: _CountdownBadge(value: _countdown),
        ),
        if (_isCounting)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'ค้างไว้! ทำได้ดีมาก 👍',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameView() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange, width: 6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildCameraStack(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _currentPose.color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentPose.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Icon(_currentPose.icon, size: 140, color: Colors.white),
                const SizedBox(height: 24),
                _InstructionButton(text: _currentPose.instruction),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView() => Center(
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 100,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          const Text(
            'เยี่ยมมาก! เสร็จสิ้นแล้ว 🎉',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'คะแนนของคุณ: $_score',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay),
                label: const Text('ทำอีกครั้ง'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('กลับหน้าหลัก'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ====================== WIDGETS ======================

class _PosePainter extends CustomPainter {
  final Map<PoseLandmarkType, _NKp> kps;
  _PosePainter(this.kps);

  static const _edges = [
    // Arms
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Legs
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = Colors.limeAccent
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = Colors.limeAccent.withOpacity(0.6)
      ..strokeWidth = 2;

    Offset map(_NKp k) => Offset(k.x * size.width, k.y * size.height);

    for (final e in _edges) {
      final a = kps[e[0]], b = kps[e[1]];
      if (a != null && b != null) canvas.drawLine(map(a), map(b), line);
    }
    for (final k in kps.values) {
      canvas.drawCircle(map(k), 5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _PosePainter old) => old.kps != kps;
}

class _CountdownBadge extends StatelessWidget {
  final int value;
  const _CountdownBadge({required this.value});
  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox();
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 4),
      ),
      alignment: Alignment.center,
      child: Text(
        value.toString(),
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InstructionButton extends StatelessWidget {
  final String text;
  const _InstructionButton({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
