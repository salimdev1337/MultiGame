import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'ability_type.dart';

/// On-track collectible that grants the player an ability when touched.
/// Scrolls left like an obstacle; glows with a pulsing aura.
class AbilityPickup extends PositionComponent {
  AbilityPickup({
    required this.type,
    required Vector2 position,
    required double scrollSpeed,
  }) : _scrollSpeed = scrollSpeed,
       super(
         position: position,
         size: Vector2(44, 44),
         // bottomCenter so it sits on the ground like obstacles
         anchor: Anchor.bottomCenter,
       );

  final AbilityType type;
  double _scrollSpeed;
  bool _collected = false;
  double _glowTimer = 0.0;

  bool get isCollected => _collected;
  bool get isOffScreen => position.x + size.x < 0;

  void markCollected() => _collected = true;
  void updateSpeed(double speed) => _scrollSpeed = speed;

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= _scrollSpeed * dt;
    _glowTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final center = Offset(cx, cy);
    final radius = size.x / 2 - 2;

    // Pulsing glow (0..1)
    final glowPulse = (math.sin(_glowTimer * 4) + 1) / 2;
    final abilityColor = Color(type.colorValue);

    // Outer glow
    canvas.drawCircle(
      center,
      radius + 8 + 3 * glowPulse,
      Paint()
        ..color = abilityColor.withValues(alpha: 0.15 + 0.15 * glowPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Dark background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.75),
    );

    // Colored ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = abilityColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Emoji label
    final tp = TextPainter(
      text: TextSpan(text: type.emoji, style: const TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }
}
