import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../components/joystick_component.dart';
import 'components/door_component.dart';
import 'components/player_component.dart';
import 'components/tile_map_component.dart';

/// Isometric field exploration game.
///
/// Features:
/// - Scrollable forest map with 10 doors
/// - Player movement via joystick or keyboard (8-directional)
/// - Door collision triggers question screen
/// - Camera follows player
class FieldGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  FieldGame({
    this.onDoorEnter,
    this.completedDoors = const [],
    this.useIsometricMovement = true,
  });

  /// Callback when player enters a door
  final void Function(int doorIndex)? onDoorEnter;

  /// List of already completed door indices
  final List<int> completedDoors;

  /// Whether to use isometric movement transformation
  final bool useIsometricMovement;

  /// Map dimensions in tiles
  static const int mapWidth = 30;
  static const int mapHeight = 30;

  // Game components
  late TileMapComponent tileMap;
  late PlayerComponent player;
  late SpriteJoystick joystick;
  late List<DoorComponent> doors;

  // Keyboard state
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Camera
  late CameraComponent cameraComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create world
    final world = World();
    add(world);

    // Create tile map
    tileMap = TileMapComponent(
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
    world.add(tileMap);

    // Wait for tile map to load
    await tileMap.onLoad();

    // Create player at spawn position
    player = PlayerComponent(
      position: tileMap.getSpawnPosition(),
      useIsometricMovement: useIsometricMovement,
    );
    player.onDoorCollision = _onPlayerDoorCollision;
    world.add(player);

    // Create 10 doors
    doors = [];
    for (int i = 0; i < 10; i++) {
      final doorPos = tileMap.getDoorWorldPosition(i);
      final door = DoorComponent(
        position: doorPos,
        doorIndex: i,
        state: completedDoors.contains(i)
            ? DoorState.completed
            : DoorState.available,
      );
      door.onDoorEnter = _onDoorEnter;
      doors.add(door);
      world.add(door);
    }

    // Setup camera to follow player
    cameraComponent = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.center;
    add(cameraComponent);
    cameraComponent.follow(player);

    // Create joystick (fixed to viewport)
    joystick = SpriteJoystick(
      position: Vector2(
        GameSizes.joystickSize / 2 + 20,
        size.y - GameSizes.joystickSize / 2 - 20,
      ),
    );
    cameraComponent.viewport.add(joystick);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    return KeyEventResult.handled;
  }

  Vector2 _getKeyboardInput() {
    double x = 0, y = 0;

    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      x += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      y += 1;
    }

    return Vector2(x, y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Combine joystick and keyboard input (keyboard takes priority when active)
    final joystickInput = joystick.directionWithDeadZone;
    final keyboardInput = _getKeyboardInput();
    final movementInput =
        keyboardInput.length > 0 ? keyboardInput : joystickInput;

    player.setMovementInput(movementInput);

    // Clamp player position to map bounds
    _clampPlayerToMap();
  }

  void _clampPlayerToMap() {
    final bounds = tileMap.getMapBounds();
    final padding = 50.0;

    player.position.x = player.position.x.clamp(
      bounds.left + padding,
      bounds.right - padding,
    );
    player.position.y = player.position.y.clamp(
      bounds.top + padding,
      bounds.bottom - padding,
    );
  }

  void _onPlayerDoorCollision(PositionComponent door) {
    // Player touched a door - handled by door's collision callback
  }

  void _onDoorEnter(int doorIndex) {
    // Notify external callback
    onDoorEnter?.call(doorIndex);
  }

  /// Mark a door as completed
  void completeDoor(int doorIndex) {
    if (doorIndex >= 0 && doorIndex < doors.length) {
      doors[doorIndex].complete();
    }
  }

  /// Check if all doors are completed
  bool get allDoorsCompleted => doors.every((d) => d.state == DoorState.completed);

  /// Get number of completed doors
  int get completedDoorsCount =>
      doors.where((d) => d.state == DoorState.completed).length;

  @override
  Color backgroundColor() => AppColors.background;
}
