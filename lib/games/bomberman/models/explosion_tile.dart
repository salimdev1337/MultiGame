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

  ExplosionTile copyWith({int? remainingMs}) => ExplosionTile(
    x: x,
    y: y,
    remainingMs: remainingMs ?? this.remainingMs,
    totalMs: totalMs,
  );

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'remainingMs': remainingMs,
    'totalMs': totalMs,
  };

  factory ExplosionTile.fromJson(Map<String, dynamic> json) => ExplosionTile(
    x: json['x'] as int,
    y: json['y'] as int,
    remainingMs: json['remainingMs'] as int,
    totalMs: json['totalMs'] as int,
  );
}
