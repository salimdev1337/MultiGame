// Sudoku module barrel file - see docs/SUDOKU_ARCHITECTURE.md

export 'models/game_mode.dart';
export 'models/sudoku_cell.dart';
export 'models/sudoku_board.dart';
export 'models/sudoku_action.dart';
export 'models/saved_game.dart';
export 'models/completed_game.dart';
export 'models/sudoku_stats.dart';
export 'models/match_status.dart';
export 'models/match_player.dart';
export 'models/match_room.dart';

export 'constants/sudoku_colors.dart';

export 'logic/sudoku_validator.dart';
export 'logic/sudoku_solver.dart';
export 'logic/sudoku_generator.dart';

export 'services/sudoku_persistence_service.dart';
export 'services/sudoku_stats_service.dart';
export 'services/matchmaking_service.dart';
export 'services/sudoku_sound_service.dart';
export 'services/sudoku_haptic_service.dart';

export 'providers/sudoku_provider.dart';
export 'providers/sudoku_rush_provider.dart';
export 'providers/sudoku_ui_provider.dart';
export 'providers/sudoku_online_provider.dart';
export 'providers/sudoku_settings_provider.dart';

export 'screens/modern_mode_difficulty_screen.dart';
export 'screens/sudoku_classic_screen.dart';
export 'screens/sudoku_rush_screen.dart';
export 'screens/sudoku_online_matchmaking_screen.dart';
export 'screens/sudoku_online_game_screen.dart';
export 'screens/sudoku_online_result_screen.dart';
export 'screens/sudoku_settings_screen.dart';

export 'widgets/sudoku_grid.dart';
export 'widgets/sudoku_cell_widget.dart';
export 'widgets/number_pad.dart';
export 'widgets/control_buttons.dart';
export 'widgets/stats_panel.dart';

export 'sudoku_game_definition.dart';
