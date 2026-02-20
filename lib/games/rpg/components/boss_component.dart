import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:multigame/games/rpg/components/attack_component.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/models/attack_command.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/sprites/golem_sprites.dart';
import 'package:multigame/games/rpg/sprites/wraith_sprites.dart';

class BossComponent extends PositionComponent with CollisionCallbacks {
  BossComponent({
    required Vector2 position,
    required this.config,
    required this.ai,
    required this.scaledHp,
  }) : super(
          position: position,
          size: config.id == BossId.golem ? Vector2(96, 112) : Vector2(80, 112),
        ) {
    currentHp = scaledHp;
    maxHp = scaledHp;
  }

  final BossConfig config;
  final BossAI ai;
  final int scaledHp;

  int currentHp = 0;
  int maxHp = 0;
  int _currentPhase = 0;
  bool _isDead = false;
  bool facingLeft = true;

  double _animTime = 0;
  BossAnimState _animState = BossAnimState.idle;

  // Wraith vertical float
  double _floatTime = 0;
  double _baseY = 0;

  ui.Image? _idleImg;
  ui.Image? _attackImg;

  void Function(int phase)? onPhaseChange;
  void Function()? onDeath;

  static const int _pixelScale = 6;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _baseY = position.y;
    add(RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.9),
      position: Vector2(size.x * 0.1, size.y * 0.05),
    ));
    if (config.id == BossId.golem) {
      _idleImg = await GolemSprites.idle0.toImage(_pixelScale);
      _attackImg = await GolemSprites.idle1.toImage(_pixelScale);
    } else {
      _idleImg = await WraithSprites.float0.toImage(_pixelScale);
      _attackImg = await WraithSprites.float1.toImage(_pixelScale);
    }
  }

  AttackCommand? update2(double dt, Vector2 playerPos) {
    _animTime += dt;

    if (_isDead) {
      return null;
    }

    // Phase check
    final hpRatio = maxHp > 0 ? currentHp / maxHp : 0.0;
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
      ai.onPhaseChange(_currentPhase);
      onPhaseChange?.call(_currentPhase);
    }

    final speed = config.phases[_currentPhase].moveSpeed;
    final centerX = position.x + size.x / 2;
    final playerCenterX = playerPos.x + 24;
    final dx = playerCenterX - centerX;
    facingLeft = dx > 0;

    // Continuous pursuit — maintain a fighting distance
    final dist = dx.abs();
    const closeDist = 80.0;
    const chaseDist = 220.0;
    if (dist > chaseDist) {
      // Chase aggressively
      position.x += (dx > 0 ? 1.0 : -1.0) * speed * dt;
    } else if (dist > closeDist) {
      // Close in at moderate pace
      position.x += (dx > 0 ? 1.0 : -1.0) * speed * 0.6 * dt;
    } else if (dist < 40) {
      // Too close — back off slightly
      position.x -= (dx > 0 ? 1.0 : -1.0) * speed * 0.3 * dt;
    }

    // Wraith vertical float — sinusoidal hover
    if (config.id == BossId.wraith) {
      _floatTime += dt;
      position.y = _baseY + math.sin(_floatTime * 1.4) * 22;
    }

    // Clamp position to game bounds
    position.x = position.x.clamp(0, 2000 - size.x);

    return ai.decide(dt, position, playerPos);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_animState == BossAnimState.attack && _animTime > 0.3) {
      _animState = BossAnimState.idle;
      _animTime = 0;
    }
  }

  void takeDamage(int damage) {
    if (_isDead) {
      return;
    }
    currentHp -= damage;
    if (currentHp <= 0) {
      currentHp = 0;
      _isDead = true;
      _animState = BossAnimState.die;
      _animTime = 0;
      onDeath?.call();
    } else {
      _animState = BossAnimState.hurt;
      _animTime = 0;
    }
  }

  bool get isDead => _isDead;
  int get currentPhase => _currentPhase;

  AttackComponent? spawnAttack(AttackCommand cmd, int cycle) {
    _animState = BossAnimState.attack;
    _animTime = 0;
    final baseDmg = config.phases[_currentPhase].attackDamage;
    final scaledDmg = (baseDmg * math.pow(config.dmgScaleFactor, cycle)).round();
    final spawnPos = position + Vector2(size.x / 2, size.y / 3);
    return AttackComponent(
      position: spawnPos,
      direction: cmd.direction,
      damage: scaledDmg,
      owner: 'boss',
      attackType: cmd.type,
      speed: _speedForType(cmd.type),
      lifetime: _lifetimeForType(cmd.type),
    );
  }

  double _speedForType(AttackType type) {
    switch (type) {
      case AttackType.rockProjectile:
        return 220;
      case AttackType.shadowBolt:
        return 300;
      case AttackType.dashAttack:
        return 480;
      default:
        return 0;
    }
  }

  double _lifetimeForType(AttackType type) {
    switch (type) {
      case AttackType.groundStomp:
      case AttackType.aoe:
        return 0.5;
      case AttackType.dashAttack:
        return 0.3;
      default:
        return 2.0;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final img = _animState == BossAnimState.attack ? _attackImg : _idleImg;
    if (img != null) {
      final src = ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = ui.Rect.fromLTWH(0, 0, size.x, size.y);
      if (!facingLeft) {
        canvas.save();
        canvas.translate(size.x, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(img, src, dst, ui.Paint());
      if (!facingLeft) {
        canvas.restore();
      }
    } else {
      final color = config.id == BossId.golem
          ? const ui.Color(0xFF808080)
          : const ui.Color(0xFF4A0080);
      canvas.drawRect(size.toRect(), ui.Paint()..color = color);
    }
  }
}
