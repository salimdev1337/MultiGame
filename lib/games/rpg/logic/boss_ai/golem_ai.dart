import 'dart:math';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/models/attack_command.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class GolemAI implements BossAI {
  GolemAI();

  BossAiState _state = BossAiState.idle;
  int _phase = 0;
  double _stateTimer = 0;
  double _cooldownTimer = 0;
  static const double _cooldownBase = 1.5;
  static const double _cooldownEnraged = 0.8;
  final Random _rand = Random();

  BossAiState get currentState => _state;

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
      _stateTimer = 1.2;
    }
  }

  @override
  AttackCommand? decide(double dt, Vector2 bossPos, Vector2 playerPos) {
    _stateTimer = max(0, _stateTimer - dt);
    _cooldownTimer = max(0, _cooldownTimer - dt);

    switch (_state) {
      case BossAiState.idle:
        _state = BossAiState.move;
        return null;

      case BossAiState.move:
        if (_cooldownTimer <= 0) {
          _pickAttack();
        }
        return null;

      case BossAiState.stomp:
        if (_stateTimer <= 0) {
          _cooldownTimer =
              _phase >= 1 ? _cooldownEnraged : _cooldownBase;
          _state = BossAiState.cooldown;
          return AttackCommand(
            type: AttackType.groundStomp,
            direction: Vector2(0, 1),
            targetPosition: playerPos.clone(),
          );
        }
        return null;

      case BossAiState.rockThrow:
        if (_stateTimer <= 0) {
          _cooldownTimer =
              _phase >= 1 ? _cooldownEnraged : _cooldownBase;
          _state = BossAiState.cooldown;
          final dir = (playerPos - bossPos)..normalize();
          return AttackCommand(
            type: AttackType.rockProjectile,
            direction: dir,
            targetPosition: playerPos.clone(),
          );
        }
        return null;

      case BossAiState.spin:
        if (_stateTimer <= 0) {
          _cooldownTimer = _cooldownEnraged;
          _state = BossAiState.cooldown;
          return AttackCommand(
            type: AttackType.aoe,
            direction: Vector2(1, 0),
            targetPosition: bossPos.clone(),
          );
        }
        return null;

      case BossAiState.enrage:
        if (_stateTimer <= 0) {
          _state = BossAiState.move;
        }
        return null;

      case BossAiState.cooldown:
        if (_cooldownTimer <= 0) {
          _state = BossAiState.move;
        }
        return null;

      default:
        return null;
    }
  }

  void _pickAttack() {
    if (_phase >= 1) {
      final roll = _rand.nextInt(3);
      if (roll == 0) {
        _state = BossAiState.stomp;
        _stateTimer = 0.4;
      } else if (roll == 1) {
        _state = BossAiState.rockThrow;
        _stateTimer = 0.5;
      } else {
        _state = BossAiState.spin;
        _stateTimer = 0.6;
      }
    } else {
      if (_rand.nextBool()) {
        _state = BossAiState.stomp;
        _stateTimer = 0.5;
      } else {
        _state = BossAiState.rockThrow;
        _stateTimer = 0.6;
      }
    }
  }
}
