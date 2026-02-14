import 'package:flutter/foundation.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

@immutable
class PowerupCell {
  final int x;
  final int y;
  final PowerupType type;

  const PowerupCell({
    required this.x,
    required this.y,
    required this.type,
  });
}
