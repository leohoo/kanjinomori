import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Virtual joystick component for player movement control.
///
/// Position: Bottom-left of screen
/// Dead zone: 20% (configurable via [GamePhysics.joystickDeadZone])
///
/// Used in both field exploration (8-directional) and battle (left/right).
class GameJoystick extends JoystickComponent {
  GameJoystick({
    super.position,
    double? size,
    double? knobSize,
  }) : super(
          knob: CircleComponent(
            radius: (knobSize ?? GameSizes.joystickKnobSize) / 2,
            paint: Paint()
              ..color = Colors.white.withValues(alpha: 0.8)
              ..style = PaintingStyle.fill,
          ),
          background: CircleComponent(
            radius: (size ?? GameSizes.joystickSize) / 2,
            paint: Paint()
              ..color = Colors.white.withValues(alpha: 0.3)
              ..style = PaintingStyle.fill,
          ),
        );

  /// Returns the joystick direction with dead zone applied.
  /// Values below [GamePhysics.joystickDeadZone] are treated as zero.
  Vector2 get directionWithDeadZone {
    if (delta.length < GamePhysics.joystickDeadZone) {
      return Vector2.zero();
    }
    return delta;
  }

  /// Returns true if the joystick is being pushed beyond dead zone.
  bool get isActive => delta.length >= GamePhysics.joystickDeadZone;

  /// Returns true if joystick is at maximum input (for dust effect trigger).
  bool get isMaxInput => delta.length > 0.9;
}
