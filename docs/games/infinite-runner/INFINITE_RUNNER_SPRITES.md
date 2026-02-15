# Infinite Runner - Sprite Integration Guide

## Overview
This guide explains how to replace placeholder graphics with actual sprite sheets for the player and obstacles.

## Performance Targets
- **Target FPS**: 60
- **Current Optimizations**:
  - Object pooling for obstacles
  - Sprite reuse and caching
  - No allocations in update() loops
  - Efficient collision detection

## Player Sprite Integration

### Sprite Sheet Format
Organize your player sprite sheet with frames for each animation:
- **Running**: 4-8 frames (looping)
- **Jumping**: 2-4 frames
- **Sliding**: 2-3 frames  
- **Dead**: 1-2 frames

### Example Sprite Sheet Layout
```
[Run1][Run2][Run3][Run4][Jump1][Jump2][Slide1][Slide2][Dead]
```

### Implementation in `player.dart`

Replace the `_createPlaceholderAnimation` method with actual sprite loading:

```dart
@override
Future<void> onLoad() async {
  await super.onLoad();

  // Load player sprite sheet
  final spriteSheet = await images.load('player_spritesheet.png');

  animations = {
    PlayerState.running: SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 4,              // Number of frames
        stepTime: 0.1,          // Time per frame
        textureSize: Vector2(64, 64),  // Size of each frame
        texturePosition: Vector2(0, 0), // Starting position
      ),
    ),
    PlayerState.jumping: SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.15,
        textureSize: Vector2(64, 64),
        texturePosition: Vector2(256, 0), // Skip 4 running frames
      ),
    ),
    PlayerState.sliding: SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.1,
        textureSize: Vector2(96, 48), // Wider, shorter for slide
        texturePosition: Vector2(384, 0),
      ),
    ),
    PlayerState.dead: SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1.0,
        textureSize: Vector2(64, 64),
        texturePosition: Vector2(576, 0),
      ),
    ),
  };

  current = PlayerState.running;
  
  // ... rest of setup
}
```

## Obstacle Sprite Integration

### Sprite Files
Create individual sprites for each obstacle type:
- `barrier.png` (30x50)
- `crate.png` (40x45)
- `cone.png` (25x55)
- `spikes.png` (50x30)
- `low_wall.png` (60x35)
- `high_barrier.png` (35x80)

### Implementation in `obstacle.dart`

Replace the `_createPlaceholderSprite` method:

```dart
Future<Sprite> _createPlaceholderSprite() async {
  // Load actual obstacle sprite based on type
  final imagePath = 'obstacles/${type.name}.png';
  return Sprite(await images.load(imagePath));
}
```

## Asset Setup

### 1. Add Assets to `pubspec.yaml`
```yaml
flutter:
  assets:
    - assets/images/player_spritesheet.png
    - assets/images/obstacles/barrier.png
    - assets/images/obstacles/crate.png
    - assets/images/obstacles/cone.png
    - assets/images/obstacles/spikes.png
    - assets/images/obstacles/low_wall.png
    - assets/images/obstacles/high_barrier.png
```

### 2. Directory Structure
```
assets/
└── images/
    ├── player_spritesheet.png
    └── obstacles/
        ├── barrier.png
        ├── crate.png
        ├── cone.png
        ├── spikes.png
        ├── low_wall.png
        └── high_barrier.png
```

## Performance Optimization Tips

### 1. Sprite Caching
All sprites are automatically cached by Flame's `images` loader. Avoid reloading the same image.

### 2. Texture Atlases (Advanced)
For better performance with many sprites, consider using texture atlases:

```dart
final atlas = await images.load('game_atlas.png');
final player = SpriteAnimationComponent.fromAtlas(
  image: atlas,
  frameData: /* ... */,
);
```

### 3. Memory Management
- Keep sprite sheets under 2048x2048 for mobile compatibility
- Use PNG with transparency
- Compress images appropriately (use tools like TinyPNG)

## Animation Timing

### Best Practices
- **Running**: 0.08-0.12s per frame for smooth motion
- **Jumping**: 0.15-0.20s per frame for visible action
- **Sliding**: 0.10-0.15s per frame
- **Looping**: Only running animation should loop

### Frame Counts
- **Minimum viable**: 2 frames per animation
- **Good quality**: 4-6 frames for running, 2-3 for others
- **Professional**: 8+ frames for running, 4+ for others

## Collision Hitbox Adjustment

After adding sprites, you may need to adjust hitboxes in `player.dart`:

```dart
// In onLoad()
_hitbox = RectangleHitbox(
  size: Vector2(size.x * 0.7, size.y * 0.9), // Adjust multipliers
  position: Vector2(size.x * 0.15, size.y * 0.05), // Center hitbox
)..debugMode = debugMode;
```

Use the **debug toggle button** (top-right bug icon) to visualize hitboxes while tuning.

## Critical Slide Mechanic Rules

The slide mechanic is strictly controlled to prevent bugs:

✅ **Allowed**: Slide when `isOnGround == true` and `!isSliding`
❌ **Prevented**: Mid-air slide, slide spam, sliding while jumping

The hitbox changes but Y position does NOT change during slide.

## Testing Checklist

- [ ] All animations play smoothly
- [ ] No visual glitches during state transitions
- [ ] Hitboxes match visual sprites reasonably
- [ ] Slide only works on ground
- [ ] Game maintains 60 FPS
- [ ] No memory growth after multiple restarts
- [ ] Debug mode shows hitboxes correctly

## Common Issues

### Issue: Animation doesn't play
**Solution**: Check that `amount` matches actual frame count in sprite sheet

### Issue: Wrong sprite showing
**Solution**: Verify `texturePosition` offsets in sprite sheet

### Issue: Hitbox misaligned
**Solution**: Adjust hitbox size/position or sprite anchor point

### Issue: Performance drops
**Solution**: Check sprite size, ensure caching, verify no allocations in update()

## Resources

- [Flame Sprite Documentation](https://docs.flame-engine.org/latest/flame/rendering/images.html)
- [Flame Animations](https://docs.flame-engine.org/latest/flame/rendering/images.html#animation)
- Sprite sheet tools: Aseprite, Piskel, TexturePacker

---

**Current Status**: Game uses placeholder colored rectangles with character features. Replace by following this guide for production-quality visuals.
