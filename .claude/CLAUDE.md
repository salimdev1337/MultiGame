# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MultiGame is a Flutter-based multi-platform gaming app featuring:
- Image Puzzle (sliding puzzle with Unsplash images)
- 2048 Game
- Snake Game
- Infinite Runner (Flame engine)
- Achievement system and leaderboards
- Firebase backend for stats and authentication

## Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Run without API key (uses fallback images)
flutter run

# Run with Unsplash API key
flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/game_2048_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Platform-Specific Builds
```bash
# Android
flutter run -d android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter run -d ios

# Windows
flutter run -d windows
flutter build windows --release

# Web
flutter run -d chrome
flutter build web --release
```

### Linting
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```

## Architecture

### State Management
The app uses **Provider** for state management with dedicated providers for each game:

- **PuzzleGameProvider** ([lib/providers/puzzle_game_provider.dart](lib/providers/puzzle_game_provider.dart)) - Manages puzzle game state, timer, moves
- **Game2048Provider** ([lib/providers/game_2048_provider.dart](lib/providers/game_2048_provider.dart)) - Handles 2048 game logic
- **SnakeGameProvider** ([lib/providers/snake_game_provider.dart](lib/providers/snake_game_provider.dart)) - Snake game state
- **UserAuthProvider** ([lib/providers/user_auth_provider.dart](lib/providers/user_auth_provider.dart)) - User authentication state

All providers are registered in [lib/main.dart](lib/main.dart) using `MultiProvider`.

### Firebase Integration
The app initializes Firebase in [lib/main.dart](lib/main.dart) with anonymous authentication by default. A persistent user ID is stored locally to maintain user identity across sessions.

**Important:** Firebase Auth is required for Firestore access. The app signs in anonymously on startup if no user is authenticated.

Services:
- **FirebaseStatsService** ([lib/services/firebase_stats_service.dart](lib/services/firebase_stats_service.dart)) - Saves game stats to Firestore
- **AchievementService** ([lib/services/achievement_service.dart](lib/services/achievement_service.dart)) - Manages achievement system using SharedPreferences
- **NicknameService** ([lib/services/nickname_service.dart](lib/services/nickname_service.dart)) - Stores persistent user ID

### Infinite Runner Architecture
The Infinite Runner game uses **Flame engine** with an ECS-inspired architecture. See [docs/INFINITE_RUNNER_ARCHITECTURE.md](docs/INFINITE_RUNNER_ARCHITECTURE.md) for detailed diagrams.

Key concepts:
- **Object Pooling**: 60 pre-allocated obstacles (10 per type) to eliminate GC pauses
- **Component-based**: Player, obstacles, background, ground are separate components
- **Systems**: CollisionSystem, SpawnSystem, ObstaclePool handle game logic
- **State machines**: Player (running/jumping/sliding/dead) and Game (idle/playing/paused/gameover)

Files:
- [lib/infinite_runner/infinite_runner_game.dart](lib/infinite_runner/infinite_runner_game.dart) - Main game loop
- [lib/infinite_runner/components/player.dart](lib/infinite_runner/components/player.dart) - Player with animations
- [lib/infinite_runner/components/obstacle.dart](lib/infinite_runner/components/obstacle.dart) - 6 obstacle types with sprites
- [lib/infinite_runner/systems/obstacle_pool.dart](lib/infinite_runner/systems/obstacle_pool.dart) - Object pooling implementation
- [lib/infinite_runner/systems/spawn_system.dart](lib/infinite_runner/systems/spawn_system.dart) - Obstacle spawning logic

**Performance**: Target 60 FPS. No allocations in `update()` loop. All Vector2 objects are reused.

### Navigation Structure
Bottom navigation managed by [lib/screens/main_navigation.dart](lib/screens/main_navigation.dart):
1. Home - Game carousel
2. Profile - Stats and achievements
3. Leaderboard - Firebase leaderboard

### Image Loading
**UnsplashService** ([lib/services/unsplash_service.dart](lib/services/unsplash_service.dart)) fetches random images. Falls back to local assets if API key not configured.

API key configuration: Pass via `--dart-define=UNSPLASH_ACCESS_KEY=key` (see [docs/API_CONFIGURATION.md](docs/API_CONFIGURATION.md))

### Game Models
- **GameModel** ([lib/models/game_model.dart](lib/models/game_model.dart)) - Defines available games
- **AchievementModel** ([lib/models/achievement_model.dart](lib/models/achievement_model.dart)) - Achievement definitions
- **PuzzlePiece** ([lib/models/puzzle_piece.dart](lib/models/puzzle_piece.dart)) - Puzzle tile data

## Key Patterns

### Provider Pattern
When adding new game features:
1. Create a provider extending `ChangeNotifier`
2. Register in [lib/main.dart](lib/main.dart) `MultiProvider`
3. Use `context.watch<Provider>()` for UI updates
4. Call `notifyListeners()` after state changes

### Saving Game Stats
All games should save stats via `FirebaseStatsService`:
```dart
await _statsService.saveUserStats(
  userId: userId,
  displayName: displayName,
  gameType: 'game_name',  // e.g., 'puzzle', '2048', 'snake', 'infinite_runner'
  score: score,
);
```

### Achievement System
Record completions via `AchievementService`:
```dart
final newAchievements = await _achievementService.recordGameCompletion(
  gridSize: gridSize,
  moves: moves,
  seconds: seconds,
);
```

## CI/CD
GitHub Actions workflows in [.github/workflows/](.github/workflows/):
- **ci.yml** - Runs tests on every push
- **build.yml** - Builds Android APK, Windows, and Web
- **deploy-web.yml** - Deploys to GitHub Pages
- **release.yml** - Creates releases with downloadable builds

See [docs/CI_CD_SETUP_COMPLETE.md](docs/CI_CD_SETUP_COMPLETE.md) for setup details.

## Testing Strategy
- **Unit tests**: Models, services, game logic
- **Widget tests**: UI components
- **Integration tests**: End-to-end flows (in `integration_test/`)

Mock network images in tests using `network_image_mock` package.

## Asset Management
Assets in [assets/images/](assets/images/):
- Player sprites for infinite runner
- Obstacle sprites (barrier, crate, cone, spikes, walls)
- Background and ground assets

Declared in [pubspec.yaml](pubspec.yaml) under `flutter.assets`.

## Firebase Configuration
Firebase options in `lib/config/firebase_options.dart` (generated via FlutterFire CLI).

For manual setup, see [docs/FIREBASE_SETUP_GUIDE.md](docs/FIREBASE_SETUP_GUIDE.md).

## Additional Documentation
- [docs/INFINITE_RUNNER_ARCHITECTURE.md](docs/INFINITE_RUNNER_ARCHITECTURE.md) - Detailed architecture diagrams
- [docs/API_CONFIGURATION.md](docs/API_CONFIGURATION.md) - Unsplash API setup
- [docs/FIREBASE_SETUP_GUIDE.md](docs/FIREBASE_SETUP_GUIDE.md) - Firebase configuration
- [docs/SECURITY_IMPROVEMENTS.md](docs/SECURITY_IMPROVEMENTS.md) - Security best practices
