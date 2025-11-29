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
