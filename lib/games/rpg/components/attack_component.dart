import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// A short-lived attack hitbox in the top-down arena.
/// Melee arcs are stationary. Projectiles move in a direction.
/// AOE (ultimate) covers the full arena and expires quickly.
class AttackComponent extends PositionComponent {
  AttackComponent({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.owner,
    required this.attackType,
    this.speed = 0,
    this.lifetime = 0.2,
    this.radius = 0,
  }) : super(position: position, size: _sizeForType(attackType)) {
    _dir = direction.length > 0 ? direction.normalized() : Vector2(1, 0);
  }

  final Vector2 direction;
  final int damage;

  /// 'player' or 'boss'
  final String owner;
  final AttackType attackType;
  final double speed;
  double lifetime;

  /// For circular attacks (slam, pool, ultimate). 0 = use rect size.
  final double radius;

  late Vector2 _dir;
  bool consumed = false;

  static Vector2 _sizeForType(AttackType type) {
    switch (type) {
      case AttackType.meleeSlash1:
      case AttackType.meleeSlash2:
        return Vector2(48, 32);
      case AttackType.heavySlash:
        return Vector2(64, 48);
      case AttackType.ultimateAoe:
        return Vector2(480, 480); // covers arena
      case AttackType.chargeAttack:
        return Vector2(72, 40);
      case AttackType.overheadSlam:
        return Vector2(96, 96);
      case AttackType.poisonPool:
        return Vector2(80, 80);
      case AttackType.poisonProjectile:
        return Vector2(18, 18);
      case AttackType.dashSlash:
        return Vector2(80, 36);
      case AttackType.bladeTrail:
        return Vector2(24, 80);
      case AttackType.voidBlast:
        return Vector2(20, 20);
      case AttackType.shadowSurge:
        return Vector2(600, 48);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifetime -= dt;
    if (lifetime <= 0 || consumed) {
      removeFromParent();
      return;
    }
    if (speed > 0) {
      position += _dir * speed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (consumed) {
      return;
    }
    final paint = Paint()..color = _colorForType();

    if (attackType == AttackType.overheadSlam ||
        attackType == AttackType.poisonPool ||
        attackType == AttackType.ultimateAoe) {
      canvas.drawOval(size.toRect(), paint);
    } else {
      canvas.drawRect(size.toRect(), paint);

      // Directional outline for charged attacks
      if (attackType == AttackType.heavySlash) {
        final outline = Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(size.toRect(), outline);
      }
    }
  }

  Color _colorForType() {
    switch (attackType) {
      case AttackType.meleeSlash1:
        return const Color(0xBBFFD700);
      case AttackType.meleeSlash2:
        return const Color(0xCCFFAA00);
      case AttackType.heavySlash:
        return const Color(0xEEFF6600);
      case AttackType.ultimateAoe:
        return const Color(0x66FFFFFF);
      case AttackType.chargeAttack:
        return const Color(0xCC8B5E00);
      case AttackType.overheadSlam:
        return const Color(0x99FF6600);
      case AttackType.poisonPool:
        return const Color(0x8844CC00);
      case AttackType.poisonProjectile:
        return const Color(0xCC44FF00);
      case AttackType.dashSlash:
        return const Color(0xCCCCCCFF);
      case AttackType.bladeTrail:
        return const Color(0x994444FF);
      case AttackType.voidBlast:
        return const Color(0xCC8800CC);
      case AttackType.shadowSurge:
        return const Color(0x88440088);
    }
  }

  /// Axis-aligned bounding box for fast overlap tests.
  Rect get aabb => Rect.fromLTWH(
    position.x - size.x / 2,
    position.y - size.y / 2,
    size.x,
    size.y,
  );

  /// Returns true if this attack's bounds overlap a circle at [center] with [r].
  bool overlapsCircle(Vector2 center, double r) {
    final closestX = center.x.clamp(position.x, position.x + size.x);
    final closestY = center.y.clamp(position.y, position.y + size.y);
    final dx = center.x - closestX;
    final dy = center.y - closestY;
    return (dx * dx + dy * dy) <= r * r;
  }

  /// Returns true if this attack's center is within [r] of [center].
  bool centerWithin(Vector2 center, double r) {
    final cx = position.x + size.x / 2;
    final cy = position.y + size.y / 2;
    final dx = cx - center.x;
    final dy = cy - center.y;
    return math.sqrt(dx * dx + dy * dy) <= r;
  }
}
