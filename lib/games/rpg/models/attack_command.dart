import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class AttackCommand {
  const AttackCommand({
    required this.type,
    required this.direction,
    this.targetPosition,
  });

  final AttackType type;
  final Vector2 direction;
  final Vector2? targetPosition;
}
