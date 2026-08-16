import '../models/exercise_session.dart';

class ExerciseStatistics {
  const ExerciseStatistics({
    required this.sessions,
    required this.completedRoutines,
    required this.completedPoses,
    required this.totalSeconds,
    required this.averageScore,
    required this.dailySessions,
  });

  final int sessions;
  final int completedRoutines;
  final int completedPoses;
  final int totalSeconds;
  final double averageScore;
  final Map<DateTime, int> dailySessions;

  double get completionRate => sessions == 0 ? 0 : completedRoutines / sessions;

  factory ExerciseStatistics.from(
    Iterable<ExerciseSession> sessions, {
    DateTime? now,
  }) {
    final todaySource = now ?? DateTime.now();
    final today = DateTime(
      todaySource.year,
      todaySource.month,
      todaySource.day,
    );
    final firstDay = today.subtract(const Duration(days: 6));
    final daily = <DateTime, int>{
      for (var offset = 0; offset < 7; offset++)
        firstDay.add(Duration(days: offset)): 0,
    };

    var sessionCount = 0;
    var completedRoutines = 0;
    var completedPoses = 0;
    var totalSeconds = 0;
    var totalScore = 0;

    for (final session in sessions) {
      final day = DateTime(
        session.performedAt.year,
        session.performedAt.month,
        session.performedAt.day,
      );
      if (day.isBefore(firstDay) || day.isAfter(today)) continue;

      sessionCount++;
      completedRoutines += session.completed ? 1 : 0;
      completedPoses += session.completedPoses;
      totalSeconds += session.durationSeconds;
      totalScore += session.score;
      daily[day] = (daily[day] ?? 0) + 1;
    }

    return ExerciseStatistics(
      sessions: sessionCount,
      completedRoutines: completedRoutines,
      completedPoses: completedPoses,
      totalSeconds: totalSeconds,
      averageScore: sessionCount == 0 ? 0 : totalScore / sessionCount,
      dailySessions: daily,
    );
  }
}
