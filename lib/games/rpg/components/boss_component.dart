import 'dart:ui';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/components/attack_component.dart';
import 'package:multigame/games/rpg/components/boss_sprite_renderer.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class BossComponent extends PositionComponent {
  BossComponent({
    required Vector2 position,
    required this.config,
    required this.ai,
  }) : super(
          position: position,
          size: Vector2(config.bossWidth, config.bossHeight),
        );

  final BossConfig config;
  final BossAI ai;

  late int _maxHp;
  late int _currentHp;
  int _currentPhase = 0;
  BossAnimState _animState = BossAnimState.idle;
  double _animTime = 0;

  // Hurt flash
  bool _isHurt = false;
  double _hurtTimer = 0;

  late BossSpriteRenderer _sprites;

  // Callbacks
  VoidCallback? onDeath;
  void Function(int newPhase)? onPhaseChange;

  int get currentHp => _currentHp;
  int get maxHp => _maxHp;
  int get currentPhase => _currentPhase;

  /// Collision radius.
  double get hitRadius => size.x * 0.42;

  /// Center position for collision checks.
  @override
  Vector2 get center => Vector2(position.x + size.x / 2, position.y + size.y / 2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _maxHp = config.baseHp;
    _currentHp = _maxHp;
    _sprites = BossSpriteRenderer(config.id);
    await _sprites.load();
  }

  void takeDamage(int damage) {
    if (_animState == BossAnimState.die) {
      return;
    }
    _currentHp = (_currentHp - damage).clamp(0, _maxHp);
    _isHurt = true;
    _hurtTimer = 0.12;

    _checkPhase();

    if (_currentHp <= 0) {
      _animState = BossAnimState.die;
      onDeath?.call();
    }
  }

  void _checkPhase() {
    final hpRatio = _currentHp / _maxHp;
    final phases = config.phases;
    int newPhase = 0;
    for (int i = phases.length - 1; i >= 0; i--) {
      if (hpRatio <= phases[i].hpThreshold && i > 0) {
        newPhase = i;
        break;
      }
    }
    if (newPhase != _currentPhase) {
      _currentPhase = newPhase;
      _animState = BossAnimState.phaseChange;
      _animTime = 0;
      ai.onPhaseChange(newPhase);
      onPhaseChange?.call(newPhase);
    }
  }

  BossPhaseConfig get _phaseConfig => config.phases[_currentPhase];

  /// Called every frame by RpgFlameGame. Returns an optional attack to spawn.
  AttackComponent? update2(double dt, Vector2 playerPos) {
    _animTime += dt;

    if (_isHurt) {
      _hurtTimer -= dt;
      if (_hurtTimer <= 0) {
        _isHurt = false;
      }
    }

    if (_animState == BossAnimState.die) {
      return null;
    }

    if (_animState == BossAnimState.phaseChange && _animTime < 0.5) {
      return null;
    } else if (_animState == BossAnimState.phaseChange) {
      _animState = BossAnimState.idle;
    }

    final params = BossPhaseParams(
      moveSpeed: _phaseConfig.moveSpeed,
      attackDamage: _phaseConfig.attackDamage,
      attackCooldown: _phaseConfig.attackCooldown,
      windupDuration: _phaseConfig.windupDuration,
    );

    final tick = ai.tick(dt, position, playerPos, _currentPhase, params);

    // Apply movement
    if (tick.velocity.length > 0) {
      position += tick.velocity * dt;
    }

    if (tick.attack == null) {
      return null;
    }

    _animState = BossAnimState.attack;
    _animTime = 0;

    final cmd = tick.attack!;
    return _buildAttack(cmd);
  }

  AttackComponent? _buildAttack(BossAttackCommand cmd) {
    switch (cmd.type) {
      case AttackType.chargeAttack:
        return AttackComponent(
          position: cmd.spawnPosition,
          direction: cmd.direction,
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.chargeAttack,
          speed: 0, // moves with boss during charging state
          lifetime: 0.45,
        );
      case AttackType.overheadSlam:
        return AttackComponent(
          position: Vector2(
            cmd.spawnPosition.x - 48,
            cmd.spawnPosition.y - 48,
          ),
          direction: Vector2(0, 1),
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.overheadSlam,
          lifetime: 0.35,
        );
      case AttackType.poisonPool:
        return AttackComponent(
          position: Vector2(
            cmd.spawnPosition.x - 40,
            cmd.spawnPosition.y - 40,
          ),
          direction: Vector2(0, 1),
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.poisonPool,
          lifetime: 4.0, // long-lived hazard
        );
      case AttackType.poisonProjectile:
        return AttackComponent(
          position: Vector2(
            cmd.spawnPosition.x - 9,
            cmd.spawnPosition.y - 9,
          ),
          direction: cmd.direction,
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.poisonProjectile,
          speed: 280,
          lifetime: 2.5,
        );
      case AttackType.dashSlash:
        return AttackComponent(
          position: Vector2(
            cmd.spawnPosition.x - 16,
            cmd.spawnPosition.y - 18,
          ),
          direction: cmd.direction,
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.dashSlash,
          speed: 0, // moves with boss dash
          lifetime: 0.30,
        );
      case AttackType.bladeTrail:
        return AttackComponent(
          position: Vector2(
            cmd.spawnPosition.x - 12,
            cmd.spawnPosition.y - 40,
          ),
          direction: Vector2(0, 1),
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.bladeTrail,
          lifetime: 2.5,
        );
      case AttackType.voidBlast:
        return AttackComponent(
          position: Vector2(
            cmd.spawnPosition.x - 10,
            cmd.spawnPosition.y - 10,
          ),
          direction: cmd.direction,
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.voidBlast,
          speed: 320,
          lifetime: 2.0,
        );
      case AttackType.shadowSurge:
        return AttackComponent(
          position: Vector2(cmd.spawnPosition.x - 300, cmd.spawnPosition.y - 24),
          direction: Vector2(0, 1),
          damage: cmd.damage,
          owner: 'boss',
          attackType: AttackType.shadowSurge,
          lifetime: 0.5,
        );
      default:
        return null;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_animState == BossAnimState.die) {
      final alpha = (_hurtTimer * 4).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFF666666).withValues(alpha: alpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
        paint,
      );
      return;
    }

    _sprites.draw(canvas, _animState, _isHurt, _animTime, size);

    if (_currentPhase > 0) {
      final phasePaint = Paint()..color = const Color(0xCCFF0000);
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        8 + _currentPhase * 4,
        phasePaint,
      );
    }
  }
}
