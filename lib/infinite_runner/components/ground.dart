import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ground tiles that scroll from right to left
/// Uses object pooling for memory efficiency
class Ground extends PositionComponent {
  Ground({
    required Vector2 position,
    required Vector2 size,
    required this.scrollSpeed,
  }) : super(position: position, size: size);

  double scrollSpeed;

  bool _isOffScreen = false;
  bool get isOffScreen => _isOffScreen;

  @override
  void update(double dt) {
    super.update(dt);

    // Move ground left
    position.x -= scrollSpeed * dt;

    // Check if off screen (completely left of view)
    if (position.x + size.x < 0) {
      _isOffScreen = true;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw ground base
    final basePaint = Paint()
      ..color = const Color(0xFF2d343f)
      ..style = PaintingStyle.fill;

    canvas.drawRect(size.toRect(), basePaint);

    // Draw grass pattern on top
    final grassPaint = Paint()
      ..color = const Color(0xFF19e6a2)
      ..style = PaintingStyle.fill;

    final grassHeight = size.y * 0.15;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, grassHeight), grassPaint);

    // Draw grass blades
    final bladePaint = Paint()
      ..color = const Color(0xFF14b8a6)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.x; x += 20) {
      // Draw small triangles as grass blades
      final path = Path()
        ..moveTo(x, grassHeight)
        ..lineTo(x + 5, 0)
        ..lineTo(x + 10, grassHeight)
        ..close();
      canvas.drawPath(path, bladePaint);
    }

    // Draw dirt pattern
    final dirtPaint = Paint()
      ..color = const Color(0xFF1a1e26)
      ..style = PaintingStyle.fill;

    // Random dirt spots
    for (double x = 10; x < size.x; x += 30) {
      for (double y = grassHeight + 10; y < size.y; y += 25) {
        canvas.drawCircle(Offset(x, y), 3, dirtPaint);
      }
    }
  }

  /// Reposition ground tile to the right (for reuse)
  void reposition(double newX) {
    position.x = newX;
    _isOffScreen = false;
  }

  /// Update scroll speed
  void updateSpeed(double newSpeed) {
    scrollSpeed = newSpeed;
  }
}
