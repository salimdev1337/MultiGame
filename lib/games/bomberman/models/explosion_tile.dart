import 'package:flutter/foundation.dart';

@immutable
class ExplosionTile {
  final int x;
  final int y;
  final int remainingMs;
  final int totalMs;

  const ExplosionTile({
    required this.x,
    required this.y,
    required this.remainingMs,
    this.totalMs = 400,
  });

  double get alpha => (remainingMs / totalMs).clamp(0.0, 1.0);

  ExplosionTile copyWith({int? remainingMs}) =>
      ExplosionTile(
        x: x,
        y: y,
        remainingMs: remainingMs ?? this.remainingMs,
        totalMs: totalMs,
      );
}
