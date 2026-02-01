import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/screens/snake_game_page.dart';

class SnakeGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'snake';

  @override
  String get displayName => 'Snake';

  @override
  String get description => 'Classic snake game - eat and grow';

  @override
  IconData get icon => Icons.gamepad;

  @override
  String get route => '/snake';

  @override
  Color get color => const Color(0xFF4caf50);

  @override
  String get category => 'arcade';

  @override
  Widget createScreen() => const SnakeGamePage();
}
