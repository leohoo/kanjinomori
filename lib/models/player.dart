import 'package:hive/hive.dart';

part 'player.g.dart';

@HiveType(typeId: 1)
class Player extends HiveObject {
  @HiveField(0)
  int coins;

  @HiveField(1)
  int currentStage;

  @HiveField(2)
  List<int> unlockedStages;

  @HiveField(3)
  String? equippedWeapon;

  @HiveField(4)
  String? equippedCostume;

  @HiveField(5)
  List<String> ownedWeapons;

  @HiveField(6)
  List<String> ownedCostumes;

  @HiveField(7)
  List<String> ownedDecorations;

  @HiveField(8)
  Map<int, int> stageHighScores; // stageId -> highest coins earned

  Player({
    this.coins = 0,
    this.currentStage = 1,
    List<int>? unlockedStages,
    this.equippedWeapon,
    this.equippedCostume,
    List<String>? ownedWeapons,
    List<String>? ownedCostumes,
    List<String>? ownedDecorations,
    Map<int, int>? stageHighScores,
  })  : unlockedStages = unlockedStages ?? [1],
        ownedWeapons = ownedWeapons ?? ['wooden_staff'],
        ownedCostumes = ownedCostumes ?? ['default'],
        ownedDecorations = ownedDecorations ?? [],
        stageHighScores = stageHighScores ?? {};

  void addCoins(int amount) {
    coins += amount;
  }

  bool spendCoins(int amount) {
    if (coins >= amount) {
      coins -= amount;
      return true;
    }
    return false;
  }

  void unlockStage(int stageId) {
    if (!unlockedStages.contains(stageId)) {
      unlockedStages.add(stageId);
    }
  }

  bool isStageUnlocked(int stageId) {
    return unlockedStages.contains(stageId);
  }

  void equipWeapon(String weaponId) {
    if (ownedWeapons.contains(weaponId)) {
      equippedWeapon = weaponId;
    }
  }

  void equipCostume(String costumeId) {
    if (ownedCostumes.contains(costumeId)) {
      equippedCostume = costumeId;
    }
  }

  void purchaseItem(String itemId, String category) {
    switch (category) {
      case 'weapon':
        if (!ownedWeapons.contains(itemId)) {
          ownedWeapons.add(itemId);
        }
        break;
      case 'costume':
        if (!ownedCostumes.contains(itemId)) {
          ownedCostumes.add(itemId);
        }
        break;
      case 'decoration':
        if (!ownedDecorations.contains(itemId)) {
          ownedDecorations.add(itemId);
        }
        break;
    }
  }

  void updateHighScore(int stageId, int score) {
    final current = stageHighScores[stageId] ?? 0;
    if (score > current) {
      stageHighScores[stageId] = score;
    }
  }
}
