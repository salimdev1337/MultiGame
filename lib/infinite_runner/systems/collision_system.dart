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

    // Calculate absolute positions of hitboxes
    final playerLeft = player.position.x + playerHitbox.position.x;
    final playerRight = playerLeft + playerHitbox.size.x;
    final playerTop = player.position.y + playerHitbox.position.y;
    final playerBottom = playerTop + playerHitbox.size.y;

    final obstacleLeft = obstacle.position.x + obstacleHitbox.position.x;
    final obstacleRight = obstacleLeft + obstacleHitbox.size.x;
    final obstacleTop = obstacle.position.y + obstacleHitbox.position.y;
    final obstacleBottom = obstacleTop + obstacleHitbox.size.y;

    // AABB collision detection with hitboxes
    return playerLeft < obstacleRight &&
        playerRight > obstacleLeft &&
        playerTop < obstacleBottom &&
        playerBottom > obstacleTop;
  }

  /// Fallback basic AABB collision detection
  bool _basicAABB(PositionComponent a, PositionComponent b) {
    return a.position.x < b.position.x + b.size.x &&
        a.position.x + a.size.x > b.position.x &&
        a.position.y < b.position.y + b.size.y &&
        a.position.y + a.size.y > b.position.y;
  }

  /// Reset collision state for new game
  void reset() {
    _hasCollided = false;
  }
}
