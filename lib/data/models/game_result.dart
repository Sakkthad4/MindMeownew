import 'package:hive/hive.dart';

part 'game_result.g.dart';

@HiveType(typeId: 1)
class GameResult extends HiveObject {
  @HiveField(0)
  final String game; // catpaw, dicedash, supermarket

  @HiveField(1)
  final String difficulty; // easy, normal, hard

  @HiveField(2)
  final double accuracy;

  @HiveField(3)
  final int hits;

  @HiveField(4)
  final int miss;

  @HiveField(5)
  final DateTime playedAt;

  GameResult({
    required this.game,
    required this.difficulty,
    required this.accuracy,
    required this.hits,
    required this.miss,
    required this.playedAt,
  });
}
