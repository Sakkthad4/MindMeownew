import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';

import 'mqtt_touch_service.dart';

class TouchCollectorPage extends StatefulWidget {
  /// ผูกเข้าระบบ Overall เดิมของคุณ
  final Future<void> Function(int xp)? onAddXp;

  /// (ถ้าอยากทำอย่างอื่นด้วย เช่น log event)
  final void Function(bool touched, int? rawValue)? onTouchEvent;

  final String brokerHost;
  final int port;
  final String clientId;

  final String topicValue;
  final String topicState;

  final String xpSoundAssetPath;
  final int xpPerSwipe; // ลูบ 1 ครั้งได้กี่ XP

  const TouchCollectorPage({
    super.key,
    required this.brokerHost,
    this.port = 1883,
    required this.clientId,
    this.topicValue = 'esp32/eye/touch/value',
    this.topicState = 'esp32/eye/touch/state',
    this.xpSoundAssetPath = 'audio/xp.mp3',
    this.xpPerSwipe = 10,
    this.onAddXp,
    this.onTouchEvent,
  });

  @override
  State<TouchCollectorPage> createState() => _TouchCollectorPageState();
}

class _TouchCollectorPageState extends State<TouchCollectorPage> {
  late final MqttTouchService mqtt;
  final AudioPlayer _player = AudioPlayer();

  bool _lastTouched = false;
  int? _latestRaw;

  @override
  void initState() {
    super.initState();

    mqtt = MqttTouchService(
      brokerHost: widget.brokerHost,
      port: widget.port,
      clientId: widget.clientId,
      topicValue: widget.topicValue,
      topicState: widget.topicState,
    );

    _start();
  }

  Future<void> _start() async {
    try {
      await mqtt.connect();

      mqtt.stream.listen((d) async {
        final raw = d.value;
        if (raw != null) _latestRaw = raw;

        final touched = d.touched;
        if (touched != null) {
          // callback เผื่ออยากเก็บ log
          widget.onTouchEvent?.call(touched, _latestRaw);

          // ✅ edge detect: false -> true = ลูบ 1 ครั้ง
          if (!_lastTouched && touched) {
            widget.onAddXp?.call(widget.xpPerSwipe);
            await _playXpSound();
          }

          _lastTouched = touched;
        }
      });
    } catch (_) {
      // ถ้าต่อไม่ติด คุณจะเลือกทำ retry เองก็ได้
      // หรือจะปล่อยเงียบ ๆ ก็ได้ตามต้องการ
    }
  }

  Future<void> _playXpSound() async {
    try {
      await _player.stop();
      await _player.play(
        AssetSource(widget.xpSoundAssetPath),
        volume: 1.0,
      );
    } catch (_) {
      // asset ไม่เจอ/ยังไม่ประกาศใน pubspec ก็จะเล่นไม่ได้ แต่ไม่ให้แอพ crash
    }
  }

  @override
  void dispose() {
    _player.dispose();
    mqtt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ไม่มี UI
    return const SizedBox.shrink();
  }
}
