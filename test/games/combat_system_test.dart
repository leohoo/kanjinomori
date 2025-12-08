import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/games/battle/systems/combat_system.dart';
import 'package:kanji_game/utils/constants.dart';

void main() {
  group('CombatSystem', () {
    group('calculateDamage', () {
      test('base damage with no modifiers', () {
        final result = CombatSystem.calculateDamage(
          baseDamage: 10.0,
          isAerial: false,
          kanjiCorrectRatio: 0.3, // Below 50%, no bonus
          randomValue: 0.5, // No crit
        );

        expect(result.damage, 10);
        expect(result.isCritical, false);
        expect(result.isAerial, false);
        expect(result.hasKanjiBonus, false);
      });

      test('aerial attack applies 80% damage multiplier', () {
        final result = CombatSystem.calculateDamage(
          baseDamage: 100.0,
          isAerial: true,
          kanjiCorrectRatio: 0.3,
          randomValue: 0.5, // No crit
        );

        expect(result.damage, 80); // 100 * 0.8
        expect(result.isAerial, true);
      });

      test('kanji bonus applies 1.5x when >50% correct', () {
        final result = CombatSystem.calculateDamage(
          baseDamage: 100.0,
          isAerial: false,
          kanjiCorrectRatio: 0.6, // Above 50%
          randomValue: 0.5, // No crit
        );

        expect(result.damage, 150); // 100 * 1.5
        expect(result.hasKanjiBonus, true);
      });

      test('kanji bonus does not apply at exactly 50%', () {
        final result = CombatSystem.calculateDamage(
          baseDamage: 100.0,
          isAerial: false,
          kanjiCorrectRatio: 0.5, // Exactly 50%, no bonus
          randomValue: 0.5,
        );

        expect(result.damage, 100);
        expect(result.hasKanjiBonus, false);
      });

      test('critical hit applies 1.5x multiplier', () {
        final result = CombatSystem.calculateDamage(
          baseDamage: 100.0,
          isAerial: false,
          kanjiCorrectRatio: 0.3,
          randomValue: 0.0, // Guaranteed crit (needs height bonus)
          heightBonus: 0.1, // 10% crit chance
        );

        expect(result.damage, 150); // 100 * 1.5
        expect(result.isCritical, true);
      });

      test('aerial attack has +5% base crit chance', () {
        // With aerial, crit chance is 0.05 + heightBonus
        // randomValue 0.04 should crit with aerial
        final result = CombatSystem.calculateDamage(
          baseDamage: 100.0,
          isAerial: true,
          kanjiCorrectRatio: 0.3,
          randomValue: 0.04, // Below 0.05 aerial crit threshold
        );

        expect(result.isCritical, true);
        expect(result.damage, 120); // 100 * 0.8 (aerial) * 1.5 (crit)
      });

      test('ground attack without height bonus cannot crit', () {
        final result = CombatSystem.calculateDamage(
          baseDamage: 100.0,
          isAerial: false,
          kanjiCorrectRatio: 0.3,
          randomValue: 0.0, // Would crit if there was any chance
          heightBonus: 0.0,
        );

        expect(result.isCritical, false);
        expect(result.damage, 100);
      });

      test('all multipliers stack correctly', () {
        // Aerial + Kanji bonus + Crit
        final result = CombatSystem.calculateDamage(
          baseDamage: 100.0,
          isAerial: true,
          kanjiCorrectRatio: 0.8, // Kanji bonus
          randomValue: 0.0, // Crit
          heightBonus: 0.1,
        );

        // 100 * 1.5 (kanji) * 1.5 (crit) * 0.8 (aerial) = 180
        expect(result.damage, 180);
        expect(result.isCritical, true);
        expect(result.isAerial, true);
        expect(result.hasKanjiBonus, true);
      });
    });

    group('DamageResult', () {
      test('toString formats correctly with no modifiers', () {
        final result = DamageResult(
          damage: 10,
          isCritical: false,
          isAerial: false,
          hasKanjiBonus: false,
        );

        expect(result.toString(), '10 ダメージ');
      });

      test('toString includes all modifiers', () {
        final result = DamageResult(
          damage: 180,
          isCritical: true,
          isAerial: true,
          hasKanjiBonus: true,
        );

        expect(result.toString(), contains('CRIT'));
        expect(result.toString(), contains('AERIAL'));
        expect(result.toString(), contains('漢字ボーナス'));
      });
    });
  });

  group('GamePhysics constants', () {
    test('aerial damage multiplier is 0.8 (80%)', () {
      expect(GamePhysics.aerialDamageMultiplier, 0.8);
    });

    test('aerial crit bonus is 0.05 (5%)', () {
      expect(GamePhysics.aerialCritBonusPercent, 0.05);
    });

    test('crit damage multiplier is 1.5', () {
      expect(GamePhysics.critDamageMultiplier, 1.5);
    });

    test('kanji bonus multiplier is 1.5', () {
      expect(GamePhysics.kanjiBonusMultiplier, 1.5);
    });

    test('joystick dead zone is 0.2 (20%)', () {
      expect(GamePhysics.joystickDeadZone, 0.2);
    });

    test('jump wind effect duration is 0.35 seconds', () {
      expect(GamePhysics.jumpWindEffectDuration, 0.35);
    });
  });
}
