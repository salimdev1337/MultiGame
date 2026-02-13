import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../state/player_state.dart';

/// Player character in the infinite runner using Kenney sprites
/// Optimized for 60 FPS with zero allocations in hot paths
class Player extends SpriteAnimationGroupComponent<PlayerState>
    with CollisionCallbacks {
  Player({
    required Vector2 position,
    required Vector2 size,
    required double groundY,
  }) : _groundY = groundY,
       _standingWidth = size.x,
       _standingHeight = size.y,
       super(position: position, size: size, anchor: Anchor.bottomCenter);

  // Physics constants (primitives only - no allocations)
  static const double gravity = 1200.0;
  static const double jumpVelocity = -650.0;
  static const double maxFallSpeed = 800.0;
  static const double fastDropSpeed = 1200.0;

  // Player state (primitives only)
  PlayerState _currentState = PlayerState.running;
  double _velocityY = 0.0;
  bool _isOnGround = true;
  bool _isSliding = false;
  double _slideTimer = 0.0;
  static const double slideDuration = 0.6;

  // Slowdown state (race mode)
  double speedMultiplier = 1.0;
  double _slowdownTimer = 0.0;
  double _slowdownDuration = 0.0;
  bool get isSlowed => speedMultiplier < 1.0;

  // Dimensions (primitives - no Vector2 allocations)
  final double _standingWidth;
  final double _standingHeight;
  double _groundY;

  // Cached hitbox (REUSED - never recreated)
  late final RectangleHitbox _hitbox;

  bool get isOnGround => _isOnGround;
  bool get isSliding => _isSliding;
  PlayerState get currentState => _currentState;

  /// Update ground level and reposition player (for screen resize)
  void updateGroundY(double newGroundY) {
    _groundY = newGroundY;
    position.y = newGroundY;
    _isOnGround = true;
    _velocityY = 0.0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load real sprite animations from Kenney Industrial assets
    animations = {
      PlayerState.running: await _loadRunAnimation(),
      PlayerState.jumping: await _loadJumpAnimation(),
      PlayerState.sliding: await _loadSlideAnimation(),
      PlayerState.dead: await _loadDeadAnimation(),
    };

    current = PlayerState.running;

    // Create hitbox ONCE - never recreated during gameplay
    // Hitbox is 85% of sprite size for fair gameplay
    // Position relative to bottomCenter anchor
    final hitboxWidth = _standingWidth * 0.85;
    final hitboxHeight = _standingHeight * 0.85;
    _hitbox = RectangleHitbox(
      size: Vector2(hitboxWidth, hitboxHeight),
      position: Vector2(-hitboxWidth / 2, -hitboxHeight),
    );
    add(_hitbox);

    // Set initial size
    size.x = _standingWidth;
    size.y = _standingHeight;
  }

  /// Load running animation (2 frames looping)
  Future<SpriteAnimation> _loadRunAnimation() async {
    return SpriteAnimation.spriteList(
      [
        await Sprite.load('alienBlue_walk1.png'),
        await Sprite.load('alienBlue_walk2.png'),
      ],
      stepTime: 0.15,
      loop: true,
    );
  }

  /// Load jump animation (single sprite)
  Future<SpriteAnimation> _loadJumpAnimation() async {
    return SpriteAnimation.spriteList(
      [await Sprite.load('alienBlue_jump.png')],
      stepTime: 1.0,
      loop: false,
    );
  }

  /// Load slide animation (reuse walk1 for now, scaled)
  Future<SpriteAnimation> _loadSlideAnimation() async {
    return SpriteAnimation.spriteList(
      [await Sprite.load('alienBlue_walk1.png')],
      stepTime: 1.0,
      loop: false,
    );
  }

  /// Load dead animation (walk1 but static)
  Future<SpriteAnimation> _loadDeadAnimation() async {
    return SpriteAnimation.spriteList(
      [await Sprite.load('alienBlue_walk1.png')],
      stepTime: 1.0,
      loop: false,
    );
  }

  /// Apply a temporary speed penalty (race mode)
  /// [factor] — multiplier applied to scroll speed (e.g. 0.6 = 40% slower)
  /// [duration] — seconds the penalty lasts
  void applySlowdown({required double factor, required double duration}) {
    speedMultiplier = factor;
    _slowdownTimer = 0.0;
    _slowdownDuration = duration;
  }

  /// ✅ OPTIMIZED update() - ZERO allocations in hot path
  /// - No Vector2 creation
  /// - No object instantiation
  /// - Direct primitive operations only
  @override
  void update(double dt) {
    super.update(dt);

    // Tick slowdown timer and restore speed when done
    if (speedMultiplier < 1.0) {
      _slowdownTimer += dt;
      if (_slowdownTimer >= _slowdownDuration) {
        speedMultiplier = 1.0;
        _slowdownTimer = 0.0;
        _slowdownDuration = 0.0;
      }
    }

    // Update slide timer
    if (_isSliding) {
      _slideTimer += dt;
      if (_slideTimer >= slideDuration) {
        _endSlide();
      }
    }

    // Apply gravity (primitive math only)
    _velocityY += gravity * dt;

    // Clamp fall speed (simple comparison - no Math.min allocation)
    if (_velocityY > maxFallSpeed) {
      _velocityY = maxFallSpeed;
    }

    // Update position (direct field access - no Vector2)
    position.y += _velocityY * dt;

    // Check ground collision
    if (position.y >= _groundY) {
      position.y = _groundY;
      _velocityY = 0.0;

      // Update ground state
      final wasInAir = !_isOnGround;
      _isOnGround = true;

      // If just landed and not sliding, return to running
      if (wasInAir && !_isSliding) {
        _setState(PlayerState.running);
      }
    } else {
      _isOnGround = false;
    }

    // Update animation state based on physics
    if (!_isSliding && _currentState != PlayerState.dead) {
      if (!_isOnGround) {
        _setState(PlayerState.jumping);
      } else {
        _setState(PlayerState.running);
      }
    }
  }

  /// ✅ Set player state - ONLY changes animation reference (zero allocations)
  void _setState(PlayerState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      current = newState; // Reference swap only - no animation creation
    }
  }

  /// ✅ OPTIMIZED jump() - No allocations, just state change
  /// Jump ONLY allowed when grounded and not sliding
  void jump() {
    if (_isOnGround && !_isSliding && _currentState != PlayerState.dead) {
      _velocityY = jumpVelocity;
      _isOnGround = false;
      _setState(PlayerState.jumping); // ✅ Animation swap by reference only
    }
  }

  /// Slide (disabled as per requirements)
  void slide() {
    // Slide mechanic removed
  }

  /// Fast drop when in air
  void fastDrop() {
    if (!_isOnGround && _currentState != PlayerState.dead) {
      _velocityY = fastDropSpeed;
    }
  }

  /// ✅ OPTIMIZED hitbox update - Modify size in place, NEVER recreate
  /// This is critical for performance - no remove/add operations
  void _updateHitboxSize(double width, double height) {
    // Direct size modification (no allocation)
    size.x = width;
    size.y = height;

    // Hitbox automatically adjusts to component size
    // No need to recreate it
  }

  /// End slide animation
  void _endSlide() {
    if (_isSliding) {
      _isSliding = false;
      _slideTimer = 0.0;

      // Restore standing size
      _updateHitboxSize(_standingWidth, _standingHeight);

      // Return to running if on ground
      if (_isOnGround) {
        _setState(PlayerState.running);
      }
    }
  }

  /// Handle death state
  void die() {
    _setState(PlayerState.dead);
    _velocityY = 0.0;
  }

  /// Reset player to initial state
  void reset() {
    position.y = _groundY;
    _velocityY = 0.0;
    _isOnGround = true;
    _isSliding = false;
    _slideTimer = 0.0;
    speedMultiplier = 1.0;
    _slowdownTimer = 0.0;
    _slowdownDuration = 0.0;
    _updateHitboxSize(_standingWidth, _standingHeight);
    _setState(PlayerState.running);
  }

  @override
  void onRemove() {
    _hitbox.removeFromParent();
    super.onRemove();
  }
}
