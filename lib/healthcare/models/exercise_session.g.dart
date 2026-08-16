// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_session.dart';

class ExerciseSessionAdapter extends TypeAdapter<ExerciseSession> {
  @override
  final int typeId = 4;

  @override
  ExerciseSession read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return ExerciseSession(
      completedPoses: fields[0] as int,
      totalPoses: fields[1] as int,
      score: fields[2] as int,
      durationSeconds: fields[3] as int,
      completed: fields[4] as bool,
      performedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseSession object) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(object.completedPoses)
      ..writeByte(1)
      ..write(object.totalPoses)
      ..writeByte(2)
      ..write(object.score)
      ..writeByte(3)
      ..write(object.durationSeconds)
      ..writeByte(4)
      ..write(object.completed)
      ..writeByte(5)
      ..write(object.performedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
