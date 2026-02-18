import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:multigame/games/rpg/components/attack_component.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/sprites/player_sprites.dart';

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  PlayerComponent({required Vector2 position, required this.stats})
    : super(position: position, size: Vector2(48, 72));

  PlayerStats stats;
  int currentHp = 0;

  PlayerAnimState _animState = PlayerAnimState.idle;
  double _animTime = 0;
  double _velocityY = 0;
  bool _grounded = false;
  bool facingRight = true;
  bool invincible = false;
  double _invincibleTimer = 0;

  // Dodge state
  double _dodgeTimer = 0;
  double _dodgeCooldown = 0;
  double _dodgeDx = 1;
  bool get isDodging => _dodgeTimer > 0;

  // Images cache — set after onLoad resolves them
  ui.Image? _idleImg;
  ui.Image? _walkImg;
  ui.Image? _attackImg;
  ui.Image? _dodgeImg;

  // Cached Paint objects
  static final _imagePaint = ui.Paint();
  static final _fallbackPaint = ui.Paint()..color = const ui.Color(0xFF5C8A8A);
  static final _dodgeTrailPaint = ui.Paint()
    ..color = const ui.Color(0x44FFD700);

  static const double _gravity = 900;
  static const double _jumpForce = 480;
  static const int _pixelScale = 4;

  late RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    currentHp = stats.hp;
    _hitbox = RectangleHitbox(
      size: Vector2(size.x * 0.85, size.y * 0.9),
      position: Vector2(size.x * 0.075, size.y * 0.05),
    );
    add(_hitbox);
    // Pre-render pixel art
    _idleImg = await PlayerSprites.idle0.toImage(_pixelScale);
    _walkImg = await PlayerSprites.walk0.toImage(_pixelScale);
    _attackImg = await PlayerSprites.attack0.toImage(_pixelScale);
    _dodgeImg = await PlayerSprites.dodge0.toImage(_pixelScale);
  }

  void applyMovement(
    double dx,
    double dy,
    double dt,
    List<ui.Rect> platformRects,
  ) {
    if (isDodging) {
      // Dodge overrides horizontal input — dash in dodge direction
      position.x += _dodgeDx * stats.speed * 2.8 * dt;
    } else {
      position.x += dx * stats.speed * dt;
    }
    // Clamp to game bounds
    position.x = position.x.clamp(0, 2000);

    // Jump
    if (dy < -0.5 && _grounded && !isDodging) {
      _velocityY = -_jumpForce;
      _grounded = false;
    }

    // Gravity
    _velocityY += _gravity * dt;
    position.y += _velocityY * dt;

    // Platform collision
    _grounded = false;
    final feet = ui.Rect.fromLTWH(
      position.x + 4,
      position.y + size.y - 4,
      size.x - 8,
      8,
    );
    for (final p in platformRects) {
      if (feet.overlaps(p) && _velocityY >= 0) {
        position.y = p.top - size.y;
        _velocityY = 0;
        _grounded = true;
        break;
      }
    }

    // Update animation state
    if (!isDodging) {
      if (dx.abs() > 0.1) {
        facingRight = dx > 0;
        if (_animState != PlayerAnimState.attack) {
          _animState = PlayerAnimState.walk;
        }
      } else {
        if (_animState != PlayerAnimState.attack) {
          _animState = PlayerAnimState.idle;
        }
      }
    }
  }

  AttackComponent? triggerAttack() {
    if (_animState == PlayerAnimState.attack || isDodging) {
      return null;
    }
    _animState = PlayerAnimState.attack;
    _animTime = 0;
    final dir = facingRight ? Vector2(1, 0) : Vector2(-1, 0);
    final spawnX = facingRight ? position.x + size.x : position.x - 40;
    return AttackComponent(
      position: Vector2(spawnX, position.y + size.y * 0.4),
      direction: dir,
      damage: stats.attack + 5,
      owner: 'player',
      attackType: AttackType.meleeSlash,
      speed: 0,
      lifetime: 0.2,
    );
  }

  AttackComponent? triggerFireball() {
    if (isDodging) {
      return null;
    }
    final dir = facingRight ? Vector2(1, 0) : Vector2(-1, 0);
    final spawnX = facingRight ? position.x + size.x : position.x - 16;
    return AttackComponent(
      position: Vector2(spawnX, position.y + size.y * 0.4),
      direction: dir,
      damage: 20,
      owner: 'player',
      attackType: AttackType.fireOrb,
      speed: 350,
      lifetime: 1.8,
    );
  }

  void triggerDodge() {
    if (_dodgeCooldown > 0 || isDodging) {
      return;
    }
    _dodgeDx = facingRight ? 1.0 : -1.0;
    _dodgeTimer = 0.32;
    _dodgeCooldown = 1.0;
    invincible = true;
    _invincibleTimer = 0.32;
    _animState = PlayerAnimState.dodge;
    _animTime = 0;
  }

  void takeDamage(int damage) {
    if (invincible) {
      return;
    }
    currentHp -= damage;
    if (currentHp < 0) {
      currentHp = 0;
    }
    invincible = true;
    _invincibleTimer = 0.8;
    _animState = PlayerAnimState.hurt;
    _animTime = 0;
  }

  bool get isDead => currentHp <= 0;

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    if (_dodgeTimer > 0) {
      _dodgeTimer -= dt;
      if (_dodgeTimer <= 0) {
        _dodgeTimer = 0;
        if (_animState == PlayerAnimState.dodge) {
          _animState = PlayerAnimState.idle;
          _animTime = 0;
        }
      }
    }

    if (_dodgeCooldown > 0) {
      _dodgeCooldown -= dt;
      if (_dodgeCooldown < 0) {
        _dodgeCooldown = 0;
      }
    }

    if (invincible) {
      _invincibleTimer -= dt;
      if (_invincibleTimer <= 0) {
        invincible = false;
      }
    }

    // Recover from hurt animation
    if (_animState == PlayerAnimState.hurt && _animTime > 0.3) {
      _animState = PlayerAnimState.idle;
      _animTime = 0;
    }
    // Recover from attack animation
    if (_animState == PlayerAnimState.attack && _animTime > 0.25) {
      _animState = PlayerAnimState.idle;
      _animTime = 0;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    // During dodge, draw a gold afterimage trail behind player
    if (isDodging) {
      final trailOffset = _dodgeDx < 0 ? 12.0 : -12.0;
      canvas.drawRect(
        ui.Rect.fromLTWH(trailOffset, 4, size.x, size.y - 8),
        _dodgeTrailPaint,
      );
    }

    // Standard flicker during non-dodge invincibility
    if (invincible && !isDodging && (_animTime * 10).floor() % 2 == 0) {
      return;
    }

    final img = _imageForState();
    if (img != null) {
      final src = ui.Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      final dst = ui.Rect.fromLTWH(0, 0, size.x, size.y);
      if (!facingRight) {
        canvas.save();
        canvas.translate(size.x, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(img, src, dst, _imagePaint);
      if (!facingRight) {
        canvas.restore();
      }
    } else {
      canvas.drawRect(size.toRect(), _fallbackPaint);
    }
  }

  ui.Image? _imageForState() {
    switch (_animState) {
      case PlayerAnimState.walk:
        return _walkImg;
      case PlayerAnimState.attack:
        return _attackImg;
      case PlayerAnimState.dodge:
        return _dodgeImg;
      default:
        return _idleImg;
    }
  }
}
