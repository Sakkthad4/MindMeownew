// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_bond.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CatBondAdapter extends TypeAdapter<CatBond> {
  @override
  final int typeId = 2;

  @override
  CatBond read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CatBond(
      totalXp: fields[0] as int,
      updatedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CatBond obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.totalXp)
      ..writeByte(1)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatBondAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
