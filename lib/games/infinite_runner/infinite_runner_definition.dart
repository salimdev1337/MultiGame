import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/games/infinite_runner/screens/infinite_runner_screen.dart';

class InfiniteRunnerDefinition extends BaseGameDefinition {
  @override
  String get id => 'infinite_runner';

  @override
  String get displayName => 'Infinite Runner';

  @override
  String get description => 'Jump and slide to avoid obstacles';

  @override
  IconData get icon => Icons.directions_run;

  @override
  String get route => '/infinite-runner';

  @override
  Color get color => const Color(0xFFffc107);

  @override
  String get category => 'arcade';

  @override
  Widget createScreen() => const InfiniteRunnerPage();
}
