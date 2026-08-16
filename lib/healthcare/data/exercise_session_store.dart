import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/exercise_session.dart';

class ExerciseSessionStore {
  static const boxName = 'exercise_sessions';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<ExerciseSession>(boxName);
    }
  }

  Box<ExerciseSession> get _box => Hive.box<ExerciseSession>(boxName);

  Future<void> record({
    required int completedPoses,
    required int totalPoses,
    required int score,
    required Duration duration,
    required bool completed,
  }) {
    return _box.add(
      ExerciseSession(
        completedPoses: completedPoses.clamp(0, totalPoses),
        totalPoses: totalPoses,
        score: score.clamp(0, 1000000),
        durationSeconds: duration.inSeconds.clamp(0, 86400),
        completed: completed,
        performedAt: DateTime.now(),
      ),
    );
  }

  List<ExerciseSession> recent({int days = 7}) {
    final from = DateTime.now().subtract(Duration(days: days));
    return _box.values
        .where((session) => session.performedAt.isAfter(from))
        .toList()
      ..sort((a, b) => a.performedAt.compareTo(b.performedAt));
  }

  ValueListenable<Box<ExerciseSession>> listenable() => _box.listenable();
}
