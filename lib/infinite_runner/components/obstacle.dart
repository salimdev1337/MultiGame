import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Types of obstacles in the game with specific characteristics
enum ObstacleType {
  /// Small barrier - requires jump
  barrier(width: 30, height: 50, color: Color(0xFFff5c00)),

  /// Crate - requires jump
  crate(width: 40, height: 45, color: Color(0xFF8B4513)),

  /// Traffic cone - requires jump or slide depending on height
  cone(width: 25, height: 55, color: Color(0xFFff6600)),

  /// Spikes - requires jump (lethal)
  spikes(width: 50, height: 30, color: Color(0xFFff0000)),

  /// Low wall - slide under
  lowWall(width: 60, height: 35, color: Color(0xFF666666)),

  /// High barrier - requires slide
  highBarrier(width: 35, height: 80, color: Color(0xFFa855f7));

  const ObstacleType({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  /// Whether this obstacle requires jumping over
  bool get requiresJump =>
      this == barrier || this == crate || this == cone || this == spikes;

  /// Whether this obstacle requires sliding under
  bool get requiresSlide => this == lowWall || this == highBarrier;
}

/// Obstacle component that moves from right to left
/// Uses sprite-based rendering with custom hitboxes
class Obstacle extends SpriteComponent with CollisionCallbacks {
  Obstacle({
    required this.type,
    required Vector2 position,
    required this.scrollSpeed,
  }) : super(position: position, size: Vector2(type.width, type.height));

  final ObstacleType type;
  double scrollSpeed;

  bool _isOffScreen = false;
  bool get isOffScreen => _isOffScreen;

  RectangleHitbox? _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load sprite (placeholder for now - replace with actual sprites)
    sprite = await _createPlaceholderSprite();

    // Add custom hitbox based on obstacle type
    _hitbox = RectangleHitbox(
      size: _getHitboxSize(),
      position: _getHitboxOffset(),
    )..debugMode = debugMode;

    add(_hitbox!);
  }

  /// Get custom hitbox size for this obstacle type
  Vector2 _getHitboxSize() {
    switch (type) {
      case ObstacleType.spikes:
        // Tighter hitbox for spikes
        return Vector2(size.x * 0.8, size.y * 0.6);
      case ObstacleType.cone:
        // Cone-shaped hitbox (smaller at top)
        return Vector2(size.x * 0.7, size.y * 0.9);
      default:
        // Default to 90% of size for better feel
        return Vector2(size.x * 0.9, size.y * 0.9);
    }
  }

  /// Get hitbox offset for centered collision
  Vector2 _getHitboxOffset() {
    final hitboxSize = _getHitboxSize();
    return Vector2((size.x - hitboxSize.x) / 2, (size.y - hitboxSize.y) / 2);
  }

  /// Create placeholder sprite (replace with actual sprite loading)
  /// Example sprite loading:
  /// ```dart
  /// return Sprite(await images.load('obstacles/${type.name}.png'));
  /// ```
  Future<Sprite> _createPlaceholderSprite() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = type.color;

    // Draw obstacle shape based on type
    switch (type) {
      case ObstacleType.barrier:
        _drawBarrier(canvas, paint);
        break;
      case ObstacleType.crate:
        _drawCrate(canvas, paint);
        break;
      case ObstacleType.cone:
        _drawCone(canvas, paint);
        break;
      case ObstacleType.spikes:
        _drawSpikes(canvas, paint);
        break;
      case ObstacleType.lowWall:
        _drawLowWall(canvas, paint);
        break;
      case ObstacleType.highBarrier:
        _drawHighBarrier(canvas, paint);
        break;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.x.toInt(), size.y.toInt());
    return Sprite(image);
  }

  void _drawBarrier(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(4)),
      paint,
    );

    // Add stripes
    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.y * (0.1 + i * 0.3), size.x, size.y * 0.1),
        stripePaint,
      );
    }
  }

  void _drawCrate(Canvas canvas, Paint paint) {
    // Draw crate body
    canvas.drawRect(size.toRect(), paint);

    // Draw crate lines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(size.x, size.y), linePaint);
    canvas.drawLine(Offset(size.x, 0), Offset(0, size.y), linePaint);
  }

  void _drawCone(Canvas canvas, Paint paint) {
    // Draw cone shape
    final path = Path()
      ..moveTo(size.x * 0.5, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();

    canvas.drawPath(path, paint);

    // Add orange stripes
    final stripePaint = Paint()..color = Colors.white;
    for (int i = 0; i < 2; i++) {
      final y = size.y * (0.3 + i * 0.3);
      final width = size.x * (1 - (y / size.y) * 0.5);
      canvas.drawRect(
        Rect.fromLTWH((size.x - width) / 2, y, width, size.y * 0.1),
        stripePaint,
      );
    }
  }

  void _drawSpikes(Canvas canvas, Paint paint) {
    // Draw multiple spikes
    for (int i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(size.x * (i * 0.2), size.y)
        ..lineTo(size.x * (i * 0.2 + 0.1), 0)
        ..lineTo(size.x * ((i + 1) * 0.2), size.y)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawLowWall(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(4)),
      paint,
    );

    // Add brick pattern
    final brickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(0, size.y * (i / 3)),
        Offset(size.x, size.y * (i / 3)),
        brickPaint,
      );
    }
  }

  void _drawHighBarrier(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)),
      paint,
    );

    // Add diagonal stripes
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 3;

    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(i * 10, 0),
        Offset(i * 10 + size.y, size.y),
        stripePaint,
      );
    }
  }

  /// Reset obstacle state for reuse from pool
  void reset(Vector2 newPosition) {
    position = newPosition.clone();
    _isOffScreen = false;

    // Recreate hitbox if missing or not mounted
    if (_hitbox == null || !_hitbox!.isMounted) {
      // Remove old hitbox if it exists
      if (_hitbox != null) {
        _hitbox!.removeFromParent();
      }

      // Create new hitbox
      _hitbox = RectangleHitbox(
        size: _getHitboxSize(),
        position: _getHitboxOffset(),
      )..debugMode = debugMode;

      add(_hitbox!);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move obstacle left (avoid allocation in update loop)
    position.x -= scrollSpeed * dt;

    // Check if off screen (left side with small buffer)
    if (position.x + size.x < -10) {
      _isOffScreen = true;
    }
  }

  /// Update scroll speed (called when game speeds up)
  void updateSpeed(double newSpeed) {
    scrollSpeed = newSpeed;
  }

  @override
  void onRemove() {
    // Clean up hitbox
    if (_hitbox != null) {
      _hitbox!.removeFromParent();
    }
    super.onRemove();
  }
}
