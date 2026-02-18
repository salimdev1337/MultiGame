import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/design_system/ds_colors.dart';

class LudoGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'ludo';

  @override
  String get displayName => 'Ludo';

  @override
  String get description =>
      'Race tokens home — roll, capture, and use powerups!';

  @override
  IconData get icon => Icons.casino_rounded;

  @override
  String get route => '/play/ludo';

  @override
  Color get color => DSColors.ludoPrimary;

  @override
  String get category => 'strategy';

  @override
  Widget createScreen() => throw UnimplementedError('Use go_router');
}
