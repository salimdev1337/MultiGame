import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/games/bomberman/screens/bomberman_game_screen.dart';

class BombermanDefinition extends BaseGameDefinition {
  @override
  String get id => 'bomberman';

  @override
  String get displayName => 'Bomberman';

  @override
  String get description => 'Drop bombs, destroy blocks, blast your opponents';

  @override
  IconData get icon => Icons.sports_esports_rounded;

  @override
  String get route => '/play/bomberman';

  @override
  Color get color => const Color(0xFF00d4ff);

  @override
  String get category => 'arcade';

  @override
  Widget createScreen() => const BombermanGamePage();
}
