import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/models/models.dart';

void main() {
  group('Kanji Model', () {
    test('creates Kanji from JSON', () {
      final json = {
        'kanji': '山',
        'readings': ['やま', 'さん'],
        'meaning': 'mountain',
        'grade': 1,
        'stroke_count': 3,
      };

      final kanji = Kanji.fromJson(json);

      expect(kanji.kanji, '山');
      expect(kanji.readings, ['やま', 'さん']);
      expect(kanji.meaning, 'mountain');
      expect(kanji.grade, 1);
      expect(kanji.strokeCount, 3);
    });
  });

  group('Player Model', () {
    test('adds and spends coins correctly', () {
      final player = Player();

      player.addCoins(100);
      expect(player.coins, 100);

      final spent = player.spendCoins(30);
      expect(spent, true);
      expect(player.coins, 70);

      final failedSpend = player.spendCoins(100);
      expect(failedSpend, false);
      expect(player.coins, 70);
    });

    test('unlocks stages', () {
      final player = Player();

      expect(player.isStageUnlocked(1), true);
      expect(player.isStageUnlocked(2), false);

      player.unlockStage(2);
      expect(player.isStageUnlocked(2), true);
    });
  });

  group('Battle Model', () {
    test('initializes battle correctly', () {
      final battle = Battle(
        playerName: 'Test Player',
        playerHp: 100,
        playerDamage: 10,
        enemyName: 'Test Enemy',
        enemyHp: 50,
        enemyDamage: 5,
      );

      expect(battle.player.hp, 100);
      expect(battle.enemy.hp, 50);
      expect(battle.state, BattleState.waiting);
    });

    test('player attack deals damage', () {
      final battle = Battle(
        playerName: 'Test Player',
        playerHp: 100,
        playerDamage: 10,
        enemyName: 'Test Enemy',
        enemyHp: 50,
        enemyDamage: 5,
      );

      battle.startBattle();
      battle.playerAction(BattleAction.attack);

      expect(battle.enemy.hp, 40);
    });
  });
}
