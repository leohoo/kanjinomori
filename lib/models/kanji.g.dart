// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanji.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KanjiAdapter extends TypeAdapter<Kanji> {
  @override
  final int typeId = 0;

  @override
  Kanji read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Kanji(
      kanji: fields[0] as String,
      readings: (fields[1] as List).cast<String>(),
      meaning: fields[2] as String,
      grade: fields[3] as int,
      strokeCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Kanji obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.kanji)
      ..writeByte(1)
      ..write(obj.readings)
      ..writeByte(2)
      ..write(obj.meaning)
      ..writeByte(3)
      ..write(obj.grade)
      ..writeByte(4)
      ..write(obj.strokeCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanjiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
