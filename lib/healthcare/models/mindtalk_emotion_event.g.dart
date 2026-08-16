// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mindtalk_emotion_event.dart';

class MindTalkEmotionEventAdapter extends TypeAdapter<MindTalkEmotionEvent> {
  @override
  final int typeId = 3;

  @override
  MindTalkEmotionEvent read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return MindTalkEmotionEvent(
      emotion: fields[0] as String,
      source: fields[1] as String,
      confidence: fields[2] as double,
      recordedAt: fields[3] as DateTime,
      sessionId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MindTalkEmotionEvent object) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(object.emotion)
      ..writeByte(1)
      ..write(object.source)
      ..writeByte(2)
      ..write(object.confidence)
      ..writeByte(3)
      ..write(object.recordedAt)
      ..writeByte(4)
      ..write(object.sessionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindTalkEmotionEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
