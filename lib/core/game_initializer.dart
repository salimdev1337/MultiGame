import 'game_registry.dart';
import 'package:multigame/games/puzzle/puzzle_game_definition.dart';
import 'package:multigame/games/game_2048/game_2048_definition.dart';
import 'package:multigame/games/snake/snake_game_definition.dart';
import 'package:multigame/games/sudoku/sudoku_game_definition.dart';
import 'package:multigame/games/infinite_runner/infinite_runner_definition.dart';
import 'package:multigame/games/memory/memory_game_definition.dart';
import 'package:multigame/games/bomberman/bomberman_definition.dart';
import 'package:multigame/games/wordle/wordle_game_definition.dart';
import 'package:multigame/games/connect_four/connect_four_game_definition.dart';

/// Initialize and register all games
/// Should be called once during app startup
void initializeGames() {
  final registry = gameRegistry;

  // Register all games
  registry.register(PuzzleGameDefinition());
  registry.register(Game2048Definition());
  registry.register(SnakeGameDefinition());
  registry.register(SudokuGameDefinition());
  registry.register(InfiniteRunnerDefinition());
  registry.register(MemoryGameDefinition());
  registry.register(BombermanDefinition());
  registry.register(WordleGameDefinition());
  registry.register(ConnectFourGameDefinition());
}
