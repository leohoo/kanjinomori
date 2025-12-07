import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

/// Isometric tile types for the forest map
enum TileType {
  grass,
  path,
  tree,
  bush,
  rock,
}

/// Single tile data
class Tile {
  final int x;
  final int y;
  final TileType type;

  const Tile(this.x, this.y, this.type);
}

/// Isometric tile map component for forest field.
///
/// Features:
/// - Procedural forest generation
/// - Isometric coordinate conversion
/// - Decorative elements (trees, bushes, rocks)
/// - Path tiles for walkable areas
class TileMapComponent extends PositionComponent {
  TileMapComponent({
    required this.mapWidth,
    required this.mapHeight,
  }) : super(priority: -1); // Render behind other components

  /// Map dimensions in tiles
  final int mapWidth;
  final int mapHeight;

  /// Tile data
  late List<List<TileType>> _tiles;

  /// Door positions on the map (tile coordinates)
  final List<Vector2> doorPositions = [];

  /// Random generator for procedural generation
  final Random _random = Random(42); // Fixed seed for consistency

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _generateMap();
  }

  void _generateMap() {
    // Initialize with grass
    _tiles = List.generate(
      mapHeight,
      (y) => List.generate(mapWidth, (x) => TileType.grass),
    );

    // Generate door positions FIRST so we can avoid placing obstacles near them
    _generateDoorPositions();

    // Add some random trees and decorations
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        // Don't place obstacles in center spawn area
        if (_isInSpawnArea(x, y)) continue;

        // Don't place obstacles near door positions
        if (_isNearDoor(x, y)) continue;

        final chance = _random.nextDouble();
        if (chance < 0.1) {
          _tiles[y][x] = TileType.tree;
        } else if (chance < 0.15) {
          _tiles[y][x] = TileType.bush;
        } else if (chance < 0.17) {
          _tiles[y][x] = TileType.rock;
        }
      }
    }
  }

  bool _isInSpawnArea(int x, int y) {
    final centerX = mapWidth ~/ 2;
    final centerY = mapHeight ~/ 2;
    return (x - centerX).abs() < 3 && (y - centerY).abs() < 3;
  }

  bool _isNearDoor(int x, int y) {
    for (final doorPos in doorPositions) {
      if ((x - doorPos.x).abs() < 2 && (y - doorPos.y).abs() < 2) {
        return true;
      }
    }
    return false;
  }

  void _generateDoorPositions() {
    // Distribute 10 doors across the map in a pattern
    final positions = <Vector2>[
      // Top row
      Vector2(mapWidth * 0.2, mapHeight * 0.15),
      Vector2(mapWidth * 0.5, mapHeight * 0.1),
      Vector2(mapWidth * 0.8, mapHeight * 0.15),
      // Middle rows
      Vector2(mapWidth * 0.1, mapHeight * 0.4),
      Vector2(mapWidth * 0.9, mapHeight * 0.4),
      Vector2(mapWidth * 0.1, mapHeight * 0.6),
      Vector2(mapWidth * 0.9, mapHeight * 0.6),
      // Bottom row
      Vector2(mapWidth * 0.2, mapHeight * 0.85),
      Vector2(mapWidth * 0.5, mapHeight * 0.9),
      Vector2(mapWidth * 0.8, mapHeight * 0.85),
    ];

    doorPositions.clear();
    for (final pos in positions) {
      doorPositions.add(Vector2(pos.x.roundToDouble(), pos.y.roundToDouble()));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render tiles in isometric order (back to front)
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        final screenPos = tileToScreen(x, y);
        _renderTile(canvas, screenPos, _tiles[y][x]);
      }
    }
  }

  void _renderTile(Canvas canvas, Vector2 screenPos, TileType type) {
    final paint = Paint();

    switch (type) {
      case TileType.grass:
        paint.color = AppColors.primary.withValues(alpha: 0.3);
        _drawIsometricTile(canvas, screenPos, paint);
        break;
      case TileType.path:
        paint.color = AppColors.secondary.withValues(alpha: 0.4);
        _drawIsometricTile(canvas, screenPos, paint);
        break;
      case TileType.tree:
        // Draw grass base
        paint.color = AppColors.primary.withValues(alpha: 0.3);
        _drawIsometricTile(canvas, screenPos, paint);
        // Draw tree
        paint.color = AppColors.primaryDark;
        _drawTree(canvas, screenPos, paint);
        break;
      case TileType.bush:
        paint.color = AppColors.primary.withValues(alpha: 0.3);
        _drawIsometricTile(canvas, screenPos, paint);
        paint.color = AppColors.primaryLight;
        _drawBush(canvas, screenPos, paint);
        break;
      case TileType.rock:
        paint.color = AppColors.primary.withValues(alpha: 0.3);
        _drawIsometricTile(canvas, screenPos, paint);
        paint.color = Colors.grey;
        _drawRock(canvas, screenPos, paint);
        break;
    }
  }

  void _drawIsometricTile(Canvas canvas, Vector2 pos, Paint paint) {
    final path = Path()
      ..moveTo(pos.x, pos.y)
      ..lineTo(pos.x + GameSizes.tileWidth / 2, pos.y + GameSizes.tileHeight / 2)
      ..lineTo(pos.x, pos.y + GameSizes.tileHeight)
      ..lineTo(pos.x - GameSizes.tileWidth / 2, pos.y + GameSizes.tileHeight / 2)
      ..close();

    canvas.drawPath(path, paint);

    // Draw outline
    paint
      ..color = paint.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawTree(Canvas canvas, Vector2 pos, Paint paint) {
    // Tree trunk
    final trunkPaint = Paint()..color = AppColors.secondaryDark;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(pos.x, pos.y - 10),
        width: 8,
        height: 20,
      ),
      trunkPaint,
    );

    // Tree crown (triangle)
    final crownPath = Path()
      ..moveTo(pos.x, pos.y - 50)
      ..lineTo(pos.x + 20, pos.y - 10)
      ..lineTo(pos.x - 20, pos.y - 10)
      ..close();
    canvas.drawPath(crownPath, paint);
  }

  void _drawBush(Canvas canvas, Vector2 pos, Paint paint) {
    canvas.drawCircle(
      Offset(pos.x, pos.y - 8),
      12,
      paint,
    );
  }

  void _drawRock(Canvas canvas, Vector2 pos, Paint paint) {
    final rockPath = Path()
      ..moveTo(pos.x - 10, pos.y)
      ..lineTo(pos.x - 8, pos.y - 12)
      ..lineTo(pos.x + 5, pos.y - 15)
      ..lineTo(pos.x + 12, pos.y - 8)
      ..lineTo(pos.x + 10, pos.y)
      ..close();
    canvas.drawPath(rockPath, paint);
  }

  /// Convert tile coordinates to screen position
  Vector2 tileToScreen(int tileX, int tileY) {
    return Vector2(
      (tileX - tileY) * GameSizes.tileWidth / 2,
      (tileX + tileY) * GameSizes.tileHeight / 2,
    );
  }

  /// Convert screen position to tile coordinates
  Vector2 screenToTile(Vector2 screenPos) {
    final x = (screenPos.x / (GameSizes.tileWidth / 2) +
            screenPos.y / (GameSizes.tileHeight / 2)) /
        2;
    final y = (screenPos.y / (GameSizes.tileHeight / 2) -
            screenPos.x / (GameSizes.tileWidth / 2)) /
        2;
    return Vector2(x, y);
  }

  /// Get world position for a door at given index
  Vector2 getDoorWorldPosition(int doorIndex) {
    if (doorIndex < 0 || doorIndex >= doorPositions.length) {
      return Vector2.zero();
    }
    final tilePos = doorPositions[doorIndex];
    return tileToScreen(tilePos.x.toInt(), tilePos.y.toInt());
  }

  /// Get spawn position (center of map)
  Vector2 getSpawnPosition() {
    return tileToScreen(mapWidth ~/ 2, mapHeight ~/ 2);
  }

  /// Check if a world position is walkable
  bool isWalkable(Vector2 worldPos) {
    final tilePos = screenToTile(worldPos);
    final x = tilePos.x.toInt();
    final y = tilePos.y.toInt();

    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) {
      return false;
    }

    final tile = _tiles[y][x];
    return tile != TileType.tree && tile != TileType.rock;
  }

  /// Get map bounds in world coordinates
  Rect getMapBounds() {
    final topLeft = tileToScreen(0, 0);
    final topRight = tileToScreen(mapWidth - 1, 0);
    final bottomLeft = tileToScreen(0, mapHeight - 1);
    final bottomRight = tileToScreen(mapWidth - 1, mapHeight - 1);

    return Rect.fromLTRB(
      bottomLeft.x,
      topLeft.y,
      topRight.x,
      bottomRight.y + GameSizes.tileHeight,
    );
  }
}
