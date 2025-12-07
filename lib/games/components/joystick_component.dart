import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Sprite-based joystick using Kenney Mobile Controls assets.
/// Falls back to basic circles if sprites fail to load.
class SpriteJoystick extends JoystickComponent {
  // Note: Sprite loading disabled - Kenney joystick sprites are dark and
  // invisible against dark backgrounds. Using white translucent circles instead.
  SpriteJoystick({
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
