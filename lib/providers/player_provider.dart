import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';
import '../models/shop_item.dart';

class PlayerNotifier extends StateNotifier<Player> {
  final Box<Player> _playerBox;

  PlayerNotifier(this._playerBox) : super(_playerBox.get('player') ?? Player()) {
    // Ensure default weapon is equipped
    if (state.equippedWeapon == null && state.ownedWeapons.isNotEmpty) {
      state.equippedWeapon = state.ownedWeapons.first;
    }
    if (state.equippedCostume == null && state.ownedCostumes.isNotEmpty) {
      state.equippedCostume = state.ownedCostumes.first;
    }
  }

  void _saveState() {
    _playerBox.put('player', state);
  }

  void addCoins(int amount) {
    state.addCoins(amount);
    state = Player(
      coins: state.coins,
      currentStage: state.currentStage,
      unlockedStages: state.unlockedStages,
      equippedWeapon: state.equippedWeapon,
      equippedCostume: state.equippedCostume,
      ownedWeapons: state.ownedWeapons,
      ownedCostumes: state.ownedCostumes,
      ownedDecorations: state.ownedDecorations,
      stageHighScores: state.stageHighScores,
      useIsometricMovement: state.useIsometricMovement,
    );
    _saveState();
  }

  bool purchaseItem(ShopItem item) {
    if (state.coins < item.price) return false;

    // Check if already owned
    switch (item.category) {
      case ShopCategory.weapon:
        if (state.ownedWeapons.contains(item.id)) return false;
        break;
      case ShopCategory.costume:
        if (state.ownedCostumes.contains(item.id)) return false;
        break;
      case ShopCategory.decoration:
        if (state.ownedDecorations.contains(item.id)) return false;
        break;
      case ShopCategory.animation:
        if (state.ownedDecorations.contains(item.id)) return false;
        break;
    }

    state.spendCoins(item.price);
    state.purchaseItem(item.id, item.category.name);

    state = Player(
      coins: state.coins,
      currentStage: state.currentStage,
      unlockedStages: state.unlockedStages,
      equippedWeapon: state.equippedWeapon,
      equippedCostume: state.equippedCostume,
      ownedWeapons: List.from(state.ownedWeapons),
      ownedCostumes: List.from(state.ownedCostumes),
      ownedDecorations: List.from(state.ownedDecorations),
      stageHighScores: state.stageHighScores,
      useIsometricMovement: state.useIsometricMovement,
    );
    _saveState();
    return true;
  }

  void equipWeapon(String weaponId) {
    if (!state.ownedWeapons.contains(weaponId)) return;
    state = Player(
      coins: state.coins,
      currentStage: state.currentStage,
      unlockedStages: state.unlockedStages,
      equippedWeapon: weaponId,
      equippedCostume: state.equippedCostume,
      ownedWeapons: state.ownedWeapons,
      ownedCostumes: state.ownedCostumes,
      ownedDecorations: state.ownedDecorations,
      stageHighScores: state.stageHighScores,
      useIsometricMovement: state.useIsometricMovement,
    );
    _saveState();
  }

  void equipCostume(String costumeId) {
    if (!state.ownedCostumes.contains(costumeId)) return;
    state = Player(
      coins: state.coins,
      currentStage: state.currentStage,
      unlockedStages: state.unlockedStages,
      equippedWeapon: state.equippedWeapon,
      equippedCostume: costumeId,
      ownedWeapons: state.ownedWeapons,
      ownedCostumes: state.ownedCostumes,
      ownedDecorations: state.ownedDecorations,
      stageHighScores: state.stageHighScores,
      useIsometricMovement: state.useIsometricMovement,
    );
    _saveState();
  }

  void unlockStage(int stageId) {
    if (state.unlockedStages.contains(stageId)) return;
    final newUnlocked = List<int>.from(state.unlockedStages)..add(stageId);
    state = Player(
      coins: state.coins,
      currentStage: state.currentStage,
      unlockedStages: newUnlocked,
      equippedWeapon: state.equippedWeapon,
      equippedCostume: state.equippedCostume,
      ownedWeapons: state.ownedWeapons,
      ownedCostumes: state.ownedCostumes,
      ownedDecorations: state.ownedDecorations,
      stageHighScores: state.stageHighScores,
      useIsometricMovement: state.useIsometricMovement,
    );
    _saveState();
  }

  void updateHighScore(int stageId, int score) {
    final current = state.stageHighScores[stageId] ?? 0;
    if (score <= current) return;

    final newScores = Map<int, int>.from(state.stageHighScores);
    newScores[stageId] = score;

    state = Player(
      coins: state.coins,
      currentStage: state.currentStage,
      unlockedStages: state.unlockedStages,
      equippedWeapon: state.equippedWeapon,
      equippedCostume: state.equippedCostume,
      ownedWeapons: state.ownedWeapons,
      ownedCostumes: state.ownedCostumes,
      ownedDecorations: state.ownedDecorations,
      stageHighScores: newScores,
      useIsometricMovement: state.useIsometricMovement,
    );
    _saveState();
  }

  void setUseIsometricMovement(bool value) {
    state = Player(
      coins: state.coins,
      currentStage: state.currentStage,
      unlockedStages: state.unlockedStages,
      equippedWeapon: state.equippedWeapon,
      equippedCostume: state.equippedCostume,
      ownedWeapons: state.ownedWeapons,
      ownedCostumes: state.ownedCostumes,
      ownedDecorations: state.ownedDecorations,
      stageHighScores: state.stageHighScores,
      useIsometricMovement: value,
    );
    _saveState();
  }

  int getWeaponDamage() {
    final weapon = ShopItem.getItem(state.equippedWeapon ?? 'wooden_staff');
    return weapon?.stats?['damage'] ?? 5;
  }
}

final playerBoxProvider = Provider<Box<Player>>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final playerProvider = StateNotifierProvider<PlayerNotifier, Player>((ref) {
  final box = ref.watch(playerBoxProvider);
  return PlayerNotifier(box);
});
