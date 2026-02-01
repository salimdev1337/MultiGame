import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/screens/game_2048_page.dart';

class Game2048Definition extends BaseGameDefinition {
  @override
  String get id => '2048';

  @override
  String get displayName => '2048';

  @override
  String get description => 'Combine tiles to reach 2048';

  @override
  IconData get icon => Icons.grid_4x4;

  @override
  String get route => '/2048';

  @override
  Color get color => const Color(0xFFff5c00);

  @override
  String get category => 'puzzle';

  @override
  Widget createScreen() => const Game2048Page();
}
