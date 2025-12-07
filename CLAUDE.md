# Project Guidelines for Claude

## Before Committing

**Always run tests and analyze before committing:**

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Both must pass before creating a commit.

## Project Structure

- `lib/` - Main application code
  - `games/` - Flame game components (field, battle, effects)
  - `models/` - Data models
  - `providers/` - Riverpod state management
  - `screens/` - Flutter UI screens
  - `widgets/` - Reusable widgets
  - `utils/` - Constants and utilities
- `test/` - Unit and widget tests
- `assets/` - Sprites, data files, fonts

## Testing

- Tests use `flutter_test` and Flame's test utilities
- Components with `HasGameReference` need proper game context in tests
- Run tests with: `flutter test`

## Code Style

- Follow Flutter/Dart conventions
- Use `withValues(alpha: x)` instead of deprecated `withOpacity(x)`
- Prefer `HasGameReference` over deprecated `HasGameRef`
