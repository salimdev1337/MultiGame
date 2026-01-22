import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../components/player.dart';
import '../components/obstacle.dart';

/// System that handles collision detection between player and obstacles
/// Notifies game when collision occurs
class CollisionSystem {
  CollisionSystem({required this.onCollision});

  /// Callback when collision detected
  final VoidCallback onCollision;

  bool _hasCollided = false;

  /// Check for collisions between player and obstacles
  void checkCollisions(Player player, List<Obstacle> obstacles) {
    if (_hasCollided) return;

    for (final obstacle in obstacles) {
      if (_checkCollision(player, obstacle)) {
        _hasCollided = true;
        onCollision();
        return;
      }
    }
  }

  /// Check if player and obstacle are colliding using their hitboxes
  bool _checkCollision(Player player, Obstacle obstacle) {
    // Get hitboxes from components
    final playerHitboxes = player.children.whereType<RectangleHitbox>();
    final obstacleHitboxes = obstacle.children.whereType<RectangleHitbox>();

    if (playerHitboxes.isEmpty || obstacleHitboxes.isEmpty) {
      // Fallback to basic AABB if hitboxes not found
      return _basicAABB(player, obstacle);
    }

    final playerHitbox = playerHitboxes.first;
    final obstacleHitbox = obstacleHitboxes.first;

    // Check if hitboxes are mounted and loaded
    if (!playerHitbox.isMounted || !obstacleHitbox.isMounted) {
      return _basicAABB(player, obstacle);
    }

    // Calculate absolute positions accounting for bottomLeft anchor
    // Player uses default anchor (topLeft), so position.y is the top
    final playerLeft = player.position.x + playerHitbox.position.x;
    final playerRight = playerLeft + playerHitbox.size.x;
    final playerTop = player.position.y + playerHitbox.position.y;
    final playerBottom = playerTop + playerHitbox.size.y;

    // Obstacle uses bottomLeft anchor, so position.y is the bottom
    final obstacleLeft = obstacle.position.x + obstacleHitbox.position.x;
    final obstacleRight = obstacleLeft + obstacleHitbox.size.x;
    final obstacleBottom = obstacle.position.y + obstacleHitbox.position.y;
    final obstacleTop = obstacleBottom - obstacle.size.y;

    // AABB collision detection with hitboxes
    return playerLeft < obstacleRight &&
        playerRight > obstacleLeft &&
        playerTop < obstacleBottom &&
        playerBottom > obstacleTop;
  }

  /// Fallback basic AABB collision detection accounting for anchors
  bool _basicAABB(PositionComponent a, PositionComponent b) {
    // Player (a) uses default topLeft anchor
    final aLeft = a.position.x;
    final aRight = a.position.x + a.size.x;
    final aTop = a.position.y;
    final aBottom = a.position.y + a.size.y;

    // Obstacle (b) uses bottomLeft anchor
    final bLeft = b.position.x;
    final bRight = b.position.x + b.size.x;
    final bBottom = b.position.y;
    final bTop = b.position.y - b.size.y;

    return aLeft < bRight && aRight > bLeft && aTop < bBottom && aBottom > bTop;
  }

  /// Reset collision state for new game
  void reset() {
    _hasCollided = false;
  }
}
