# Architecture Documentation

This document provides a comprehensive overview of the MultiGame application architecture, design patterns, and development guidelines.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Dependency Injection](#dependency-injection)
4. [State Management](#state-management)
5. [Repository Pattern](#repository-pattern)
6. [Service Layer](#service-layer)
7. [Game Architecture](#game-architecture)
8. [Data Flow](#data-flow)
9. [Design Patterns](#design-patterns)
10. [Best Practices](#best-practices)

---

## Architecture Overview

MultiGame follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│  (Screens, Widgets, UI Components)      │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         State Management Layer          │
│         (Providers, UI State)           │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Business Logic Layer          │
│    (Services, Game Logic, Validators)   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│            Data Access Layer            │
│    (Repositories, Storage, Firebase)    │
└─────────────────────────────────────────┘
```

### Key Principles

- **Separation of Concerns**: Each layer has a single responsibility
- **Dependency Inversion**: Layers depend on abstractions, not implementations
- **Dependency Injection**: Dependencies are injected, not instantiated
- **Testability**: All components are unit-testable with mocks
- **Modularity**: Games are self-contained modules

---

## Project Structure

### Current Structure (After Refactoring)

```
lib/
├── main.dart                           # App entry point, DI setup
│
├── config/                             # Configuration
│   ├── service_locator.dart           # GetIt DI configuration
│   ├── api_config.dart                # API key management
│   └── firebase_options.dart          # Firebase configuration (gitignored)
│
├── core/                               # Core utilities and interfaces
│   ├── game_interface.dart            # Game metadata interface
│   └── game_registry.dart             # Game registration system
│
├── games/                              # Game modules (feature-based organization)
│   ├── puzzle/                        # Image Puzzle Game
│   │   ├── models/
│   │   │   └── puzzle_piece.dart
│   │   ├── logic/
│   │   │   └── puzzle_game_logic.dart
│   │   ├── services/
│   │   │   └── image_puzzle_generator.dart
│   │   └── providers/
│   │       ├── puzzle_game_provider.dart
│   │       └── puzzle_ui_provider.dart
│   │
│   ├── game_2048/                     # 2048 Game
│   │   ├── models/
│   │   ├── logic/
│   │   └── providers/
│   │       ├── game_2048_provider.dart
│   │       └── game_2048_ui_provider.dart
│   │
│   ├── snake/                         # Snake Game
│   │   ├── models/
│   │   ├── logic/
│   │   └── providers/
│   │       ├── snake_game_provider.dart
│   │       └── snake_ui_provider.dart
│   │
│   └── infinite_runner/               # Infinite Runner (Flame engine)
│       ├── components/                # Flame components (Player, Obstacle, etc.)
│       ├── systems/                   # Game systems (Collision, Spawn, Pool)
│       ├── state/                     # Game and player states
│       └── ui/                        # Game UI overlays
│
├── models/                             # Shared data models
│   ├── game_model.dart                # Game definitions
│   ├── achievement_model.dart         # Achievement definitions
│   └── user_stats_model.dart          # User statistics
│
├── providers/                          # Global state providers
│   ├── user_auth_provider.dart        # User authentication state
│   └── mixins/
│       └── game_stats_mixin.dart      # Shared score-saving logic
│
├── repositories/                       # Data access layer
│   ├── secure_storage_repository.dart # Secure local storage
│   ├── user_repository.dart           # User data persistence
│   ├── stats_repository.dart          # Statistics persistence
│   └── achievement_repository.dart    # Achievement persistence
│
├── services/                           # Business logic services
│   ├── auth/
│   │   └── auth_service.dart          # Authentication logic
│   ├── data/
│   │   ├── firebase_stats_service.dart # Firestore stats operations
│   │   └── achievement_service.dart    # Achievement logic
│   ├── game/
│   │   └── unsplash_service.dart       # Image fetching service
│   └── storage/
│       └── nickname_service.dart       # Nickname persistence
│
├── screens/                            # UI screens
│   ├── main_navigation.dart           # Bottom navigation
│   ├── home_page.dart                 # Game selection
│   ├── profile_screen.dart            # User profile & stats
│   ├── leaderboard_screen.dart        # Global leaderboard
│   ├── puzzle.dart                    # Puzzle game screen
│   ├── game_2048_page.dart            # 2048 game screen
│   ├── snake_game_page.dart           # Snake game screen
│   └── infinite_runner_page.dart      # Runner game screen
│
├── widgets/                            # Reusable widgets
│   ├── game_carousel.dart             # Game selection carousel
│   ├── achievement_card.dart          # Achievement display
│   ├── stat_card.dart                 # Statistics display
│   └── dialogs/                       # Dialog components
│       ├── game_dialog.dart           # Base game dialog
│       ├── achievement_dialog.dart    # Achievement notifications
│       └── settings_dialog.dart       # Settings modal
│
└── utils/                              # Utility functions
    ├── input_validator.dart           # Input validation
    ├── secure_logger.dart             # Secure logging
    ├── storage_migrator.dart          # Data migration utilities
    └── dialog_utils.dart              # Dialog helper methods
```

### Migration Notes

The structure above represents the **target architecture** after completing all refactoring phases. Some modules may still be in the old structure during migration.

---

## Dependency Injection

MultiGame uses **GetIt** for dependency injection, providing:
- Singleton lifecycle management
- Lazy initialization
- Dependency resolution
- Testability through interface injection

### Service Locator Setup

**File:** `lib/config/service_locator.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:puzzle/repositories/secure_storage_repository.dart';
import 'package:puzzle/services/auth/auth_service.dart';
import 'package:puzzle/services/data/firebase_stats_service.dart';
// ... other imports

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Repositories (singleton, lazy)
  getIt.registerLazySingleton<SecureStorageRepository>(
    () => SecureStorageRepository(),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      secureStorage: getIt<SecureStorageRepository>(),
    ),
  );

  getIt.registerLazySingleton<StatsRepository>(
    () => StatsRepositoryImpl(),
  );

  // Services (singleton, lazy)
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(
      userRepository: getIt<UserRepository>(),
    ),
  );

  getIt.registerLazySingleton<FirebaseStatsService>(
    () => FirebaseStatsService(
      statsRepository: getIt<StatsRepository>(),
    ),
  );

  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(
      achievementRepository: getIt<AchievementRepository>(),
    ),
  );

  // ... register all services
}
```

### Initialization in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup dependency injection
  await setupServiceLocator();

  runApp(const MyApp());
}
```

### Using Services in Providers

```dart
class PuzzleGameProvider with ChangeNotifier {
  // Inject services via constructor
  PuzzleGameProvider({
    required this.statsService,
    required this.achievementService,
    required this.imagePuzzleGenerator,
  });

  final FirebaseStatsService statsService;
  final AchievementService achievementService;
  final ImagePuzzleGenerator imagePuzzleGenerator;

  // ... provider implementation
}

// Register provider in main.dart
ChangeNotifierProvider(
  create: (_) => PuzzleGameProvider(
    statsService: getIt<FirebaseStatsService>(),
    achievementService: getIt<AchievementService>(),
    imagePuzzleGenerator: getIt<ImagePuzzleGenerator>(),
  ),
),
```

### Testing with DI

```dart
void main() {
  late PuzzleGameProvider provider;
  late MockFirebaseStatsService mockStatsService;

  setUp(() {
    mockStatsService = MockFirebaseStatsService();
    provider = PuzzleGameProvider(
      statsService: mockStatsService,
      achievementService: MockAchievementService(),
      imagePuzzleGenerator: MockImagePuzzleGenerator(),
    );
  });

  test('should save score on game completion', () async {
    // Arrange
    when(mockStatsService.saveUserStats(...)).thenAnswer((_) async => {});

    // Act
    await provider.completeGame();

    // Assert
    verify(mockStatsService.saveUserStats(...)).called(1);
  });
}
```

---

## State Management

MultiGame uses **Provider** for state management with a clear split between **game state** and **UI state**.

### Game State vs UI State

**Game State (Business Logic):**
- Puzzle grid, moves, timer
- 2048 grid, score, tiles
- Snake position, direction, food
- Runner player state, obstacles

**UI State (Presentation):**
- Loading indicators
- Dialog visibility
- Animation states
- Error messages

### Provider Architecture

```dart
// Game State Provider
class PuzzleGameProvider with ChangeNotifier, GameStatsMixin {
  // Game data
  List<PuzzlePiece> _grid = [];
  int _moves = 0;
  int _seconds = 0;

  // Getters
  List<PuzzlePiece> get grid => _grid;
  int get moves => _moves;
  int get seconds => _seconds;

  // Game logic methods
  void moveTile(int index) {
    // Update game state
    _moves++;
    notifyListeners();
  }

  bool checkWinCondition() {
    // Pure game logic
  }
}

// UI State Provider
class PuzzleUIProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _showAchievementDialog = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get showAchievementDialog => _showAchievementDialog;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void showAchievement() {
    _showAchievementDialog = true;
    notifyListeners();
  }
}
```

### GameStatsMixin (Shared Logic)

```dart
// lib/providers/mixins/game_stats_mixin.dart
mixin GameStatsMixin on ChangeNotifier {
  String? _userId;
  String? _displayName;

  String? get userId => _userId;
  String? get displayName => _displayName;

  void setUserInfo(String userId, String displayName) {
    _userId = userId;
    _displayName = displayName;
    notifyListeners();
  }

  Future<void> saveScore({
    required String gameType,
    required int score,
    required FirebaseStatsService statsService,
  }) async {
    if (_userId == null || _displayName == null) {
      SecureLogger.warning('Cannot save score: user info not set');
      return;
    }

    try {
      await statsService.saveUserStats(
        userId: _userId!,
        displayName: _displayName!,
        gameType: gameType,
        score: score,
      );
      SecureLogger.info('Score saved successfully');
    } catch (e) {
      SecureLogger.error('Failed to save score', error: e);
    }
  }
}
```

### Provider Registration

```dart
// lib/main.dart
MultiProvider(
  providers: [
    // Game providers
    ChangeNotifierProvider(
      create: (_) => PuzzleGameProvider(
        statsService: getIt<FirebaseStatsService>(),
        achievementService: getIt<AchievementService>(),
        imagePuzzleGenerator: getIt<ImagePuzzleGenerator>(),
      ),
    ),
    ChangeNotifierProvider(create: (_) => PuzzleUIProvider()),

    ChangeNotifierProvider(
      create: (_) => Game2048Provider(
        statsService: getIt<FirebaseStatsService>(),
      ),
    ),
    ChangeNotifierProvider(create: (_) => Game2048UIProvider()),

    // Global providers
    ChangeNotifierProvider(
      create: (_) => UserAuthProvider(
        authService: getIt<AuthService>(),
      ),
    ),
  ],
  child: const MyApp(),
);
```

---

## Repository Pattern

The **Repository Pattern** abstracts data access, providing:
- Interface-based design for testability
- Centralized data operations
- Platform-agnostic storage
- Easy migration between storage backends

### Repository Interface

```dart
// Abstract interface
abstract class UserRepository {
  Future<String?> getUserId();
  Future<void> saveUserId(String userId);
  Future<String?> getDisplayName();
  Future<void> saveDisplayName(String displayName);
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

  @override
  Future<void> saveUserId(String userId) async {
    await secureStorage.write(key: 'user_id', value: userId);
  }

  // ... other methods
}
```

### Repository Registration

```dart
// In service_locator.dart
getIt.registerLazySingleton<UserRepository>(
  () => UserRepositoryImpl(
    secureStorage: getIt<SecureStorageRepository>(),
  ),
);
```

### Repository Usage in Services

```dart
class AuthService {
  AuthService({required this.userRepository});

  final UserRepository userRepository;

  Future<UserInfo> getCurrentUser() async {
    final userId = await userRepository.getUserId();
    final displayName = await userRepository.getDisplayName();

    if (userId == null) {
      return await _createAnonymousUser();
    }

    return UserInfo(userId: userId, displayName: displayName ?? 'Player');
  }
}
```

---

## Service Layer

Services contain **business logic** that operates on data from repositories.

### Service Categories

**1. Authentication Services**
- User sign-in/sign-out
- Anonymous authentication
- User profile management

**2. Data Services**
- Firebase operations
- Achievement tracking
- Leaderboard management

**3. Game Services**
- Image fetching (Unsplash)
- Puzzle generation
- Score calculation

**4. Storage Services**
- Nickname persistence
- User preferences
- Cache management

### Service Example

```dart
class AchievementService {
  AchievementService({required this.achievementRepository});

  final AchievementRepository achievementRepository;

  Future<List<AchievementModel>> recordGameCompletion({
    required int gridSize,
    required int moves,
    required int seconds,
  }) async {
    final unlockedAchievements = <AchievementModel>[];

    // Check for newly unlocked achievements
    if (_isFirstVictory()) {
      final achievement = await _unlockAchievement('first_victory');
      unlockedAchievements.add(achievement);
    }

    if (_isSpeedDemon(seconds)) {
      final achievement = await _unlockAchievement('speed_demon');
      unlockedAchievements.add(achievement);
    }

    // ... more checks

    return unlockedAchievements;
  }

  Future<bool> _isFirstVictory() async {
    final completionCount = await achievementRepository.getCompletionCount();
    return completionCount == 0;
  }
}
```

---

## Game Architecture

### Game Module Structure

Each game follows a consistent structure:

```
games/<game_name>/
├── models/              # Game-specific data models
├── logic/               # Pure game logic (no dependencies)
├── services/            # Game-specific services
└── providers/           # State management for the game
```

### Game Registration Pattern

```dart
// lib/core/game_interface.dart
abstract class GameInterface {
  String get id;
  String get displayName;
  IconData get icon;
  String get route;
  Type get providerType;

  void register();
}

// lib/core/game_registry.dart
class GameRegistry {
  static final _games = <String, GameInterface>{};

  static void register(GameInterface game) {
    _games[game.id] = game;
  }

  static GameInterface? getGame(String id) => _games[id];
  static List<GameInterface> getAllGames() => _games.values.toList();
}

// In each game module
class PuzzleGame implements GameInterface {
  @override
  String get id => 'puzzle';

  @override
  String get displayName => 'Image Puzzle';

  @override
  IconData get icon => Icons.extension;

  @override
  String get route => '/puzzle';

  @override
  Type get providerType => PuzzleGameProvider;

  @override
  void register() {
    GameRegistry.register(this);
  }
}

// Initialize in main.dart
void main() {
  // Register all games
  PuzzleGame().register();
  Game2048().register();
  SnakeGame().register();
  InfiniteRunnerGame().register();

  runApp(const MyApp());
}
```

### Infinite Runner Architecture (Flame Engine)

The Infinite Runner uses Flame game engine with ECS-inspired architecture:

**Components:** Player, Obstacle, Background, Ground
**Systems:** CollisionSystem, SpawnSystem, ObstaclePool
**State Machines:** PlayerState, GameState

See [docs/INFINITE_RUNNER_ARCHITECTURE.md](INFINITE_RUNNER_ARCHITECTURE.md) for detailed diagrams.

---

## Data Flow

### Score Saving Flow

```
User completes game
      ↓
Provider calls saveScore() from GameStatsMixin
      ↓
FirebaseStatsService validates data
      ↓
StatsRepository writes to Firestore
      ↓
Achievement Service checks for new achievements
      ↓
AchievementRepository updates local storage
      ↓
UI updates via notifyListeners()
```

### Authentication Flow

```
App starts
      ↓
main.dart initializes Firebase
      ↓
UserAuthProvider checks for existing user
      ↓
AuthService queries UserRepository
      ↓
If no user → sign in anonymously
      ↓
Save user ID to SecureStorageRepository
      ↓
UserAuthProvider notifies listeners
      ↓
UI displays user info
```

---

## Design Patterns

### 1. Repository Pattern
**Purpose:** Abstract data access
**Usage:** All persistence operations
**Benefit:** Testable, swappable storage backends

### 2. Service Locator Pattern
**Purpose:** Dependency injection
**Usage:** GetIt for singleton management
**Benefit:** Loose coupling, testability

### 3. Mixin Pattern
**Purpose:** Code reuse across providers
**Usage:** GameStatsMixin for score saving
**Benefit:** DRY principle, reduces duplication

### 4. Provider Pattern
**Purpose:** State management
**Usage:** All UI state and game state
**Benefit:** Reactive UI, separation of concerns

### 5. Registry Pattern
**Purpose:** Dynamic game registration
**Usage:** GameRegistry for extensibility
**Benefit:** Easy to add new games

### 6. Template Method Pattern
**Purpose:** Reusable dialog components
**Usage:** GameDialog base class
**Benefit:** Consistent UI, reduced code

### 7. Object Pooling Pattern
**Purpose:** Performance optimization
**Usage:** Infinite Runner obstacle pool
**Benefit:** Zero GC allocations during gameplay

---

## Best Practices

### Code Organization

1. **Feature-First Structure**: Organize by feature (games), not by type
2. **Barrel Files**: Use `index.dart` for clean imports
3. **Single Responsibility**: Each class has one clear purpose
4. **Dependency Injection**: Always inject dependencies, never instantiate

### State Management

1. **Split Game/UI State**: Separate business logic from presentation
2. **Use Mixins for Shared Logic**: Avoid code duplication
3. **Immutable State**: Prefer immutable data structures
4. **Selective Rebuilds**: Use Consumer and Selector for performance

### Testing

1. **Test Repositories**: Mock storage backends
2. **Test Services**: Mock repository dependencies
3. **Test Providers**: Mock service dependencies
4. **Widget Tests**: Test UI with mock providers

### Security

1. **Validate All Inputs**: Use InputValidator
2. **Secure Logging**: Use SecureLogger
3. **Encrypt Sensitive Data**: Use SecureStorageRepository
4. **Sanitize Errors**: Don't expose internal details

### Performance

1. **Lazy Loading**: Load services only when needed
2. **Object Pooling**: Reuse objects in game loops
3. **Avoid Allocations**: Minimize GC in update() loops
4. **Profile Regularly**: Use Flutter DevTools

---

## Adding New Features

### Adding a New Game

See [docs/ADDING_GAMES.md](ADDING_GAMES.md) for a complete guide.

### Adding a New Service

1. Define service interface in `lib/services/<category>/`
2. Implement concrete class
3. Register in `lib/config/service_locator.dart`
4. Inject into providers that need it
5. Write unit tests with mocks

### Adding a New Provider

1. Create provider class extending `ChangeNotifier`
2. Add `GameStatsMixin` if it saves scores
3. Inject services via constructor
4. Register in `lib/main.dart` MultiProvider
5. Use in UI with `context.watch<Provider>()`

---

## Migration Guide

If you're migrating from the old architecture:

1. **Phase 1**: Add GetIt and set up service locator
2. **Phase 2**: Create repositories for data access
3. **Phase 3**: Split providers into game/UI state
4. **Phase 4**: Reorganize into feature-based structure
5. **Phase 5**: Implement game registry pattern
6. **Phase 6**: Update tests and documentation

See [task.md](../task.md) for detailed migration steps.

---

## Additional Resources

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Provider Package Documentation](https://pub.dev/packages/provider)
- [GetIt Package Documentation](https://pub.dev/packages/get_it)
- [Flame Engine Documentation](https://docs.flame-engine.org/)
- [SOLID Principles in Dart](https://dart.academy/solid-principles/)

---

## Questions?

For architecture-related questions:
- Review this document and related files
- Check [docs/ADDING_GAMES.md](ADDING_GAMES.md) for game integration
- See [docs/SECURITY.md](SECURITY.md) for security patterns
- Refer to code comments in key files
