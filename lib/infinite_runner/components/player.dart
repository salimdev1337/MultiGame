import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../state/player_state.dart';

/// Player character in the infinite runner
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
       super(position: position, size: size);

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

    // ✅ CRITICAL: Load ALL animations ONCE during initialization
    // These animations are NEVER recreated during gameplay
    // All frames MUST have identical dimensions (64x64) to avoid texture reallocation
    animations = {
      PlayerState.running: await _createPlaceholderAnimation(
        const Color(0xFF00d4ff),
        4,
      ),
      PlayerState.jumping: await _createPlaceholderAnimation(
        const Color(0xFF00ff88),
        2,
      ),
      PlayerState.sliding: await _createPlaceholderAnimation(
        const Color(0xFFff5c00),
        2,
      ),
      PlayerState.dead: await _createPlaceholderAnimation(
        const Color(0xFFff0000),
        1,
      ),
    };

    current = PlayerState.running;

    // ✅ CRITICAL: Create hitbox ONCE - never recreated during gameplay
    // We only modify its size property, never remove/add it
    _hitbox = RectangleHitbox()..debugMode = debugMode;
    add(_hitbox);

    // Set initial size (no clone() - direct assignment)
    size.x = _standingWidth;
    size.y = _standingHeight;
  }

  /// Create placeholder animation with FIXED 64x64 size
  /// ✅ All animations use identical frame dimensions - critical for performance
  Future<SpriteAnimation> _createPlaceholderAnimation(
    Color color,
    int frameCount,
  ) async {
    final frames = <SpriteAnimationFrame>[];
    for (int i = 0; i < frameCount; i++) {
      final sprite = await _createColorSprite(color);
      frames.add(SpriteAnimationFrame(sprite, 0.1));
    }
    return SpriteAnimation(frames);
  }

  /// Create sprite with FIXED 64x64 dimensions
  /// ✅ Consistent size prevents GPU texture reallocation
  Future<Sprite> _createColorSprite(Color color) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 64, 64),
        const Radius.circular(8),
      ),
      paint,
    );

    // Draw eyes
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(20, 20), 4, eyePaint);
    canvas.drawCircle(const Offset(44, 20), 4, eyePaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    return Sprite(image);
  }

  /// ✅ OPTIMIZED update() - ZERO allocations in hot path
  /// - No Vector2 creation
  /// - No object instantiation
  /// - Direct primitive operations only
  @override
  void update(double dt) {
    super.update(dt);

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
    _updateHitboxSize(_standingWidth, _standingHeight);
    _setState(PlayerState.running);
  }

  @override
  void onRemove() {
    _hitbox.removeFromParent();
    super.onRemove();
  }
}
