import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../components/joystick_component.dart';
import 'components/door_component.dart';
import 'components/player_component.dart';
import 'components/tile_map_component.dart';

/// Isometric field exploration game.
///
/// Features:
/// - Scrollable forest map with 10 doors
/// - Player movement via joystick (8-directional)
/// - Door collision triggers question screen
/// - Camera follows player
class FieldGame extends FlameGame with HasCollisionDetection {
  FieldGame({
    this.onDoorEnter,
    this.completedDoors = const [],
  });

  /// Callback when player enters a door
  final void Function(int doorIndex)? onDoorEnter;

  /// List of already completed door indices
  final List<int> completedDoors;

  /// Map dimensions in tiles
  static const int mapWidth = 30;
  static const int mapHeight = 30;

  // Game components
  late TileMapComponent tileMap;
  late PlayerComponent player;
  late SpriteJoystick joystick;
  late List<DoorComponent> doors;

  // Camera
  late CameraComponent cameraComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set custom asset prefix (default is 'assets/images/')
    images.prefix = 'assets/';

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

    // Add minimap indicator
    _addMinimap();
  }

  void _addMinimap() {
    // Simple minimap in top-right corner
    final minimapSize = Vector2(100, 100);
    final minimapPos = Vector2(size.x - minimapSize.x - 10, 10);

    final minimap = RectangleComponent(
      position: minimapPos,
      size: minimapSize,
      paint: Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    cameraComponent.viewport.add(minimap);

    // Minimap border
    final border = RectangleComponent(
      position: minimapPos,
      size: minimapSize,
      paint: Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    cameraComponent.viewport.add(border);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update player movement from joystick
    player.setMovementInput(joystick.directionWithDeadZone);

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
