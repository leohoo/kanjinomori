import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32); // Forest green
  static const primaryLight = Color(0xFF60AD5E);
  static const primaryDark = Color(0xFF005005);

  static const secondary = Color(0xFF8D6E63); // Wood brown
  static const secondaryLight = Color(0xFFBE9C91);
  static const secondaryDark = Color(0xFF5F4339);

  static const accent = Color(0xFFFFD54F); // Golden yellow for coins
  static const accentLight = Color(0xFFFFFF81);
  static const accentDark = Color(0xFFC8A415);

  static const background = Color(0xFFF1F8E9); // Light forest
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);

  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textOnPrimary = Color(0xFFFFFFFF);

  static const hp = Color(0xFFE53935); // Red for health
  static const hpBackground = Color(0xFFFFCDD2);
  static const enemyHp = Color(0xFF7B1FA2); // Purple for enemy
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 20.0;

  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 44.0;

  static const double iconSmall = 20.0;
  static const double iconMedium = 28.0;
  static const double iconLarge = 40.0;

  static const double kanjiSize = 120.0;
  static const double kanjiSizeSmall = 60.0;
}

class AppDurations {
  static const questionTimeout = Duration(seconds: 30);
  static const correctAnswerCelebration = Duration(milliseconds: 1500);
  static const wrongAnswerFeedback = Duration(milliseconds: 800);
  static const battleActionWindow = Duration(milliseconds: 500);
  static const enemyTelegraph = Duration(milliseconds: 1000);
  static const transitionDuration = Duration(milliseconds: 300);
}

class GameConfig {
  static const int questionsPerStage = 10;
  static const int coinsPerCorrect = 5;
  static const int bonusForPerfect = 10;
  static const int playerBaseHp = 100;
  static const int playerBaseDamage = 10;
}

/// Physics constants for 2.5D game mechanics
class GamePhysics {
  // Player movement (pixels/sec)
  static const double playerSpeed = 200.0;
  static const double playerAcceleration = 800.0;
  static const double playerFriction = 600.0;

  // Jump physics (pixels/sec)
  static const double jumpForce = 400.0;
  static const double maxJumpForce = 600.0; // held jump
  static const double gravity = 980.0;
  static const double maxFallSpeed = 800.0;

  // Joystick
  static const double joystickDeadZone = 0.2; // 20%

  // Combat timing (seconds)
  static const double attackDuration = 0.3;
  static const double aerialAttackDuration = 0.25;
  static const double shieldDuration = 1.0;
  static const double shieldCooldown = 0.5;
  static const double invincibilityDuration = 0.5;
  static const double knockbackDuration = 0.2;

  // Combat multipliers
  static const double aerialDamageMultiplier = 0.8; // 80% damage
  static const double aerialCritBonusPercent = 0.05; // +5% crit chance
  static const double critDamageMultiplier = 1.5;
  static const double kanjiBonusMultiplier = 1.5; // >50% correct answers

  // Effects (seconds)
  static const double jumpWindEffectDuration = 0.35;
  static const double landingDustDuration = 0.2;

  // Enemy AI distances (pixels)
  static const double enemyApproachDistance = 200.0;
  static const double enemyRetreatDistance = 80.0;
  static const double enemyAttackRange = 100.0;
  static const double enemySafeDistance = 150.0;

  // Knockback velocities (pixels/sec)
  static const double knockbackHorizontal = 80.0;
  static const double knockbackVertical = 100.0;
  static const double playerKnockbackHorizontal = 100.0;
  static const double playerKnockbackVertical = 150.0;
}

/// Tile and sprite sizes for isometric rendering
class GameSizes {
  // Isometric tile dimensions
  static const double tileWidth = 64.0;
  static const double tileHeight = 32.0;

  // Player sprite
  static const double playerWidth = 48.0;
  static const double playerHeight = 64.0;

  // Door sprite
  static const double doorWidth = 64.0;
  static const double doorHeight = 96.0;

  // UI elements
  static const double joystickSize = 120.0;
  static const double joystickKnobSize = 50.0;
  static const double actionButtonLarge = 80.0;
  static const double actionButtonMedium = 60.0;

  // Hitboxes
  static const double playerHitboxWidth = 32.0;
  static const double playerHitboxHeight = 48.0;
  static const double attackHitboxWidth = 40.0;
  static const double attackHitboxHeight = 32.0;
}
