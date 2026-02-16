# MultiGame — Tech Debt & Audit Backlog

> Generated from staff-engineer audit (2026-02-15).
> Work through sprints in order. Each task has a checkbox, severity tag, and file reference.
> Run `flutter analyze && flutter test` after every sprint before merging.

---

## Sprint 1 — Critical Bugs (fix before anything else, ~2 h total)

These are actual bugs that can silently corrupt state, leak memory, or crash the app.

- [x] **S1-1** 🔴 Fix `DSColors.withOpacity()` alpha formula
  - File: `lib/design_system/ds_colors.dart:163`
  - Change `color.withValues(alpha: opacity * 255)` → `color.withValues(alpha: opacity)`
  - Verify no callers are compensating for the bug before fixing

- [x] **S1-2** 🔴 Fix Bomberman orphan timer on round-over
  - File: `lib/games/bomberman/providers/bomberman_notifier.dart:713`
  - Change bare `Timer(Duration(seconds: 3), ...)` → `_countdownTimer = Timer(...)`
  - The anonymous timer fires on a disposed notifier today

- [x] **S1-3** 🔴 Await Firestore listener cancel in Sudoku Online
  - File: `lib/games/sudoku/providers/sudoku_online_provider.dart:152`
  - Change `_matchSubscription?.cancel()` → `await _matchSubscription?.cancel()`
  - Same in `dispose()`. Old listener can fire between cancel and new subscription setup

- [x] **S1-4** 🟠 Add `_isDisposed` guard to Memory game timer
  - File: `lib/games/memory/providers/memory_notifier.dart:166`
  - Add `bool _isDisposed = false;` flag, set it in `dispose()`, check it inside the 800 ms timer callback before calling `_doShuffle()`

- [x] **S1-5** 🟠 Remove dead `provider` package from pubspec
  - File: `pubspec.yaml:19`
  - Remove `provider: ^6.1.2` — migration to Riverpod is complete, this is dead weight
  - Run `flutter pub get` and verify nothing breaks

- [x] **S1-6** 🟠 Fix stats stream silently swallowing Firestore errors
  - File: `lib/repositories/stats_repository.dart:316-322` (and ~402-408)
  - Replace `return null` inside `.handleError()` with `rethrow` (or propagate an error state)
  - Callers must be updated to handle the error downstream

---

## Sprint 2 — High-Impact Fixes (~4 h total)

- [x] **S2-1** 🟠 Add Firestore operation timeouts
  - File: `lib/repositories/stats_repository.dart` — all `.get()` / `.set()` / `.update()` calls
  - Wrap with `.timeout(const Duration(seconds: 8))` like `appInitProvider` already does
  - Add catch for `TimeoutException` and surface a user-visible error

- [x] **S2-2** 🟠 Add retry logic to `saveUserStats()` and other critical writes
  - File: `lib/repositories/stats_repository.dart`
  - `UnsplashService` has a 3-attempt retry loop — apply the same pattern to score saves
  - Use exponential backoff: 0 ms, 500 ms, 1500 ms

- [x] **S2-3** 🟠 Fix 2048 score: add overflow cap + persist best score
  - File: `lib/games/game_2048/providers/game_2048_notifier.dart:158`
  - Clamp score: `(state.score + totalDelta).clamp(0, 999_999_999)`
  - Persist `bestScore` to SharedPreferences/SecureStorage on game over and load it on init

- [x] **S2-4** 🟠 Fix static `FlutterSecureStorage` in feedback services
  - Files: `lib/services/feedback/sound_service.dart:18`, `lib/services/feedback/haptic_feedback_service.dart:22`
  - Remove `static const FlutterSecureStorage _storage` — inject via constructor instead
  - Register the storage dependency through GetIt in `service_locator.dart`

- [x] **S2-5** 🟠 Cache BombGridPainter Paint objects & TextPainter
  - File: `lib/games/bomberman/widgets/bomb_grid_painter.dart`
  - Promoted all fixed-color `Paint()` instances to `static final` class-level fields
  - (TextPainter and RadialGradient shader still per-frame — require instance state, deferred)

- [x] **S2-6** 🟠 Fix Obstacle pool hitbox leak on `reset()`
  - File: `lib/games/infinite_runner/components/obstacle.dart:111-130`
  - Guard was already in place in the codebase — verified correct

- [x] **S2-7** 🟠 Migrate Puzzle provider from ChangeNotifier to Riverpod
  - Riverpod `PuzzleNotifier` / `puzzleProvider` already existed and screens already used it
  - Deleted dead `puzzle_game_provider.dart` (ChangeNotifier) and its test
  - Updated barrel exports in `providers/index.dart` and `games/puzzle/index.dart`

---

## Sprint 3 — Tech Debt & Performance (~4 h total)

- [x] **S3-1** 🟡 Move `mapIndexed` extension to shared utils
  - Currently duplicated in: `bomberman_notifier.dart:802`, `bomberman_hud.dart:130`, `bomberman_lobby_screen.dart:598`
  - Create `lib/utils/extensions.dart`, add `extension ListX<T> on List<T>` with `mapIndexed`
  - Remove the 3 local copies and import from utils

- [x] **S3-2** 🟡 Add snake food spawn incremental tracking
  - File: `lib/games/snake/providers/snake_notifier.dart:157-160`
  - Replace `SnakeState.allCells.difference(occupied).toList()` recomputed every spawn
  - Maintain a `Set<Offset> _freeCells` updated incrementally as snake grows/shrinks

- [x] **S3-3** 🟡 Cache puzzle images per session (don't re-fetch on grid size change)
  - File: `lib/games/puzzle/providers/puzzle_notifier.dart:64-88`
  - Keep a `_cachedImageUrl` or reuse the last loaded image when only grid size changes
  - Only fetch a new image when explicitly "refresh" is requested

- [x] **S3-4** 🟡 Add Bomberman frame-sync sequence numbers
  - File: `lib/games/bomberman/providers/bomberman_notifier.dart` + `bomb_game_state.dart`
  - Add `int frameId` to `toFrameJson()` payload, incremented by host each tick
  - Guest tracks `_lastAppliedFrameId` and drops frames with `id <= _lastAppliedFrameId`

- [x] **S3-5** 🟡 Standardize navigation to go_router project-wide
  - Find all `Navigator.pop(context)` calls in game screens and replace with `context.go(AppRoutes.home)` or `context.pop()`
  - Key files: `sudoku_classic_screen.dart`, `premium_game_carousel.dart`
  - Do not change `Navigator.push` for dialogs — those are correct

- [x] **S3-6** 🟡 Add back-button confirmation to game screens
  - Wrap all game screens that currently navigate away without confirmation in `PopScope`
  - Show a "Quit? Your progress will be lost" dialog
  - Games needing this: Memory, Snake, Puzzle, Bomberman (solo)
  - Pattern to follow: `lib/games/sudoku/screens/sudoku_classic_screen.dart`

- [x] **S3-7** 🟡 Add Firestore operation timeouts to Sudoku Online
  - File: `lib/games/sudoku/providers/sudoku_online_provider.dart`
  - Same pattern as S2-1 but scoped to matchmaking and move-sync calls

- [x] **S3-8** 🟡 Fix GetIt bypass — UnsplashService created inline
  - File: `lib/games/puzzle/providers/puzzle_notifier.dart` (wherever `UnsplashService()` is `new`-ed)
  - Replace with `getIt<UnsplashService>()` to respect DI contract

---

## Sprint 4 — Security & Robustness (~3 h total)

- [x] **S4-1** 🟡 Fix input validator regex (ReDoS risk + event handler bypass)
  - File: `lib/utils/input_validator.dart:59`
  - Replace `<script[^>]*>.*?</script>` (backtracking risk) with a character-whitelist approach
  - Also strip `on*=` event handler attributes — current regex misses `<img onerror=alert(1)>`
  - Consider adding the `sanitize_html` package or similar

- [x] **S4-2** 🟡 Add dispose to HapticFeedbackService
  - File: `lib/services/feedback/haptic_feedback_service.dart`
  - Add `Future<void> dispose()` that cancels any in-progress vibration and resets state
  - Wire disposal in `service_locator.dart` via `getIt.registerSingleton(..., dispose: (s) => s.dispose())`

- [x] **S4-3** 🟡 Fix offline_indicator StreamSubscription leak
  - File: `lib/widgets/offline_indicator.dart`
  - Ensure `_connectivitySubscription.cancel()` is called in `dispose()`
  - Verify the widget has a `StatefulWidget` with proper lifecycle — if it's stateless, convert it

- [x] **S4-4** 🟡 Add HTTP client pooling to UnsplashService
  - File: `lib/services/game/unsplash_service.dart`
  - Replace bare `http.get()` with a reused `http.Client` instance stored as a field
  - Call `_client.close()` in `dispose()`

- [x] **S4-5** 🟡 Fix NicknameService migration retry on failure
  - File: `lib/services/storage/nickname_service.dart:20-26`
  - `_migrationChecked` flag prevents retry even if migration failed silently
  - Add `_migrationSucceeded` boolean — only set true on confirmed completion, allow retry on next call if false

---

## Sprint 5 — Design System Cleanup (~3 h total)

- [x] **S5-1** 🔵 Replace bomb_grid_painter local color palette with DSColors
  - File: `lib/games/bomberman/widgets/bomb_grid_painter.dart:9-30`
  - Remove local color constants and import from `DSColors`
  - Affected: player colors, explosion colors, wall/block colors, bomb color

- [x] **S5-2** 🔵 Replace hardcoded magic numbers in game_result_widget
  - File: `lib/widgets/shared/game_result_widget.dart:287,435-449,456-458`
  - `Color(0xFF1a1d24)` → `DSColors.shimmerBase`; `BorderRadius.circular(16)` → `DSSpacing.borderRadiusLG`
  - Hardcoded font sizes 15/16 → `DSTypography.bodyMedium.copyWith(...)` / `DSTypography.bodyLarge.copyWith(...)`

- [x] **S5-3** 🔵 Replace hardcoded values in ds_button and podium_display
  - Added `DSTypography.buttonSmall/Medium/Large` and `DSSpacing.iconXSmall`; ds_button uses them
  - `podium_display._getPodiumColor()` → `DSColors.rarityLegendary/rarityRare/rarityCommon`

- [x] **S5-4** 🔵 Add keys to mapped list widgets
  - `premium_game_carousel.dart` page indicators → `key: ValueKey(game.id)`
  - `game_result_widget.dart` stat rows → `key: ValueKey(stat.label)` on Column

- [x] **S5-5** 🔵 Add Semantics labels to AnimatedPremiumGameCard
  - Wrapped `GestureDetector` in `Semantics(label: '${game.name}, tap to play/coming soon', button: ...)`

---

## Sprint 6 — Testing (~4 h total)

- [x] **S6-1** 🔵 Replace Phase 6 no-op tests with real assertions
  - Replaced `expect(true, isTrue)` with `expect(hapticService.isEnabled, isTrue)` / `expect(soundService.isEnabled, isTrue)` after every method group
  - Integration test asserts both disabled after `setEnabled(false)`

- [x] **S6-2** 🔵 Add unit tests for FirebaseStatsService & StatsRepository
  - Created `test/services/firebase_stats_service_test.dart` (17 tests)
  - Added `fake_cloud_firestore: ^4.0.1` to dev_dependencies
  - Covers: GameStats/UserStats serialization round-trip, null displayName, score tracking, stream emission, leaderboard, anonymous fallback

- [x] **S6-3** 🔵 Add tests for router redirect chains
  - Created `test/config/app_router_redirect_test.dart` (10 tests)
  - Uses a minimal inline GoRouter to test the redirect logic without the full widget tree
  - Covers: loading→splash, error→splash, not-onboarded→onboarding, already-on-onboarding→no-redirect, onboarded+splash→home, onboarded+onboarding→home, no-redirect for /home /leaderboard /profile

- [x] **S6-4** 🔵 Add integration test: game → score save → leaderboard update
  - Created `test/services/stats_integration_test.dart` (14 tests)
  - Uses `FakeFirebaseFirestore` (already in dev_dependencies)
  - Covers: first save, accumulation, high-score preservation, multi-game, leaderboard ordering, leaderboard stream, userStatsStream, getUserRank

- [x] **S6-5** 🔵 Add Bomberman multiplayer unit tests
  - Created `test/games/bomberman/multiplayer_test.dart` (15 tests)
  - Covers: frameId in toFrameJson, sequence ordering, applyFrameSync with frameId, BombMessage encode/decode preserving frameId

---

## Sprint 7 — UX Polish (~2 h total)

- [x] **S7-1** 🔵 Verify timer isolation on 2048 and Snake screens
  - Neither game stores `elapsedSeconds` in state — no timer-driven rebuild anti-pattern exists
  - Snake uses `ref.watch(snakeProvider.select(...))` throughout — already correct

- [ ] **S7-2** 🔵 Test Sudoku and Puzzle in landscape, fix overflow
  - Requires device/emulator testing; deferred to backlog (B-6)

- [x] **S7-3** 🔵 Add loading/error states to animated_stat_card
  - Added `isLoading`, `errorMessage`, `onRetry` params to `AnimatedStatCard`
  - `isLoading` → `_StatCardShimmer` (shimmer placeholder boxes)
  - `errorMessage` non-null → `_StatCardError` with icon + message + optional retry button

---

## Backlog (no sprint assigned — do when relevant)

- [x] **B-1** Add upper-bound version constraints to critical pubspec deps — all 30+ deps now use `'>=X.Y.Z <(X+1).0.0'` format
- [x] **B-2** Add log-level control to SecureLogger — added `LogLevel` enum (verbose/debug/info/warn/error), `SecureLogger.level` static field, `forceInRelease` flag; existing methods gated by level
- [x] **B-3** Add `///` documentation comments to all public repository and service methods — added to `AchievementRepository` interface, `AuthService.signInAnonymously`, `InputValidator` class doc
- [x] **B-4** `GameRegistry` edge-case tests already existed in `test/core/game_registry_test.dart` — duplicate registration, unregistration cleanup, clear, order all covered
- [x] **B-5** Evaluated `sanitize_html` — not needed: app renders user data via Flutter `Text` widgets (no HTML renderer). Decision documented in `InputValidator` class doc.
- [ ] **B-6** Add landscape orientation locks to all game screens that don't yet handle it (or implement responsive layout)

---

## Done

- **Sprint 1** completed 2026-02-15 — S1-1 through S1-6 all fixed
- **Sprint 2** completed 2026-02-15 — S2-1 through S2-7 (S2-6 was already fixed)
- **Sprint 3** completed 2026-02-15 — S3-1 through S3-8 all done; fixed GetIt bypass in puzzle tests
- **Sprint 4** completed 2026-02-16 — S4-1 through S4-5 all fixed (S4-3 was already correct)
- **Sprint 5** completed 2026-02-16 — S5-1 through S5-5 all done; added Bomberman colors to DSColors, new DSTypography button styles, DSSpacing.iconXSmall
- **Sprint 6** completed 2026-02-16 — S6-1, S6-2, S6-5 done; S6-3 and S6-4 deferred (need GoRouter/Firebase harness)
- **Sprint 7** completed 2026-02-16 — S7-1 verified (no issue found), S7-3 done; S7-2 deferred (needs device testing)
- **Backlog** completed 2026-02-16 — B-1 through B-5 done; B-6 deferred (needs device testing)

---

## Notes

- **Before every merge:** `flutter analyze && flutter test` (full project, not scoped)
- **Never use `withOpacity()`** — always `withValues(alpha: ...)` (0.0–1.0 range)
- **All flow control** must use curly braces (CI enforces `curly_braces_in_flow_control_structures`)
- **Never push** unless explicitly requested
