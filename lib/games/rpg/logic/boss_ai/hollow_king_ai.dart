import 'dart:math';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// The Hollow King AI: dash patterns that players must step out of.
/// Phase 0 (>66%): horizontal/vertical dashes.
/// Phase 1 (66-33%): diagonal dashes added + blade trail after each dash.
/// Phase 2 (<=33%): very fast dashes + litters arena with blade trails.
class HollowKingAI implements BossAI {
  BossAiState _state = BossAiState.idle;
  int _phase = 0;
  double _stateTimer = 0;
  double _cooldownTimer = 0;
  Vector2 _dashDir = Vector2.zero();

  static const double _dashSpeed = 700;
  static const double _dashDuration = 0.30;

  bool get isDashing => _state == BossAiState.dashing;
  Vector2 get dashVelocity => isDashing ? _dashDir * _dashSpeed : Vector2.zero();

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
      _stateTimer = 0.6;
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
        if (_cooldownTimer <= 0) {
          _pickDashDirection(playerPos - bossPos);
          _state = BossAiState.dashWindup;
          _stateTimer = params.windupDuration;
        }
        final toPlayer = playerPos - bossPos;
        if (toPlayer.length > 90) {
          return BossTick(velocity: toPlayer.normalized() * params.moveSpeed);
        }
        return BossTick(velocity: Vector2.zero());

      case BossAiState.dashWindup:
        // Stand still and flash (telegraphs dash direction)
        if (_stateTimer <= 0) {
          _state = BossAiState.dashing;
          _stateTimer = _dashDuration;
          final cmd = BossAttackCommand(
            type: AttackType.dashSlash,
            spawnPosition: bossPos.clone(),
            direction: _dashDir.clone(),
            damage: params.attackDamage,
          );
          return BossTick(velocity: Vector2.zero(), attack: cmd);
        }
        return BossTick(velocity: Vector2.zero());

      case BossAiState.dashing:
        if (_stateTimer <= 0) {
          _dashDir = Vector2.zero();
          _cooldownTimer = params.attackCooldown;
          _state = BossAiState.cooldown;

          if (_phase >= 1) {
            // Leave a blade trail at dash end position
            final trailCmd = BossAttackCommand(
              type: AttackType.bladeTrail,
              spawnPosition: bossPos.clone(),
              direction: Vector2(1, 0),
              damage: params.attackDamage ~/ 2,
            );
            return BossTick(velocity: Vector2.zero(), attack: trailCmd);
          }
        }
        return BossTick(velocity: _dashDir * _dashSpeed);

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

  void _pickDashDirection(Vector2 toPlayer) {
    if (_phase >= 1) {
      // Diagonal dashes added in phase 1+
      final angle = atan2(toPlayer.y, toPlayer.x);
      final snapped = (angle / (pi / 4)).round() * (pi / 4);
      _dashDir = Vector2(cos(snapped), sin(snapped));
    } else {
      // Cardinal only: horizontal or vertical
      if (toPlayer.x.abs() > toPlayer.y.abs()) {
        _dashDir = Vector2(toPlayer.x.sign, 0);
      } else {
        _dashDir = Vector2(0, toPlayer.y.sign);
      }
    }
  }
}
