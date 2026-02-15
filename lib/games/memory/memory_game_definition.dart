import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/games/memory/screens/memory_game_screen.dart';

class MemoryGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'memory_game';

  @override
  String get displayName => 'Memory Game';

  @override
  String get description => 'Match all pairs — wrong guess shuffles the board!';

  @override
  IconData get icon => Icons.grid_view_rounded;

  @override
  String get route => '/memory_game';

  @override
  Color get color => DSColors.memoryPrimary;

  @override
  String get category => 'puzzle';

  @override
  Widget createScreen() => const MemoryGamePage();
}
