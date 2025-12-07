# UI Assets

This folder contains UI assets for game controls.

## Structure

```
ui/
├── joystick_bg.png     # Joystick background circle
├── joystick_knob.png   # Joystick movable knob
└── buttons/
    ├── jump.png        # Jump button
    ├── attack.png      # Attack button
    └── shield.png      # Shield button
```

## Dimensions

- Joystick background: 120x120 pixels (GameSizes.joystickSize)
- Joystick knob: 50x50 pixels (GameSizes.joystickKnobSize)
- Large button: 80x80 pixels (GameSizes.actionButtonLarge)
- Medium button: 60x60 pixels (GameSizes.actionButtonMedium)

## Notes

Initial implementation uses programmatic rendering (Paint/Canvas).
These image assets are optional enhancements for polished visuals.
