import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Short-lived hit spark effect spawned on attack contact.
/// Self-removes after [_duration] seconds — no external disposal needed.
class HitParticle extends PositionComponent {
  HitParticle({required Vector2 position, this.isBossHit = false})
      : super(position: position);

  final bool isBossHit;

  static const double _duration = 0.3;
  static const int _count = 6;

  final List<double> _dx = [];
  final List<double> _dy = [];
  final List<double> _px = [];
  final List<double> _py = [];
  double _elapsed = 0;

  @override
  void onMount() {
    super.onMount();
    final rng = math.Random();
    for (int i = 0; i < _count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 60 + rng.nextDouble() * 80;
      _dx.add(math.cos(angle) * speed);
      _dy.add(math.sin(angle) * speed);
      _px.add(0);
      _py.add(0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }
    for (int i = 0; i < _count; i++) {
      _px[i] += _dx[i] * dt;
      _py[i] += _dy[i] * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    final alphaInt = (alpha * 255).round();
    final color = isBossHit
        ? Color.fromARGB(alphaInt, 0xFF, 0x88, 0x00)
        : Color.fromARGB(alphaInt, 0xCC, 0x22, 0x00);
    final paint = Paint()..color = color;
    final r = 3.5 * (1.0 - t * 0.5);
    for (int i = 0; i < _count; i++) {
      canvas.drawCircle(Offset(_px[i], _py[i]), r, paint);
    }
  }
}
