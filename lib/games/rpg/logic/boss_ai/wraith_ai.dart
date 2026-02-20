import 'dart:math';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/models/attack_command.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class WraithAI implements BossAI {
  WraithAI();

  BossAiState _state = BossAiState.float;
  int _phase = 0;
  double _stateTimer = 0;
  double _cooldownTimer = 0;
  final Random _rand = Random();

  BossAiState get currentState => _state;

  @override
  void reset() {
    _state = BossAiState.float;
    _phase = 0;
    _stateTimer = 0;
    _cooldownTimer = 0;
  }

  @override
  void onPhaseChange(int newPhase) {
    _phase = newPhase;
    _state = BossAiState.teleport;
    _stateTimer = 0.5;
  }

  @override
  AttackCommand? decide(double dt, Vector2 bossPos, Vector2 playerPos) {
    _stateTimer = max(0, _stateTimer - dt);
    _cooldownTimer = max(0, _cooldownTimer - dt);

    switch (_state) {
      case BossAiState.float:
        if (_cooldownTimer <= 0) {
          _pickAttack();
        }
        return null;

      case BossAiState.shadowBolt:
        if (_stateTimer <= 0) {
          _state = BossAiState.float;
          // Phase-scaled cooldown — phase 2 fires almost constantly
          _cooldownTimer = _phase >= 2
              ? 0.15
              : _phase == 1
              ? 0.35
              : 0.6;
          final dir = (playerPos - bossPos)..normalize();
          // Phase 1+: chance of burst (fire again quickly)
          if (_phase >= 1 && _rand.nextDouble() < 0.45) {
            _state = BossAiState.shadowBolt;
            _stateTimer = _phase >= 2 ? 0.12 : 0.2;
          }
          return AttackCommand(
            type: AttackType.shadowBolt,
            direction: dir,
            targetPosition: playerPos.clone(),
          );
        }
        return null;

      case BossAiState.dash:
        if (_stateTimer <= 0) {
          _state = BossAiState.float;
          _cooldownTimer = _phase >= 1 ? 0.5 : 0.8;
          final dir = (playerPos - bossPos)..normalize();
          return AttackCommand(
            type: AttackType.dashAttack,
            direction: dir,
            targetPosition: playerPos.clone(),
          );
        }
        return null;

      case BossAiState.desperation:
        if (_stateTimer <= 0) {
          _state = BossAiState.float;
          _cooldownTimer = 0.12;
          final dir = (playerPos - bossPos)..normalize();
          return AttackCommand(
            type: AttackType.shadowBolt,
            direction: dir,
            targetPosition: playerPos.clone(),
          );
        }
        return null;

      case BossAiState.teleport:
        if (_stateTimer <= 0) {
          _state = BossAiState.float;
        }
        return null;

      case BossAiState.cooldown:
        if (_cooldownTimer <= 0) {
          _state = BossAiState.float;
        }
        return null;

      default:
        return null;
    }
  }

  void _pickAttack() {
    if (_phase >= 2) {
      // Desperation: constant shadow bolts, occasional dash
      if (_rand.nextDouble() < 0.25) {
        _state = BossAiState.dash;
        _stateTimer = 0.15;
      } else {
        _state = BossAiState.desperation;
        _stateTimer = 0.12;
      }
    } else if (_phase == 1) {
      // Aggressive mix: 55% bolt, 30% dash, 15% burst
      final roll = _rand.nextDouble();
      if (roll < 0.55) {
        _state = BossAiState.shadowBolt;
        _stateTimer = 0.18;
      } else {
        _state = BossAiState.dash;
        _stateTimer = 0.22;
      }
    } else {
      // Phase 0: 50/50 but with proper wind-up
      if (_rand.nextBool()) {
        _state = BossAiState.shadowBolt;
        _stateTimer = 0.28;
      } else {
        _state = BossAiState.dash;
        _stateTimer = 0.32;
      }
    }
  }
}
