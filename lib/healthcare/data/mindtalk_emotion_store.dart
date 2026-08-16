import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/mindtalk_emotion_event.dart';

class MindTalkEmotionStore {
  static const boxName = 'mindtalk_emotions';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<MindTalkEmotionEvent>(boxName);
    }
  }

  Box<MindTalkEmotionEvent> get _box => Hive.box<MindTalkEmotionEvent>(boxName);

  Future<void> record({
    required MindTalkEmotion emotion,
    required MindTalkEmotionSource source,
    required double confidence,
    required String sessionId,
  }) {
    final event = MindTalkEmotionEvent(
      emotion: emotion.name,
      source: source.name,
      confidence: confidence.clamp(0.0, 1.0),
      recordedAt: DateTime.now(),
      sessionId: sessionId,
    );
    return _box.add(event);
  }

  List<MindTalkEmotionEvent> recent({int days = 7}) {
    final from = DateTime.now().subtract(Duration(days: days));
    return _box.values.where((event) => event.recordedAt.isAfter(from)).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  ValueListenable<Box<MindTalkEmotionEvent>> listenable() => _box.listenable();
}
