// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      coins: fields[0] as int,
      currentStage: fields[1] as int,
      unlockedStages: (fields[2] as List?)?.cast<int>(),
      equippedWeapon: fields[3] as String?,
      equippedCostume: fields[4] as String?,
      ownedWeapons: (fields[5] as List?)?.cast<String>(),
      ownedCostumes: (fields[6] as List?)?.cast<String>(),
      ownedDecorations: (fields[7] as List?)?.cast<String>(),
      stageHighScores: (fields[8] as Map?)?.cast<int, int>(),
    ).._useIsometricMovement = fields[9] as bool?;
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.coins)
      ..writeByte(1)
      ..write(obj.currentStage)
      ..writeByte(2)
      ..write(obj.unlockedStages)
      ..writeByte(3)
      ..write(obj.equippedWeapon)
      ..writeByte(4)
      ..write(obj.equippedCostume)
      ..writeByte(5)
      ..write(obj.ownedWeapons)
      ..writeByte(6)
      ..write(obj.ownedCostumes)
      ..writeByte(7)
      ..write(obj.ownedDecorations)
      ..writeByte(8)
      ..write(obj.stageHighScores)
      ..writeByte(9)
      ..write(obj._useIsometricMovement);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
