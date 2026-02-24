import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/design_system/ds_colors.dart';

class RummyGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'rummy';

  @override
  String get displayName => 'Rummy';

  @override
  String get description =>
      'Classic card game — meld sets & runs, declare before your opponents!';

  @override
  IconData get icon => Icons.style_rounded;

  @override
  String get route => '/play/rummy';

  @override
  Color get color => DSColors.rummyPrimary;

  @override
  String get category => 'card';

  @override
  Widget createScreen() => throw UnimplementedError('Use go_router');
}
