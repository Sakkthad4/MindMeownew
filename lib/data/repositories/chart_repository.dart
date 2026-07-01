import '../models/game_result.dart';

class ChartRepository {
  final List<GameResult> _results;

  ChartRepository(this._results);

  /// ทั้งหมด
  List<GameResult> all() {
    return [..._results]..sort((a, b) => a.playedAt.compareTo(b.playedAt));
  }

  /// เฉพาะเกม
  List<GameResult> byGame(String game) {
    return _results
        .where((r) => r.game == game)
        .toList()
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
  }

  /// เฉพาะเกม + difficulty
  List<GameResult> byGameAndDifficulty(
    String game,
    String difficulty,
  ) {
    return _results
        .where((r) => r.game == game && r.difficulty == difficulty)
        .toList()
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
  }

  /// average accuracy
  double averageAccuracy(List<GameResult> list) {
    if (list.isEmpty) return 0;
    final total = list.fold<double>(0, (s, r) => s + r.accuracy);
    return total / list.length;
  }
}
