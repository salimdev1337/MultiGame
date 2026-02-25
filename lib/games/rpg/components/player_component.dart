import 'dart:ui';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/components/attack_component.dart';
import 'package:multigame/games/rpg/components/player_sprite_renderer.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/models/stamina_system.dart';
import 'package:multigame/games/rpg/models/ultimate_gauge.dart';

class PlayerComponent extends PositionComponent {
  PlayerComponent({required Vector2 position, required this.stats})
      : super(position: position, size: Vector2(48, 48));

  PlayerStats stats;
  int currentHp = 0;

  /// Facing direction (normalized). Updated by movement input.
  Vector2 facingDir = Vector2(1, 0);

  late final StaminaSystem stamina;
  late final UltimateGauge ultimate;

  // Combo
  int _comboStep = 0;
  double _comboTimer = 0;
  double _attackCooldown = 0;
  static const double _baseComboWindow = 0.6;

  // Dodge
  bool _isDodging = false;
  double _dodgeTimer = 0;
  Vector2 _dodgeDir = Vector2.zero();
  static const double _dodgeDuration = 0.28;
  static const double _dodgeSpeed = 520;

  // Invincibility
  bool invincible = false;
  double _invincibleTimer = 0;

  // Ultimate
  bool _isUltimateActive = false;
  double _ultimateTimer = 0;
  static const double _ultimateDuration = 0.8;

  // Visual
  PlayerAnimState _animState = PlayerAnimState.idle;
  double _animTime = 0;
  final _renderer = PlayerSpriteRenderer();

  /// Collision radius for hit detection.
  double get hitRadius => 20.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _renderer.load();
    currentHp = stats.hp;
    stamina = StaminaSystem(
      maxPips: stats.maxStaminaPips,
      regenInterval: stats.staminaRegenInterval,
    );
    ultimate = UltimateGauge(
      hitChargeRate: 0.05 + stats.ultimateHitChargeBonus,
      damageChargeRate: 0.10 + stats.ultimateDmgChargeBonus,
      startCharge: stats.ultimateStartCharge,
    );
  }

  /// Called each frame by RpgFlameGame with joystick input.
  void applyMovement(
    double dx,
    double dy,
    double dt,
    Vector2 arenaMin,
    Vector2 arenaMax,
  ) {
    if (_isDodging) {
      position += _dodgeDir * _dodgeSpeed * dt;
      _setWalkAnim(true);
    } else if (dx != 0 || dy != 0) {
      final input = Vector2(dx, dy);
      if (input.length > 0) {
        input.normalize();
        facingDir = input.clone();
        position += input * stats.speed.toDouble() * dt;
        _setWalkAnim(true);
      }
    } else {
      _setWalkAnim(false);
    }

    position.x = position.x.clamp(arenaMin.x, arenaMax.x - size.x);
    position.y = position.y.clamp(arenaMin.y, arenaMax.y - size.y);
  }

  /// Spawns the next attack in the 3-hit combo.
  /// Returns the AttackComponent to add, or null if combo is blocked.
  AttackComponent? triggerAttack() {
    if (_isDodging || _attackCooldown > 0 || _isUltimateActive) {
      return null;
    }

    _comboTimer = _baseComboWindow + stats.comboWindowBonus;
    _attackCooldown = 0.18;

    final step = _comboStep;
    _comboStep = (_comboStep + 1) % 3;

    _animState = PlayerAnimState.attack;
    _animTime = 0;

    final isHeavy = step == 2;
    final baseDmg = stats.attack + (isHeavy ? 5 : 0);
    final finalDmg = isHeavy
        ? (baseDmg * (1.8 + stats.heavyFinisherBonus)).round()
        : baseDmg;

    final type = isHeavy
        ? AttackType.heavySlash
        : (step == 0 ? AttackType.meleeSlash1 : AttackType.meleeSlash2);

    final offset = facingDir * (size.x * 0.65);
    return AttackComponent(
      position: Vector2(
        position.x + size.x / 2 + offset.x - (isHeavy ? 32 : 24),
        position.y + size.y / 2 + offset.y - (isHeavy ? 24 : 16),
      ),
      direction: facingDir.clone(),
      damage: finalDmg,
      owner: 'player',
      attackType: type,
      lifetime: isHeavy ? 0.22 : 0.18,
    );
  }

  /// Triggers a dodge if stamina is available.
  /// Returns true if dodge was triggered.
  bool triggerDodge() {
    if (!stamina.hasPips || _isDodging || _isUltimateActive) {
      return false;
    }
    stamina.consumePip();
    _isDodging = true;
    _dodgeTimer = _dodgeDuration;
    _dodgeDir = facingDir.clone();
    invincible = true;
    _invincibleTimer = _dodgeDuration;
    _animState = PlayerAnimState.dodge;
    _animTime = 0;
    return true;
  }

  /// Triggers the ultimate AOE blast if gauge is full.
  /// Returns the AttackComponent (covers the full arena), or null.
  AttackComponent? triggerUltimate() {
    if (!ultimate.isReady || _isUltimateActive) {
      return null;
    }
    ultimate.fire();
    _isUltimateActive = true;
    _ultimateTimer = _ultimateDuration;
    invincible = true;
    _invincibleTimer = _ultimateDuration;
    _animState = PlayerAnimState.ultimate;
    _animTime = 0;

    return AttackComponent(
      position: Vector2(
        position.x + size.x / 2 - 240,
        position.y + size.y / 2 - 240,
      ),
      direction: Vector2(1, 0),
      damage: (stats.attack * 3.5).round(),
      owner: 'player',
      attackType: AttackType.ultimateAoe,
      lifetime: 0.4,
    );
  }

  void takeDamage(int damage) {
    if (invincible) {
      return;
    }
    currentHp = (currentHp - damage).clamp(0, stats.maxHp);
    ultimate.onHitTaken();
    invincible = true;
    _invincibleTimer = 0.8;
    _animState = PlayerAnimState.hurt;
    _animTime = 0;
  }

  void takePoisonDamage(int damage) {
    if (invincible) {
      return;
    }
    final reduced = stats.hazardResistance > 0
        ? (damage * (1.0 - stats.hazardResistance)).round()
        : damage;
    currentHp = (currentHp - reduced).clamp(0, stats.maxHp);
    invincible = true;
    _invincibleTimer = 0.4;
  }

  bool get isDead => currentHp <= 0;
  bool get isUltimateActive => _isUltimateActive;

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    stamina.update(dt);

    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _comboStep = 0;
      }
    }

    if (_attackCooldown > 0) {
      _attackCooldown = (_attackCooldown - dt).clamp(0, double.infinity);
    }

    if (_isDodging) {
      _dodgeTimer -= dt;
      if (_dodgeTimer <= 0) {
        _isDodging = false;
        _dodgeTimer = 0;
        if (_animState == PlayerAnimState.dodge) {
          _animState = PlayerAnimState.idle;
        }
      }
    }

    if (_isUltimateActive) {
      _ultimateTimer -= dt;
      if (_ultimateTimer <= 0) {
        _isUltimateActive = false;
        _ultimateTimer = 0;
        if (_animState == PlayerAnimState.ultimate) {
          _animState = PlayerAnimState.idle;
        }
      }
    }

    if (invincible) {
      _invincibleTimer -= dt;
      if (_invincibleTimer <= 0) {
        invincible = false;
      }
    }

    if (_animState == PlayerAnimState.attack && _animTime > 0.22) {
      _animState = PlayerAnimState.idle;
    }
    if (_animState == PlayerAnimState.hurt && _animTime > 0.30) {
      _animState = PlayerAnimState.idle;
    }
  }

  @override
  void render(Canvas canvas) {
    // Flicker during non-dodge invincibility
    if (invincible &&
        !_isDodging &&
        !_isUltimateActive &&
        (_animTime * 10).floor() % 2 == 0) {
      return;
    }

    // Dodge trail
    if (_isDodging) {
      final trail = Paint()..color = const Color(0x44FFD700);
      canvas.drawRect(
        Rect.fromLTWH(-5, -5, size.x + 10, size.y + 10),
        trail,
      );
    }

    // Ultimate glow (flame orange)
    if (_isUltimateActive) {
      final glow = Paint()..color = const Color(0x88FF6600);
      canvas.drawOval(
        Rect.fromLTWH(-10, -10, size.x + 20, size.y + 20),
        glow,
      );
    }

    // Flip sprite horizontally when facing left
    if (facingDir.x < 0) {
      canvas.save();
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    _renderer.draw(
      canvas,
      _animState,
      _animState == PlayerAnimState.hurt,
      _animTime,
      size,
    );
    if (facingDir.x < 0) {
      canvas.restore();
    }
  }

  void _setWalkAnim(bool moving) {
    if (!_isDodging &&
        _animState != PlayerAnimState.attack &&
        _animState != PlayerAnimState.hurt &&
        _animState != PlayerAnimState.ultimate) {
      _animState = moving ? PlayerAnimState.walk : PlayerAnimState.idle;
    }
  }

  /// Center position (for collision checks).
  @override
  Vector2 get center => Vector2(position.x + size.x / 2, position.y + size.y / 2);
}
