# Adding New Games to MultiGame

This guide provides a step-by-step process for adding new games to the MultiGame application. Follow this checklist to ensure proper integration with the existing architecture.

---

## Table of Contents

1. [Before You Start](#before-you-start)
2. [Game Module Setup](#game-module-setup)
3. [Implementing Game Logic](#implementing-game-logic)
4. [State Management](#state-management)
5. [UI Implementation](#ui-implementation)
6. [Integration Steps](#integration-steps)
7. [Testing](#testing)
8. [Documentation](#documentation)
9. [Checklist](#checklist)
10. [Examples](#examples)

---

## Before You Start

### Prerequisites

- Understand the [Architecture](ARCHITECTURE.md)
- Review existing games (puzzle, 2048, snake) as references
- Identify game requirements:
  - Game rules and mechanics
  - Scoring system
  - Win/lose conditions
  - Required assets (images, sprites, sounds)

### Design Decisions

Answer these questions before coding:

1. **State Management:** Does your game need UI state separate from game state?
2. **Dependencies:** What services will your game use? (Firebase, image loading, etc.)
3. **Rendering:** Will you use Flutter widgets or a game engine (like Flame)?
4. **Multiplayer:** Does the game support multiplayer or just single-player?
5. **Persistence:** What data needs to be saved? (scores, progress, settings)

---

## Game Module Setup

### Step 1: Create Game Directory Structure

```bash
# Create game directory
mkdir -p lib/games/your_game

# Create subdirectories
cd lib/games/your_game
mkdir models logic services providers
```

### Step 2: Directory Structure

Your game module should follow this structure:

```
lib/games/your_game/
├── models/                    # Game-specific data models
│   ├── game_state_model.dart
│   └── game_piece_model.dart
│
├── logic/                     # Pure game logic (no dependencies)
│   └── your_game_logic.dart
│
├── services/                  # Game-specific services (optional)
│   └── your_game_service.dart
│
├── providers/                 # State management
│   ├── your_game_provider.dart      # Game state
│   └── your_game_ui_provider.dart   # UI state
│
└── index.dart                 # Barrel file for clean imports
```

### Step 3: Create Barrel File

**File:** `lib/games/your_game/index.dart`

```dart
// Models
export 'models/game_state_model.dart';
export 'models/game_piece_model.dart';

// Logic
export 'logic/your_game_logic.dart';

// Services
export 'services/your_game_service.dart';

// Providers
export 'providers/your_game_provider.dart';
export 'providers/your_game_ui_provider.dart';
```

---

## Implementing Game Logic

### Step 1: Create Game Models

Define data models for your game state:

**File:** `lib/games/your_game/models/game_state_model.dart`

```dart
class YourGameState {
  final int score;
  final int level;
  final bool isGameOver;
  final DateTime startTime;

  YourGameState({
    required this.score,
    required this.level,
    required this.isGameOver,
    required this.startTime,
  });

  // Copy with method for immutability
  YourGameState copyWith({
    int? score,
    int? level,
    bool? isGameOver,
    DateTime? startTime,
  }) {
    return YourGameState(
      score: score ?? this.score,
      level: level ?? this.level,
      isGameOver: isGameOver ?? this.isGameOver,
      startTime: startTime ?? this.startTime,
    );
  }

  // Serialization (if needed for persistence)
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'isGameOver': isGameOver,
      'startTime': startTime.toIso8601String(),
    };
  }

  factory YourGameState.fromJson(Map<String, dynamic> json) {
    return YourGameState(
      score: json['score'] as int,
      level: json['level'] as int,
      isGameOver: json['isGameOver'] as bool,
      startTime: DateTime.parse(json['startTime'] as String),
    );
  }
}
```

### Step 2: Implement Pure Game Logic

Keep game logic separate from Flutter dependencies:

**File:** `lib/games/your_game/logic/your_game_logic.dart`

```dart
class YourGameLogic {
  // Pure functions - no side effects, no state

  /// Check if the game is won
  static bool checkWinCondition(YourGameState state) {
    // Your win condition logic
    return state.score >= 1000;
  }

  /// Check if the game is lost
  static bool checkLoseCondition(YourGameState state) {
    // Your lose condition logic
    return state.level > 10 && state.score == 0;
  }

  /// Calculate score for an action
  static int calculateScore({
    required int currentScore,
    required int actionValue,
    required int multiplier,
  }) {
    return currentScore + (actionValue * multiplier);
  }

  /// Process a game move
  static YourGameState processMove({
    required YourGameState currentState,
    required GameMove move,
  }) {
    // Process the move and return new state
    final newScore = calculateScore(
      currentScore: currentState.score,
      actionValue: move.value,
      multiplier: currentState.level,
    );

    return currentState.copyWith(
      score: newScore,
      isGameOver: checkLoseCondition(currentState),
    );
  }
}
```

### Step 3: Create Game Services (If Needed)

**File:** `lib/games/your_game/services/your_game_service.dart`

```dart
class YourGameService {
  // If your game needs external data or complex operations

  Future<List<GameItem>> loadGameItems() async {
    // Load items from assets or API
  }

  Future<void> saveGameProgress(YourGameState state) async {
    // Save progress to local storage
  }
}
```

---

## State Management

### Step 1: Create Game State Provider

**File:** `lib/games/your_game/providers/your_game_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:puzzle/providers/mixins/game_stats_mixin.dart';
import 'package:puzzle/services/data/firebase_stats_service.dart';
import 'package:puzzle/services/data/achievement_service.dart';
import 'package:puzzle/games/your_game/index.dart';

class YourGameProvider with ChangeNotifier, GameStatsMixin {
  YourGameProvider({
    required this.statsService,
    required this.achievementService,
  });

  final FirebaseStatsService statsService;
  final AchievementService achievementService;

  // Game state
  YourGameState _gameState = YourGameState(
    score: 0,
    level: 1,
    isGameOver: false,
    startTime: DateTime.now(),
  );

  // Getters
  YourGameState get gameState => _gameState;
  int get score => _gameState.score;
  int get level => _gameState.level;
  bool get isGameOver => _gameState.isGameOver;

  /// Start a new game
  void startNewGame() {
    _gameState = YourGameState(
      score: 0,
      level: 1,
      isGameOver: false,
      startTime: DateTime.now(),
    );
    notifyListeners();
  }

  /// Process a game move
  void makeMove(GameMove move) {
    if (_gameState.isGameOver) return;

    _gameState = YourGameLogic.processMove(
      currentState: _gameState,
      move: move,
    );

    if (_gameState.isGameOver) {
      _handleGameOver();
    }

    notifyListeners();
  }

  /// Handle game over
  Future<void> _handleGameOver() async {
    // Save score using mixin method
    await saveScore(
      gameType: 'your_game',
      score: _gameState.score,
      statsService: statsService,
    );

    // Check for achievements
    final newAchievements = await achievementService.recordGameCompletion(
      gridSize: _gameState.level,
      moves: 0, // Adjust based on your game
      seconds: DateTime.now().difference(_gameState.startTime).inSeconds,
    );

    // Handle new achievements (emit event or update UI state)
  }

  /// Reset game state
  void reset() {
    startNewGame();
  }
}
```

### Step 2: Create UI State Provider

**File:** `lib/games/your_game/providers/your_game_ui_provider.dart`

```dart
import 'package:flutter/foundation.dart';

class YourGameUIProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isPaused = false;
  bool _showVictoryDialog = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPaused => _isPaused;
  bool get showVictoryDialog => _showVictoryDialog;
  String? get errorMessage => _errorMessage;

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Pause/resume game
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  /// Show victory dialog
  void showVictory() {
    _showVictoryDialog = true;
    notifyListeners();
  }

  /// Hide victory dialog
  void hideVictory() {
    _showVictoryDialog = false;
    notifyListeners();
  }

  /// Show error message
  void showError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

### Step 3: Register Providers

**File:** `lib/config/service_locator.dart` (if services are needed)

```dart
// Register any game-specific services
getIt.registerLazySingleton<YourGameService>(
  () => YourGameService(),
);
```

**File:** `lib/main.dart`

```dart
MultiProvider(
  providers: [
    // ... existing providers

    // Your game providers
    ChangeNotifierProvider(
      create: (_) => YourGameProvider(
        statsService: getIt<FirebaseStatsService>(),
        achievementService: getIt<AchievementService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => YourGameUIProvider(),
    ),
  ],
  child: const MyApp(),
);
```

---

## UI Implementation

### Step 1: Create Game Screen

**File:** `lib/screens/your_game_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puzzle/games/your_game/index.dart';

class YourGamePage extends StatefulWidget {
  const YourGamePage({Key? key}) : super(key: key);

  @override
  State<YourGamePage> createState() => _YourGamePageState();
}

class _YourGamePageState extends State<YourGamePage> {
  @override
  void initState() {
    super.initState();
    // Initialize game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<YourGameProvider>().startNewGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<YourGameProvider>().reset();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScoreBar(),
          Expanded(child: _buildGameArea()),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Consumer<YourGameProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Score: ${provider.score}'),
              Text('Level: ${provider.level}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameArea() {
    return Consumer<YourGameProvider>(
      builder: (context, provider, child) {
        if (provider.isGameOver) {
          return _buildGameOverScreen();
        }
        return _buildActiveGame();
      },
    );
  }

  Widget _buildActiveGame() {
    // Your game rendering logic
    return const Center(child: Text('Game Area'));
  }

  Widget _buildGameOverScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Game Over!', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 20),
          Consumer<YourGameProvider>(
            builder: (context, provider, child) {
              return Text('Final Score: ${provider.score}');
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<YourGameProvider>().reset();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Consumer<YourGameUIProvider>(
      builder: (context, uiProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: uiProvider.isPaused
                    ? null
                    : () {
                        // Handle game action
                      },
                child: const Text('Action'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Step 2: Add Route

**File:** `lib/screens/main_navigation.dart` or routing configuration

```dart
// Add route for your game
case '/your_game':
  return MaterialPageRoute(builder: (_) => const YourGamePage());
```

---

## Integration Steps

### Step 1: Register Game in Registry

**File:** `lib/core/game_interface.dart` (ensure this exists)

```dart
import 'package:flutter/material.dart';

abstract class GameInterface {
  String get id;
  String get displayName;
  String get description;
  IconData get icon;
  String get route;
  Type get providerType;

  void register();
}
```

**File:** `lib/games/your_game/your_game_registration.dart`

```dart
import 'package:flutter/material.dart';
import 'package:puzzle/core/game_interface.dart';
import 'package:puzzle/core/game_registry.dart';
import 'package:puzzle/games/your_game/providers/your_game_provider.dart';

class YourGame implements GameInterface {
  @override
  String get id => 'your_game';

  @override
  String get displayName => 'Your Game';

  @override
  String get description => 'A brief description of your game';

  @override
  IconData get icon => Icons.gamepad;

  @override
  String get route => '/your_game';

  @override
  Type get providerType => YourGameProvider;

  @override
  void register() {
    GameRegistry.register(this);
  }
}
```

**File:** `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup DI
  await setupServiceLocator();

  // Register games
  PuzzleGame().register();
  Game2048().register();
  SnakeGame().register();
  InfiniteRunnerGame().register();
  YourGame().register(); // ← Add your game

  runApp(const MyApp());
}
```

### Step 2: Add to Game Model

**File:** `lib/models/game_model.dart`

```dart
static List<GameModel> getAllGames() {
  return [
    // ... existing games
    GameModel(
      id: 'your_game',
      name: 'Your Game',
      description: 'A brief description',
      icon: Icons.gamepad,
      color: Colors.purple,
      route: '/your_game',
    ),
  ];
}
```

### Step 3: Add to Navigation

**File:** `lib/screens/home_page.dart` or game selection screen

The game should automatically appear if using `GameRegistry.getAllGames()`.

---

## Testing

### Step 1: Unit Tests for Game Logic

**File:** `test/games/your_game/logic/your_game_logic_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/games/your_game/index.dart';

void main() {
  group('YourGameLogic', () {
    test('should detect win condition', () {
      // Arrange
      final state = YourGameState(
        score: 1000,
        level: 5,
        isGameOver: false,
        startTime: DateTime.now(),
      );

      // Act
      final isWin = YourGameLogic.checkWinCondition(state);

      // Assert
      expect(isWin, true);
    });

    test('should calculate score correctly', () {
      // Arrange
      const currentScore = 100;
      const actionValue = 50;
      const multiplier = 2;

      // Act
      final newScore = YourGameLogic.calculateScore(
        currentScore: currentScore,
        actionValue: actionValue,
        multiplier: multiplier,
      );

      // Assert
      expect(newScore, 200); // 100 + (50 * 2)
    });
  });
}
```

### Step 2: Provider Tests

**File:** `test/games/your_game/providers/your_game_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:puzzle/games/your_game/index.dart';

class MockFirebaseStatsService extends Mock implements FirebaseStatsService {}
class MockAchievementService extends Mock implements AchievementService {}

void main() {
  late YourGameProvider provider;
  late MockFirebaseStatsService mockStatsService;
  late MockAchievementService mockAchievementService;

  setUp(() {
    mockStatsService = MockFirebaseStatsService();
    mockAchievementService = MockAchievementService();
    provider = YourGameProvider(
      statsService: mockStatsService,
      achievementService: mockAchievementService,
    );
  });

  group('YourGameProvider', () {
    test('should start with initial state', () {
      expect(provider.score, 0);
      expect(provider.level, 1);
      expect(provider.isGameOver, false);
    });

    test('should reset game state', () {
      // Arrange
      provider.startNewGame();
      // (make some moves to change state)

      // Act
      provider.reset();

      // Assert
      expect(provider.score, 0);
      expect(provider.level, 1);
      expect(provider.isGameOver, false);
    });
  });
}
```

### Step 3: Widget Tests

**File:** `test/screens/your_game_page_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:puzzle/screens/your_game_page.dart';
import 'package:puzzle/games/your_game/index.dart';

void main() {
  testWidgets('YourGamePage displays score', (tester) async {
    // Arrange
    final provider = YourGameProvider(
      statsService: MockFirebaseStatsService(),
      achievementService: MockAchievementService(),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => YourGameUIProvider()),
          ],
          child: const YourGamePage(),
        ),
      ),
    );

    // Assert
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
```

---

## Documentation

### Step 1: Update CLAUDE.md

Add your game to the project overview:

```markdown
## Game Modules

### Your Game
- **Provider**: `YourGameProvider` - Manages game state, scoring
- **Location**: `lib/games/your_game/`
- **Dependencies**: FirebaseStatsService, AchievementService
```

### Step 2: Add Game-Specific Documentation

If your game has complex mechanics, create:

**File:** `docs/YOUR_GAME_GUIDE.md`

```markdown
# Your Game Guide

## Game Rules
...

## Controls
...

## Scoring System
...
```

### Step 3: Update README

Add your game to the features list in `README.md`.

---

## Checklist

Use this checklist to ensure complete integration:

### Game Implementation
- [ ] Created game directory: `lib/games/your_game/`
- [ ] Created subdirectories: models/, logic/, providers/
- [ ] Implemented game models
- [ ] Implemented pure game logic
- [ ] Created game service (if needed)
- [ ] Created barrel file (`index.dart`)

### State Management
- [ ] Created game state provider
- [ ] Created UI state provider
- [ ] Added `GameStatsMixin` to game provider
- [ ] Registered providers in `main.dart`
- [ ] Injected services via constructor (DI)

### UI
- [ ] Created game screen
- [ ] Implemented score display
- [ ] Implemented game controls
- [ ] Implemented game over screen
- [ ] Added victory/defeat dialogs

### Integration
- [ ] Implemented `GameInterface`
- [ ] Registered game in `GameRegistry`
- [ ] Added to `GameModel.getAllGames()`
- [ ] Added route to navigation
- [ ] Tested navigation to game

### Firebase Integration
- [ ] Saves scores to Firestore
- [ ] Uses correct game type identifier
- [ ] Integrates with achievement system
- [ ] Handles authentication properly

### Testing
- [ ] Unit tests for game logic
- [ ] Unit tests for provider
- [ ] Widget tests for game screen
- [ ] All tests pass: `flutter test`

### Documentation
- [ ] Updated CLAUDE.md
- [ ] Updated README.md
- [ ] Created game guide (if complex)
- [ ] Added code comments

### Quality Checks
- [ ] No analyzer warnings: `flutter analyze`
- [ ] Code formatted: `dart format lib/`
- [ ] Follows project conventions
- [ ] Secure logging implemented
- [ ] Input validation added (if applicable)

---

## Examples

### Simple Example: Coin Flip Game

**Minimal implementation for reference:**

```dart
// lib/games/coin_flip/models/coin_flip_state.dart
class CoinFlipState {
  final String result; // 'heads' or 'tails'
  final int wins;
  final int losses;

  CoinFlipState({required this.result, required this.wins, required this.losses});
}

// lib/games/coin_flip/logic/coin_flip_logic.dart
import 'dart:math';

class CoinFlipLogic {
  static String flipCoin() {
    return Random().nextBool() ? 'heads' : 'tails';
  }

  static bool checkWin(String guess, String result) {
    return guess == result;
  }
}

// lib/games/coin_flip/providers/coin_flip_provider.dart
class CoinFlipProvider with ChangeNotifier, GameStatsMixin {
  CoinFlipState _state = CoinFlipState(result: '', wins: 0, losses: 0);

  CoinFlipState get state => _state;

  void flip(String guess) {
    final result = CoinFlipLogic.flipCoin();
    final isWin = CoinFlipLogic.checkWin(guess, result);

    _state = CoinFlipState(
      result: result,
      wins: isWin ? _state.wins + 1 : _state.wins,
      losses: isWin ? _state.losses : _state.losses + 1,
    );

    notifyListeners();
  }
}
```

### Complex Example: Tower Defense Game

For a complex game like tower defense, see `lib/infinite_runner/` as a reference for:
- Component-based architecture
- Object pooling
- State machines
- Performance optimization

---

## Troubleshooting

### Common Issues

**Issue:** Provider not updating UI
**Solution:** Ensure you call `notifyListeners()` after state changes

**Issue:** Services not injected properly
**Solution:** Check service_locator.dart registration and constructor injection

**Issue:** Game not appearing in carousel
**Solution:** Verify game is registered in GameRegistry and added to GameModel

**Issue:** Scores not saving to Firebase
**Solution:** Check Firebase Auth status, verify gameType matches Firestore rules

---

## Need Help?

- Review existing games: `lib/games/puzzle/`, `lib/games/game_2048/`
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for patterns
- See [SECURITY.md](SECURITY.md) for security guidelines
- Ask in project discussions or open an issue

Happy game development! 🎮
