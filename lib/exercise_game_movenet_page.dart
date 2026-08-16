import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_language.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

import 'exercise_pose_geometry.dart';
import 'healthcare/data/exercise_session_store.dart';

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

class _StretchPose {
  final String title;
  final String instruction;
  final String imagePath;
  final Color color;
  final bool Function(Map<PoseLandmarkType, _NKp>) check;
  const _StretchPose({
    required this.title,
    required this.instruction,
    required this.imagePath,
    required this.color,
    required this.check,
  });
}

// ====================== PAGE ======================

class _MindExercisesPageState extends State<MindExercisesPage> {
  final ExerciseSessionStore _sessionStore = ExerciseSessionStore();
  DateTime _sessionStartedAt = DateTime.now();
  bool _sessionRecorded = false;

  CameraController? _cameraController;
  PoseDetector? _poseDetector;

  bool _isDetecting = false;
  bool _isCounting = false;
  bool _isCompleted = false;
  int _countdown = 0;
  int _frameCount = 0;
  DateTime? _holdStartedAt;
  InputImageRotation? _lastInputRotation;
  String _poseDebugStatus = '';

  int _score = 0;
  int _currentPoseIndex = 0;
  int _stableFrames = 0;
  int _missedFrames = 0;
  static const int _requiredStableFrames = 2;
  static const int _allowedMissedFramesWhileHolding = 3;
  static const int _holdSeconds = 5;

  Map<PoseLandmarkType, _NKp> _lastKeypoints = {};
  final bool _showDebugOverlay = true;
  String? _cameraError;

  late final List<_StretchPose> _poses;

  _StretchPose get _currentPose => _poses[_currentPoseIndex];
  int get _totalPoses => _poses.length;
  double get _progressPercent => _currentPoseIndex / _totalPoses;
  bool get _isShoulderStretch =>
      _currentPoseIndex == 4 || _currentPoseIndex == 5;

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
    if (!_sessionRecorded && _currentPoseIndex > 0) {
      _recordSession(completed: false);
    }
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  // ====================== ROUTINE ======================
  List<_StretchPose> _buildRoutine() => [
    _StretchPose(
      title: AppText.name('OVERHEAD REACH'),
      instruction: AppText.name(
        'STAND TALL AND REACH BOTH ARMS GENTLY ABOVE YOUR HEAD',
      ),
      imagePath: 'assets/images/exercise_poses/overhead_reach.png',
      color: const Color(0xFFFFB347),
      check: _checkArmsUp,
    ),
    _StretchPose(
      title: AppText.name('SIDE BEND RIGHT'),
      instruction: AppText.name(
        'KEEP YOUR ARMS UP AND BEND YOUR UPPER BODY GENTLY TO THE RIGHT',
      ),
      imagePath: 'assets/images/exercise_poses/side_bend_right.png',
      color: const Color(0xFFFFD1DC),
      check: (points) =>
          _checkArmsRaisedForSideBend(points) && _checkLeanRight(points),
    ),
    _StretchPose(
      title: AppText.name('SIDE BEND LEFT'),
      instruction: AppText.name(
        'KEEP YOUR ARMS UP AND BEND YOUR UPPER BODY GENTLY TO THE LEFT',
      ),
      imagePath: 'assets/images/exercise_poses/side_bend_left.png',
      color: const Color(0xFFFFD1DC),
      check: (points) =>
          _checkArmsRaisedForSideBend(points) && _checkLeanLeft(points),
    ),
    _StretchPose(
      title: AppText.name('CHEST OPENER'),
      instruction: AppText.name(
        'OPEN BOTH ARMS SIDEWAYS AND KEEP YOUR SHOULDERS RELAXED',
      ),
      imagePath: 'assets/images/exercise_poses/chest_opener.png',
      color: const Color(0xFF8ED1FF),
      check: _checkTPose,
    ),
    _StretchPose(
      title: AppText.name('RIGHT SHOULDER STRETCH'),
      instruction: AppText.name(
        'BRING YOUR RIGHT ARM ACROSS YOUR CHEST AND KEEP IT STRAIGHT',
      ),
      imagePath: 'assets/images/exercise_poses/right_shoulder_stretch.png',
      color: const Color(0xFFC9B8FF),
      check: (points) => _checkCrossBodyShoulder(points, rightArm: true),
    ),
    _StretchPose(
      title: AppText.name('LEFT SHOULDER STRETCH'),
      instruction: AppText.name(
        'BRING YOUR LEFT ARM ACROSS YOUR CHEST AND KEEP IT STRAIGHT',
      ),
      imagePath: 'assets/images/exercise_poses/left_shoulder_stretch.png',
      color: const Color(0xFFC9B8FF),
      check: (points) => _checkCrossBodyShoulder(points, rightArm: false),
    ),
    _StretchPose(
      title: AppText.name('RIGHT QUAD STRETCH'),
      instruction: AppText.name(
        'BEND YOUR RIGHT KNEE AND LIFT YOUR FOOT GENTLY BEHIND YOU',
      ),
      imagePath: 'assets/images/exercise_poses/right_quad_stretch.png',
      color: const Color(0xFF8EDDC2),
      check: (points) => _checkQuadStretch(points, rightLeg: true),
    ),
    _StretchPose(
      title: AppText.name('LEFT QUAD STRETCH'),
      instruction: AppText.name(
        'BEND YOUR LEFT KNEE AND LIFT YOUR FOOT GENTLY BEHIND YOU',
      ),
      imagePath: 'assets/images/exercise_poses/left_quad_stretch.png',
      color: const Color(0xFF8EDDC2),
      check: (points) => _checkQuadStretch(points, rightLeg: false),
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
    if (_isDetecting || _isCompleted) return;
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

      final poseIsCorrect = _currentPose.check(keypoints);
      if (poseIsCorrect) {
        _missedFrames = 0;
        _stableFrames++;
        if (!_isCounting && _stableFrames >= _requiredStableFrames) {
          _holdStartedAt = DateTime.now();
          if (mounted) {
            setState(() {
              _isCounting = true;
              _countdown = _holdSeconds;
            });
          }
        } else if (_isCounting && _holdStartedAt != null) {
          final elapsed = DateTime.now().difference(_holdStartedAt!).inSeconds;
          final remaining = (_holdSeconds - elapsed).clamp(0, _holdSeconds);
          if (remaining == 0) {
            _completeCurrentPose();
          } else if (remaining != _countdown && mounted) {
            setState(() => _countdown = remaining);
          }
        }
      } else {
        _stableFrames = 0;
        if (_isCounting) _missedFrames++;
        if (_isCounting &&
            _missedFrames > _allowedMissedFramesWhileHolding &&
            mounted) {
          setState(() {
            _isCounting = false;
            _countdown = 0;
            _holdStartedAt = null;
            _missedFrames = 0;
          });
        }
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
    _lastInputRotation = rotation;

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
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final rotation = _lastInputRotation ?? InputImageRotation.rotation0deg;
    final rotatedOnAndroid =
        Platform.isAndroid &&
        (rotation == InputImageRotation.rotation90deg ||
            rotation == InputImageRotation.rotation270deg);
    final xDenominator = rotatedOnAndroid ? imageHeight : imageWidth;
    final yDenominator = rotatedOnAndroid ? imageWidth : imageHeight;
    final camera = _cameraController!.description;

    final result = <PoseLandmarkType, _NKp>{};
    pose.landmarks.forEach((type, lm) {
      // Cross-body stretches naturally occlude a wrist or elbow. Retain these
      // lower-confidence points and use multi-frame stability to reject noise.
      if (lm.likelihood < 0.15) return;

      var x = lm.x / xDenominator;
      final y = lm.y / yDenominator;
      final shouldFlipX =
          rotation == InputImageRotation.rotation270deg ||
          ((rotation == InputImageRotation.rotation0deg ||
                  rotation == InputImageRotation.rotation180deg) &&
              camera.lensDirection == CameraLensDirection.front);
      if (shouldFlipX) x = 1 - x;

      result[type] = _NKp(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0), lm.likelihood);
    });
    return result;
  }

  // ====================== POSE CHECKS ======================
  bool _checkArmsUp(Map<PoseLandmarkType, _NKp> p) {
    return _checkRaisedArms(p, minimumElbowAngle: 150, liftMargin: 0.05);
  }

  bool _checkArmsRaisedForSideBend(Map<PoseLandmarkType, _NKp> p) {
    return _checkRaisedArms(p, minimumElbowAngle: 125, liftMargin: -0.02);
  }

  bool _checkRaisedArms(
    Map<PoseLandmarkType, _NKp> p, {
    required double minimumElbowAngle,
    required double liftMargin,
  }) {
    final lw = p[PoseLandmarkType.leftWrist];
    final rw = p[PoseLandmarkType.rightWrist];
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (lw == null || rw == null || ls == null || rs == null) return false;

    final leftElbowAngle = _calculateAngle(
      ls,
      p[PoseLandmarkType.leftElbow],
      lw,
    );
    final rightElbowAngle = _calculateAngle(
      rs,
      p[PoseLandmarkType.rightElbow],
      rw,
    );

    final wristsRaised = lw.y < ls.y - liftMargin && rw.y < rs.y - liftMargin;
    final elbowsStraight =
        leftElbowAngle > minimumElbowAngle &&
        rightElbowAngle > minimumElbowAngle;

    return wristsRaised && elbowsStraight;
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

  bool _checkLeanRight(Map<PoseLandmarkType, _NKp> p) {
    final lean = _bodyRelativeLean(p);
    return lean != null && lean > 0.08;
  }

  bool _checkLeanLeft(Map<PoseLandmarkType, _NKp> p) {
    final lean = _bodyRelativeLean(p);
    return lean != null && lean < -0.08;
  }

  /// Positive values mean the shoulders move toward the user's anatomical
  /// right side. This stays correct when a front-camera preview is mirrored.
  double? _bodyRelativeLean(Map<PoseLandmarkType, _NKp> p) {
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    final lh = p[PoseLandmarkType.leftHip];
    final rh = p[PoseLandmarkType.rightHip];
    if (ls == null || rs == null || lh == null || rh == null) return null;

    final shoulderWidth = (rs.x - ls.x).abs();
    if (shoulderWidth < 0.04) return null;
    final bodyRightDirection = (rs.x - ls.x).sign;
    final shoulderMidX = (ls.x + rs.x) / 2;
    final hipMidX = (lh.x + rh.x) / 2;
    final hipsAreLevel = (lh.y - rh.y).abs() < 0.10;
    if (!hipsAreLevel) return null;

    return ((shoulderMidX - hipMidX) * bodyRightDirection) / shoulderWidth;
  }

  bool _checkCrossBodyShoulder(
    Map<PoseLandmarkType, _NKp> p, {
    required bool rightArm,
  }) {
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    final shoulder =
        p[rightArm
            ? PoseLandmarkType.rightShoulder
            : PoseLandmarkType.leftShoulder];
    final elbow =
        p[rightArm ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow];
    final wrist =
        p[rightArm ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist];
    if (ls == null ||
        rs == null ||
        shoulder == null ||
        (elbow == null && wrist == null)) {
      _poseDebugStatus =
          '${rightArm ? 'R' : 'L'} shoulder: missing arm landmarks';
      return false;
    }

    final shoulderWidth = (rs.x - ls.x).abs();
    if (shoulderWidth < 0.04) return false;

    double bodyX(_NKp point) => ExercisePoseGeometry.bodyRelativeX(
      pointX: point.x,
      leftShoulderX: ls.x,
      rightShoulderX: rs.x,
    );

    final isCorrect = ExercisePoseGeometry.isCrossBodyShoulder(
      rightArm: rightArm,
      leftShoulder: Offset(ls.x, ls.y),
      rightShoulder: Offset(rs.x, rs.y),
      activeShoulder: Offset(shoulder.x, shoulder.y),
      activeElbow: elbow == null ? null : Offset(elbow.x, elbow.y),
      activeWrist: wrist == null ? null : Offset(wrist.x, wrist.y),
    );

    final wristValue = wrist == null ? '--' : bodyX(wrist).toStringAsFixed(2);
    final elbowValue = elbow == null ? '--' : bodyX(elbow).toStringAsFixed(2);
    _poseDebugStatus =
        '${rightArm ? 'R' : 'L'} arm  E:$elbowValue W:$wristValue  '
        '${isCorrect ? 'POSE ✓' : 'move arm across chest'}';

    return isCorrect;
  }

  bool _checkQuadStretch(
    Map<PoseLandmarkType, _NKp> p, {
    required bool rightLeg,
  }) {
    final hip =
        p[rightLeg ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip];
    final knee =
        p[rightLeg ? PoseLandmarkType.rightKnee : PoseLandmarkType.leftKnee];
    final ankle =
        p[rightLeg ? PoseLandmarkType.rightAnkle : PoseLandmarkType.leftAnkle];
    final oppositeAnkle =
        p[rightLeg ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    final ls = p[PoseLandmarkType.leftShoulder];
    final rs = p[PoseLandmarkType.rightShoulder];
    if (hip == null ||
        knee == null ||
        ankle == null ||
        oppositeAnkle == null ||
        ls == null ||
        rs == null) {
      return false;
    }

    final shoulderWidth = (rs.x - ls.x).abs();
    final kneeAngle = _calculateAngle(hip, knee, ankle);
    final thighMostlyDown = knee.y > hip.y + 0.10;
    final footLifted = ankle.y < knee.y - 0.06;
    final kneeBent = kneeAngle > 25 && kneeAngle < 115;
    final supportFootLower = oppositeAnkle.y > ankle.y + 0.08;
    final kneeNearHipLine = (knee.x - hip.x).abs() < shoulderWidth * 0.85;

    return thighMostlyDown &&
        footLifted &&
        kneeBent &&
        supportFootLower &&
        kneeNearHipLine;
  }

  // ====================== COUNTDOWN ======================
  void _completeCurrentPose() {
    if (!mounted || !_isCounting) return;
    var routineCompleted = false;
    setState(() {
      _score += 100;
      _currentPoseIndex++;
      _isCounting = false;
      _countdown = 0;
      _holdStartedAt = null;
      _stableFrames = 0;
      _missedFrames = 0;
      if (_currentPoseIndex >= _totalPoses) {
        _isCompleted = true;
        routineCompleted = true;
      }
    });
    if (routineCompleted) {
      _recordSession(completed: true);
    }
  }

  void _restart() => setState(() {
    _sessionStartedAt = DateTime.now();
    _sessionRecorded = false;
    _currentPoseIndex = 0;
    _score = 0;
    _isCompleted = false;
    _isCounting = false;
    _countdown = 0;
    _holdStartedAt = null;
    _stableFrames = 0;
    _missedFrames = 0;
  });

  void _recordSession({required bool completed}) {
    if (_sessionRecorded) return;
    _sessionRecorded = true;
    unawaited(
      _sessionStore.record(
        completedPoses: _currentPoseIndex,
        totalPoses: _totalPoses,
        score: _score,
        duration: DateTime.now().difference(_sessionStartedAt),
        completed: completed,
      ),
    );
  }

  void _retryInit() {
    setState(() => _cameraError = null);
    _init();
  }

  // ====================== UI ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBF4), Color(0xFFFFEED7)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isCompleted
                      ? _buildCompletedView()
                      : _buildGameView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFFE8C2),
            foregroundColor: const Color(0xFFE87923),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB44A), Color(0xFFFF7A3D)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.self_improvement_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppText.get('morningStretch'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4E3829),
                ),
              ),
              Text(
                AppText.get('exerciseSafety'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A7B67),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(_currentPoseIndex.clamp(0, _totalPoses))} / $_totalPoses',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6D5544),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: _progressPercent.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFFFE6C6),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8A3D)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD08A)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFF9A2E),
                size: 24,
              ),
              const SizedBox(width: 6),
              Text(
                '$_score',
                style: const TextStyle(
                  color: Color(0xFFD86F1D),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
            Text(
              AppText.get('cameraFailed'),
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
              label: Text(AppText.get('retry')),
            ),
          ],
        ),
      );
    }

    if (!_cameraReady) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 12),
            Text(
              AppText.get('openingCamera'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF151515),
      child: Center(
        child: AspectRatio(
          // Keeping the native preview aspect ratio prevents faces and bodies
          // from being stretched to match the surrounding card.
          aspectRatio: _cameraController!.value.aspectRatio,
          child: Stack(
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
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.accessibility_new_rounded,
                        size: 16,
                        color: Colors.limeAccent,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'LANDMARKS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isCounting)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF36A66A).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        AppText.get('holdPose'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isShoulderStretch &&
                  !_isCounting &&
                  _poseDebugStatus.isNotEmpty)
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _poseDebugStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final camera = Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _buildCameraStack(),
          ),
        );
        final guide = _buildPoseGuide();
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              Expanded(flex: 3, child: camera),
              const SizedBox(height: 14),
              Expanded(flex: 2, child: guide),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: camera),
            const SizedBox(width: 18),
            Expanded(flex: 2, child: guide),
          ],
        );
      },
    );
  }

  Widget _buildPoseGuide() {
    final holdProgress = _isCounting
        ? ((_holdSeconds - _countdown) / _holdSeconds).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _currentPose.color,
            Color.lerp(_currentPose.color, Colors.black, 0.12)!,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _currentPose.color.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${AppText.get('exerciseStep')} ${_currentPoseIndex + 1} '
                '${AppText.get('exerciseOf')} $_totalPoses',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                _currentPose.imagePath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentPose.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _InstructionButton(text: _currentPose.instruction),
          const SizedBox(height: 18),
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    _isCounting
                        ? Icons.check_circle_rounded
                        : Icons.center_focus_strong_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isCounting
                          ? AppText.get('keepHoldingPose')
                          : AppText.get('fitBodyInCamera'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _isCounting ? '$_countdown s' : '$_holdSeconds s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: holdProgress,
                  minHeight: 11,
                  backgroundColor: Colors.white.withValues(alpha: 0.28),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
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
          Text(
            AppText.get('greatCompleted'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '${AppText.get('yourScore')}: $_score',
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
                label: Text(AppText.get('doAgain')),
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
                label: Text(AppText.get('backHome')),
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
    final line = Paint()
      ..color = Colors.limeAccent.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    final leftDot = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;
    final rightDot = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.fill;
    final otherDot = Paint()
      ..color = Colors.limeAccent
      ..style = PaintingStyle.fill;

    Offset map(_NKp k) => Offset(k.x * size.width, k.y * size.height);

    for (final e in _edges) {
      final a = kps[e[0]], b = kps[e[1]];
      if (a != null && b != null) canvas.drawLine(map(a), map(b), line);
    }
    for (final entry in kps.entries) {
      final isLeft = entry.key.name.startsWith('left');
      final isRight = entry.key.name.startsWith('right');
      canvas.drawCircle(
        map(entry.value),
        5,
        isLeft ? leftDot : (isRight ? rightDot : otherDot),
      );
    }

    _paintSideLabel(
      canvas,
      kps[PoseLandmarkType.leftWrist],
      size,
      'L',
      Colors.yellowAccent,
    );
    _paintSideLabel(
      canvas,
      kps[PoseLandmarkType.rightWrist],
      size,
      'R',
      Colors.lightBlueAccent,
    );
  }

  void _paintSideLabel(
    Canvas canvas,
    _NKp? point,
    Size size,
    String label,
    Color color,
  ) {
    if (point == null) return;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(point.x * size.width + 7, point.y * size.height - 18),
    );
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
