import 'dart:math';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// The Warden AI: top-down charge + overhead slam patterns.
/// Phase 0 (>50% HP): pursue → charge OR slam (if close).
/// Phase 1 (<=50% HP): enrage -> faster attacks, charges at longer range.
class WardenAI implements BossAI {
  BossAiState _state = BossAiState.idle;
  int _phase = 0;
  double _stateTimer = 0;
  double _cooldownTimer = 0;
  Vector2 _chargeDir = Vector2.zero();

  static const double _chargeSpeed = 620;
  static const double _chargeDuration = 0.45;

  bool get isCharging =>
      _state == BossAiState.attacking && _chargeDir.length > 0;

  @override
  void reset() {
    _state = BossAiState.idle;
    _phase = 0;
    _stateTimer = 0;
    _cooldownTimer = 0;
  }

  @override
  void onPhaseChange(int newPhase) {
    _phase = newPhase;
    if (newPhase >= 1) {
      _state = BossAiState.enrage;
      _stateTimer = 0.7;
    }
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
      case BossAiState.idle:
        _state = BossAiState.pursue;
        return BossTick(velocity: Vector2.zero());

      case BossAiState.pursue:
        final dist = (playerPos - bossPos).length;
        if (_cooldownTimer <= 0) {
          final chargeThreshold = _phase >= 1 ? 130.0 : 140.0;
          if (dist < 110) {
            _chargeDir = Vector2.zero();
            _state = BossAiState.windupAttack;
            _stateTimer = params.windupDuration;
          } else if (dist > chargeThreshold) {
            _chargeDir = (playerPos - bossPos).normalized();
            _state = BossAiState.windupAttack;
            _stateTimer = params.windupDuration;
          }
        }
        final toPlayer = (playerPos - bossPos);
        if (toPlayer.length > 80) {
          return BossTick(velocity: toPlayer.normalized() * params.moveSpeed);
        }
        return BossTick(velocity: Vector2.zero());

      case BossAiState.windupAttack:
        if (_stateTimer <= 0) {
          if (_chargeDir.length > 0) {
            _state = BossAiState.attacking;
            _stateTimer = _chargeDuration;
            final cmd = BossAttackCommand(
              type: AttackType.chargeAttack,
              spawnPosition: bossPos.clone(),
              direction: _chargeDir.clone(),
              damage: params.attackDamage,
            );
            return BossTick(velocity: Vector2.zero(), attack: cmd);
          } else {
            _cooldownTimer = params.attackCooldown;
            _state = BossAiState.cooldown;
            final cmd = BossAttackCommand(
              type: AttackType.overheadSlam,
              spawnPosition: bossPos.clone(),
              direction: Vector2(0, 1),
              damage: params.attackDamage,
            );
            return BossTick(velocity: Vector2.zero(), attack: cmd);
          }
        }
        return BossTick(velocity: Vector2.zero());

      case BossAiState.attacking:
        if (_stateTimer <= 0) {
          _chargeDir = Vector2.zero();
          _cooldownTimer = params.attackCooldown;
          _state = BossAiState.cooldown;
        }
        return BossTick(velocity: _chargeDir * _chargeSpeed);

      case BossAiState.enrage:
        if (_stateTimer <= 0) {
          _state = BossAiState.pursue;
        }
        return BossTick(velocity: Vector2.zero());

      case BossAiState.cooldown:
        if (_cooldownTimer <= 0) {
          _state = BossAiState.pursue;
        }
        return BossTick(velocity: Vector2.zero());

      default:
        return BossTick(velocity: Vector2.zero());
    }
  }
}
