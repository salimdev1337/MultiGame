import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/attack_command.dart';

abstract class BossAI {
  AttackCommand? decide(double dt, Vector2 bossPos, Vector2 playerPos);
  void onPhaseChange(int newPhase);
  void reset();
}
