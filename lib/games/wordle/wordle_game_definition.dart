import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/games/wordle/screens/wordle_game_screen.dart';

class WordleGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'wordle';

  @override
  String get displayName => 'Wordle Duel';

  @override
  String get description =>
      'Solo or 2-player head-to-head word guessing duel';

  @override
  IconData get icon => Icons.abc_rounded;

  @override
  String get route => '/wordle';

  @override
  Color get color => DSColors.wordlePrimary;

  @override
  String get category => 'puzzle';

  @override
  Widget createScreen() => const WordleGamePage();
}
