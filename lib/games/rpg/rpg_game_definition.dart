import 'package:flutter/material.dart';
import 'package:multigame/core/game_interface.dart';
import 'package:multigame/design_system/ds_colors.dart';

class RpgGameDefinition extends BaseGameDefinition {
  @override
  String get id => 'rpg';

  @override
  String get displayName => 'Shadowfall Chronicles';

  @override
  String get description =>
      'Fight pixel-art bosses, grow stronger, conquer New Game+';

  @override
  IconData get icon => Icons.auto_fix_high_rounded;

  @override
  String get route => '/play/rpg/boss_select';

  @override
  Color get color => DSColors.rpgPrimary;

  @override
  String get category => 'action';

  @override
  Widget createScreen() => throw UnimplementedError('Use go_router');
}
