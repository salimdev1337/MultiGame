# Remaining Refactoring Tasks

## Status: Phase 1 Complete ✅

Phase 1 (Critical Security Fixes) has been completed. The following phases remain.

---

## Phase 2: Dependency Injection & Service Layer

### 2.1 Add Service Locator (GetIt) 🔄 IN PROGRESS
**Status:** Package added to pubspec.yaml, service locator file needs to be created

**Tasks:**
- [ ] Create `lib/config/service_locator.dart`
- [ ] Register all services as singletons:
  - AchievementService
  - FirebaseStatsService
  - NicknameService
  - AuthService
  - UnsplashService
  - ImagePuzzleGenerator
  - SecureStorageRepository
- [ ] Initialize service locator in `lib/main.dart` before runApp()
- [ ] Update all providers to inject services via constructor instead of instantiating

**Files to Create:**
- `lib/config/service_locator.dart`

**Files to Modify:**
- `lib/main.dart` (initialize service locator)
- All provider files (inject services via constructor)

---

### 2.2 Reorganize Service Layer
**Status:** Not started

**Current Structure:**
```
lib/services/
├── achievement_service.dart
├── auth_service.dart
├── firebase_stats_service.dart
├── image_puzzle_generator.dart
├── nickname_service.dart
└── unsplash_service.dart
```

**Target Structure:**
```
lib/services/
├── auth/
│   └── auth_service.dart
├── data/
│   ├── firebase_stats_service.dart
│   └── achievement_service.dart
├── game/
│   ├── image_puzzle_generator.dart
│   └── unsplash_service.dart
└── storage/
    └── nickname_service.dart
```

**Tasks:**
- [ ] Create subdirectories: auth/, data/, game/, storage/
- [ ] Move service files to appropriate subdirectories
- [ ] Create barrel files (index.dart) for clean imports
- [ ] Update all imports across the codebase
- [ ] Update service_locator.dart imports

**Files to Move:**
- Move all service files to new subdirectories
- Update ~30+ files with import changes

---

### 2.3 Implement Repository Pattern for Data Persistence
**Status:** Not started (SecureStorageRepository already created in Phase 1.3)

**Tasks:**
- [ ] Create `lib/repositories/user_repository.dart` (interface + implementation)
- [ ] Create `lib/repositories/stats_repository.dart`
- [ ] Create `lib/repositories/achievement_repository.dart`
- [ ] Update services to depend on repository interfaces:
  - `lib/services/data/achievement_service.dart`
  - `lib/services/data/firebase_stats_service.dart`
  - `lib/services/storage/nickname_service.dart`
- [ ] Register repositories in service locator

**Files to Create:**
- `lib/repositories/user_repository.dart`
- `lib/repositories/stats_repository.dart`
- `lib/repositories/achievement_repository.dart`

**Files to Modify:**
- `lib/services/data/achievement_service.dart`
- `lib/services/data/firebase_stats_service.dart`
- `lib/services/storage/nickname_service.dart`
- `lib/config/service_locator.dart`

---

## Phase 3: Provider Refactoring & Deduplication

### 3.1 Extract Duplicate Score Saving Logic
**Status:** Not started

**Problem:** Same `_saveScore()` and `setUserInfo()` in 3 providers (~250 lines of duplicate code)

**Tasks:**
- [ ] Create `lib/providers/mixins/game_stats_mixin.dart`
- [ ] Extract common methods:
  - `setUserInfo(String userId, String displayName)`
  - `saveScore(String gameType, int score)`
  - User info state management (_userId, _displayName)
- [ ] Apply mixin to all game providers:
  - `lib/providers/game_2048_provider.dart`
  - `lib/providers/snake_game_provider.dart`
  - `lib/providers/puzzle_game_provider.dart`
- [ ] Remove duplicate code from providers
- [ ] Test all games save scores correctly

**Files to Create:**
- `lib/providers/mixins/game_stats_mixin.dart`

**Files to Modify:**
- `lib/providers/game_2048_provider.dart`
- `lib/providers/snake_game_provider.dart`
- `lib/providers/puzzle_game_provider.dart`

**Expected Impact:** Remove ~250 lines of duplicate code

---

### 3.2 Separate UI State from Game State
**Status:** Not started

**Problem:** Providers mix game logic, UI state, and business logic

**Tasks:**
- [ ] Split `puzzle_game_provider.dart` into:
  - `PuzzleGameProvider` (game state: grid, moves, timer)
  - `PuzzleUIProvider` (UI state: loading, dialogs, animations)
- [ ] Split `game_2048_provider.dart` into:
  - `Game2048Provider` (game state: grid, score, tiles)
  - `Game2048UIProvider` (UI state: animations, loading)
- [ ] Split `snake_game_provider.dart` into:
  - `SnakeGameProvider` (game state: snake position, food, direction)
  - `SnakeUIProvider` (UI state: loading, dialogs)
- [ ] Update screens to use both providers
- [ ] Move statistics logic to service layer (not provider)

**Files to Create:**
- `lib/providers/puzzle_ui_provider.dart`
- `lib/providers/game_2048_ui_provider.dart`
- `lib/providers/snake_ui_provider.dart`

**Files to Modify:**
- `lib/providers/puzzle_game_provider.dart`
- `lib/providers/game_2048_provider.dart`
- `lib/providers/snake_game_provider.dart`
- `lib/screens/puzzle.dart`
- `lib/screens/game_2048_page.dart`
- `lib/screens/snake_game_page.dart`

---

### 3.3 Update Provider Registration with DI
**Status:** Not started (depends on 2.1, 3.1, 3.2)

**Tasks:**
- [ ] Update `lib/main.dart` MultiProvider with:
  - New split providers (game + UI for each game)
  - Inject services from service locator
  - Use GetIt for service dependencies
- [ ] Remove direct service instantiation from providers
- [ ] Test all provider initialization

**Files to Modify:**
- `lib/main.dart`

---

## Phase 4: Game Architecture Standardization

### 4.1 Reorganize Game Modules with Consistent Structure
**Status:** Not started

**Problem:** Only infinite_runner is well-organized, others are scattered

**Target Structure (for each game):**
```
lib/games/
├── puzzle/
│   ├── models/
│   │   └── puzzle_piece.dart
│   ├── logic/
│   │   └── puzzle_game_logic.dart
│   ├── services/
│   │   └── image_puzzle_generator.dart
│   └── providers/
│       ├── puzzle_game_provider.dart
│       └── puzzle_ui_provider.dart
├── game_2048/
│   ├── models/
│   ├── logic/
│   └── providers/
├── snake/
│   ├── models/
│   ├── logic/
│   └── providers/
└── infinite_runner/
    └── (existing structure - already good)
```

**Tasks:**
- [ ] Create game directories: puzzle/, game_2048/, snake/
- [ ] Create subdirectories: models/, logic/, services/, providers/ for each
- [ ] Move game-specific files to respective directories:
  - Models from `lib/models/` (puzzle_piece.dart, etc.)
  - Providers from `lib/providers/`
  - Services from `lib/services/game/`
- [ ] Create barrel files (index.dart) for each game
- [ ] Update imports across entire codebase (~40+ files)

**Files to Move:**
- Move 20+ files to new game structure
- Update imports in 40+ files

---

### 4.2 Create Game Registry Pattern
**Status:** Not started

**Problem:** Hardcoded game IDs in navigation and multiple locations

**Tasks:**
- [ ] Create `lib/core/game_interface.dart` (interface for game metadata)
- [ ] Create `lib/core/game_registry.dart` (singleton registry)
- [ ] Each game registers itself with:
  - Game ID
  - Display name
  - Icon
  - Route
  - Provider type
- [ ] Update `lib/models/game_model.dart` to use registry
- [ ] Update `lib/screens/main_navigation.dart` to use registry for routing
- [ ] Remove hardcoded game IDs from:
  - Navigation
  - Leaderboard
  - Achievement system

**Files to Create:**
- `lib/core/game_interface.dart`
- `lib/core/game_registry.dart`

**Files to Modify:**
- `lib/models/game_model.dart`
- `lib/screens/main_navigation.dart`
- `lib/screens/leaderboard_screen.dart`
- Each game's main file (to register itself)

**Benefit:** Easy to add new games - just register them

---

### 4.3 Consolidate Reusable Dialog Widgets
**Status:** Not started

**Problem:** Duplicate dialog creation code in 5+ screens (~200+ lines)

**Tasks:**
- [ ] Create `lib/widgets/dialogs/game_dialog.dart` (base dialog with app styling)
- [ ] Create `lib/widgets/dialogs/achievement_dialog.dart`
- [ ] Create `lib/widgets/dialogs/settings_dialog.dart`
- [ ] Create `lib/utils/dialog_utils.dart` (helper methods)
- [ ] Update all screens to use shared dialog components:
  - `lib/screens/game_2048_page.dart`
  - `lib/screens/snake_game_page.dart`
  - `lib/screens/puzzle.dart`
  - `lib/screens/infinite_runner_page.dart`
- [ ] Remove duplicate dialog code

**Files to Create:**
- `lib/widgets/dialogs/game_dialog.dart`
- `lib/widgets/dialogs/achievement_dialog.dart`
- `lib/widgets/dialogs/settings_dialog.dart`
- `lib/utils/dialog_utils.dart`

**Files to Modify:**
- `lib/screens/game_2048_page.dart`
- `lib/screens/snake_game_page.dart`
- `lib/screens/puzzle.dart`
- `lib/screens/infinite_runner_page.dart`

**Expected Impact:** Remove ~200+ lines of duplicate dialog code

---

## Phase 5: Testing Infrastructure

### 5.1 Add Unit Tests for New Components
**Status:** Not started

**Tasks:**
- [ ] Create `test/repositories/secure_storage_repository_test.dart`
- [ ] Create `test/repositories/user_repository_test.dart`
- [ ] Create `test/repositories/stats_repository_test.dart`
- [ ] Create `test/services/auth_service_test.dart` (with DI and mocks)
- [ ] Create `test/providers/mixins/game_stats_mixin_test.dart`
- [ ] Create `test/utils/input_validator_test.dart`
- [ ] Create `test/utils/secure_logger_test.dart`
- [ ] Create `test/utils/storage_migrator_test.dart`
- [ ] Create `test/core/game_registry_test.dart`

**Files to Create:**
- 9 new test files

**Target Coverage:** ~85% (up from ~60%)

---

### 5.2 Update Existing Tests
**Status:** Not started

**Tasks:**
- [ ] Update all existing test files to use service locator for DI
- [ ] Mock services instead of using real implementations
- [ ] Update tests for refactored providers (split UI/game state)
- [ ] Fix any broken tests due to file reorganization
- [ ] Ensure all tests pass: `flutter test`

**Files to Modify:**
- All existing test files in `test/`

---

## Phase 6: Documentation Updates

### 6.1 Update Existing Documentation
**Status:** Not started

**Tasks:**
- [ ] Update `README.md`:
  - Add architecture section with new structure
  - Add security notes
  - Update setup instructions
- [ ] Update `CLAUDE.md`:
  - Document new directory structure
  - Document DI pattern usage
  - Document security practices
  - Update game integration guide
- [ ] Update `docs/FIREBASE_SETUP_GUIDE.md`:
  - Add security rules deployment instructions
  - Document firebase_options.dart.template usage

**Files to Modify:**
- `README.md`
- `CLAUDE.md`
- `docs/FIREBASE_SETUP_GUIDE.md`

---

### 6.2 Create New Documentation
**Status:** Not started

**Tasks:**
- [ ] Create `docs/SECURITY.md`:
  - Security best practices
  - Secure storage usage
  - Input validation patterns
  - Logging guidelines
- [ ] Create `docs/ARCHITECTURE.md`:
  - Detailed architecture documentation
  - Dependency injection patterns
  - Repository pattern usage
  - Provider state management strategy
- [ ] Create `docs/ADDING_GAMES.md`:
  - Step-by-step guide for adding new games
  - Game registry usage
  - File structure requirements
  - Integration checklist

**Files to Create:**
- `docs/SECURITY.md`
- `docs/ARCHITECTURE.md`
- `docs/ADDING_GAMES.md`

---

## Verification Checklist

### After Each Phase
- [ ] Code builds successfully: `flutter build apk --release`
- [ ] All tests pass: `flutter test`
- [ ] No analyzer warnings: `flutter analyze`
- [ ] Code formatted: `dart format lib/ test/`

### Final Verification (After Phase 6)

**Security:**
- [ ] Verify firebase_options.dart not in git: `git ls-files | grep firebase_options.dart` (should be empty)
- [ ] Check no API keys in logs: Search codebase for `debugPrint.*[Kk]ey`
- [ ] Test secure storage: Verify user data encrypted on device
- [ ] Deploy Firestore rules to Firebase console
- [ ] Test input validation: Try malicious inputs in nickname field

**Architecture:**
- [ ] Build succeeds: `flutter build apk --release`
- [ ] All tests pass: `flutter test`
- [ ] No duplicate code: Verify mixins used, dialog widgets consolidated
- [ ] Service locator works: Verify services injected, not instantiated
- [ ] Add test game: Verify game registry pattern works

**Integration Testing:**
- [ ] Run app and play each game
- [ ] Verify achievements save correctly
- [ ] Verify leaderboard displays
- [ ] Test offline mode
- [ ] Test Firebase auth flow
- [ ] Verify score saving across all games

---

## Estimated Impact Summary

**Code Quality:**
- Remove ~250 lines of duplicate code (provider mixins)
- Remove ~200 lines of duplicate code (dialog widgets)
- Reduce provider complexity by 40%
- Improve test coverage from ~60% to ~85%

**Security:**
- ✅ Eliminated 4 critical vulnerabilities (Phase 1 complete)
- ✅ Closed 6 high-severity issues (Phase 1 complete)
- ✅ Implemented industry-standard security practices (Phase 1 complete)

**Maintainability:**
- Add new game in 1 file instead of 5+ (game registry)
- Clear separation of concerns (UI/game state split)
- Dependency injection enables easy testing
- Consistent game structure across all games

**Performance:**
- No negative impact (refactoring only)
- Slightly better memory usage with singletons

---

## Implementation Order

**Must be done in this order due to dependencies:**

1. **Phase 2.1** → Foundation for everything else (DI)
2. **Phase 2.2** → Organize services before creating repositories
3. **Phase 2.3** → Repository pattern needed for Phase 3
4. **Phase 3.1** → Mixin needed before splitting providers
5. **Phase 3.2** → Split providers before updating registration
6. **Phase 3.3** → Update provider registration with DI
7. **Phase 4.1** → Reorganize games before creating registry
8. **Phase 4.2** → Game registry can be done anytime after 4.1
9. **Phase 4.3** → Dialog consolidation can be done anytime
10. **Phase 5** → Test after structure is stable
11. **Phase 6** → Document final architecture

---

## Quick Start for Next Session

1. Start with Phase 2.1 (Service Locator)
2. Create `lib/config/service_locator.dart`
3. Register all existing services
4. Initialize in `lib/main.dart`
5. Update providers to use injected services

## Notes

- **Phase 1 complete**: All security fixes implemented ✅
- `get_it` package already added to pubspec.yaml
- `flutter_secure_storage` already added to pubspec.yaml
- Secure logging infrastructure in place
- Input validation utilities created
- Firestore security rules created (need deployment)
