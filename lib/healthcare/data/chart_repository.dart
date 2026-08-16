import 'package:hive/hive.dart';
import '../models/game_result.dart';

class ChartRepository {
  ChartRepository({Box<GameResult>? box})
    : _box = box ?? Hive.box<GameResult>('results');

  final Box<GameResult> _box;

  Future<List<GameResult>> getAll() async {
    final list = _box.values.toList()
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    return list;
  }

  Future<List<GameResult>> getByGameAndDifficulty({
    required String game,
    required String difficulty,
  }) async {
    final list =
        _box.values
            .where((e) => e.game == game && e.difficulty == difficulty)
            .toList()
          ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    return list;
  }

  /// Overview bar: ค่าเฉลี่ย accuracy ต่อเกม (0..100)
  Future<Map<String, double>> getOverallScoreByGame(List<String> games) async {
    final all = _box.values.toList();
    final bucket = <String, List<double>>{};

    for (final r in all) {
      bucket.putIfAbsent(r.game, () => []).add(r.accuracy);
    }

    final out = <String, double>{};
    for (final g in games) {
      final arr = bucket[g] ?? const <double>[];
      out[g] = arr.isEmpty ? 0 : (arr.reduce((a, b) => a + b) / arr.length);
    }
    return out;
  }
}
