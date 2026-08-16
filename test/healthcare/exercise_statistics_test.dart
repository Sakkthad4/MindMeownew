import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/healthcare/data/exercise_statistics.dart';
import 'package:flutter_test22/healthcare/models/exercise_session.dart';

void main() {
  group('ExerciseStatistics', () {
    final now = DateTime(2026, 7, 31, 12);

    test('aggregates sessions from the latest seven calendar days', () {
      final stats = ExerciseStatistics.from([
        ExerciseSession(
          completedPoses: 8,
          totalPoses: 8,
          score: 800,
          durationSeconds: 120,
          completed: true,
          performedAt: DateTime(2026, 7, 31, 10),
        ),
        ExerciseSession(
          completedPoses: 3,
          totalPoses: 8,
          score: 300,
          durationSeconds: 60,
          completed: false,
          performedAt: DateTime(2026, 7, 29, 10),
        ),
        ExerciseSession(
          completedPoses: 8,
          totalPoses: 8,
          score: 800,
          durationSeconds: 120,
          completed: true,
          performedAt: DateTime(2026, 7, 20, 10),
        ),
      ], now: now);

      expect(stats.sessions, 2);
      expect(stats.completedRoutines, 1);
      expect(stats.completedPoses, 11);
      expect(stats.totalSeconds, 180);
      expect(stats.averageScore, 550);
      expect(stats.completionRate, 0.5);
      expect(stats.dailySessions[DateTime(2026, 7, 31)], 1);
      expect(stats.dailySessions[DateTime(2026, 7, 29)], 1);
    });

    test('returns safe zero values when there are no sessions', () {
      final stats = ExerciseStatistics.from(const [], now: now);

      expect(stats.sessions, 0);
      expect(stats.averageScore, 0);
      expect(stats.completionRate, 0);
      expect(stats.dailySessions.length, 7);
    });
  });
}
