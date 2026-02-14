import 'package:flutter/foundation.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

@immutable
class BombPlayer {
  final int id;          // 0–3
  final double x;        // grid column (pixel-level smooth position)
  final double y;        // grid row
  final int lives;
  final int maxBombs;    // max simultaneous bombs
  final int activeBombs; // currently placed bombs
  final int range;       // explosion tiles in each direction
  final double speed;    // cells per second
  final bool isAlive;
  final bool isGhost;    // died but still plays — walks through walls, bombs reshape map only
  final bool hasShield;  // absorbs next explosion hit
  final bool isBot;
  final List<PowerupType> powerups;
  final String displayName;

  /// Target cell centre the player is currently sliding toward.
  /// When the player reaches this position, the next direction input is accepted.
  final double targetX;
  final double targetY;

  const BombPlayer({
    required this.id,
    required this.x,
    required this.y,
    this.lives = 1,
    this.maxBombs = 2,
    this.activeBombs = 0,
    this.range = 1,
    this.speed = 6.0,
    this.isAlive = true,
    this.isGhost = false,
    this.hasShield = false,
    this.isBot = false,
    this.powerups = const [],
    this.displayName = '',
    double? targetX,
    double? targetY,
  })  : targetX = targetX ?? x,
        targetY = targetY ?? y;

  /// True if this player can act (alive or ghost)
  bool get canAct => isAlive;

  /// True if player can place a bomb
  bool get canPlaceBomb => isAlive && activeBombs < maxBombs;

  /// Grid cell for bomb placement (the cell the player is heading to/at)
  int get bombCellX => targetX.floor();
  int get bombCellY => targetY.floor();

  /// Current grid cell the player's center is inside
  int get gridX => x.floor();
  int get gridY => y.floor();

  BombPlayer copyWith({
    int? id,
    double? x,
    double? y,
    int? lives,
    int? maxBombs,
    int? activeBombs,
    int? range,
    double? speed,
    bool? isAlive,
    bool? isGhost,
    bool? hasShield,
    bool? isBot,
    List<PowerupType>? powerups,
    String? displayName,
    double? targetX,
    double? targetY,
  }) {
    return BombPlayer(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      lives: lives ?? this.lives,
      maxBombs: maxBombs ?? this.maxBombs,
      activeBombs: activeBombs ?? this.activeBombs,
      range: range ?? this.range,
      speed: speed ?? this.speed,
      isAlive: isAlive ?? this.isAlive,
      isGhost: isGhost ?? this.isGhost,
      hasShield: hasShield ?? this.hasShield,
      isBot: isBot ?? this.isBot,
      powerups: powerups ?? this.powerups,
      displayName: displayName ?? this.displayName,
      targetX: targetX ?? this.targetX,
      targetY: targetY ?? this.targetY,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BombPlayer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
