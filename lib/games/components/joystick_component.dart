import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Circle with fill and border for visibility on both light and dark backgrounds.
class _BorderedCircle extends PositionComponent {
  _BorderedCircle({
    required double radius,
    required Color fillColor,
    required Color borderColor,
    double borderWidth = 2.0,
  })  : _radius = radius,
        _fillPaint = Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
        _borderPaint = Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
        super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  final double _radius;
  final Paint _fillPaint;
  final Paint _borderPaint;

  @override
  void render(ui.Canvas canvas) {
    canvas.drawCircle(Offset(_radius, _radius), _radius, _fillPaint);
    canvas.drawCircle(Offset(_radius, _radius), _radius, _borderPaint);
  }
}

/// Virtual joystick with bordered circles for visibility on any background.
class SpriteJoystick extends JoystickComponent {
  SpriteJoystick({
    super.position,
    double? size,
    double? knobSize,
  }) : super(
          knob: _BorderedCircle(
            radius: (knobSize ?? GameSizes.joystickKnobSize) / 2,
            fillColor: Colors.white.withValues(alpha: 0.8),
            borderColor: Colors.black.withValues(alpha: 0.5),
          ),
          background: _BorderedCircle(
            radius: (size ?? GameSizes.joystickSize) / 2,
            fillColor: Colors.white.withValues(alpha: 0.3),
            borderColor: Colors.black.withValues(alpha: 0.3),
          ),
        );

  /// Returns the joystick direction with dead zone applied.
  Vector2 get directionWithDeadZone {
    if (delta.length < GamePhysics.joystickDeadZone) {
      return Vector2.zero();
    }
    return delta;
  }

  /// Returns true if the joystick is being pushed beyond dead zone.
  bool get isActive => delta.length >= GamePhysics.joystickDeadZone;

  /// Returns true if joystick is at maximum input.
  bool get isMaxInput => delta.length > 0.9;
}
