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
  String _playerName = 'Player';

  /// Enemy name
  String _enemyName = 'Boss';

  // HP bar components
  late RectangleComponent _playerHpBackground;
  late RectangleComponent _playerHpBar;
  late RectangleComponent _enemyHpBackground;
  late RectangleComponent _enemyHpBar;

  // Cached text painters for performance
  final TextPainter _playerNamePainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  final TextPainter _enemyNamePainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  // Text style
  static const _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
  );

  // Constants
  static const double barHeight = 20;
  static const double padding = 16;
  static const double barGap = 20;

  // Dynamic bar width based on screen size
  double get barWidth => (screenSize.x - padding * 2 - barGap) / 2;

  String get playerName => _playerName;
  set playerName(String value) {
    if (_playerName != value) {
      _playerName = value;
      _updatePlayerNamePainter();
    }
  }

  String get enemyName => _enemyName;
  set enemyName(String value) {
    if (_enemyName != value) {
      _enemyName = value;
      _updateEnemyNamePainter();
    }
  }

  void _updatePlayerNamePainter() {
    _playerNamePainter.text = TextSpan(text: _playerName, style: _labelStyle);
    _playerNamePainter.layout();
  }

  void _updateEnemyNamePainter() {
    _enemyNamePainter.text = TextSpan(text: _enemyName, style: _labelStyle);
    _enemyNamePainter.layout();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize text painters
    _updatePlayerNamePainter();
    _updateEnemyNamePainter();

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

    // Draw cached labels
    _playerNamePainter.paint(canvas, Offset(padding, padding + barHeight + 4));
    _enemyNamePainter.paint(
      canvas,
      Offset(screenSize.x - padding - _enemyNamePainter.width, padding + barHeight + 4),
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
