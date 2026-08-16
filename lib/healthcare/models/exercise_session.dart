import 'package:hive/hive.dart';

part 'exercise_session.g.dart';

@HiveType(typeId: 4)
class ExerciseSession extends HiveObject {
  @HiveField(0)
  final int completedPoses;

  @HiveField(1)
  final int totalPoses;

  @HiveField(2)
  final int score;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final DateTime performedAt;

  ExerciseSession({
    required this.completedPoses,
    required this.totalPoses,
    required this.score,
    required this.durationSeconds,
    required this.completed,
    required this.performedAt,
  });
}
