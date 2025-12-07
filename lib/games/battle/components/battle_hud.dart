import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

/// HUD component showing HP bars and battle info.
class BattleHud extends PositionComponent {
  BattleHud({
    required this.screenSize,
  });

  /// Screen size for positioning
  final Vector2 screenSize;

  /// Player HP percentage (0-1)
  double playerHpPercent = 1.0;

  /// Enemy HP percentage (0-1)
  double enemyHpPercent = 1.0;

  /// Player name
  String playerName = 'Player';

  /// Enemy name
  String enemyName = 'Boss';

  // HP bar components
  late RectangleComponent _playerHpBackground;
  late RectangleComponent _playerHpBar;
  late RectangleComponent _enemyHpBackground;
  late RectangleComponent _enemyHpBar;

  // Constants
  static const double barWidth = 200;
  static const double barHeight = 20;
  static const double padding = 16;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Player HP bar (left side)
    _playerHpBackground = RectangleComponent(
      position: Vector2(padding, padding),
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = AppColors.hpBackground,
    );
    add(_playerHpBackground);

    _playerHpBar = RectangleComponent(
      position: Vector2(padding, padding),
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = AppColors.hp,
    );
    add(_playerHpBar);

    // Enemy HP bar (right side)
    _enemyHpBackground = RectangleComponent(
      position: Vector2(screenSize.x - padding - barWidth, padding),
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = AppColors.hpBackground,
    );
    add(_enemyHpBackground);

    _enemyHpBar = RectangleComponent(
      position: Vector2(screenSize.x - padding - barWidth, padding),
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = AppColors.enemyHp,
    );
    add(_enemyHpBar);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animate HP bar changes smoothly
    final targetPlayerWidth = barWidth * playerHpPercent.clamp(0, 1);
    final targetEnemyWidth = barWidth * enemyHpPercent.clamp(0, 1);

    _playerHpBar.size.x = _lerp(_playerHpBar.size.x, targetPlayerWidth, dt * 5);
    _enemyHpBar.size.x = _lerp(_enemyHpBar.size.x, targetEnemyWidth, dt * 5);

    // Enemy HP bar should fill from right to left
    _enemyHpBar.position.x = screenSize.x - padding - _enemyHpBar.size.x;
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t.clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Player name
    textPainter.text = TextSpan(
      text: playerName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padding, padding + barHeight + 4));

    // Enemy name
    textPainter.text = TextSpan(
      text: enemyName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(screenSize.x - padding - textPainter.width, padding + barHeight + 4),
    );
  }

  /// Update player HP display
  void setPlayerHp(double percent) {
    playerHpPercent = percent.clamp(0, 1);
  }

  /// Update enemy HP display
  void setEnemyHp(double percent) {
    enemyHpPercent = percent.clamp(0, 1);
  }
}
