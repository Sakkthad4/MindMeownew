import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/healthcare/data/cognitive_domain_statistics.dart';
import 'package:flutter_test22/healthcare/models/exercise_session.dart';
import 'package:flutter_test22/healthcare/models/game_result.dart';
import 'package:flutter_test22/healthcare/models/mindtalk_emotion_event.dart';

void main() {
  GameResult game(String name, double score, DateTime playedAt) => GameResult(
    game: name,
    difficulty: 'easy',
    accuracy: score,
    hits: score.round(),
    miss: 100 - score.round(),
    playedAt: playedAt,
  );

  MindTalkEmotionEvent emotion(
    MindTalkEmotionSource source,
    DateTime recordedAt,
  ) => MindTalkEmotionEvent(
    emotion: MindTalkEmotion.neutral.name,
    source: source.name,
    confidence: 0.8,
    recordedAt: recordedAt,
    sessionId: 'session',
  );

  test('combines games, MindTalk, and Exercise into all six domains', () {
    final anchor = DateTime(2026, 7, 31, 12);
    final statistics = CognitiveDomainStatistics.from(
      games: [
        game('supermarket', 71, DateTime(2026, 7, 31, 1)),
        game('catpaw', 82, DateTime(2026, 7, 31, 2)),
        game('dicedash', 93, DateTime(2026, 7, 31, 3)),
        game('drawvis', 64, DateTime(2026, 7, 31, 4)),
      ],
      mindTalkEvents: [
        emotion(MindTalkEmotionSource.conversation, DateTime(2026, 7, 31, 5)),
        emotion(MindTalkEmotionSource.camera, DateTime(2026, 7, 31, 5, 10)),
      ],
      exerciseSessions: [
        ExerciseSession(
          completedPoses: 6,
          totalPoses: 8,
          score: 600,
          durationSeconds: 60,
          completed: false,
          performedAt: DateTime(2026, 7, 31, 6),
        ),
      ],
      scale: CognitiveTimeScale.day,
      anchor: anchor,
    );

    expect(statistics.scores[CognitiveDomain.memory]![1], 71);
    expect(statistics.scores[CognitiveDomain.attention]![2], 82);
    expect(statistics.scores[CognitiveDomain.executiveFunction]![3], 93);
    expect(statistics.scores[CognitiveDomain.visuospatial]![4], 64);
    expect(statistics.scores[CognitiveDomain.language]![5], 25);
    expect(statistics.scores[CognitiveDomain.socialCognition]![5], 40);
    expect(statistics.scores[CognitiveDomain.attention]![6], 75);
    expect(statistics.scores[CognitiveDomain.executiveFunction]![6], 75);
    expect(statistics.hasData, isTrue);
  });

  test('hour uses minute buckets and excludes the next hour', () {
    final statistics = CognitiveDomainStatistics.from(
      games: [
        game('catpaw', 80, DateTime(2026, 7, 31, 12, 15)),
        game('catpaw', 90, DateTime(2026, 7, 31, 13)),
      ],
      mindTalkEvents: const [],
      exerciseSessions: const [],
      scale: CognitiveTimeScale.hour,
      anchor: DateTime(2026, 7, 31, 12, 40),
    );

    expect(statistics.labels.length, 60);
    expect(statistics.scores[CognitiveDomain.attention]![15], 80);
    expect(
      statistics.scores[CognitiveDomain.attention]!.whereType<double>().length,
      1,
    );
  });

  test('month uses one bucket for every calendar day', () {
    final statistics = CognitiveDomainStatistics.from(
      games: [game('drawvis', 88, DateTime(2024, 2, 29, 10))],
      mindTalkEvents: const [],
      exerciseSessions: const [],
      scale: CognitiveTimeScale.month,
      anchor: DateTime(2024, 2, 10),
    );

    expect(statistics.labels.length, 29);
    expect(statistics.scores[CognitiveDomain.visuospatial]![28], 88);
  });
}
