import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'battle_game.dart';

/// Flutter screen wrapper for the side-scrolling battle game.
///
/// This screen embeds the Flame game widget and handles:
/// - Battle end callbacks (victory/defeat)
/// - Navigation back to field or result screen
class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.stageId,
    required this.enemyName,
    required this.onBattleEnd,
    this.difficulty = 1.0,
    this.correctAnswerRatio = 0.5,
  });

  /// Current stage ID
  final String stageId;

  /// Enemy display name
  final String enemyName;

  /// Callback when battle ends
  final void Function(BattleResult result) onBattleEnd;

  /// Difficulty multiplier (based on stage)
  final double difficulty;

  /// Ratio of correct kanji answers (for damage bonus)
  final double correctAnswerRatio;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late BattleGame _game;
  BattleResult? _result;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _game = BattleGame(
      enemyName: widget.enemyName,
      difficulty: widget.difficulty,
      correctAnswerRatio: widget.correctAnswerRatio,
      onBattleEnd: _handleBattleEnd,
    );
  }

  void _handleBattleEnd(BattleResult result) {
    setState(() {
      _result = result;
    });
  }

  void _onContinue() {
    if (_result != null) {
      widget.onBattleEnd(_result!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame game
          GameWidget(game: _game),

          // Battle result overlay
          if (_result != null) _buildResultOverlay(),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final isVictory = _result == BattleResult.victory;
    final title = isVictory ? 'Victory!' : 'Defeat...';
    final color = isVictory ? Colors.green : Colors.red;
    final icon = isVictory ? Icons.emoji_events : Icons.sentiment_dissatisfied;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isVictory
                    ? 'You defeated the ${widget.enemyName}!'
                    : 'The ${widget.enemyName} was too strong...',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  isVictory ? 'Continue' : 'Try Again',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
