# Tile Assets

This folder contains isometric tile assets for the field exploration.

## Structure

```
tiles/
├── forest_ground.png    # Base forest floor tiles
├── forest_trees.png     # Decorative tree sprites
└── forest_door.png      # Door sprite (10 used per stage)
```

## Recommended Sources

- **Kenney.nl** - Free isometric tiles (kenney.nl/assets/isometric-tiles)
- **itch.io** - Search "isometric forest tiles"

## Tile Requirements

### Isometric Dimensions
- Tile size: 64x32 pixels (see GameSizes.tileWidth/Height)
- Door size: 64x96 pixels (see GameSizes.doorWidth/Height)

### Door States
The door sprite should support these visual states:
- `available` - Normal, slight glow
- `completed` - Green glow, checkmark overlay
- `locked` - Grayed out (optional, all doors may be available)
