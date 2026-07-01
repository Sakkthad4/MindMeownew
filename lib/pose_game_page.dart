/*// main.dart
//
// ✅ โหมดแนวตั้ง (Portrait locked)
// ✅ กล้องหน้า/หลังสลับได้
// ✅ ML Kit Pose Detection (stream) + โครงกระดูกทับกล้อง (เปิดไว้เพื่อ debug)
// ✅ ภารกิจ: “ยืนเอียงข้าง + แกว่งแขน 50 ครั้ง” (นับ rep)
// ✅ พูดชื่อท่าก่อน → แล้วค่อยเริ่มนับ (State machine)
// ✅ เสียงนับ “ห้ามรัว” เว้นอย่างน้อย 1000ms (นับเฉพาะตอนเพิ่ม rep)
// ✅ ทำครบมีเสียง “ติ๊ง” + flash สีเขียว
// ✅ มีรูป guide ครึ่งหน้าจอ (asset มี/ไม่มี ก็ไม่ค้าง)
//
// ---------------------------
// pubspec.yaml (ต้องมี)
// dependencies:
//   flutter:
//     sdk: flutter
//   camera: ^0.10.5+5
//   google_mlkit_pose_detection: ^0.10.0
//   flutter_tts: ^3.8.5
//   audioplayers: ^6.0.0
//
// flutter:
//   assets:
//     - assets/guides/
//     - assets/sounds/
//
// แนะนำใส่ไฟล์:
//   assets/guides/side_lean_arm_swing.png
//   assets/sounds/ding.mp3
// ---------------------------

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SideLeanArmSwing50Page()));
}

enum FlowState { intro, findPose, ready, active, success }

class SideLeanArmSwing50Page extends StatefulWidget {
  const SideLeanArmSwing50Page({super.key});

  @override
  State<SideLeanArmSwing50Page> createState() => _SideLeanArmSwing50PageState();
}

class _SideLeanArmSwing50PageState extends State<SideLeanArmSwing50Page> {
  // ===== ML Kit / Camera =====
  CameraController? _controller;
  late final PoseDetector _detector;
  Pose? _pose;

  // ===== Performance guards (กันค้าง) =====
  bool _processing = false;
  DateTime _lastProcessAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _processEveryMs = 120; // ~8fps
  DateTime _lastUiAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _uiEveryMs = 80;

  // ===== Audio =====
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _ttsBusy = false;
  DateTime _lastSpeakAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _speakCooldownMs = 250; // กันกด/เรียกซ้อน
  DateTime _lastCountSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _minCountSpeakMs = 1000; // ✅ ตามที่ขอ: เว้นอย่างน้อย 1000ms

  // ===== UX/State =====
  FlowState _flow = FlowState.intro;
  bool _missionAnnounced = false;
  bool _flashGreen = false;

  // ===== Mission config =====
  final String _title = "ท่า: ยืนเอียงข้าง + แกว่งแขน";
  final String _instruction =
      "เอียงลำตัวไปด้านขวาเล็กน้อย แล้วแกว่งแขนขวาขึ้นลง\nนับให้ครบ 50 ครั้ง";
  final String _guideAsset = "assets/guides/side_lean_arm_swing.png";

  static const int _targetReps = 50;
  int _reps = 0;

  // READY gating: ต้อง “ทำท่าถูกนิ่ง ๆ” ก่อนเริ่มนับจริง
  static const double _readySeconds = 0.8;
  double _readyHold = 0.0;

  // ===== Rep detection (hysteresis + debounce) =====
  // เราจะนับ “1 ครั้ง” เมื่อแขนแกว่งครบ 1 รอบ (สูง -> ต่ำ -> สูง)
  bool _wasHigh = false;
  bool _wasLow = false;
  DateTime _lastRepAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _minRepIntervalMs = 260; // กันสั่น/นับซ้ำ

  // ===== timing for smooth progress =====
  DateTime? _lastTick;

  @override
  void initState() {
    super.initState();
    _detector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
    _initTts();
    _initCamera(preferFront: true);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("th-TH");
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() => _ttsBusy = false);
    _tts.setErrorHandler((_) => _ttsBusy = false);
  }

  Future<void> _safeSpeak(String text) async {
    final now = DateTime.now();
    if (_ttsBusy) return;
    if (now.difference(_lastSpeakAt).inMilliseconds < _speakCooldownMs) return;

    _ttsBusy = true;
    _lastSpeakAt = now;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      _ttsBusy = false;
    }
  }

  Future<void> _speakCount(int n) async {
    final now = DateTime.now();
    if (now.difference(_lastCountSpokenAt).inMilliseconds < _minCountSpeakMs) return;
    _lastCountSpokenAt = now;
    await _safeSpeak("$n");
  }

  Future<void> _ding() async {
    try {
      await _player.play(AssetSource("sounds/ding.mp3"));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _initCamera({required bool preferFront}) async {
    final cams = await availableCameras();
    final cam = cams.firstWhere(
      (c) => c.lensDirection == (preferFront ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => cams.first,
    );

    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processFrame);

    if (mounted) setState(() {});
    _resetMission();
  }

  Future<void> _switchCamera() async {
    if (_controller == null) return;
    final cams = await availableCameras();
    final cur = _controller!.description;
    final next = cams.firstWhere((c) => c.lensDirection != cur.lensDirection, orElse: () => cams.first);

    await _controller!.stopImageStream();
    await _controller!.dispose();

    _controller = CameraController(
      next,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processFrame);

    if (mounted) setState(() {});
  }

  InputImageRotation _rotation() {
    final camera = _controller!.description;
    final device = _controller!.value.deviceOrientation;

    int rotationCompensation;
    switch (device) {
      case DeviceOrientation.portraitUp:
        rotationCompensation = 0;
        break;
      case DeviceOrientation.landscapeLeft:
        rotationCompensation = 90;
        break;
      case DeviceOrientation.portraitDown:
        rotationCompensation = 180;
        break;
      case DeviceOrientation.landscapeRight:
        rotationCompensation = 270;
        break;
    }

    final sensor = camera.sensorOrientation;
    final rotationDegrees = camera.lensDirection == CameraLensDirection.front
        ? (sensor + rotationCompensation) % 360
        : (sensor - rotationCompensation + 360) % 360;

    switch (rotationDegrees) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Uint8List _concatPlanes(CameraImage image) {
    final WriteBuffer wb = WriteBuffer();
    for (final p in image.planes) {
      wb.putUint8List(p.bytes);
    }
    return wb.done().buffer.asUint8List();
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_processing) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessAt).inMilliseconds < _processEveryMs) return;
    _lastProcessAt = now;

    _processing = true;
    try {
      final input = InputImage.fromBytes(
        bytes: _concatPlanes(image),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _rotation(),
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final poses = await _detector.processImage(input);
      final pose = poses.isNotEmpty ? poses.first : null;

      // dt
      final tickNow = DateTime.now();
      final dt = _lastTick == null ? 0.0 : tickNow.difference(_lastTick!).inMilliseconds / 1000.0;
      _lastTick = tickNow;

      await _updateFlow(pose, dt);

      // update UI throttled
      if (mounted && tickNow.difference(_lastUiAt).inMilliseconds >= _uiEveryMs) {
        _lastUiAt = tickNow;
        setState(() => _pose = pose);
      } else {
        _pose = pose;
      }
    } finally {
      _processing = false;
    }
  }

  void _resetMission() {
    _flow = FlowState.intro;
    _missionAnnounced = false;
    _reps = 0;
    _readyHold = 0;
    _wasHigh = false;
    _wasLow = false;
    _lastRepAt = DateTime.fromMillisecondsSinceEpoch(0);
    _lastCountSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);
    _flashGreen = false;
    _safeSpeak("เริ่มโหมดออกกำลังกาย");
  }

  Future<void> _announceOnce() async {
    if (_missionAnnounced) return;
    _missionAnnounced = true;
    await _safeSpeak("$_title. $_instruction");
  }

  Future<void> _flashSuccess() async {
    if (!mounted) return;
    setState(() => _flashGreen = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (mounted) setState(() => _flashGreen = false);
  }

  // ===== Core: State Machine =====
  Future<void> _updateFlow(Pose? pose, double dt) async {
    if (pose == null) {
      _flow = FlowState.findPose;
      _readyHold = 0;
      _wasHigh = false;
      _wasLow = false;
      return;
    }

    // ตรวจท่าพื้นฐาน “เอียงขวา”
    final leanOk = _isLeaningRight(pose);

    switch (_flow) {
      case FlowState.intro:
        await _announceOnce();
        _flow = FlowState.findPose;
        break;

      case FlowState.findPose:
        // ต้องเอียงถูกก่อนถึงไป READY
        if (leanOk) {
          _flow = FlowState.ready;
          _readyHold = 0;
        }
        break;

      case FlowState.ready:
        if (!leanOk) {
          _flow = FlowState.findPose;
          _readyHold = 0;
          break;
        }

        _readyHold += dt;
        if (_readyHold >= _readySeconds) {
          _flow = FlowState.active;
          // พูดสั้น ๆ ว่าเริ่มนับได้
          await _safeSpeak("เริ่มนับ");
        }
        break;

      case FlowState.active:
        if (!leanOk) {
          // หลุดท่า → กลับ READY (ไม่ให้นับมั่ว)
          _flow = FlowState.ready;
          _readyHold = 0;
          _wasHigh = false;
          _wasLow = false;
          break;
        }

        final didInc = _tryCountArmSwingRep(pose);
        if (didInc) {
          // ✅ พูดเลขตาม rep แต่เว้น 1000ms (ห้ามรัว)
          await _speakCount(_reps);
          if (_reps >= _targetReps) {
            _flow = FlowState.success;
          }
        }
        break;

      case FlowState.success:
        await _ding();
        await _flashSuccess();
        await _safeSpeak("ทำครบแล้ว เก่งมาก");
        // รีสตาร์ท (หรือจะไปท่าอื่นต่อก็ได้)
        _resetMission();
        break;
    }
  }

  // ===== Pose logic =====

  // เอียงขวา: ใช้มุมของเวกเตอร์ hip->shoulder เทียบกับแนวตั้ง
  // ถ้าไหล่ขวา “ต่ำกว่า” ไหล่ซ้าย และลำตัวเอียงพอ → ผ่าน
  bool _isLeaningRight(Pose pose) {
    final lS = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rS = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lH = pose.landmarks[PoseLandmarkType.leftHip];
    final rH = pose.landmarks[PoseLandmarkType.rightHip];
    if (lS == null || rS == null || lH == null || rH == null) return false;

    final shoulderMid = Offset((lS.x + rS.x) / 2, (lS.y + rS.y) / 2);
    final hipMid = Offset((lH.x + rH.x) / 2, (lH.y + rH.y) / 2);

    // เวกเตอร์จากสะโพกไปไหล่
    final v = shoulderMid - hipMid;

    // มุมจากแนวตั้ง (0 = ตั้งตรง)
    final angleFromVertical = _angleBetween(v, const Offset(0, -1)); // up
    // ต้องเอียงชัด ๆ (เช่น > 15°)
    final leanEnough = angleFromVertical > 15;

    // ขวา: ไหล่ขวาต่ำกว่าไหล่ซ้าย (y มากกว่า = ต่ำกว่า)
    final rightDown = rS.y > lS.y + 8; // 8px กัน noise

    return leanEnough && rightDown;
  }

  double _angleBetween(Offset a, Offset b) {
    final dot = a.dx * b.dx + a.dy * b.dy;
    final magA = sqrt(a.dx * a.dx + a.dy * a.dy);
    final magB = sqrt(b.dx * b.dx + b.dy * b.dy);
    if (magA < 1e-6 || magB < 1e-6) return 0.0;
    final cosv = (dot / (magA * magB)).clamp(-1.0, 1.0);
    return acos(cosv) * 180 / pi;
  }

  // นับการแกว่งแขนขวา: wrist ขึ้นสูง/ลงต่ำแบบมี hysteresis
  // 1 rep = สูง -> ต่ำ -> สูง
  bool _tryCountArmSwingRep(Pose pose) {
    final rW = pose.landmarks[PoseLandmarkType.rightWrist];
    final rS = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rH = pose.landmarks[PoseLandmarkType.rightHip];
    if (rW == null || rS == null || rH == null) return false;

    final shoulder = Offset(rS.x, rS.y);
    final hip = Offset(rH.x, rH.y);
    final wrist = Offset(rW.x, rW.y);

    // ความยาวลำตัวอ้างอิง
    final torso = (hip - shoulder).distance;
    if (torso < 20) return false;

    // กำหนด threshold แบบสัมพันธ์กับ torso (กันเครื่อง/ระยะกล้องต่างกัน)
    final highY = shoulder.dy + torso * 0.15; // ข้อมือสูง (อยู่ใกล้ไหล่/เหนือไหล่)
    final lowY = hip.dy + torso * 0.25;      // ข้อมือต่ำ (ต่ำกว่าเอว)

    final isHigh = wrist.dy <= highY;
    final isLow = wrist.dy >= lowY;

    // สะสมสถานะ
    if (isHigh) _wasHigh = true;
    if (isLow) _wasLow = true;

    // ครบรอบ: เคยสูง + เคยต่ำ + กลับมาสูงอีกครั้ง
    final now = DateTime.now();
    final canCount = now.difference(_lastRepAt).inMilliseconds >= _minRepIntervalMs;

    if (canCount && _wasHigh && _wasLow && isHigh) {
      _lastRepAt = now;
      _reps = min(_targetReps, _reps + 1);

      // รีเซ็ต pattern เพื่อรอรอบใหม่
      _wasLow = false;
      // _wasHigh คงไว้ได้ เพื่อให้ “สูง” เป็นจุดเริ่มต้นที่นิ่ง
      return true;
    }

    return false;
  }

  // ===== UI =====

  double get _progress01 => (_reps / _targetReps).clamp(0.0, 1.0);

  String get _statusText {
    switch (_flow) {
      case FlowState.intro:
        return "เตรียมเริ่ม...";
      case FlowState.findPose:
        return "ยืนให้เห็นตัว และเอียงขวา";
      case FlowState.ready:
        return "ค้างท่าถูกต้อง...";
      case FlowState.active:
        return "กำลังนับ...";
      case FlowState.success:
        return "สำเร็จ!";
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    _tts.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFront = _controller!.description.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Stretch - Rep Counter"),
        actions: [
          IconButton(onPressed: _switchCamera, icon: const Icon(Icons.cameraswitch)),
          IconButton(onPressed: () => setState(_resetMission), icon: const Icon(Icons.restart_alt)),
          IconButton(onPressed: () => _safeSpeak("$_title. $_instruction"), icon: const Icon(Icons.volume_up)),
        ],
      ),
      body: Stack(
        children: [
          // แบ่งครึ่งจอ: บนกล้อง / ล่างไกด์+นับ
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    CameraPreview(_controller!),

                    // โครงกระดูก (debug/โชว์)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _pose == null
                              ? null
                              : SkeletonPainter(
                                  pose: _pose!,
                                  previewSize: _controller!.value.previewSize!,
                                  isFrontCamera: isFront,
                                ),
                        ),
                      ),
                    ),

                    // การ์ดโจทย์ (ตัวใหญ่)
                    Positioned(
                      left: 12,
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _instruction,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // guide ครึ่งจอ
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.white.withOpacity(0.08),
                            child: Image.asset(
                              _guideAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.accessibility_new, size: 90, color: Colors.white70),
                                      SizedBox(height: 10),
                                      Text(
                                        "ใส่รูปไกด์ใน\nassets/guides/side_lean_arm_swing.png",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // วงกลม progress + rep counter
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(value: _progress01, strokeWidth: 12),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "$_reps/$_targetReps",
                                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _statusText,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _pose == null ? "ไม่พบร่างกาย" : "ตรวจพบร่างกาย",
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "สถานะ: ${_flow.name}",
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // flash สีเขียวเมื่อสำเร็จ
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flashGreen ? 0.35 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: Container(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size previewSize;
  final bool isFrontCamera;

  SkeletonPainter({
    required this.pose,
    required this.previewSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    Offset? mapPoint(PoseLandmarkType t) {
      final lm = pose.landmarks[t];
      if (lm == null) return null;

      // mapping แบบง่าย
      final scaleX = size.width / previewSize.height;
      final scaleY = size.height / previewSize.width;

      double x = lm.x * scaleX;
      double y = lm.y * scaleY;

      if (isFrontCamera) x = size.width - x;
      return Offset(x, y);
    }

    void drawPoint(Offset p) => canvas.drawCircle(p, 5, pointPaint);
    void drawLine(Offset a, Offset b) => canvas.drawLine(a, b, linePaint);

    final lS = mapPoint(PoseLandmarkType.leftShoulder);
    final rS = mapPoint(PoseLandmarkType.rightShoulder);
    final lE = mapPoint(PoseLandmarkType.leftElbow);
    final rE = mapPoint(PoseLandmarkType.rightElbow);
    final lW = mapPoint(PoseLandmarkType.leftWrist);
    final rW = mapPoint(PoseLandmarkType.rightWrist);

    final lH = mapPoint(PoseLandmarkType.leftHip);
    final rH = mapPoint(PoseLandmarkType.rightHip);
    final lK = mapPoint(PoseLandmarkType.leftKnee);
    final rK = mapPoint(PoseLandmarkType.rightKnee);
    final lA = mapPoint(PoseLandmarkType.leftAnkle);
    final rA = mapPoint(PoseLandmarkType.rightAnkle);

    final pairs = <List<Offset?>>[
      [lS, rS],
      [lS, lE],
      [lE, lW],
      [rS, rE],
      [rE, rW],
      [lS, lH],
      [rS, rH],
      [lH, rH],
      [lH, lK],
      [lK, lA],
      [rH, rK],
      [rK, rA],
    ];

    for (final pair in pairs) {
      final a = pair[0], b = pair[1];
      if (a != null && b != null) drawLine(a, b);
    }

    final points = [lS, rS, lE, rE, lW, rW, lH, rH, lK, rK, lA, rA];
    for (final p in points) {
      if (p != null) drawPoint(p);
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}*/
