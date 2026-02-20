import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// A short-lived hitbox representing a player or boss attack in flight.
class AttackComponent extends PositionComponent with CollisionCallbacks {
  AttackComponent({
    required Vector2 position,
    required Vector2 direction,
    required this.damage,
    required this.owner,
    required this.attackType,
    this.speed = 300,
    this.lifetime = 0.5,
  }) : super(
          position: position,
          size: _sizeForType(attackType),
        ) {
    _direction = direction.normalized();
  }

  final int damage;
  final String owner; // 'player' or 'boss'
  final AttackType attackType;
  final double speed;
  double lifetime;

  late Vector2 _direction;
  bool consumed = false;

  static Vector2 _sizeForType(AttackType type) {
    switch (type) {
      case AttackType.meleeSlash:
        return Vector2(40, 32);
      case AttackType.rockProjectile:
      case AttackType.shadowBolt:
      case AttackType.fireOrb:
        return Vector2(16, 16);
      case AttackType.groundStomp:
      case AttackType.aoe:
        return Vector2(120, 32);
      case AttackType.dashAttack:
        return Vector2(48, 32);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..isSolid = true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifetime -= dt;
    if (lifetime <= 0 || consumed) {
      removeFromParent();
      return;
    }
    if (attackType != AttackType.groundStomp && attackType != AttackType.aoe) {
      position += _direction * speed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (consumed) {
      return;
    }
    final paint = Paint()..color = _colorForType();
    canvas.drawRect(size.toRect(), paint);
  }

  Color _colorForType() {
    switch (attackType) {
      case AttackType.meleeSlash:
        return const Color(0xCCFFD700);
      case AttackType.rockProjectile:
        return const Color(0xFF808080);
      case AttackType.shadowBolt:
        return const Color(0xCC8000CC);
      case AttackType.fireOrb:
        return const Color(0xCCFF4400);
      case AttackType.groundStomp:
        return const Color(0x88FF6600);
      case AttackType.aoe:
        return const Color(0x88CC0000);
      case AttackType.dashAttack:
        return const Color(0xCC4A0080);
    }
  }
}
