import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart'; // GameDefinition + BaseGameDefinition
import 'package:multigame/design_system/ds_colors.dart';

class ConnectFourGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'connect_four';

  @override
  String get displayName => 'Connect Four';

  @override
  String get description =>
      'Drop pieces and connect 4 in a row — solo vs AI or pass-and-play';

  @override
  IconData get icon => Icons.grid_on;

  @override
  String get route => '/play/connect_four';

  @override
  Color get color => DSColors.connectFourPrimary;

  @override
  String get category => 'strategy';

  @override
  Widget createScreen() => throw UnimplementedError('Use go_router');
}
