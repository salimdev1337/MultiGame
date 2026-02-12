# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MultiGame is a Flutter multi-platform gaming app with:
- **5 Games:** Sudoku (Classic/Rush/1v1 Online), 2048, Snake, Image Puzzle, Infinite Runner (Flame engine)
- **Premium UI:** 13,950+ lines of polished design system (glassmorphic, animations, charts)
- **Backend:** Firebase (auth, Firestore stats, leaderboards)
- **Architecture:** Clean layered with DI (GetIt), Provider state management, Repository pattern

## Development Commands

### Essential Commands
```bash
# Setup
flutter pub get
flutter run  # Uses fallback images without API key
flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key

# Testing
flutter test                              # All tests
flutter test test/game_2048_test.dart     # Specific test
flutter test --coverage                    # With coverage

# Build
flutter build apk --release               # Android APK
flutter build appbundle --release         # Android bundle
flutter build web --release               # Web

# Quality
flutter analyze
dart format lib/ test/
```

**⚠️ CRITICAL:** DO NOT USE `withOpacity()` - use `withValues()` instead

**⚠️ PRODUCTION WARNING:** Current builds use debug keys and `com.example.multigame` package name. See [task.md](task.md) before Play Store submission.

## Architecture Essentials

### Layered Architecture
```
Presentation (Screens/Widgets)
     ↓
State Management (Providers)
     ↓
Business Logic (Services)
     ↓
Data Access (Repositories)
```

### Key Principles
1. **Dependency Injection:** Services injected via GetIt, never instantiated directly
2. **Separation of Concerns:** Game state providers separate from UI providers
3. **Repository Pattern:** Abstract data access from business logic
4. **Feature-First:** Games organized as self-contained modules
5. **Testability:** All components mockable

### Directory Structure (Simplified)
```
lib/
├── config/               # DI setup, API config, Firebase options
├── core/                 # Game interface, registry
├── design_system/        # DSColors, DSTypography, DSSpacing, DSShadows, DSAnimations, DSTheme
├── widgets/
│   ├── shared/          # Premium components (buttons, cards, toasts, empty states)
│   └── profile/         # Stats visualizations, achievement gallery, history timeline
├── games/               # Feature modules (sudoku, puzzle, 2048, snake, infinite_runner)
│   └── [game]/
│       ├── models/      # Data models
│       ├── logic/       # Pure functions (testable)
│       ├── providers/   # State management (game + UI providers)
│       ├── services/    # Game-specific services
│       └── widgets/     # UI components + animations
├── repositories/        # Data access layer
├── services/
│   ├── auth/           # Authentication
│   ├── data/           # Firebase stats, achievements
│   ├── feedback/       # Haptics, sound
│   └── storage/        # Persistence
└── utils/              # Validators, logging, migrations
```

**Full details:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Critical Patterns

### 1. Dependency Injection (GetIt)

**❌ WRONG:**
```dart
class MyProvider {
  final service = FirebaseStatsService(); // NEVER DO THIS
}
```

**✅ CORRECT:**
```dart
class MyProvider {
  MyProvider({required this.service});
  final FirebaseStatsService service;
}

// Registration in main.dart:
ChangeNotifierProvider(
  create: (_) => MyProvider(service: getIt<FirebaseStatsService>()),
)
```

### 2. State Management (Provider)

**Separate game state from UI state:**
- `GameProvider` - Business logic (score, moves, game state)
- `GameUIProvider` - Presentation (loading, dialogs, animations)

**Use GameStatsMixin to avoid duplicate code:**
```dart
class MyGameProvider with ChangeNotifier, GameStatsMixin {
  Future<void> handleGameOver() async {
    await saveScore(gameType: 'game_name', score: _score, statsService: _statsService);
  }
}
```

### 3. Security (CRITICAL)

**Secure Storage:**
```dart
// ✅ DO: Use SecureStorageRepository for sensitive data
final storage = getIt<SecureStorageRepository>();
await storage.write(key: 'user_token', value: token);

// ❌ DON'T: Use SharedPreferences for sensitive data
```

**Secure Logging:**
```dart
// ✅ DO: Use SecureLogger (auto-redacts secrets)
SecureLogger.info('User logged in', data: {'token': token}); // token: [REDACTED]

// ❌ DON'T: Use print() - leaks in logs
```

**API Keys:**
```dart
// ✅ DO: Build-time configuration
const key = String.fromEnvironment('UNSPLASH_ACCESS_KEY');

// ❌ DON'T: Hardcode keys
```

**See [docs/SECURITY.md](docs/SECURITY.md) for complete guide.**

## Design System (Phase 1-6 Complete)

**Status:** 13,950+ lines of premium UI code across 6 phases

**Core System (`lib/design_system/`):**
- **DSColors** - Brand, semantic, game-specific colors + gradients
- **DSTypography** - Google Fonts (Poppins, Inter, Roboto Mono)
- **DSSpacing** - 4px grid system
- **DSShadows** - Elevation + colored glows
- **DSAnimations** - Durations, curves, configs
- **DSTheme** - Master theme builder

**Premium Components:**
- **Phase 1-3:** Buttons, cards, skeletons, game carousel, floating nav, game animations
- **Phase 4:** Profile headers, stat cards, charts, heat maps, achievement gallery
- **Phase 5:** Leaderboard podium, crown animations, rank cards, time filters
- **Phase 6:** Toast notifications, empty states, loading overlays, haptic/sound services

**Usage:**
```dart
import 'package:multigame/design_system/design_system.dart';

// Use tokens
Container(
  padding: DSSpacing.paddingMD,
  decoration: BoxDecoration(
    color: DSColors.surface,
    borderRadius: DSSpacing.borderRadiusLG,
    boxShadow: DSShadows.shadowMd,
  ),
  child: Text('Content', style: DSTypography.titleLarge),
)

// Premium components
DSButton.gradient(
  text: 'Start Game',
  gradient: DSColors.gradientPrimary,
  onPressed: () => startGame(),
)

// Phase 6 feedback
final haptics = getIt<HapticFeedbackService>();
await haptics.success();

context.showSuccessToast('Level completed!');

DSEmptyState.noData(actionLabel: 'Retry', onAction: () => retry())
```

**Full phase details:** [docs/UI_UX_REDESIGN_PLAN.md](docs/UI_UX_REDESIGN_PLAN.md)

## Game-Specific Architectures

### Sudoku (3 Modes)
- **Classic:** Traditional with difficulty levels
- **Rush:** Time-limited progressive difficulty
- **1v1 Online:** Real-time multiplayer via Firebase (room codes, hints, connection tracking)

**Architecture:** Pure logic layer (generator, solver, validator) + providers (Classic, Rush, Online, UI, Settings) + services (persistence, stats, matchmaking, sound, haptics)

### Infinite Runner (Flame Engine)
- **Object Pooling:** 60 pre-allocated obstacles (eliminates GC pauses)
- **ECS-inspired:** Component-based with systems (CollisionSystem, SpawnSystem, ObstaclePool)
- **Performance:** 60 FPS target, no allocations in update() loop, Vector2 reuse

**Details:** [docs/INFINITE_RUNNER_ARCHITECTURE.md](docs/INFINITE_RUNNER_ARCHITECTURE.md)

## Testing Strategy

- **Unit tests:** Pure functions, models, services
- **Provider tests:** Mock injected services via interfaces
- **Widget tests:** UI components with mock providers
- **Integration tests:** End-to-end flows

**Mock services for testing:**
```dart
class MockFirebaseStatsService extends Mock implements FirebaseStatsService {}

test('should save score', () async {
  final mockService = MockFirebaseStatsService();
  when(mockService.saveUserStats(...)).thenAnswer((_) async => {});

  final provider = MyProvider(statsService: mockService);
  await provider.handleGameOver();

  verify(mockService.saveUserStats(...)).called(1);
});
```

## Adding New Games

**Quick Steps:**
1. Create directory structure: `lib/games/your_game/{models,logic,providers,services}`
2. Implement pure logic (no dependencies)
3. Create game + UI providers with injected services
4. Register providers in `main.dart`
5. Register in `GameRegistry`
6. Add tests

**Full guide:** [docs/ADDING_GAMES.md](docs/ADDING_GAMES.md)

## Code Quality Guidelines

### Naming
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/Functions:** `camelCase`

### Organization
1. Imports order: dart, flutter, packages, relative
2. One class per file (except small helpers)
3. Barrel files (`index.dart`) for clean imports
4. Documentation on public APIs

### Error Handling
```dart
// ✅ DO: Handle gracefully
try {
  await service.operation();
} catch (e, stackTrace) {
  SecureLogger.error('Operation failed', error: e, stackTrace: stackTrace);
  // Show user-friendly message
}

// ❌ DON'T: Swallow silently
```

### Performance
- Avoid allocations in game loops (60 FPS requirement)
- Use object pooling for frequently created objects
- Profile with DevTools before optimizing
- Lazy-load services via GetIt

## Production Readiness

**Status:** ⚠️ NOT READY FOR PLAY STORE (Updated 2026-02-09)
**Overall Score:** 7.5/10

**Critical Blockers (Must Fix):**
1. Invalid package name (`com.example.multigame`)
2. Debug signing keys in production
3. Missing privacy policy

**Strengths:**
- ⭐ World-class architecture (9/10)
- ⭐ Premium UI/UX - 13,950+ lines, 30+ animations (9.5/10)
- ⭐ Complete feedback systems (9.5/10)
- ⭐ Rich data visualization (9/10)
- ⭐ Good security foundation (7/10)

**Weaknesses:**
- 🔴 Incomplete release configuration (3/10)
- 🔴 Missing legal compliance (2/10)
- 🟠 Error handling needs improvement (5/10)

**Action Required:** Complete Phase 1-2 in [task.md](task.md) before Play Store submission (3-5 days).

## CI/CD

GitHub Actions workflows:
- **ci.yml** - Tests on every push
- **build.yml** - Builds Android/Windows/Web
- **deploy-web.yml** - GitHub Pages deployment
- **release.yml** - Release builds with downloads

**Details:** [docs/CI_CD_SETUP_COMPLETE.md](docs/CI_CD_SETUP_COMPLETE.md)

## Additional Documentation

### Architecture & Design
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Complete architecture guide
- [docs/ADDING_GAMES.md](docs/ADDING_GAMES.md) - Game integration guide
- [docs/SECURITY.md](docs/SECURITY.md) - Security best practices
- [docs/UI_UX_REDESIGN_PLAN.md](docs/UI_UX_REDESIGN_PLAN.md) - 8-phase UI/UX master plan
- [docs/PHASE_3_IMPLEMENTATION_ANALYSIS.md](docs/PHASE_3_IMPLEMENTATION_ANALYSIS.md) - Game polish
- [docs/PHASE_4_IMPLEMENTATION_ANALYSIS.md](docs/PHASE_4_IMPLEMENTATION_ANALYSIS.md) - Profile & stats
- [docs/PHASE_5_IMPLEMENTATION_REPORT.md](docs/PHASE_5_IMPLEMENTATION_REPORT.md) - Leaderboard
- [docs/PHASE_6_IMPLEMENTATION_REPORT.md](docs/PHASE_6_IMPLEMENTATION_REPORT.md) - Micro-interactions

### Setup & Configuration
- [docs/API_CONFIGURATION.md](docs/API_CONFIGURATION.md) - Unsplash API setup
- [docs/FIREBASE_SETUP_GUIDE.md](docs/FIREBASE_SETUP_GUIDE.md) - Firebase configuration

### Production & Release
- [task.md](task.md) - Production readiness tasks and deployment guide
- [firestore.rules](firestore.rules) - Firebase security rules

### Technical Deep Dives
- [docs/INFINITE_RUNNER_ARCHITECTURE.md](docs/INFINITE_RUNNER_ARCHITECTURE.md) - Flame engine
- [docs/SECURITY_IMPROVEMENTS.md](docs/SECURITY_IMPROVEMENTS.md) - Security changelog
