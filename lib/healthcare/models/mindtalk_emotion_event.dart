import 'package:hive/hive.dart';

part 'mindtalk_emotion_event.g.dart';

enum MindTalkEmotion { neutral, happy, sad, angry, anxious }

enum MindTalkEmotionSource { conversation, camera }

@HiveType(typeId: 3)
class MindTalkEmotionEvent extends HiveObject {
  @HiveField(0)
  final String emotion;

  @HiveField(1)
  final String source;

  @HiveField(2)
  final double confidence;

  @HiveField(3)
  final DateTime recordedAt;

  @HiveField(4)
  final String sessionId;

  MindTalkEmotionEvent({
    required this.emotion,
    required this.source,
    required this.confidence,
    required this.recordedAt,
    required this.sessionId,
  });

  MindTalkEmotion get emotionValue => MindTalkEmotion.values.firstWhere(
    (value) => value.name == emotion,
    orElse: () => MindTalkEmotion.neutral,
  );

  MindTalkEmotionSource get sourceValue =>
      MindTalkEmotionSource.values.firstWhere(
        (value) => value.name == source,
        orElse: () => MindTalkEmotionSource.conversation,
      );
}
