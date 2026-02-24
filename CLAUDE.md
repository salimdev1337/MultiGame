# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commit Rules

**NEVER add `Co-Authored-By: Claude` or any Claude/Anthropic authorship lines to commit messages.** Commits should only contain the user's authorship.

**ALWAYS run `flutter analyze` and `flutter test` across the full project before committing or pushing.** Never scope analyze to a single directory — the CI runs the full project. A scoped `flutter analyze lib/games/foo/` can pass while the full project fails.

**NEVER push to remote unless the user explicitly says "push".** Commit only — stop there and wait.

## Project Overview

MultiGame is a Flutter multi-platform gaming app with:
- **6 Games:** Sudoku (Classic/Rush/1v1 Online), 2048, Snake, Image Puzzle, Infinite Runner (Flame engine), Bomberman (solo vs bots + local WiFi multiplayer)
- **Premium UI:** 13,950+ lines of polished design system (glassmorphic, animations, charts)
- **Backend:** Firebase (auth, Firestore stats, leaderboards)
- **Architecture:** Clean layered with DI (GetIt), Riverpod state management, Repository pattern

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

**Full details:** [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md)

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

**See [docs/architecture/SECURITY.md](docs/architecture/SECURITY.md) for complete guide.**

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

**Full phase details:** [docs/ui-ux/UI_UX_REDESIGN_PLAN.md](docs/ui-ux/UI_UX_REDESIGN_PLAN.md)

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

**Details:** [docs/games/infinite-runner/INFINITE_RUNNER_ARCHITECTURE.md](docs/games/infinite-runner/INFINITE_RUNNER_ARCHITECTURE.md)

### Bomberman (Solo + Local WiFi Multiplayer)
- **Grid:** 15×13 (`kGridW`/`kGridH`), destructible blocks, powerups, chain explosions
- **Provider:** `bombermanProvider` — `NotifierProvider.autoDispose<BombermanNotifier, BombGameState>`
- **Routes:** `/play/bomberman` (game), `/play/bomberman/lobby` (multiplayer lobby)
- **Solo:** Player vs 1–3 bots with Easy/Medium/Hard AI (`BotAI.decide`)
- **Multiplayer:** Host-authoritative LAN model — host runs full game loop, broadcasts state to guests

#### Multiplayer Architecture (Host-Authoritative Frame Sync)
```
HOST: BombermanNotifier (game loop) → BombServerIo (WebSocket server)
        broadcasts frameSync (~60fps) + gridUpdate (on block destroy) to all guests

GUEST: BombClient → receives frameSync → applyFrameSync() onto local state
        setInput() / pressPlaceBomb() → sends move/placeBomb messages to host
```

**Notifier roles:**
```dart
// Start solo game (unchanged API)
ref.read(bombermanProvider.notifier).startSolo(BotDifficulty.medium);

// Host hands off server+client after lobby is ready
ref.read(bombermanProvider.notifier).startMultiplayerHost(
  server: server,   // BombServer — notifier takes ownership, calls stop() on dispose
  client: client,   // BombClient self-connected to own server
  players: [...],   // List<({int id, String name})> from room
);

// Guest after receiving start message
ref.read(bombermanProvider.notifier).connectAsGuest(
  client: client,
  localPlayerId: myId,   // assigned by host via joined message
);
```

**Input API (backward-compatible):**
```dart
// Solo or host — playerId defaults to 0
notifier.setInput(dx: 1.0, dy: 0.0);           // player 0
notifier.setInput(playerId: 2, dx: 0, dy: 1);  // player 2

// Guest — playerId ignored, routes to host over network
notifier.setInput(dx: 1.0, dy: 0.0);
```

**JSON serialization** — all models support `toJson()`/`fromJson()`:
- `BombGameState.toFrameJson()` — frame slice (players/bombs/explosions, no grid)
- `BombGameState.toFullJson()` / `fromFullJson()` — full state including grid
- `BombGameState.applyFrameSync(json)` — guest-side patch, preserves local grid

**Server platform:** `BombServerIo` (native only — shelf + shelf_web_socket). Web can join but not host (`BombServerStub` throws `UnsupportedError`). Import pattern:
```dart
import 'package:multigame/games/bomberman/multiplayer/bomb_server_stub.dart'
    if (dart.library.io) 'package:multigame/games/bomberman/multiplayer/bomb_server_io.dart';
```

**Android:** `usesCleartextTraffic="true"` required for `ws://` on Android 9+.

**Tests:** 58 unit tests in `test/games/bomberman/` — all pure logic + serialization, no Flutter context needed.

### RPG — Shadowfall Chronicles (Flame Engine)
- **Provider:** `rpgProvider` — `NotifierProvider.autoDispose<RpgNotifier, RpgState>`
- **Routes:** `/play/rpg` (game screen), `/play/rpg/boss_select` (boss map)
- **Colors:** `DSColors.rpgPrimary` (0xFFCC2200 blood red), `DSColors.rpgAccent` (0xFFFFD700 gold)

**Bosses (sequential unlock chain):**
| Boss | HP | Phases | Drop |
|---|---|---|---|
| The Warden | 300 | 2 (50%) | wardenSword (+8 ATK) |
| The Plague Shaman | 450 | 2 (50%) | shamanCloak (+25 HP, poison resist) |
| The Hollow King | 600 | 3 (66%/33%) | hollowCrown (+10 ATK, +20% ult start) |
| The Shadowlord | 900 | 3 (66%/33%) | — (final boss) |

**Key systems:**
- `SkillTree` — 3 random node options after each boss; `SkillTree.pickOptions(applied, rng)` / `SkillTree.applyNode(stats, nodeId)` — 12 nodes (maxHp, attack, staminaPip, staminaRegen, comboWindow, ultHit, ultDmg, heavyFinisher, moveSpeed, quickRecovery, ironFist, rugged)
- `Equipment` — weapon/armor slots; `ProgressionEngine.applyEquipment(stats, weapon, armor)` applies bonuses; equip flow triggered by `pendingEquipment` on `RpgState`
- `StaminaSystem` — mutable pip-based dodge charges (default 3 pips, 2s regen); `consumePip()` / `update(dt)`
- `UltimateGauge` — 0.0–1.0 charge; fills on hit landed (`+0.05`) and hit taken (`+0.10`); `fire()` resets; `isReady` when `>= 1.0`
- `BossAI` abstract → `GolemAI` / `WraithAI` / `HollowKingAI` / `ShadowlordAI` state machines

**`RpgState` fields:** `playerStats`, `defeatedBosses`, `weapon`, `armor`, `selectedBoss`, `appliedNodes`, `levelUpOptions`, `pendingLevelUp`, `pendingEquipment`

**Notifier flow:**
```
selectBoss(id) → game screen launches boss fight
onBossDefeated(id) → marks defeated, picks 3 skill nodes, sets pendingEquipment, saves score (defeatedBosses.length × 100)
selectLevelUpNode(nodeId) → applies skill, clears pendingLevelUp
equipPending() / skipEquip() → resolves equipment overlay, saves progress
```

**Save:** `SharedPreferences` key `rpg_save` (JSON — playerStats, defeatedBosses, weapon, armor, appliedNodes)

**Flame:** `RpgFlameGame` landscape-locked, `HasCollisionDetection`; `gameTick` ValueNotifier 50ms throttle; `ArenaComponent` uses `HasGameReference` (not `HasGameRef`), `game.size` accessor

**Attack types:** meleeSlash1/2, heavySlash, ultimateAoe (player); chargeAttack, overheadSlam (Warden); poisonPool, poisonProjectile (Shaman); dashSlash, bladeTrail (Hollow King); voidBlast, shadowSurge (Shadowlord)

**Tests:** 16 pure tests in `test/games/rpg/`

### Ludo (Multi-Mode Board Game)
- **Provider:** `ludoProvider` — `NotifierProvider.autoDispose<LudoNotifier, LudoGameState>`
- **Routes:** `/play/ludo`, game model id: `ludo`
- **Colors:** `DSColors.ludoPrimary` (0xFFE91E63 pink), `DSColors.ludoAccent` (0xFFFFEB3B yellow)

**Modes:** soloVsBots (Red=human + 3 bots), freeForAll3 (yellow excluded, triangular board), freeForAll4, twoVsTwo (Red+Green=team0, Blue+Yellow=team1)

**Token encoding:** trackPosition=-1=base, 0–51=track, -2=homeColumn sentinel (+homeColumnStep 1–6), isFinished=true=centre

**Magic Dice Mode:** `LudoDiceMode` enum (classic/magic); `MagicDiceFace` enum (turbo/skip/swap/shield/blast/wildcard)
- turbo: doubles dice value; `diceValue` = effective doubled, `normalDiceValue` = raw pip display
- skip: notifier returns early, advances turn (no-op in `applyMagicEffect`)
- blast: drops `LudoBomb` on track; `activeBombs: List<LudoBomb>` on `LudoGameState`; bomb ticks down per player-turn

**Key constants:** `kSafeSquares = {0,8,13,21,26,34,39,47}`; start positions Red=0, Yellow=13, Blue=26, Green=39

**Triangular board (freeForAll3):** `kTriTrackLength=48`, 16 squares/side; `kTriStartPositions={red:0,green:16,blue:32}`; `kTriSafeSquares={0,8,16,24,32,40}`; `LudoTriangularBoardPainter` in `ludo_board_painter.dart`

**Logic dispatch:** `_modeTrackParams(mode)` → `(trackLength, startPositions)`; `computeMovableTokenIds`/`validDiceValues` accept `{LudoMode mode}`; `computeTokenHopPath` → `List<(double,double)>` dispatches to `_computeTokenHopPathTri` for freeForAll3

**Powerups:** shield (2 turns immune), doubleStep, freeze, recall (bypasses safe), luckyRoll

**Rules:** 3 consecutive 6s = forfeit turn + send furthest token to base; extra turn on rolling 6 OR capture; `saveScore('ludo', 1)` only in soloVsBots when Red wins

**Board painter:** `flutter/rendering.dart` ONLY (NOT material.dart); `LudoTokenWidget` col/row are `double`

**Tests:** 73 pure tests in `test/games/ludo/` (ludo_logic_test.dart + ludo_notifier_test.dart)

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

**Full guide:** [docs/architecture/ADDING_GAMES.md](docs/architecture/ADDING_GAMES.md)

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

### Flow Control — Curly Braces Required
**ALWAYS wrap `if`, `else`, `for`, `while`, and `do` bodies in curly braces**, even single-line ones. The CI enforces `curly_braces_in_flow_control_structures`.

```dart
// ❌ WRONG — breaks CI
if (idx != -1) doSomething();
for (final x in list) process(x);

// ✅ CORRECT
if (idx != -1) {
  doSomething();
}
for (final x in list) {
  process(x);
}
```

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
- **CRITICAL — Isolate high-frequency widgets:** Any widget that updates frequently (timers, counters, live scores) MUST be its own `ConsumerWidget` using `ref.watch(provider.select(...))`. Never let a timer-driven state field (e.g. `elapsedSeconds`, `remainingSeconds`) cause a full screen rebuild — that rebuilds every child including expensive grids/lists.

  **❌ WRONG — timer causes 81-cell grid to rebuild every second:**
  ```dart
  class GameScreen extends ConsumerWidget {
    Widget build(context, ref) {
      final state = ref.watch(gameProvider); // elapsedSeconds changes every second!
      return Column(children: [
        Text(state.formattedTime),  // tiny widget
        HeavyGrid(board: state.board), // 81 cells rebuilt every second!
      ]);
    }
  }
  ```

  **✅ CORRECT — timer widget is isolated, grid only rebuilds on actual game events:**
  ```dart
  // Isolated timer widget
  class GameTimerDisplay extends ConsumerWidget {
    Widget build(context, ref) {
      final time = ref.watch(gameProvider.select((s) => s.formattedTime));
      return Text(time);
    }
  }

  // Screen selects only layout-relevant fields (NO elapsedSeconds)
  class GameScreen extends ConsumerWidget {
    Widget build(context, ref) {
      final state = ref.watch(gameProvider.select((s) => (
        selectedRow: s.selectedRow,
        revision: s.revision,
        // ... other fields that affect layout
        // intentionally excludes elapsedSeconds
      )));
      return Column(children: [
        const GameTimerDisplay(), // rebuilds every second in isolation
        HeavyGrid(board: ...),    // only rebuilds on real game events
      ]);
    }
  }
  ```

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

**Details:** [docs/cicd/CI_CD_SETUP_COMPLETE.md](docs/cicd/CI_CD_SETUP_COMPLETE.md)

## Additional Documentation

### Documentation Index
- [docs/README.md](docs/README.md) - Full docs navigation index

### Architecture & Design
- [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) - Complete architecture guide
- [docs/architecture/ADDING_GAMES.md](docs/architecture/ADDING_GAMES.md) - Game integration guide
- [docs/architecture/SECURITY.md](docs/architecture/SECURITY.md) - Security best practices
- [docs/architecture/SECURITY_IMPROVEMENTS.md](docs/architecture/SECURITY_IMPROVEMENTS.md) - Security changelog

### UI/UX Design System
- [docs/ui-ux/UI_UX_REDESIGN_PLAN.md](docs/ui-ux/UI_UX_REDESIGN_PLAN.md) - 8-phase UI/UX master plan
- [docs/ui-ux/PHASE_3_IMPLEMENTATION_ANALYSIS.md](docs/ui-ux/PHASE_3_IMPLEMENTATION_ANALYSIS.md) - Game polish
- [docs/ui-ux/PHASE_4_IMPLEMENTATION_ANALYSIS.md](docs/ui-ux/PHASE_4_IMPLEMENTATION_ANALYSIS.md) - Profile & stats
- [docs/ui-ux/PHASE_5_IMPLEMENTATION_REPORT.md](docs/ui-ux/PHASE_5_IMPLEMENTATION_REPORT.md) - Leaderboard
- [docs/ui-ux/PHASE_6_IMPLEMENTATION_REPORT.md](docs/ui-ux/PHASE_6_IMPLEMENTATION_REPORT.md) - Micro-interactions

### Setup & Configuration
- [docs/setup/API_CONFIGURATION.md](docs/setup/API_CONFIGURATION.md) - Unsplash API setup
- [docs/setup/FIREBASE_SETUP_GUIDE.md](docs/setup/FIREBASE_SETUP_GUIDE.md) - Firebase configuration

### Games
- [docs/games/infinite-runner/INFINITE_RUNNER_ARCHITECTURE.md](docs/games/infinite-runner/INFINITE_RUNNER_ARCHITECTURE.md) - Flame engine architecture
- [docs/games/sudoku/SUDOKU_ARCHITECTURE.md](docs/games/sudoku/SUDOKU_ARCHITECTURE.md) - Sudoku system architecture

### Production & Release
- [task.md](task.md) - Production readiness tasks and deployment guide
- [firestore.rules](firestore.rules) - Firebase security rules

---

## File Size & Class Density Rules (Non-Negotiable)

These rules apply to every Flutter file, no exceptions.

- **Max 300 lines per file.** If a change would push a file past 300 lines, STOP. Extract widgets into separate files first, then implement the change.
- **Max 3 widget classes per file.** A fourth class means a new file is needed.
- **Screen files** (`*_screen.dart`, `*_page.dart`) may only contain the page widget and its state class. Every other widget goes in the game's `widgets/` subfolder.

If the user asks to add code to a file that already violates these rules:
1. REFUSE to add the code directly
2. Show which classes should be extracted and into which target files
3. Only proceed after the extraction is planned or done

This prevents the accumulation of god-object screen files that make testing, review, and parallel development impossible.

---

## Senior Code Reviewer Mode

You are a senior engineer reviewing this codebase alongside the user. Before implementing any change over 10 lines, run this checklist silently. If any item fails, **call it out before writing a single line of code** — the way a senior peer would: clearly, with the reason, and with a concrete fix.

**Pre-implementation checklist:**

1. **File size** — will the target file exceed 300 lines after this change? If yes, propose an extraction plan first.
2. **Silent failures** — does any new function return void and silently ignore errors? If yes, require a `statusMessage` update or a thrown exception so failures are observable.
3. **Design system** — are any colors, spacings, or text styles hardcoded (raw `Color(0xFF...)`, raw `double` padding)? If yes, use `DSColors` / `DSSpacing` / `DSTypography`.
4. **Lifecycle** — does any new `Timer`, `StreamSubscription`, `AnimationController`, or listener get disposed? If not, add disposal before proceeding.
5. **Tests** — is the changed function or widget covered by a test? If not, flag it explicitly. Never require tests to be added right now, but always name the gap.

**When you spot a violation in existing code** (even if not directly touched), point it out as a brief side note: what it is, why it matters, and what the fix looks like. Do not let bad patterns pass silently.

**Tone:** Direct and concrete, like a trusted senior coworker — not a linter, not a lecture. One sentence on the problem, one sentence on the fix.

---

## Persistence & Storage Decision Rule

- **User-facing game progress** (saves, stats, achievements, scores) → `flutter_secure_storage` via `SecureStorageRepository`
- **App preferences** (theme, volume, accessibility settings) → `SharedPreferences` is acceptable
- **In-memory session state** → provider state only, never persisted unless the user expects it to survive an app restart

`SharedPreferences` is unencrypted plaintext on disk. Any data the user would consider "theirs" must be encrypted.
