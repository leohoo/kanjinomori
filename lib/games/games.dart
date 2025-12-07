// Game module exports for Flame-based game components

// Shared components
export 'components/joystick_component.dart';

// Effects (Phase 4)
export 'effects/particle_effect.dart';
export 'effects/screen_transition.dart';

// Field exploration (Phase 2)
export 'field/field_game.dart';
export 'field/field_screen.dart';
export 'field/components/player_component.dart';
export 'field/components/door_component.dart';
export 'field/components/tile_map_component.dart';

// Battle system (Phase 3)
export 'battle/battle_game.dart';
export 'battle/battle_screen.dart';
export 'battle/components/battle_player.dart';
export 'battle/components/battle_enemy.dart';
export 'battle/components/battle_hud.dart';
export 'battle/systems/combat_system.dart';

// Integration (Phase 5)
export 'coordinator/game_coordinator.dart';
export 'coordinator/stage_coordinator_screen.dart';
