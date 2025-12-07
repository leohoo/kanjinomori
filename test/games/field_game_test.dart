import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/games/field/components/door_component.dart';
import 'package:kanji_game/games/field/components/player_component.dart';
import 'package:kanji_game/games/field/components/tile_map_component.dart';

void main() {
  group('PlayerComponent', () {
    test('should initialize with correct position and state', () {
      final player = PlayerComponent(position: Vector2(100, 100));

      expect(player.position, Vector2(100, 100));
      expect(player.state, PlayerState.idle);
      expect(player.direction, PlayerDirection.down);
      expect(player.velocity, Vector2.zero());
    });

    test('should update velocity based on movement input', () {
      final player = PlayerComponent(position: Vector2.zero());

      // Set movement input
      player.setMovementInput(Vector2(1, 0));
      player.update(0.1); // 100ms

      // Velocity should be moving towards target
      expect(player.velocity.x, greaterThan(0));
    });

    test('should apply friction when no input', () {
      final player = PlayerComponent(position: Vector2.zero());

      // Give player some velocity
      player.velocity.setValues(100, 0);

      // Clear input and update
      player.setMovementInput(Vector2.zero());
      player.update(0.1);

      // Velocity should decrease due to friction
      expect(player.velocity.x, lessThan(100));
    });

    test('should change state based on movement', () {
      final player = PlayerComponent(position: Vector2.zero());

      // Initially idle
      expect(player.state, PlayerState.idle);

      // Set velocity (simulating movement)
      player.velocity.setValues(100, 0);
      player.update(0.016);

      expect(player.state, PlayerState.walking);
    });

    test('should detect max speed for dust effect', () {
      final player = PlayerComponent(position: Vector2.zero());

      // Not at max speed initially
      expect(player.isAtMaxSpeed, false);

      // Set to near max velocity
      player.velocity.setValues(190, 0);
      player.update(0.016);

      expect(player.isAtMaxSpeed, true);
    });
  });

  group('DoorComponent', () {
    test('should initialize with correct state', () {
      final door = DoorComponent(
        position: Vector2(50, 50),
        doorIndex: 3,
      );

      expect(door.doorIndex, 3);
      expect(door.state, DoorState.available);
    });

    test('should initialize as completed if specified', () {
      final door = DoorComponent(
        position: Vector2(50, 50),
        doorIndex: 5,
        state: DoorState.completed,
      );

      expect(door.state, DoorState.completed);
    });

    test('should change state when completed', () async {
      final door = DoorComponent(
        position: Vector2.zero(),
        doorIndex: 0,
      );
      await door.onLoad();

      expect(door.state, DoorState.available);

      door.complete();

      expect(door.state, DoorState.completed);
    });

    test('should trigger callback on enter', () async {
      int? enteredDoor;

      final door = DoorComponent(
        position: Vector2.zero(),
        doorIndex: 7,
      );
      await door.onLoad();
      door.onDoorEnter = (index) => enteredDoor = index;

      door.enter();

      expect(enteredDoor, 7);
    });

    test('should not enter if already completed', () async {
      int? enteredDoor;

      final door = DoorComponent(
        position: Vector2.zero(),
        doorIndex: 2,
        state: DoorState.completed,
      );
      await door.onLoad();
      door.onDoorEnter = (index) => enteredDoor = index;

      door.enter();

      expect(enteredDoor, isNull);
    });

    test('should toggle active state', () async {
      final door = DoorComponent(
        position: Vector2.zero(),
        doorIndex: 0,
      );
      await door.onLoad();

      expect(door.state, DoorState.available);

      door.setActive(true);
      expect(door.state, DoorState.active);

      door.setActive(false);
      expect(door.state, DoorState.available);
    });

    test('should not toggle active if completed', () async {
      final door = DoorComponent(
        position: Vector2.zero(),
        doorIndex: 0,
        state: DoorState.completed,
      );
      await door.onLoad();

      door.setActive(true);
      expect(door.state, DoorState.completed);
    });
  });

  group('TileMapComponent', () {
    test('should generate correct number of door positions', () async {
      final tileMap = TileMapComponent(
        mapWidth: 30,
        mapHeight: 30,
      );

      // Trigger map generation
      await tileMap.onLoad();

      expect(tileMap.doorPositions.length, 10);
    });

    test('should convert tile to screen coordinates', () {
      final tileMap = TileMapComponent(
        mapWidth: 10,
        mapHeight: 10,
      );

      // Tile at origin
      final screenPos = tileMap.tileToScreen(0, 0);
      expect(screenPos, Vector2(0, 0));

      // Tile at (1, 0) should be right and down
      final pos10 = tileMap.tileToScreen(1, 0);
      expect(pos10.x, greaterThan(0));
      expect(pos10.y, greaterThan(0));

      // Tile at (0, 1) should be left and down
      final pos01 = tileMap.tileToScreen(0, 1);
      expect(pos01.x, lessThan(0));
      expect(pos01.y, greaterThan(0));
    });

    test('should convert screen to tile coordinates', () {
      final tileMap = TileMapComponent(
        mapWidth: 10,
        mapHeight: 10,
      );

      // Origin should map to tile (0, 0)
      final tilePos = tileMap.screenToTile(Vector2(0, 0));
      expect(tilePos.x.round(), 0);
      expect(tilePos.y.round(), 0);
    });

    test('should provide spawn position at map center', () {
      final tileMap = TileMapComponent(
        mapWidth: 20,
        mapHeight: 20,
      );

      final spawn = tileMap.getSpawnPosition();

      // Should be the screen position for tile (10, 10)
      expect(spawn, tileMap.tileToScreen(10, 10));
    });

    test('should get door world position by index', () async {
      final tileMap = TileMapComponent(
        mapWidth: 30,
        mapHeight: 30,
      );
      await tileMap.onLoad();

      // Valid index
      final doorPos = tileMap.getDoorWorldPosition(0);
      expect(doorPos, isNot(Vector2.zero()));

      // Invalid index
      final invalidPos = tileMap.getDoorWorldPosition(99);
      expect(invalidPos, Vector2.zero());
    });

    test('should calculate map bounds', () {
      final tileMap = TileMapComponent(
        mapWidth: 10,
        mapHeight: 10,
      );

      final bounds = tileMap.getMapBounds();

      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });
  });
}
