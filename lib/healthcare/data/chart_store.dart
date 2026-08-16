import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';

class ChartStore {
  ChartStore({Box<GameResult>? box})
    : _box = box ?? Hive.box<GameResult>('results');

  final Box<GameResult> _box;

  /// accuracyPercent: 0..100
  Future<void> logResult({
    required String game, // 'supermarket', 'dicedash', 'catpaw', 'drawvis'
    required String difficulty, // 'easy', 'normal', 'hard'
    required double accuracyPercent,
    required int hits,
    required int miss,
  }) async {
    final now = DateTime.now();

    final result = GameResult(
      game: game,
      difficulty: difficulty,
      accuracy: accuracyPercent.clamp(0.0, 100.0),
      hits: hits,
      miss: miss,
      playedAt: now,
    );

    await _box.put(now.microsecondsSinceEpoch.toString(), result);
  }

  Future<void> clearAll() => _box.clear();

  ValueListenable<Box<GameResult>> listenable() => _box.listenable();

  static Future<void> init() async {
    // มีไว้ให้ main.dart เรียกได้ (ตอนนี้ไม่ต้องทำอะไร)
  }
}
