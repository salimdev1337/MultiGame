import 'dart:math';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// The Plague Shaman AI: orbits at range, casts poison projectiles and pools.
/// Phase 0: orbit + projectile every ~2s.
/// Phase 1 (<=50% HP): faster casts + places poison pools at player position.
class ShamanAI implements BossAI {
  BossAiState _state = BossAiState.orbit;
  int _phase = 0;
  double _stateTimer = 0;
  double _cooldownTimer = 0;
  double _orbitAngle = 0;
  final Random _rand = Random();

  static const double _orbitRadius = 200;
  static const double _orbitSpeed = 1.2; // radians/s

  @override
  void reset() {
    _state = BossAiState.orbit;
    _phase = 0;
    _stateTimer = 0;
    _cooldownTimer = 0;
  }

  @override
  void onPhaseChange(int newPhase) {
    _phase = newPhase;
  }

  @override
  BossTick tick(
    double dt,
    Vector2 bossPos,
    Vector2 playerPos,
    int phase,
    BossPhaseParams params,
  ) {
    _stateTimer = max(0, _stateTimer - dt);
    _cooldownTimer = max(0, _cooldownTimer - dt);

    switch (_state) {
      case BossAiState.orbit:
        // Orbit around player
        _orbitAngle += dt * (_phase >= 1 ? _orbitSpeed * 1.4 : _orbitSpeed);
        final targetX = playerPos.x + cos(_orbitAngle) * _orbitRadius;
        final targetY = playerPos.y + sin(_orbitAngle) * _orbitRadius;
        final target = Vector2(targetX, targetY);
        final toTarget = target - bossPos;

        if (_cooldownTimer <= 0) {
          _pickAttack(bossPos, playerPos, params);
        }

        if (toTarget.length > 12) {
          return BossTick(velocity: toTarget.normalized() * params.moveSpeed);
        }
        return BossTick(velocity: Vector2.zero());

      case BossAiState.windupAttack:
        if (_stateTimer <= 0) {
          _cooldownTimer = params.attackCooldown;
          _state = BossAiState.orbit;

          final usePool = _phase >= 1 && _rand.nextDouble() < 0.45;
          if (usePool) {
            final cmd = BossAttackCommand(
              type: AttackType.poisonPool,
              spawnPosition: playerPos.clone(),
              direction: Vector2(0, 1),
              damage: params.attackDamage ~/ 2,
            );
            return BossTick(velocity: Vector2.zero(), attack: cmd);
          } else {
            final dir = (playerPos - bossPos).normalized();
            final cmd = BossAttackCommand(
              type: AttackType.poisonProjectile,
              spawnPosition: bossPos.clone(),
              direction: dir,
              damage: params.attackDamage,
            );
            return BossTick(velocity: Vector2.zero(), attack: cmd);
          }
        }
        return BossTick(velocity: Vector2.zero());

      default:
        _state = BossAiState.orbit;
        return BossTick(velocity: Vector2.zero());
    }
  }

  void _pickAttack(
    Vector2 bossPos,
    Vector2 playerPos,
    BossPhaseParams params,
  ) {
    _state = BossAiState.windupAttack;
    _stateTimer = params.windupDuration;
  }
}
