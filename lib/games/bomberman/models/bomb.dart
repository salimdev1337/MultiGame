import 'package:flutter/foundation.dart';

@immutable
class Bomb {
  final int id;
  final int x;
  final int y;
  final int ownerId;
  final int range;
  final int fuseMs;        // remaining fuse time in ms
  final int totalFuseMs;   // original fuse duration for animation

  const Bomb({
    required this.id,
    required this.x,
    required this.y,
    required this.ownerId,
    required this.range,
    required this.fuseMs,
    this.totalFuseMs = 2500,
  });

  Bomb copyWith({
    int? id,
    int? x,
    int? y,
    int? ownerId,
    int? range,
    int? fuseMs,
    int? totalFuseMs,
  }) {
    return Bomb(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      ownerId: ownerId ?? this.ownerId,
      range: range ?? this.range,
      fuseMs: fuseMs ?? this.fuseMs,
      totalFuseMs: totalFuseMs ?? this.totalFuseMs,
    );
  }

  /// 0.0 (full fuse) → 1.0 (about to explode)
  double get fuseProgress =>
      1.0 - (fuseMs / totalFuseMs).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'ownerId': ownerId,
        'range': range,
        'fuseMs': fuseMs,
        'totalFuseMs': totalFuseMs,
      };

  factory Bomb.fromJson(Map<String, dynamic> json) => Bomb(
        id: json['id'] as int,
        x: json['x'] as int,
        y: json['y'] as int,
        ownerId: json['ownerId'] as int,
        range: json['range'] as int,
        fuseMs: json['fuseMs'] as int,
        totalFuseMs: json['totalFuseMs'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is Bomb && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
