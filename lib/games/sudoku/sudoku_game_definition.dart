import 'package:flutter/material.dart';
import '../../core/game_interface.dart';
import 'screens/modern_mode_difficulty_screen.dart';

/// Game definition for Sudoku.
///
/// Registers Sudoku with the GameRegistry for display in the
/// main game carousel and handles navigation to the game.
///
/// Entry point: Modern carousel-based mode and difficulty selection screen
class SudokuGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'sudoku';

  @override
  String get displayName => 'Sudoku';

  @override
  String get description => 'Classic number puzzle game';

  @override
  IconData get icon => Icons.grid_on;

  @override
  String get route => '/sudoku';

  @override
  Color get color => const Color(0xFF00d4ff); // Cyan theme

  @override
  String get category => 'puzzle';

  @override
  int get minScore => 0;

  @override
  int get maxScore => 10000;

  @override
  Widget createScreen() => const ModernModeDifficultyScreen();
}
