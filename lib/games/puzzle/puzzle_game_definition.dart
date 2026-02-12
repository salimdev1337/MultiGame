import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/games/puzzle/screens/puzzle_screen.dart';

class PuzzleGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'puzzle';

  @override
  String get displayName => 'Image Puzzle';

  @override
  String get description => 'Slide tiles to solve the puzzle';

  @override
  IconData get icon => Icons.extension;

  @override
  String get route => '/puzzle';

  @override
  Color get color => const Color(0xFF00d4ff);

  @override
  String get category => 'puzzle';

  @override
  Widget createScreen() => const PuzzlePage();
}
