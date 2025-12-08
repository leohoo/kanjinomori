# Sprite Assets

This folder contains sprite assets for the 2.5D game.

## Structure

```
sprites/
├── player/       # Player character animations
│   ├── idle.png
│   ├── walk.png
│   ├── jump.png
│   └── attack.png
├── enemies/      # Boss and enemy sprites
│   └── boss_*.png
└── effects/      # Visual effects
    ├── wind.png      # Jump wind lines
    ├── dust.png      # Landing dust
    └── coins.png     # Coin animation
```

## Recommended Sources

- **Kenney.nl** - Free isometric character sprites
- **itch.io** - Character sprites, effects
- **OpenGameArt.org** - Various game assets

## Sprite Requirements

### Player
- Idle: 4-8 frames
- Walk: 6-8 frames (8 directions for field, 2 for battle)
- Jump: 3-4 frames (ascending, apex, descending)
- Attack: 4-6 frames

### Dimensions
- Player: 48x64 pixels (see GameSizes.playerWidth/Height)
- Effects: Variable, typically 32x32 or 64x64
