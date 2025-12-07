import '../../../utils/constants.dart';

/// Combat damage calculation system.
///
/// Damage formula:
/// ```
/// baseDamage = playerAttack + weaponBonus
/// kanjiBonus = (correctAnswers / totalQuestions > 0.5) ? 1.5 : 1.0
/// critMultiplier = (isAerial && random < 0.05 + heightBonus) ? 1.5 : 1.0
/// finalDamage = baseDamage * kanjiBonus * critMultiplier * (isAerial ? 0.8 : 1.0)
/// ```
class CombatSystem {
  /// Calculate damage for an attack.
  ///
  /// [baseDamage] - Player's base attack + weapon bonus
  /// [isAerial] - Whether this is an aerial attack
  /// [kanjiCorrectRatio] - Ratio of correct kanji answers (0.0 to 1.0)
  /// [randomValue] - Random value for crit calculation (0.0 to 1.0)
  /// [heightBonus] - Additional crit chance from height (0.0 to 0.1)
  static DamageResult calculateDamage({
    required double baseDamage,
    required bool isAerial,
    required double kanjiCorrectRatio,
    required double randomValue,
    double heightBonus = 0.0,
  }) {
    // Kanji bonus: 1.5x if >50% correct answers
    final kanjiMultiplier = kanjiCorrectRatio > 0.5
        ? GamePhysics.kanjiBonusMultiplier
        : 1.0;

    // Critical hit calculation
    final critChance = isAerial
        ? GamePhysics.aerialCritBonusPercent + heightBonus
        : heightBonus;
    final isCrit = randomValue < critChance;
    final critMultiplier =
        isCrit ? GamePhysics.critDamageMultiplier : 1.0;

    // Aerial damage reduction
    final aerialMultiplier =
        isAerial ? GamePhysics.aerialDamageMultiplier : 1.0;

    // Final damage
    final finalDamage =
        baseDamage * kanjiMultiplier * critMultiplier * aerialMultiplier;

    return DamageResult(
      damage: finalDamage.round(),
      isCritical: isCrit,
      isAerial: isAerial,
      hasKanjiBonus: kanjiCorrectRatio > 0.5,
    );
  }
}

/// Result of a damage calculation.
class DamageResult {
  final int damage;
  final bool isCritical;
  final bool isAerial;
  final bool hasKanjiBonus;

  const DamageResult({
    required this.damage,
    required this.isCritical,
    required this.isAerial,
    required this.hasKanjiBonus,
  });

  @override
  String toString() {
    final modifiers = <String>[];
    if (isCritical) modifiers.add('CRIT');
    if (isAerial) modifiers.add('AERIAL');
    if (hasKanjiBonus) modifiers.add('漢字ボーナス');
    final modStr = modifiers.isEmpty ? '' : ' (${modifiers.join(', ')})';
    return '$damage ダメージ$modStr';
  }
}
