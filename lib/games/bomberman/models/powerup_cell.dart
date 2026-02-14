import 'package:flutter/foundation.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

@immutable
class PowerupCell {
  final int x;
  final int y;
  final PowerupType type;

  const PowerupCell({
    required this.x,
    required this.y,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'type': type.toJson(),
      };

  factory PowerupCell.fromJson(Map<String, dynamic> json) => PowerupCell(
        x: json['x'] as int,
        y: json['y'] as int,
        type: PowerupTypeJson.fromJson(json['type'] as int),
      );
}
