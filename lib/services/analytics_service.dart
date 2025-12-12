import 'package:firebase_analytics/firebase_analytics.dart';

/// Service wrapper for Firebase Analytics.
///
/// Provides typed methods for tracking game events, screen views,
/// and user actions throughout the app.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen tracking

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Stage events

  Future<void> logStageStarted({
    required int stageId,
    required int grade,
  }) async {
    await _analytics.logEvent(
      name: 'stage_started',
      parameters: {
        'stage_id': stageId,
        'grade': grade,
      },
    );
  }

  Future<void> logStageCompleted({
    required int stageId,
    required bool victory,
    required int totalCoins,
    required int questionCoins,
    required int battleCoins,
  }) async {
    await _analytics.logEvent(
      name: 'stage_completed',
      parameters: {
        'stage_id': stageId,
        'victory': victory,
        'total_coins': totalCoins,
        'question_coins': questionCoins,
        'battle_coins': battleCoins,
      },
    );
  }

  // Question events

  Future<void> logQuestionAnswered({
    required String kanji,
    required bool correct,
    required int attemptNumber,
    required String questionType,
  }) async {
    await _analytics.logEvent(
      name: 'question_answered',
      parameters: {
        'kanji': kanji,
        'correct': correct,
        'attempt_number': attemptNumber,
        'question_type': questionType,
      },
    );
  }

  Future<void> logPerfectStage({required int stageId}) async {
    await _analytics.logEvent(
      name: 'perfect_stage',
      parameters: {'stage_id': stageId},
    );
  }

  // Battle events

  Future<void> logBattleStarted({
    required int stageId,
    required String bossName,
  }) async {
    await _analytics.logEvent(
      name: 'battle_started',
      parameters: {
        'stage_id': stageId,
        'boss_name': bossName,
      },
    );
  }

  Future<void> logBattleCompleted({
    required int stageId,
    required bool victory,
    required int turns,
  }) async {
    await _analytics.logEvent(
      name: 'battle_completed',
      parameters: {
        'stage_id': stageId,
        'victory': victory,
        'turns': turns,
      },
    );
  }

  // Shop events

  Future<void> logShopViewed() async {
    await _analytics.logEvent(name: 'shop_viewed');
  }

  Future<void> logItemPurchased({
    required String itemId,
    required String category,
    required int cost,
  }) async {
    await _analytics.logEvent(
      name: 'item_purchased',
      parameters: {
        'item_id': itemId,
        'category': category,
        'cost': cost,
      },
    );
  }

  Future<void> logItemEquipped({
    required String itemId,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'item_equipped',
      parameters: {
        'item_id': itemId,
        'category': category,
      },
    );
  }

  // Achievement events

  Future<void> logStageUnlocked({required int stageId}) async {
    await _analytics.logEvent(
      name: 'stage_unlocked',
      parameters: {'stage_id': stageId},
    );
  }
}
