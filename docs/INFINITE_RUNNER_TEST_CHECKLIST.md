# Infinite Runner - Testing & Validation Checklist

## 🎯 Pre-Deployment Testing

### ✅ Core Mechanics Testing

#### Player Movement
- [ ] **Jump works only on ground**
  - Try jumping while already jumping (should not work)
  - Jump from ground (should work)
  - Verify smooth arc trajectory

- [ ] **Slide works only on ground**
  - Try sliding mid-air (should NOT work) ⚠️ CRITICAL
  - Try sliding while already sliding (should NOT work)
  - Slide on ground (should work for 0.6s)
  - Verify hitbox shrinks but position stays same

- [ ] **Fast drop works in air**
  - Jump, then press down (should drop quickly)
  - Try fast drop on ground (should slide instead)

#### Controls
- [ ] **Arrow Keys (Chrome/Desktop)**
  - Up arrow = Jump
  - Down arrow (air) = Fast drop
  - Down arrow (ground) = Slide

- [ ] **Touch/Click**
  - Tap/Click = Jump
  - Swipe down = Slide (if implemented)

- [ ] **Keyboard Alternatives**
  - Space = Jump
  - Enter = Start game

### ✅ Obstacle System Testing

#### Obstacle Variety
- [ ] **All 6 types spawn**
  - Barrier (orange, 30x50)
  - Crate (brown, 40x45)
  - Cone (orange striped, 25x55)
  - Spikes (red, 50x30)
  - Low Wall (gray, 60x35)
  - High Barrier (purple, 35x80)

- [ ] **Variety algorithm works**
  - Same obstacle doesn't repeat immediately
  - Good mix over time

#### Collision Testing
- [ ] **Hit detection accurate**
  - Enable debug mode
  - Verify collision occurs at hitbox boundaries
  - Check all 6 obstacle types

- [ ] **Jump clears obstacles**
  - Jump over barrier (should clear)
  - Jump over spikes (should clear)
  - Jump over crate (should clear)

- [ ] **Slide clears obstacles**
  - Slide under high barrier (should clear)
  - Slide under low wall (should clear)

### ✅ Performance Testing

#### FPS Monitoring
- [ ] **Initial load**
  - Check FPS counter (if available)
  - Should be steady 60 FPS

- [ ] **5-minute gameplay**
  - Play continuously for 5 minutes
  - Monitor for frame drops
  - Check browser performance tools

- [ ] **After 10+ restarts**
  - Restart game 10 times
  - Check memory in browser dev tools
  - Should not increase significantly

#### Memory Testing
- [ ] **Open Chrome DevTools**
  - Go to Performance/Memory tab
  - Take heap snapshot before playing
  - Play for 2 minutes
  - Take another snapshot
  - Compare - should be similar

- [ ] **Object pool verification**
  - Enable debug mode
  - Count active obstacles (should be < 10)
  - Verify no infinite growth

### ✅ Visual Testing

#### Animations
- [ ] **Player animations transition smoothly**
  - Running → Jumping (should be instant)
  - Jumping → Running (on landing)
  - Running → Sliding (on ground only)
  - Sliding → Running (after 0.6s)
  - Any state → Dead (on collision)

- [ ] **No visual glitches**
  - Check for flickering
  - Check for sprite tearing
  - Verify smooth scrolling

#### Debug Mode
- [ ] **Hitbox visualization**
  - Click debug toggle (bug icon)
  - Should show red outlines
  - Hitboxes should match sprites reasonably

### ✅ Game State Testing

#### Game Flow
- [ ] **Idle state**
  - Shows "TAP TO START" overlay
  - Can start with tap or up arrow
  - Player is visible and stationary

- [ ] **Playing state**
  - HUD shows score
  - Score increases over time
  - Speed increases gradually
  - Obstacles spawn continuously

- [ ] **Paused state**
  - Pause button works
  - Everything freezes
  - Can resume

- [ ] **Game Over state**
  - Shows score and high score
  - Detects new high score
  - Can restart

#### High Score
- [ ] **Saves correctly**
  - Play and get a score
  - Restart game
  - High score should persist

- [ ] **Updates on new record**
  - Beat previous high score
  - Should show "NEW HIGH SCORE!" message

### ✅ Edge Cases

#### Rapid Input
- [ ] **Spam jump** - Should only jump once per ground contact
- [ ] **Spam slide** - Should respect 0.6s duration
- [ ] **Jump + Slide simultaneously** - Should prioritize current state

#### Screen Sizes
- [ ] **Desktop** (1920x1080)
- [ ] **Tablet** (1024x768)
- [ ] **Mobile** (375x667)
- [ ] **Ultrawide** (2560x1080)

#### Browser Compatibility
- [ ] **Chrome** (primary)
- [ ] **Firefox**
- [ ] **Safari**
- [ ] **Edge**

### ✅ Bug Verification

#### Critical Bug: Mid-Air Slide (MUST BE FIXED)
```dart
// Test case:
1. Jump
2. While in air, press down arrow
3. Expected: Fast drop (NOT slide)
4. Actual: Should fast drop

Status: [ ] PASSED  [ ] FAILED
```

#### Critical Bug: Floating Character
```dart
// Test case:
1. Start game
2. Observe character at start
3. Expected: Standing on ground
4. Actual: Should be on ground

Status: [ ] PASSED  [ ] FAILED
```

#### Critical Bug: Hitbox Position During Slide
```dart
// Test case:
1. Enable debug mode
2. Slide on ground
3. Observe hitbox and sprite
4. Expected: Hitbox shrinks, position unchanged
5. Actual: Y position should not change

Status: [ ] PASSED  [ ] FAILED
```

## 📊 Performance Benchmarks

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Initial FPS | 60 | ___ | ⬜ |
| FPS after 5 min | 60 | ___ | ⬜ |
| Memory (initial) | < 100MB | ___ | ⬜ |
| Memory (after 5 min) | < 150MB | ___ | ⬜ |
| Obstacles on screen | < 10 | ___ | ⬜ |
| Max pool size | 60 | ___ | ⬜ |

## 🐛 Known Issues to Document

### Issue 1: [Description]
- **Severity**: [ ] Critical [ ] Major [ ] Minor
- **Reproducible**: [ ] Always [ ] Sometimes [ ] Rare
- **Steps**: 
- **Expected**: 
- **Actual**: 

### Issue 2: [Description]
- **Severity**: [ ] Critical [ ] Major [ ] Minor
- **Reproducible**: [ ] Always [ ] Sometimes [ ] Rare
- **Steps**: 
- **Expected**: 
- **Actual**: 

## ✅ Acceptance Sign-Off

### Developer Checklist
- [ ] All critical bugs fixed
- [ ] Slide mechanic works correctly
- [ ] 60 FPS maintained
- [ ] Memory stable
- [ ] All 6 obstacles spawn
- [ ] Debug mode works
- [ ] High score saves

### Code Quality
- [ ] No console errors
- [ ] No lint warnings
- [ ] All files formatted
- [ ] Comments up to date
- [ ] Documentation complete

### User Experience
- [ ] Controls feel responsive
- [ ] Game is fun to play
- [ ] Difficulty curve is good
- [ ] Visuals are clear
- [ ] No confusion about mechanics

## 📝 Test Results Summary

**Date**: ______________
**Tester**: ______________
**Platform**: ______________
**Browser**: ______________

**Overall Status**: 
- [ ] ✅ PASS - Ready for deployment
- [ ] ⚠️ PASS WITH ISSUES - Minor fixes needed
- [ ] ❌ FAIL - Critical issues found

**Notes**:
```
[Add any additional observations or comments]
```

---

## 🚀 Deployment Checklist

After all tests pass:

- [ ] Run `flutter build web --release`
- [ ] Test production build
- [ ] Verify no debug code in production
- [ ] Check asset loading
- [ ] Verify analytics (if any)
- [ ] Document known limitations
- [ ] Update README
- [ ] Tag release version

---

**Testing Status**: ⬜ Not Started | 🔄 In Progress | ✅ Complete
