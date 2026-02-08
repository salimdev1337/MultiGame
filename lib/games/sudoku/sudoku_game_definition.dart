// Sudoku game registration - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import '../../core/game_interface.dart';
import 'screens/modern_mode_difficulty_screen.dart';

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
  Color get color => const Color(0xFF00d4ff);

  @override
  String get category => 'puzzle';

  @override
  int get minScore => 0;

  @override
  int get maxScore => 10000;

  @override
  Widget createScreen() => const ModernModeDifficultyScreen();
}
