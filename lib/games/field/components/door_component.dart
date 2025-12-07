import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

/// Door state for visual appearance and interaction
enum DoorState {
  /// Door is available to enter
  available,

  /// Door has been completed
  completed,

  /// Door is currently being interacted with
  active,
}

/// Forest door component for field exploration.
///
/// Features:
/// - Visual states: available (glowing), completed (green)
/// - Collision detection for player interaction
/// - Glow effect on available doors
/// - Particle effect when completed
class DoorComponent extends PositionComponent with CollisionCallbacks {
  DoorComponent({
    required Vector2 position,
    required this.doorIndex,
    this.state = DoorState.available,
  }) : super(
          position: position,
          size: Vector2(GameSizes.doorWidth, GameSizes.doorHeight),
          anchor: Anchor.bottomCenter,
        );

  /// Index of this door (0-9)
  final int doorIndex;

  /// Current door state
  DoorState state;

  /// Callback when player enters door
  void Function(int doorIndex)? onDoorEnter;

  // Visual components
  late RectangleComponent _frame;
  late RectangleComponent _inner;
  late CircleComponent _glowEffect;

  // Glow animation
  bool _glowIncreasing = true;
  double _glowOpacity = 0.3;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Door frame (wood brown)
    _frame = RectangleComponent(
      size: size,
      paint: Paint()..color = AppColors.secondary,
      anchor: Anchor.bottomCenter,
    );
    add(_frame);

    // Inner door area (darker)
    _inner = RectangleComponent(
      size: Vector2(size.x * 0.8, size.y * 0.9),
      position: Vector2(size.x * 0.1, 0),
      paint: Paint()..color = AppColors.secondaryDark,
      anchor: Anchor.topLeft,
    );
    add(_inner);

    // Glow effect (only visible when available)
    _glowEffect = CircleComponent(
      radius: size.x * 0.8,
      position: Vector2(size.x / 2, size.y * 0.4),
      paint: Paint()
        ..color = _getGlowColor().withValues(alpha: _glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      anchor: Anchor.center,
    );
    add(_glowEffect);

    // Add hitbox for collision
    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.6, size.y * 0.3),
        position: Vector2(size.x * 0.2, size.y * 0.7),
      ),
    );

    _updateVisuals();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animate glow effect for available doors
    if (state == DoorState.available) {
      _animateGlow(dt);
    }
  }

  void _animateGlow(double dt) {
    const glowSpeed = 0.8;
    const minOpacity = 0.2;
    const maxOpacity = 0.6;

    if (_glowIncreasing) {
      _glowOpacity += glowSpeed * dt;
      if (_glowOpacity >= maxOpacity) {
        _glowOpacity = maxOpacity;
        _glowIncreasing = false;
      }
    } else {
      _glowOpacity -= glowSpeed * dt;
      if (_glowOpacity <= minOpacity) {
        _glowOpacity = minOpacity;
        _glowIncreasing = true;
      }
    }

    _glowEffect.paint.color = _getGlowColor().withValues(alpha: _glowOpacity);
  }

  Color _getGlowColor() {
    switch (state) {
      case DoorState.available:
        return AppColors.accent; // Golden glow
      case DoorState.completed:
        return AppColors.success; // Green glow
      case DoorState.active:
        return Colors.white; // White glow when active
    }
  }

  void _updateVisuals() {
    switch (state) {
      case DoorState.available:
        _inner.paint.color = AppColors.secondaryDark;
        _glowEffect.paint.color = _getGlowColor().withValues(alpha: _glowOpacity);
        break;
      case DoorState.completed:
        _inner.paint.color = AppColors.success.withValues(alpha: 0.5);
        _glowEffect.paint.color = AppColors.success.withValues(alpha: 0.3);
        break;
      case DoorState.active:
        _inner.paint.color = Colors.white.withValues(alpha: 0.8);
        _glowEffect.paint.color = Colors.white.withValues(alpha: 0.5);
        break;
    }
  }

  /// Mark door as completed with animation
  void complete() {
    state = DoorState.completed;
    _updateVisuals();

    // Add completion effect
    add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(
          duration: 0.2,
          reverseDuration: 0.2,
        ),
      ),
    );
  }

  /// Set door as active (player is interacting)
  void setActive(bool active) {
    if (state == DoorState.completed) return;

    state = active ? DoorState.active : DoorState.available;
    _updateVisuals();
  }

  /// Enter the door (trigger question screen)
  void enter() {
    if (state == DoorState.completed) return;

    setActive(true);
    onDoorEnter?.call(doorIndex);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // When player touches available door, enter it
    if (state == DoorState.available &&
        other.runtimeType.toString().contains('Player')) {
      enter();
    }
  }
}
