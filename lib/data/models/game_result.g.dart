// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameResultAdapter extends TypeAdapter<GameResult> {
  @override
  final int typeId = 1;

  @override
  GameResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameResult(
      game: fields[0] as String,
      difficulty: fields[1] as String,
      accuracy: fields[2] as double,
      hits: fields[3] as int,
      miss: fields[4] as int,
      playedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GameResult obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.game)
      ..writeByte(1)
      ..write(obj.difficulty)
      ..writeByte(2)
      ..write(obj.accuracy)
      ..writeByte(3)
      ..write(obj.hits)
      ..writeByte(4)
      ..write(obj.miss)
      ..writeByte(5)
      ..write(obj.playedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
