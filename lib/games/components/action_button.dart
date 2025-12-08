import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Action button types for battle controls
enum ActionButtonType {
  jump,
  attack,
  shield,
}

/// A circular action button for battle controls.
///
/// Layout (right side of screen):
/// - Shield: top-right (medium)
/// - Attack: middle-right (large)
/// - Jump: bottom-right (medium)
class ActionButton extends PositionComponent with TapCallbacks {
  final ActionButtonType type;
  final VoidCallback? onPressed;
  final VoidCallback? onReleased;

  bool _isPressed = false;
  late final Paint _bgPaint;
  late final double _radius;

  ActionButton({
    required this.type,
    this.onPressed,
    this.onReleased,
    super.position,
    double? size,
  }) : super(
          size: Vector2.all(
            size ??
                (type == ActionButtonType.attack
                    ? GameSizes.actionButtonLarge
                    : GameSizes.actionButtonMedium),
          ),
        ) {
    _radius = this.size.x / 2;
    _bgPaint = Paint()
      ..color = _getButtonColor().withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
  }

  Color _getButtonColor() {
    switch (type) {
      case ActionButtonType.jump:
        return Colors.blue;
      case ActionButtonType.attack:
        return Colors.red;
      case ActionButtonType.shield:
        return Colors.green;
    }
  }

  bool get isPressed => _isPressed;

  @override
  void render(Canvas canvas) {
    // Draw button background
    final alpha = _isPressed ? 0.6 : 0.8;
    _bgPaint.color = _getButtonColor().withValues(alpha: alpha);

    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      _bgPaint,
    );

    // Draw border
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius - 2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    _isPressed = true;
    onPressed?.call();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isPressed = false;
    onReleased?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isPressed = false;
    onReleased?.call();
  }
}
