# Infinite Runner - Quick Reference

## 🎮 Controls

| Input | Action | Condition |
|-------|--------|-----------|
| ↑ / Tap / Space | Jump | On ground only |
| ↓ (in air) | Fast drop | While jumping |
| ↓ (on ground) | Slide | On ground, not sliding |

## 🎯 Player States

```dart
enum PlayerState {
  running,  // Default, on ground
  jumping,  // In air
  sliding,  // On ground, 0.6s duration
  dead      // After collision
}
```

## 🚧 Obstacle Types

| Type | Size | Color | Strategy |
|------|------|-------|----------|
| Barrier | 30x50 | Orange | Jump |
| Crate | 40x45 | Brown | Jump |
| Cone | 25x55 | Orange/White | Jump |
| Spikes | 50x30 | Red | Jump (lethal) |
| Low Wall | 60x35 | Gray | Slide under |
| High Barrier | 35x80 | Purple | Slide under |

## ⚙️ Key Files

### Player
- `player.dart` - Character component with animations
- `player_state.dart` - State enum

### Obstacles
- `obstacle.dart` - Obstacle component with sprites
- `obstacle_pool.dart` - Object pooling system
- `spawn_system.dart` - Spawning logic

### Game
- `infinite_runner_game.dart` - Main game logic
- `infinite_runner_page.dart` - Flutter integration

## 🔧 Debug Mode

**Toggle**: Click bug icon (top-right)
**Shows**: Red hitbox outlines for all game objects
**Use**: Verify collision boundaries, tune difficulty

## 📊 Performance Specs

- **Target FPS**: 60
- **Object Pool**: 10 per obstacle type (60 total)
- **Spawn Rate**: 350-600px gaps
- **Speed Range**: 250-600 px/s

## 🐛 Critical Slide Rules

```dart
// ✅ ALLOWED
if (isOnGround && !isSliding && state != dead) {
  slide();
}

// ❌ PREVENTED
// - Mid-air slide
// - Slide spam
// - Sliding while jumping
```

## 🎨 Adding Sprites

1. Add images to `assets/images/`
2. Update `pubspec.yaml`
3. Replace placeholder methods:
   - `_createPlaceholderAnimation()` in player.dart
   - `_createPlaceholderSprite()` in obstacle.dart

See `INFINITE_RUNNER_SPRITES.md` for details.

## 🧪 Testing Checklist

- [ ] Slide only works on ground
- [ ] Fast drop works in air
- [ ] 6 obstacle types spawn
- [ ] Debug mode shows hitboxes
- [ ] 60 FPS maintained
- [ ] No memory growth (restart 10x)
- [ ] Score updates in real-time

## 📝 Common Tasks

### Adjust Jump Height
```dart
// In player.dart
static const double jumpVelocity = -650.0; // Increase for higher jump
```

### Change Game Speed
```dart
// In infinite_runner_game.dart
static const double maxScrollSpeed = 600.0; // Max difficulty speed
static const double speedIncreaseRate = 5.0; // Speed increase per second
```

### Modify Spawn Rate
```dart
// In spawn_system.dart
static const double minSpawnDistance = 350.0;
static const double maxSpawnDistance = 600.0;
```

### Adjust Hitbox Size
```dart
// In player.dart, _updateHitbox()
_hitbox = RectangleHitbox(
  size: Vector2(size.x * 0.7, size.y * 0.9), // Adjust multipliers
);
```

## 🚀 Quick Start

```bash
# Run game
flutter run -d chrome

# Navigate to Infinite Runner from home
# Press "TAP TO START"
# Use arrow keys or tap/click
```

## 📚 Documentation

- `INFINITE_RUNNER_REFACTOR_SUMMARY.md` - Complete overview
- `INFINITE_RUNNER_SPRITES.md` - Sprite integration guide
- Inline code comments - Implementation details

---

**Ready to play!** 🎮
