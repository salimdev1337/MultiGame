# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MultiGame is a Flutter-based multi-platform gaming app featuring:
- **Sudoku** (Classic, Rush, and 1v1 Online modes with difficulty levels)
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

**⚠️ PRODUCTION BUILD WARNING:**
- Current release builds use **debug signing keys** (see `android/app/build.gradle.kts:37`)
- Package name is `com.example.multigame` (invalid for Play Store)
- Must fix before Play Store submission - see [task.md](task.md) Phase 1

### Linting
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```


DO NOT USE withOpacity() use withValues()

## Architecture Overview

MultiGame follows a **clean, layered architecture**:

```
Presentation (Screens/Widgets)
     ↓
State Management (Providers)
     ↓
Business Logic (Services)
     ↓
Data Access (Repositories)
```

### Key Architectural Principles

1. **Dependency Injection**: Services are injected via GetIt, not instantiated
2. **Separation of Concerns**: UI state separate from game state
3. **Repository Pattern**: Abstract data access from business logic
4. **Feature-First Structure**: Games organized as self-contained modules
5. **Testability**: All components mockable for unit tests

### Directory Structure (Refactored)

```
lib/
├── config/                        # Configuration
│   ├── service_locator.dart       # GetIt DI setup
│   ├── api_config.dart            # API key management
│   └── firebase_options.dart      # Firebase (gitignored)
│
├── core/                          # Core interfaces
│   ├── game_interface.dart        # Game registration interface
│   └── game_registry.dart         # Game registry
│
├── games/                         # Feature-based organization
│   ├── sudoku/                    # Sudoku game (3 modes: Classic, Rush, 1v1)
│   │   ├── models/                # Game state models
│   │   ├── logic/                 # Pure game logic (generator, solver, validator)
│   │   ├── providers/             # State management
│   │   ├── services/              # Persistence, stats, sound, haptics
│   │   ├── screens/               # Mode selection, game screens
│   │   └── widgets/               # Grid, cell, number pad, controls
│   ├── puzzle/
│   │   ├── models/
│   │   ├── logic/
│   │   ├── providers/
│   │   └── services/
│   ├── game_2048/
│   ├── snake/
│   └── infinite_runner/
│
├── repositories/                  # Data access layer
│   ├── secure_storage_repository.dart
│   ├── user_repository.dart
│   └── stats_repository.dart
│
├── services/                      # Business logic
│   ├── auth/
│   ├── data/
│   ├── game/
│   └── storage/
│
└── utils/                         # Utilities
    ├── input_validator.dart
    ├── secure_logger.dart
    └── storage_migrator.dart
```

**See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for complete details.**

## Dependency Injection

### GetIt Service Locator

All services are registered as singletons in `lib/config/service_locator.dart`:

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Repositories
  getIt.registerLazySingleton<SecureStorageRepository>(
    () => SecureStorageRepository(),
  );

  // Services with injected dependencies
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(userRepository: getIt<UserRepository>()),
  );

  // ... more registrations
}
```

Initialized in `main.dart` before `runApp()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupServiceLocator(); // ← DI setup
  runApp(const MyApp());
}
```

### Using Services in Code

**❌ DON'T instantiate services directly:**
```dart
class MyProvider {
  final service = FirebaseStatsService(); // WRONG
}
```

**✅ DO inject via constructor:**
```dart
class MyProvider {
  MyProvider({required this.service});
  final FirebaseStatsService service;
}

// In provider registration:
ChangeNotifierProvider(
  create: (_) => MyProvider(
    service: getIt<FirebaseStatsService>(),
  ),
);
```

## State Management

The app uses **Provider** for state management with **separation of game state and UI state**:

**Game State Providers** (business logic):
- **SudokuProvider** - Classic mode: board state, moves, hints, validation
- **SudokuRushProvider** - Rush mode: timer, score, difficulty progression
- **SudokuOnlineProvider** - 1v1 mode: matchmaking, opponent sync, game state
- **PuzzleGameProvider** - Puzzle grid, moves, timer, game logic
- **Game2048Provider** - 2048 grid, score, tile operations
- **SnakeGameProvider** - Snake position, direction, food, collisions

**UI State Providers** (presentation):
- **SudokuUIProvider** - Loading state, dialogs, animations for sudoku
- **PuzzleUIProvider** - Loading state, dialogs, animations
- **Game2048UIProvider** - UI state for 2048 game
- **SnakeUIProvider** - UI state for snake game

**Global Settings Providers**:
- **SudokuSettingsProvider** - User preferences (sound, haptics, theme) - injected via GetIt

**Global Providers**:
- **UserAuthProvider** - User authentication and profile

All providers are registered in [lib/main.dart](lib/main.dart) using `MultiProvider` with injected services.

### Repository Pattern

The **Repository Pattern** abstracts data persistence:

```dart
// Abstract interface for testability
abstract class UserRepository {
  Future<String?> getUserId();
  Future<void> saveUserId(String userId);
  Future<void> clearUserData();
}

// Concrete implementation
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required this.secureStorage});
  final SecureStorageRepository secureStorage;

  @override
  Future<String?> getUserId() async {
    return await secureStorage.read(key: 'user_id');
  }
  // ... other methods
}
```

Repositories registered in `service_locator.dart`, used by services.

### Firebase Integration

The app initializes Firebase in [lib/main.dart](lib/main.dart) with anonymous authentication by default. A persistent user ID is stored **securely** to maintain user identity across sessions.

**Important:**
- Firebase Auth is required for Firestore access
- App signs in anonymously on startup if no user is authenticated
- User data is encrypted using Flutter Secure Storage

**Service Layer** ([lib/services/](lib/services/)):
- **auth/** - AuthService for user authentication
- **data/** - FirebaseStatsService, AchievementService (Firestore operations)
- **game/** - UnsplashService (image fetching)
- **storage/** - NicknameService (persistent storage)

### Sudoku Game Architecture

The Sudoku game features **three game modes** with complete state management and persistence:

**Game Modes:**
1. **Classic Mode** - Traditional sudoku with difficulty levels (Easy, Medium, Hard, Expert)
2. **Rush Mode** - Time-limited challenges with progressive difficulty
3. **1v1 Online** - Real-time multiplayer via Firebase (matchmaking + live gameplay)

**Key Features:**
- **Pure Logic Layer**: Generator, solver, and validator are pure functions (no dependencies)
- **Auto-save**: Games automatically save progress using secure local storage
- **Statistics Tracking**: Personal stats and global leaderboards via Firebase
- **Sound & Haptics**: Configurable audio feedback and vibration (Phase 6 polish)
- **Settings System**: Persistent user preferences for sound, haptics, and difficulty
- **Online Multiplayer** (1v1 mode):
  - Room code matchmaking (6-digit PIN codes)
  - Real-time opponent sync with debounced Firestore writes (80-90% cost reduction)
  - Hints system (3 per game, pre-solved board) with in-game UI
  - Connection handling with automatic reconnection (60s grace period)
  - Heartbeat monitoring (5-second intervals)
  - Opponent stats tracking (mistakes, hints used, connection state)
  - Live connection status indicators (color-coded dots for online/offline/reconnecting)
  - Real-time opponent stat display in game UI

**Architecture:**
```
lib/games/sudoku/
├── models/           # Data models (cell, board, stats, match)
├── logic/            # Pure functions (generator, solver, validator)
├── services/         # Persistence, stats, matchmaking, sound, haptics
├── providers/        # State management (Classic, Rush, Online, UI, Settings)
├── screens/          # Mode selection, difficulty, game screens
└── widgets/          # Reusable UI components (grid, cell, number pad)
```

**Providers:**
- **SudokuProvider** - Classic mode game state
- **SudokuRushProvider** - Rush mode with timer
- **SudokuOnlineProvider** - 1v1 multiplayer state
- **SudokuUIProvider** - UI state (loading, dialogs)
- **SudokuSettingsProvider** - User preferences (injected via GetIt)

**Services:**
- **SudokuPersistenceService** - Save/load games from secure storage
- **SudokuStatsService** - Track personal statistics
- **MatchmakingService** - Firebase-based matchmaking with room codes, connection state tracking, and player stats sync
- **SudokuSoundService** - Audio feedback (Phase 6)
- **SudokuHapticService** - Vibration feedback (Phase 6)

**Files:**
- [lib/games/sudoku/sudoku_game_definition.dart](lib/games/sudoku/sudoku_game_definition.dart) - Game registry definition
- [lib/games/sudoku/screens/mode_selection_screen.dart](lib/games/sudoku/screens/mode_selection_screen.dart) - Choose Classic/Rush/1v1
- [lib/games/sudoku/logic/sudoku_generator.dart](lib/games/sudoku/logic/sudoku_generator.dart) - Puzzle generation algorithm
- [lib/games/sudoku/logic/sudoku_solver.dart](lib/games/sudoku/logic/sudoku_solver.dart) - Backtracking solver
- [lib/games/sudoku/logic/sudoku_validator.dart](lib/games/sudoku/logic/sudoku_validator.dart) - Rule validation

**Testing:**
- Comprehensive unit tests for generator, solver, validator
- Model tests for board and cell logic
- Provider tests with mocked services

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
1. **Home** - Game carousel with available games:
   - Sudoku (Classic, Rush, 1v1 Online)
   - Infinite Runner
   - Snake
   - Image Puzzle
   - 2048
   - Memory Game (coming soon - locked)
2. **Profile** - Stats and achievements
3. **Leaderboard** - Firebase global leaderboard

### Image Loading

**UnsplashService** ([lib/services/unsplash_service.dart](lib/services/unsplash_service.dart)) fetches random images. Falls back to local assets if API key not configured.

API key configuration: Pass via `--dart-define=UNSPLASH_ACCESS_KEY=key` (see [docs/API_CONFIGURATION.md](docs/API_CONFIGURATION.md))

### Game Models

- **GameModel** ([lib/models/game_model.dart](lib/models/game_model.dart)) - Defines available games
- **AchievementModel** ([lib/models/achievement_model.dart](lib/models/achievement_model.dart)) - Achievement definitions
- **PuzzlePiece** ([lib/models/puzzle_piece.dart](lib/models/puzzle_piece.dart)) - Puzzle tile data

## Security Best Practices

**CRITICAL:** Follow these security guidelines at all times:

### Secure Storage

```dart
// ✅ DO: Use SecureStorageRepository for sensitive data
final storage = getIt<SecureStorageRepository>();
await storage.write(key: 'user_token', value: token);

// ❌ DON'T: Use SharedPreferences for sensitive data
await prefs.setString('user_token', token); // INSECURE
```

### Input Validation

```dart
// ✅ DO: Validate all user inputs
import 'package:puzzle/utils/input_validator.dart';

final error = InputValidator.validateNickname(userInput);
if (error != null) {
  showError(error);
  return;
}
```

### Secure Logging

```dart
// ✅ DO: Use SecureLogger (auto-redacts secrets)
import 'package:puzzle/utils/secure_logger.dart';

SecureLogger.info('User logged in', data: {'userId': id, 'token': token});
// Output: ... userId: abc123 | token: [REDACTED]

// ❌ DON'T: Use print or debugPrint directly
print('Token: $token'); // INSECURE - may leak in logs
```

### API Key Management

```dart
// ✅ DO: Use build-time configuration
flutter run --dart-define=UNSPLASH_ACCESS_KEY=key

// Access in code:
const key = String.fromEnvironment('UNSPLASH_ACCESS_KEY');

// ❌ DON'T: Hardcode keys in code
const key = 'abc123...'; // NEVER DO THIS
```

### Firebase Security

- **firebase_options.dart is gitignored** - never commit it
- **Security rules deployed** - see [firestore.rules](firestore.rules)
- **Anonymous auth required** - users must be authenticated

**See [docs/SECURITY.md](docs/SECURITY.md) for complete security documentation.**

## Key Patterns

### Provider Pattern (Game State + UI State)

When adding new game features:

**1. Create Game State Provider (business logic):**
```dart
class YourGameProvider with ChangeNotifier, GameStatsMixin {
  YourGameProvider({required this.statsService});
  final FirebaseStatsService statsService;

  // Game state only
  int _score = 0;
  bool _isGameOver = false;

  void makeMove() {
    _score++;
    notifyListeners();
  }
}
```

**2. Create UI State Provider (presentation):**
```dart
class YourGameUIProvider with ChangeNotifier {
  bool _isLoading = false;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
```

**3. Register both providers:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => YourGameProvider(
        statsService: getIt<FirebaseStatsService>(),
      ),
    ),
    ChangeNotifierProvider(create: (_) => YourGameUIProvider()),
  ],
  // ...
)
```

**4. Use in UI:**
```dart
// Watch game state
final score = context.watch<YourGameProvider>().score;

// Watch UI state
final isLoading = context.watch<YourGameUIProvider>().isLoading;
```

### GameStatsMixin (DRY Principle)

Use the `GameStatsMixin` to avoid duplicate score-saving code:

```dart
class YourGameProvider with ChangeNotifier, GameStatsMixin {
  // Mixin provides:
  // - setUserInfo(String userId, String displayName)
  // - saveScore({required String gameType, required int score})

  Future<void> handleGameOver() async {
    await saveScore(
      gameType: 'your_game',  // 'puzzle', '2048', 'snake', 'infinite_runner'
      score: _score,
      statsService: _statsService,
    );
  }
}
```

**Benefits:** Eliminates ~250 lines of duplicate code across providers.

### Saving Game Stats

All games save stats via `FirebaseStatsService` (use mixin method):
```dart
// Via GameStatsMixin (preferred):
await saveScore(
  gameType: 'game_name',
  score: score,
  statsService: statsService,
);

// Or directly:
await statsService.saveUserStats(
  userId: userId,
  displayName: displayName,
  gameType: 'game_name',
  score: score,
);
```

### Achievement System

Record completions via `AchievementService` (injected via DI):
```dart
final newAchievements = await achievementService.recordGameCompletion(
  gridSize: gridSize,
  moves: moves,
  seconds: seconds,
);

// Display new achievements to user
if (newAchievements.isNotEmpty) {
  // Show achievement dialog
}
```

## Adding New Games

**Quick Reference** - See [docs/ADDING_GAMES.md](docs/ADDING_GAMES.md) for complete guide.

### Structure

```
lib/games/your_game/
├── models/              # Game data models
├── logic/               # Pure game logic (testable)
├── services/            # Game-specific services
├── providers/           # State management
│   ├── your_game_provider.dart      # Game state
│   └── your_game_ui_provider.dart   # UI state
└── index.dart          # Barrel file
```

### Steps

1. Create game directory structure
2. Implement game logic (pure functions, no dependencies)
3. Create models for game state
4. Create providers (game + UI)
5. Inject services via constructor
6. Register providers in `main.dart`
7. Create game screen
8. Register game in `GameRegistry`
9. Add tests
10. Update documentation

**Example:** See [lib/games/sudoku/](lib/games/sudoku/) for a complete implementation with multiple game modes, persistence, and online multiplayer.

**Full guide:** [docs/ADDING_GAMES.md](docs/ADDING_GAMES.md)

## Testing Strategy

- **Unit tests**: Models, services, game logic (pure functions)
- **Provider tests**: Mock injected services using interfaces
- **Widget tests**: UI components with mock providers
- **Integration tests**: End-to-end flows (in `integration_test/`)

### Testing with DI

```dart
// Mock services for testing
class MockFirebaseStatsService extends Mock implements FirebaseStatsService {}

void main() {
  late YourGameProvider provider;
  late MockFirebaseStatsService mockService;

  setUp(() {
    mockService = MockFirebaseStatsService();
    provider = YourGameProvider(statsService: mockService);
  });

  test('should save score on game over', () async {
    // Arrange
    when(mockService.saveUserStats(...)).thenAnswer((_) async => {});

    // Act
    await provider.handleGameOver();

    // Assert
    verify(mockService.saveUserStats(...)).called(1);
  });
}
```

Mock network images in tests using `network_image_mock` package.

## CI/CD

GitHub Actions workflows in [.github/workflows/](.github/workflows/):
- **ci.yml** - Runs tests on every push
- **build.yml** - Builds Android APK, Windows, and Web
- **deploy-web.yml** - Deploys to GitHub Pages
- **release.yml** - Creates releases with downloadable builds

See [docs/CI_CD_SETUP_COMPLETE.md](docs/CI_CD_SETUP_COMPLETE.md) for setup details.

## Asset Management

Assets in [assets/images/](assets/images/):
- Player sprites for infinite runner
- Obstacle sprites (barrier, crate, cone, spikes, walls)
- Background and ground assets

Declared in [pubspec.yaml](pubspec.yaml) under `flutter.assets`.

## Firebase Configuration

Firebase options in `lib/config/firebase_options.dart` (generated via FlutterFire CLI).

For manual setup, see [docs/FIREBASE_SETUP_GUIDE.md](docs/FIREBASE_SETUP_GUIDE.md).

## Code Quality Guidelines

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `camelCase` or `SCREAMING_SNAKE_CASE` for compile-time constants

### Code Organization

1. **Imports** in order: dart, flutter, packages, relative
2. **One class per file** (except small helper classes)
3. **Barrel files** for clean imports: `index.dart` in each module
4. **Documentation comments** on public APIs

### Error Handling

```dart
// ✅ DO: Handle errors gracefully
try {
  await service.operation();
} catch (e, stackTrace) {
  SecureLogger.error('Operation failed', error: e, stackTrace: stackTrace);
  // Show user-friendly message
}

// ❌ DON'T: Swallow errors silently
try {
  await service.operation();
} catch (e) {
  // Empty catch - BAD
}
```

### Performance

1. **Avoid allocations in game loops** (60 FPS requirement)
2. **Use object pooling** for frequently created objects
3. **Profile with DevTools** before optimizing
4. **Lazy-load services** via GetIt

## Production Readiness

**Current Status:** ⚠️ NOT READY FOR PLAY STORE SUBMISSION
**Assessment Date:** 2026-02-05
**Overall Score:** 6.5/10

### Critical Blockers (Must Fix Before Submission)
1. **Invalid package name** (`com.example.multigame`) - Play Store will reject
2. **Debug signing keys** in production build - Cannot submit
3. **Missing privacy policy** - Required by Play Store

### High Priority Issues
1. Exposed Firebase API keys (already in git history)
2. Debug print statements in production code
3. Silent error handling (no user notifications)
4. Incomplete Firestore security rules

### Production Readiness Checklist
See **[task.md](task.md)** for comprehensive production readiness plan with:
- ✅ Phase 1: Critical Blockers (package name, signing, privacy policy)
- ⚠️ Phase 2: High Priority Fixes (security, error handling, logging)
- 🔧 Phase 3: Quality & Testing (coverage, device testing, crashlytics)
- 🎨 Phase 4: Store Preparation (assets, listing, beta testing)
- 🚀 Phase 5: CI/CD & Automation (optional)

**IMPORTANT:** Before submitting to Play Store, complete at minimum Phase 1 + Phase 2 (estimated 3-5 days).

### Strengths
- ⭐ World-class architecture (9/10)
- ⭐ Competitive feature set - 5 games with online multiplayer (9/10)
- ⭐ Above-average code quality with comprehensive docs (7.5/10)
- ⭐ Good security foundation (SecureLogger, SecureStorage, Firebase rules) (7/10)

### Weaknesses
- 🔴 Incomplete release configuration (3/10)
- 🔴 Missing legal compliance (privacy policy, ToS) (2/10)
- 🟠 Error handling needs improvement (5/10)
- 🟠 Testing adequate but not comprehensive (6/10)

### Next Steps
1. **Immediate:** Fix package name to unique reverse-domain format
2. **Urgent:** Generate production keystore and configure signing
3. **Required:** Create and publish privacy policy
4. **High Priority:** Rotate Firebase keys, replace debugPrint, add error notifications
5. **Recommended:** Complete testing, add crashlytics, prepare store assets

**Full Details:** See [task.md](task.md) for detailed implementation guide with commands, code examples, and checklists.

---

## Additional Documentation

### Architecture & Design
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Complete architecture guide
- [docs/ADDING_GAMES.md](docs/ADDING_GAMES.md) - Game integration guide
- [docs/SECURITY.md](docs/SECURITY.md) - Security best practices

### Setup & Configuration
- [docs/API_CONFIGURATION.md](docs/API_CONFIGURATION.md) - Unsplash API setup
- [docs/FIREBASE_SETUP_GUIDE.md](docs/FIREBASE_SETUP_GUIDE.md) - Firebase configuration
- [docs/CI_CD_SETUP_COMPLETE.md](docs/CI_CD_SETUP_COMPLETE.md) - GitHub Actions

### Production & Release
- **[task.md](task.md)** - Production readiness tasks and deployment guide
- [firestore.rules](firestore.rules) - Firebase security rules

### Technical Deep Dives
- [docs/INFINITE_RUNNER_ARCHITECTURE.md](docs/INFINITE_RUNNER_ARCHITECTURE.md) - Flame engine architecture
- [docs/SECURITY_IMPROVEMENTS.md](docs/SECURITY_IMPROVEMENTS.md) - Security changelog


      IMPORTANT: this context may or may not be relevant to your tasks. You should not respond to this context unless it is highly relevant to your task.
