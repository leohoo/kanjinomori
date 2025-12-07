import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Sprite-based joystick using Kenney Mobile Controls assets.
/// Falls back to basic circles if sprites fail to load.
class SpriteJoystick extends JoystickComponent {
  SpriteJoystick({
    super.position,
    double? size,
    double? knobSize,
  })  : _baseSize = size ?? GameSizes.joystickSize,
        _knobSize = knobSize ?? GameSizes.joystickKnobSize,
        super(
          // Use placeholder circles initially
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

  final double _baseSize;
  final double _knobSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      // Load sprite assets (JoystickComponent already has HasGameReference)
      final baseImage = await game.images.load('ui/joystick_base.png');
      final knobImage = await game.images.load('ui/joystick_knob.png');
      final baseSprite = Sprite(baseImage);
      final knobSprite = Sprite(knobImage);

      // Replace background with sprite
      final oldBackground = background;
      final spriteBackground = SpriteComponent(
        sprite: baseSprite,
        size: Vector2.all(_baseSize),
        anchor: Anchor.center,
      );
      background = spriteBackground;
      add(spriteBackground);
      oldBackground?.removeFromParent();

      // Replace knob with sprite
      final oldKnob = knob;
      final spriteKnob = SpriteComponent(
        sprite: knobSprite,
        size: Vector2.all(_knobSize),
        anchor: Anchor.center,
      );
      knob = spriteKnob;
      add(spriteKnob);
      oldKnob?.removeFromParent();
    } catch (e) {
      // Keep placeholder circles if sprites fail to load
      debugPrint('Failed to load joystick sprites: $e');
    }
  }

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
