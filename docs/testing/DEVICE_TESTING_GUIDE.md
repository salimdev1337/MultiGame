# Physical Device Testing Guide

**Version:** 1.0
**Date:** 2026-02-05
**App:** MultiGame v1.0.0
**Purpose:** Comprehensive manual testing on physical Android devices

---

## Overview

This guide provides a systematic approach to testing MultiGame on physical devices before Play Store submission. All tests should be performed on release builds, not debug builds.

**Testing Goal:** Ensure the app works flawlessly across different Android versions, device specs, and network conditions.

---

## Test Environment Setup

### Prerequisites

#### 1. Build Release APK
```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# APK location
# build/app/outputs/flutter-apk/app-release.apk
```

#### 2. Install on Device
```bash
# Connect device via USB and enable USB debugging
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or reinstall (removes previous data)
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

#### 3. Enable Developer Options
On test devices:
- Settings → About Phone → Tap "Build Number" 7 times
- Settings → Developer Options → Enable
- Settings → Developer Options → USB Debugging → Enable

---

## Test Matrix

### Minimum Test Coverage

| Device Type | Android Version | RAM | Status | Tester | Notes |
|-------------|----------------|-----|--------|--------|-------|
| Low-end | Android 9 (API 28) | 2GB | ⬜ Pending | - | Minimum supported |
| Mid-range | Android 12 (API 31) | 4GB | ⬜ Pending | - | Most common |
| High-end | Android 14 (API 34) | 8GB+ | ⬜ Pending | - | Latest version |
| Tablet | Android 12+ | 4GB+ | ⬜ Optional | - | If supporting tablets |

### Recommended Test Devices

**Budget Devices (Low-end):**
- Samsung Galaxy A03s (Android 11, 2GB RAM)
- Nokia G10 (Android 11, 3GB RAM)
- Redmi 9A (Android 10, 2GB RAM)

**Mid-range Devices:**
- Samsung Galaxy A54 (Android 13, 6GB RAM)
- Google Pixel 6a (Android 14, 6GB RAM)
- OnePlus Nord 2 (Android 12, 8GB RAM)

**High-end Devices:**
- Samsung Galaxy S23 (Android 14, 8GB RAM)
- Google Pixel 8 (Android 14, 8GB RAM)
- OnePlus 11 (Android 14, 12GB RAM)

---

## Test Scenarios

## 1. Installation & First Launch

### 1.1 Clean Installation
- [ ] Install APK via `adb install`
- [ ] App icon appears in launcher
- [ ] App name displays correctly: "MultiGame"
- [ ] No installation errors or warnings
- [ ] App size reasonable (<50MB)

### 1.2 First Launch
- [ ] App launches within 3 seconds
- [ ] Splash screen displays (if any)
- [ ] Firebase initializes successfully
- [ ] Anonymous authentication completes
- [ ] No crashes during initialization
- [ ] Home screen loads with game carousel
- [ ] Bottom navigation visible (Home, Profile, Leaderboard)

### 1.3 Permissions
- [ ] No unexpected permission requests
- [ ] Internet permission granted (if needed)
- [ ] No storage permission requests (app uses app-specific storage)

**Test Command:**
```bash
# Monitor logs during first launch
adb logcat | grep -i "MultiGame\|Firebase\|flutter"
```

---

## 2. Game Functionality Testing

### 2.1 Sudoku - Classic Mode

#### Basic Gameplay
- [ ] Navigate to Sudoku from home carousel
- [ ] Mode selection screen appears (Classic, Rush, 1v1)
- [ ] Select "Classic Mode"
- [ ] Difficulty selection appears (Easy, Medium, Hard, Expert)
- [ ] Select "Easy" difficulty
- [ ] Game board generates and displays correctly
- [ ] All 81 cells visible and properly sized
- [ ] Pre-filled numbers displayed in different color/style
- [ ] Number pad (1-9) displays at bottom
- [ ] Control buttons visible (Undo, Erase, Hint, Settings)

#### Input & Interaction
- [ ] Tap empty cell - cell highlights
- [ ] Tap number on number pad - number enters cell
- [ ] Tap occupied cell - cell highlights, shows entered number
- [ ] Tap Erase button - clears selected cell
- [ ] Tap Undo button - reverts last move
- [ ] Tap Hint button - provides valid number for selected cell
- [ ] Hints decrement from 3 to 0
- [ ] Cannot use hints after reaching 0

#### Validation
- [ ] Enter correct number - cell accepts, no error
- [ ] Enter incorrect number - cell shows error state (red highlight)
- [ ] Complete row with valid numbers - no errors
- [ ] Enter duplicate in same row - shows error
- [ ] Enter duplicate in same column - shows error
- [ ] Enter duplicate in same 3x3 box - shows error

#### Game Completion
- [ ] Fill all cells correctly - game over dialog appears
- [ ] Dialog shows completion time
- [ ] Dialog shows number of mistakes
- [ ] Dialog shows score
- [ ] "New Game" button works
- [ ] "Home" button returns to main menu

#### Persistence
- [ ] Start game, exit app (home button)
- [ ] Reopen app
- [ ] Game state restored (board, timer, mistakes)
- [ ] Continue playing from saved state

#### Settings & Sound
- [ ] Tap settings icon in game
- [ ] Sound toggle works (on/off)
- [ ] Haptic feedback toggle works (on/off)
- [ ] Settings persist across sessions

### 2.2 Sudoku - Rush Mode

#### Mode-Specific Features
- [ ] Select "Rush Mode" from mode selection
- [ ] Timer starts counting down (e.g., 5:00)
- [ ] Timer displays prominently
- [ ] Score increases with correct placements
- [ ] Score decreases with incorrect placements
- [ ] Difficulty increases after completing puzzle
- [ ] New puzzle generates automatically
- [ ] Time bonus added for quick completion

#### Time Pressure
- [ ] Timer counts down correctly (seconds decrease)
- [ ] Warning when time runs low (e.g., <30s, red color)
- [ ] Game ends when timer reaches 0:00
- [ ] Final score displayed
- [ ] High score saved and displayed

### 2.3 Sudoku - 1v1 Online Mode

#### Matchmaking
- [ ] Select "1v1 Online" from mode selection
- [ ] Two options appear: "Create Room" and "Join Room"
- [ ] Tap "Create Room"
- [ ] 6-digit room code generated and displayed
- [ ] "Waiting for opponent" message shown
- [ ] Copy room code button works
- [ ] Share button works (if available)
- [ ] Can cancel matchmaking
- [ ] Back button returns to mode selection

#### Joining Room
- [ ] Tap "Join Room"
- [ ] Input field for 6-digit code appears
- [ ] Enter valid room code
- [ ] "Joining room..." message appears
- [ ] Successfully joins room
- [ ] Opponent name/avatar displayed
- [ ] Game starts countdown (3, 2, 1, GO!)

#### Online Gameplay
- [ ] Both players see same puzzle
- [ ] Own moves update in real-time
- [ ] Opponent moves visible in real-time (different color)
- [ ] Opponent's progress tracked
- [ ] Opponent's mistakes counter visible
- [ ] Opponent's hints used counter visible
- [ ] Connection status indicator visible (green = connected)

#### Connection Handling
- [ ] Enable airplane mode during game
- [ ] Connection status changes (yellow/red = disconnected)
- [ ] "Reconnecting..." message appears
- [ ] Disable airplane mode
- [ ] Connection restores automatically
- [ ] Game state syncs correctly

#### Game End (Online)
- [ ] Complete puzzle first - "You Win!" dialog
- [ ] Opponent completes first - "Opponent Wins!" dialog
- [ ] Results show both players' times and mistakes
- [ ] Score saved to leaderboard
- [ ] "Play Again" button works
- [ ] Can create new room or join different room

#### Edge Cases
- [ ] Opponent disconnects - notification appears
- [ ] Wait for reconnection (60s grace period)
- [ ] Opponent reconnects - game continues
- [ ] Opponent doesn't reconnect - game ends, you win by default

### 2.4 Infinite Runner

#### Gameplay
- [ ] Tap "Infinite Runner" from home carousel
- [ ] Game loads with start screen
- [ ] Tap "Start" or anywhere to begin
- [ ] Character runs automatically
- [ ] Obstacles appear (barriers, crates, cones, spikes, walls)
- [ ] Background scrolls smoothly
- [ ] Ground scrolls smoothly

#### Controls
- [ ] Swipe up - character jumps
- [ ] Swipe down - character slides
- [ ] Jump height appropriate (clears obstacles)
- [ ] Slide duration appropriate (passes under barriers)
- [ ] Double tap - double jump (if implemented)
- [ ] Controls responsive, no lag

#### Performance
- [ ] Game runs at 60 FPS (smooth animations)
- [ ] No frame drops during gameplay
- [ ] No stuttering when spawning obstacles
- [ ] No memory leaks (play for 5+ minutes)
- [ ] Device doesn't overheat

#### Collision & Scoring
- [ ] Hit obstacle - game ends
- [ ] Score increases continuously
- [ ] Score increases faster at higher speeds
- [ ] Game difficulty increases over time
- [ ] Speed increases gradually
- [ ] Obstacle frequency increases

#### Game Over
- [ ] Collision triggers game over
- [ ] Game over screen displays final score
- [ ] High score shown if beaten
- [ ] "Restart" button works
- [ ] "Home" button returns to menu
- [ ] Score saved to leaderboard

### 2.5 Snake Game

#### Gameplay
- [ ] Tap "Snake" from home carousel
- [ ] Game starts with small snake (3 segments)
- [ ] Snake moves automatically
- [ ] Food appears randomly on grid
- [ ] Neon graphics render correctly

#### Controls
- [ ] Swipe up - snake moves up
- [ ] Swipe down - snake moves down
- [ ] Swipe left - snake moves left
- [ ] Swipe right - snake moves right
- [ ] Cannot reverse direction (no 180° turns)
- [ ] Controls responsive

#### Game Logic
- [ ] Eat food - snake grows by 1 segment
- [ ] Eat food - score increases
- [ ] New food spawns after eating
- [ ] Snake speed increases as it grows
- [ ] Hit wall - game over
- [ ] Hit own body - game over

#### Game Over
- [ ] Game over screen appears
- [ ] Final score and length displayed
- [ ] High score shown if beaten
- [ ] "Restart" button works
- [ ] Score saved

### 2.6 Image Puzzle

#### Gameplay
- [ ] Tap "Image Puzzle" from home carousel
- [ ] Difficulty selection appears (3x3, 4x4, 5x5)
- [ ] Select "3x3" difficulty
- [ ] Random image loads from Unsplash (or fallback)
- [ ] Image splits into tiles correctly
- [ ] Tiles shuffle randomly
- [ ] One tile empty (bottom-right)

#### Controls
- [ ] Tap tile adjacent to empty space - tile slides
- [ ] Cannot tap non-adjacent tiles
- [ ] Smooth sliding animation
- [ ] Tiles lock in place after sliding
- [ ] Timer starts on first move
- [ ] Move counter increases

#### Completion
- [ ] Arrange tiles in correct order
- [ ] Game detects completion
- [ ] "Puzzle Solved!" dialog appears
- [ ] Shows time taken
- [ ] Shows number of moves
- [ ] Shows preview of complete image
- [ ] "New Puzzle" button loads different image

#### Edge Cases
- [ ] No internet connection - uses fallback images
- [ ] Large images load without lag
- [ ] Image fits screen properly (no cropping issues)

### 2.7 2048 Game

#### Gameplay
- [ ] Tap "2048" from home carousel
- [ ] 4x4 grid appears
- [ ] Two tiles spawn with "2" or "4"
- [ ] Numbers clearly visible

#### Controls
- [ ] Swipe up - tiles move up
- [ ] Swipe down - tiles move down
- [ ] Swipe left - tiles move left
- [ ] Swipe right - tiles move right
- [ ] Smooth animations when tiles merge
- [ ] New tile spawns after each move

#### Game Logic
- [ ] Matching numbers merge (2+2=4)
- [ ] Merged tiles show correct value
- [ ] Score increases with merges
- [ ] Larger merges give more points
- [ ] Cannot move if no valid moves
- [ ] Game over when grid full and no merges possible

#### Special Features
- [ ] "Undo" button works (reverts one move)
- [ ] "Restart" button works (new game)
- [ ] Highest tile achieved displayed
- [ ] Reach 2048 tile - victory screen
- [ ] Can continue after reaching 2048

---

## 3. Profile & Stats Testing

### 3.1 Profile Screen
- [ ] Tap "Profile" in bottom navigation
- [ ] Profile screen loads
- [ ] Anonymous user ID displayed (or nickname if set)
- [ ] "Edit Profile" button visible
- [ ] Stats section displays correctly

### 3.2 Personal Stats
- [ ] Total games played count correct
- [ ] Sudoku stats displayed (games, wins, best time)
- [ ] Infinite Runner high score displayed
- [ ] Snake high score displayed
- [ ] Puzzle stats displayed (completions, best time)
- [ ] 2048 high score displayed
- [ ] Stats update after completing games

### 3.3 Achievements
- [ ] Achievements section visible
- [ ] Locked achievements shown (grayed out)
- [ ] Unlocked achievements shown (colored)
- [ ] Achievement cards display correctly
- [ ] Tap achievement - details dialog appears
- [ ] Achievement unlock animation triggers (when earned)

### 3.4 Nickname/Profile Edit
- [ ] Tap "Edit Profile"
- [ ] Nickname input field appears
- [ ] Enter nickname (e.g., "TestPlayer123")
- [ ] Save button updates nickname
- [ ] Nickname displays in profile
- [ ] Nickname appears in online games
- [ ] Nickname persists after app restart

---

## 4. Leaderboard Testing

### 4.1 Global Leaderboard
- [ ] Tap "Leaderboard" in bottom navigation
- [ ] Leaderboard screen loads
- [ ] Game filter tabs visible (All, Sudoku, Runner, Snake, Puzzle, 2048)
- [ ] Tap "All Games" - combined leaderboard displays
- [ ] Tap "Sudoku" - Sudoku leaderboard displays
- [ ] Top players listed (rank, name, score)
- [ ] Own rank highlighted (if in top 100)

### 4.2 Leaderboard Data
- [ ] Scores sorted correctly (highest to lowest)
- [ ] Player names displayed
- [ ] Scores formatted correctly
- [ ] Rank numbers correct (1, 2, 3, ...)
- [ ] "Load More" button works (if pagination)
- [ ] Pull-to-refresh updates leaderboard

### 4.3 Score Updates
- [ ] Play game and achieve high score
- [ ] Complete game
- [ ] Return to leaderboard
- [ ] New score appears in leaderboard
- [ ] Rank updates accordingly
- [ ] Timestamp shows recent update

---

## 5. Network Conditions Testing

### 5.1 Online Gameplay (Good Connection)
- [ ] Connect to Wi-Fi (strong signal)
- [ ] Start Sudoku 1v1 Online game
- [ ] Matchmaking works quickly (<5s)
- [ ] Game syncs smoothly
- [ ] Opponent moves update instantly
- [ ] No lag or delays
- [ ] Score saves to Firebase

### 5.2 Poor Network (3G Simulation)
**Setup:**
```bash
# Simulate poor network with adb
adb shell
settings put global mobile_data_always_on 1
exit
```

- [ ] Enable mobile data, disable Wi-Fi
- [ ] Start Sudoku 1v1 Online game
- [ ] Matchmaking takes longer but completes
- [ ] Gameplay continues with slight delay
- [ ] Opponent moves update (with lag)
- [ ] Connection status indicator shows poor connection
- [ ] Score still saves (with retry)

### 5.3 Offline Mode (Airplane Mode)
- [ ] Enable airplane mode
- [ ] Launch app
- [ ] App launches successfully (no crash)
- [ ] Offline indicator visible (in app bar or snackbar)
- [ ] Single-player games work:
  - [ ] Sudoku Classic works
  - [ ] Infinite Runner works
  - [ ] Snake works
  - [ ] 2048 works
  - [ ] Image Puzzle works (with cached images)
- [ ] Online features disabled:
  - [ ] Sudoku 1v1 shows "Offline" message
  - [ ] Leaderboard shows "No Connection" message
  - [ ] Profile stats show cached data
- [ ] Game scores queue for upload
- [ ] Disable airplane mode
- [ ] Queued scores upload automatically
- [ ] Leaderboard updates

### 5.4 Network Interruption During Gameplay
- [ ] Start Sudoku 1v1 Online game (online required)
- [ ] Play for 30 seconds
- [ ] Enable airplane mode mid-game
- [ ] "Connection lost" notification appears
- [ ] "Reconnecting..." message shown
- [ ] Game state preserved (board doesn't reset)
- [ ] Disable airplane mode
- [ ] App reconnects automatically within 60s
- [ ] Game syncs and continues
- [ ] Opponent moves catch up

---

## 6. Performance Testing

### 6.1 FPS & Smoothness
**Measure FPS:**
```bash
# Enable GPU rendering profile
adb shell setprop debug.hwui.profile visual_bars
adb shell setprop debug.hwui.render_dirty_regions false

# Monitor FPS
adb shell dumpsys gfxinfo com.yourstudio.multigame framestats
```

- [ ] Infinite Runner runs at 60 FPS
- [ ] No frame drops during gameplay
- [ ] Smooth animations (no stuttering)
- [ ] UI transitions smooth (screen changes)
- [ ] Scrolling smooth (leaderboard, carousel)

### 6.2 Memory Usage
**Monitor Memory:**
```bash
# Check memory usage
adb shell dumpsys meminfo com.yourstudio.multigame

# Monitor memory over time
adb shell top | grep com.yourstudio.multigame
```

- [ ] Memory usage reasonable (<200MB)
- [ ] No memory leaks (play each game for 10 minutes)
- [ ] Memory doesn't increase continuously
- [ ] App doesn't slow down over time
- [ ] No out-of-memory crashes

### 6.3 Battery & Heating
- [ ] Play each game for 10 minutes
- [ ] Monitor device temperature (should not overheat)
- [ ] Check battery drain (Settings → Battery → App usage)
- [ ] Battery drain acceptable (<10% per hour of gameplay)
- [ ] Device doesn't throttle (slow down due to heat)

### 6.4 App Size & Startup Time
```bash
# Check APK size
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Measure startup time
adb shell am start -W com.yourstudio.multigame/.MainActivity
```

- [ ] APK size reasonable (<50MB)
- [ ] Cold start time <3 seconds
- [ ] Warm start time <1 second
- [ ] App doesn't freeze during startup

---

## 7. Persistence & State Management

### 7.1 Game State Persistence
- [ ] Start Sudoku Classic game
- [ ] Make several moves
- [ ] Press Home button (don't close app)
- [ ] Wait 1 minute
- [ ] Reopen app
- [ ] Game state restored (board, timer, mistakes)

### 7.2 Settings Persistence
- [ ] Change sound setting to OFF
- [ ] Change haptic feedback to OFF
- [ ] Close app completely (swipe away from recent apps)
- [ ] Reopen app
- [ ] Settings still OFF
- [ ] Settings applied (no sound/haptic feedback)

### 7.3 Stats Persistence
- [ ] Complete a game (any game)
- [ ] Check profile - stats updated
- [ ] Close app completely
- [ ] Clear app cache (Settings → Apps → MultiGame → Clear Cache)
- [ ] Reopen app
- [ ] Stats still present (from Firebase)
- [ ] Leaderboard scores still present

### 7.4 Authentication Persistence
- [ ] Launch app first time (anonymous auth)
- [ ] Close app completely
- [ ] Reopen app
- [ ] User ID remains same (not re-authenticated)
- [ ] Profile data persists
- [ ] Stats persist

---

## 8. Edge Cases & Error Handling

### 8.1 Interruptions During Gameplay
- [ ] Start game
- [ ] Receive phone call during gameplay
- [ ] Answer call
- [ ] End call
- [ ] Return to app
- [ ] Game state preserved or shows "Paused"
- [ ] Can continue playing

### 8.2 Notifications During Gameplay
- [ ] Start game
- [ ] Send test notification (from another app)
- [ ] Notification banner appears
- [ ] Game pauses or continues appropriately
- [ ] Tap notification - switches to other app
- [ ] Return to game - state preserved

### 8.3 Low Battery Mode
- [ ] Enable battery saver mode (Settings → Battery)
- [ ] Launch app
- [ ] All features work
- [ ] Performance acceptable (may be slightly slower)
- [ ] No crashes due to power restrictions

### 8.4 Screen Rotation (if supported)
- [ ] Enable auto-rotate
- [ ] Launch app in portrait mode
- [ ] Rotate device to landscape
- [ ] UI adapts correctly (or stays portrait)
- [ ] No layout issues
- [ ] Game state preserved during rotation

### 8.5 Background/Foreground Transitions
- [ ] Start game
- [ ] Press Home button (background)
- [ ] Wait 5 minutes
- [ ] Reopen app
- [ ] App resumes quickly
- [ ] No crash or restart
- [ ] Game state preserved

### 8.6 App Crashes (Rare Cases)
- [ ] Monitor logs for crashes: `adb logcat | grep -i "crash\|exception\|fatal"`
- [ ] If crash occurs:
  - [ ] Note steps to reproduce
  - [ ] Check Firebase Crashlytics report
  - [ ] Log crash details
  - [ ] Attempt to reproduce

---

## 9. Firebase Integration Testing

### 9.1 Firebase Authentication
- [ ] First launch - anonymous auth triggered
- [ ] User ID generated
- [ ] User ID stored securely
- [ ] Check Firebase Console - anonymous user appears

### 9.2 Firestore Data Sync
- [ ] Complete game
- [ ] Score saves to Firestore
- [ ] Check Firebase Console - document created
- [ ] Verify data structure correct:
  ```json
  {
    "userId": "abc123",
    "displayName": "Player1",
    "gameType": "sudoku",
    "score": 1234,
    "timestamp": "2026-02-05T10:30:00Z"
  }
  ```

### 9.3 Leaderboard Sync
- [ ] Complete game with high score
- [ ] Check leaderboard in app
- [ ] New score appears
- [ ] Check Firebase Console - leaderboard collection updated
- [ ] Verify scores sorted correctly

### 9.4 Offline Queue & Sync
- [ ] Enable airplane mode
- [ ] Complete game (score queued)
- [ ] Disable airplane mode
- [ ] Score uploads automatically
- [ ] Appears in leaderboard
- [ ] Check Firebase Console - data present

---

## 10. Security & Privacy Testing

### 10.1 Secure Storage
```bash
# Check if data encrypted
adb shell
run-as com.yourstudio.multigame
ls -la
# Should not see plain-text sensitive data
```

- [ ] User data encrypted (Flutter Secure Storage)
- [ ] No plain-text passwords or tokens
- [ ] No sensitive data in logs

### 10.2 Network Traffic
**Monitor with Charles Proxy or Wireshark:**
- [ ] All Firebase requests use HTTPS
- [ ] No unencrypted data transmission
- [ ] API keys not exposed in network logs
- [ ] No sensitive data in URL parameters

### 10.3 Permissions
```bash
# Check app permissions
adb shell pm list permissions -g -d
adb shell dumpsys package com.yourstudio.multigame | grep permission
```

- [ ] Only necessary permissions requested
- [ ] No unexpected permission requests
- [ ] Internet permission only (if needed)

---

## Automated Testing Commands

### Install & Launch Script
```bash
#!/bin/bash
# test_device.sh - Automated device testing helper

echo "=== MultiGame Device Testing Script ==="
echo ""

# Check device connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No device connected!"
    exit 1
fi

echo "✅ Device connected"
echo ""

# Build release APK
echo "📦 Building release APK..."
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build successful"
echo ""

# Install APK
echo "📲 Installing APK..."
adb install -r build/app/outputs/flutter-apk/app-release.apk
if [ $? -ne 0 ]; then
    echo "❌ Installation failed!"
    exit 1
fi
echo "✅ Installation successful"
echo ""

# Launch app
echo "🚀 Launching app..."
adb shell am start -n com.yourstudio.multigame/.MainActivity
echo ""

# Monitor logs
echo "📊 Monitoring logs (Ctrl+C to stop)..."
adb logcat | grep -i "flutter\|firebase\|multigame"
```

### Performance Monitoring Script
```bash
#!/bin/bash
# monitor_performance.sh

PACKAGE="com.yourstudio.multigame"

echo "=== Performance Monitoring ===="
echo ""

# Memory usage
echo "📊 Memory Usage:"
adb shell dumpsys meminfo $PACKAGE | grep -E "TOTAL|Java Heap|Native Heap|Graphics"
echo ""

# CPU usage
echo "⚡ CPU Usage:"
adb shell top -n 1 | grep $PACKAGE
echo ""

# Battery impact
echo "🔋 Battery Usage:"
adb shell dumpsys batterystats | grep $PACKAGE
echo ""

# Frame stats (FPS)
echo "🎮 Frame Stats (Recent):"
adb shell dumpsys gfxinfo $PACKAGE | grep -A 50 "Total frames"
```

---

## Test Result Recording

### Test Report Template

Use this template to record test results:

```markdown
# Device Test Report

**Date:** YYYY-MM-DD
**Tester:** [Name]
**Build:** [version]

## Device Information
- **Device Model:** [e.g., Samsung Galaxy A54]
- **Android Version:** [e.g., Android 13]
- **RAM:** [e.g., 6GB]
- **Screen Size:** [e.g., 6.4 inches]
- **Screen Resolution:** [e.g., 1080 x 2400]

## Test Results Summary
- **Total Tests:** [X]
- **Passed:** [X]
- **Failed:** [X]
- **Critical Issues:** [X]
- **Overall Status:** ✅ PASS / ❌ FAIL

## Issues Found

### Critical Issues (Blockers)
1. [Issue description]
   - **Steps to Reproduce:** [...]
   - **Expected:** [...]
   - **Actual:** [...]
   - **Screenshot:** [attach if available]

### Major Issues
1. [Issue description]

### Minor Issues
1. [Issue description]

## Performance Metrics
- **Cold Start Time:** [X]s
- **Memory Usage (Average):** [X]MB
- **FPS (Infinite Runner):** [X] FPS
- **Battery Drain (1 hour):** [X]%

## Recommendations
- [Recommendation 1]
- [Recommendation 2]

**Tested By:** [Name]
**Signature:** [Date]
```

---

## Critical Issues Definition

### Severity Levels

**Critical (P0) - Must Fix Before Release:**
- App crashes on launch
- Cannot complete any game
- Data loss (progress not saved)
- Online multiplayer completely broken
- Firebase sync failure (scores not saving)

**Major (P1) - Should Fix Before Release:**
- Significant performance issues (FPS <30)
- Game logic errors (incorrect scoring)
- UI rendering issues
- Partial feature failure
- Inconsistent behavior across devices

**Minor (P2) - Fix If Time Permits:**
- Minor UI glitches
- Text typos
- Non-critical animations
- Edge case issues
- Cosmetic improvements

---

## Success Criteria

Before marking testing complete, ensure:

- [ ] ✅ All critical tests passed on 3+ devices
- [ ] ✅ No critical (P0) issues found
- [ ] ✅ <5 major (P1) issues found
- [ ] ✅ All games functional on all test devices
- [ ] ✅ Performance acceptable (60 FPS, <200MB RAM)
- [ ] ✅ Offline mode works
- [ ] ✅ Online multiplayer works
- [ ] ✅ Firebase sync works
- [ ] ✅ No data loss
- [ ] ✅ Battery drain acceptable
- [ ] ✅ No overheating issues
- [ ] ✅ All P0 and P1 issues resolved

---

## Resources

### ADB Commands Reference
```bash
# Device info
adb shell getprop ro.build.version.release  # Android version
adb shell getprop ro.product.model          # Device model
adb shell cat /proc/meminfo | grep MemTotal  # Total RAM

# Clear app data
adb shell pm clear com.yourstudio.multigame

# Uninstall app
adb uninstall com.yourstudio.multigame

# Take screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Record video
adb shell screenrecord /sdcard/demo.mp4
# (Ctrl+C to stop recording)
adb pull /sdcard/demo.mp4
```

### Firebase Console
- Authentication: https://console.firebase.google.com/project/[project-id]/authentication
- Firestore: https://console.firebase.google.com/project/[project-id]/firestore
- Crashlytics: https://console.firebase.google.com/project/[project-id]/crashlytics

---

**Document Version:** 1.0
**Last Updated:** 2026-02-05
**Status:** Ready for device testing
