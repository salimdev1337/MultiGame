import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// Types of obstacles in the game with sprite mappings
enum ObstacleType {
  /// Small barrier - requires jump (platformIndustrial_066.png)
  barrier(
    spritePath: 'platformIndustrial_066.png',
    baseWidth: 64,
    baseHeight: 64,
  ),

  /// Box obstacle - requires jump (platformIndustrial_067.png)
  box(spritePath: 'platformIndustrial_067.png', baseWidth: 64, baseHeight: 64),

  /// Tall barrier - requires jump (platformIndustrial_068.png)
  tallBarrier(
    spritePath: 'platformIndustrial_068.png',
    baseWidth: 64,
    baseHeight: 64,
  ),

  /// High obstacle - requires slide under (platformIndustrial_069.png)
  highObstacle(
    spritePath: 'platformIndustrial_069.png',
    baseWidth: 64,
    baseHeight: 64,
  );

  const ObstacleType({
    required this.spritePath,
    required this.baseWidth,
    required this.baseHeight,
  });

  final String spritePath;
  final double baseWidth;
  final double baseHeight;

  /// Whether this obstacle requires jumping over
  bool get requiresJump =>
      this == barrier || this == box || this == tallBarrier;

  /// Whether this obstacle requires sliding under
  bool get requiresSlide => this == highObstacle;

  /// Get a random obstacle type
  static ObstacleType random() {
    final random = math.Random();
    final values = ObstacleType.values;
    return values[random.nextInt(values.length)];
  }
}

/// Obstacle component that moves from right to left
/// Uses Kenney Industrial Platformer sprites with collision detection
class Obstacle extends SpriteComponent with CollisionCallbacks {
  Obstacle({
    required this.type,
    required Vector2 position,
    required this.scrollSpeed,
    this.scaleFactor = 1.0,
  }) : super(position: position, anchor: Anchor.bottomLeft);

  final ObstacleType type;
  double scrollSpeed;
  final double scaleFactor;

  bool _isOffScreen = false;
  bool get isOffScreen => _isOffScreen;

  RectangleHitbox? _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load sprite from asset
    sprite = await Sprite.load(type.spritePath);

    // Set size based on sprite's original size and scale factor
    size = Vector2(type.baseWidth * scaleFactor, type.baseHeight * scaleFactor);
  }

  @override
  void onMount() {
    super.onMount();

    // Add hitbox after mounting when size is finalized
    _hitbox = RectangleHitbox(
      size: _getHitboxSize(),
      position: _getHitboxOffset(),
    );

    add(_hitbox!);
  }

  /// Get custom hitbox size for better gameplay feel (90% of sprite size)
  Vector2 _getHitboxSize() {
    return Vector2(size.x * 0.85, size.y * 0.85);
  }

  /// Get hitbox offset for centered collision
  Vector2 _getHitboxOffset() {
    final hitboxSize = _getHitboxSize();
    return Vector2((size.x - hitboxSize.x) / 2, (size.y - hitboxSize.y) / 2);
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
      );

      add(_hitbox!);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move obstacle left
    position.x -= scrollSpeed * dt;

    // Check if off screen (left side with buffer)
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
