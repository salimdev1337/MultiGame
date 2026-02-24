import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// Returned by BossAI.tick() each frame.
class BossTick {
  const BossTick({required this.velocity, this.attack});

  /// Movement velocity to apply to boss this frame (world units/s).
  final Vector2 velocity;

  /// Non-null when the AI wants to spawn an attack this frame.
  final BossAttackCommand? attack;
}

/// The data the AI passes to the BossComponent to spawn an attack.
class BossAttackCommand {
  const BossAttackCommand({
    required this.type,
    required this.spawnPosition,
    required this.direction,
    required this.damage,
  });

  final AttackType type;
  final Vector2 spawnPosition;
  final Vector2 direction;
  final int damage;
}

abstract class BossAI {
  /// Called every game frame. Returns movement + optional attack this frame.
  BossTick tick(
    double dt,
    Vector2 bossPos,
    Vector2 playerPos,
    int phase,
    BossPhaseParams params,
  );

  void onPhaseChange(int newPhase);
  void reset();
}

/// Per-phase parameters passed to AI from BossComponent.
class BossPhaseParams {
  const BossPhaseParams({
    required this.moveSpeed,
    required this.attackDamage,
    required this.attackCooldown,
    required this.windupDuration,
  });

  final double moveSpeed;
  final int attackDamage;
  final double attackCooldown;
  final double windupDuration;
}
