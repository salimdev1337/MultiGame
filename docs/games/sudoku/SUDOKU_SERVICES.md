# Sudoku Services Guide

**Related Files**:
- [lib/games/sudoku/services/sudoku_persistence_service.dart](../lib/games/sudoku/services/sudoku_persistence_service.dart)
- [lib/games/sudoku/services/sudoku_stats_service.dart](../lib/games/sudoku/services/sudoku_stats_service.dart)
- [lib/games/sudoku/services/matchmaking_service.dart](../lib/games/sudoku/services/matchmaking_service.dart)
- [lib/games/sudoku/services/sudoku_sound_service.dart](../lib/games/sudoku/services/sudoku_sound_service.dart)
- [lib/games/sudoku/services/sudoku_haptic_service.dart](../lib/games/sudoku/services/sudoku_haptic_service.dart)

**See Also**:
- [SUDOKU_ARCHITECTURE.md](SUDOKU_ARCHITECTURE.md)
- [SUDOKU_ALGORITHMS.md](SUDOKU_ALGORITHMS.md)
- [SERVICES_GUIDE.md](SERVICES_GUIDE.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)

## Table of Contents
1. [Overview](#overview)
2. [Persistence Service](#persistence-service)
3. [Statistics Service](#statistics-service)
4. [Matchmaking Service](#matchmaking-service)
5. [Sound Service](#sound-service)
6. [Haptic Service](#haptic-service)

## Overview

Sudoku game services provide business logic and external integrations:

- **SudokuPersistenceService**: Local storage for saved games and history
- **SudokuStatsService**: Statistics tracking per mode/difficulty
- **MatchmakingService**: Firebase-based online multiplayer
- **SudokuSoundService**: Audio feedback (Phase 6)
- **SudokuHapticService**: Vibration feedback (Phase 6)

All services are injected via GetIt dependency injection and registered in `service_locator.dart`.

---

## Persistence Service

**File**: `lib/games/sudoku/services/sudoku_persistence_service.dart`

Service for persisting Sudoku game state and history.

### Purpose

This service uses SecureStorageRepository for encrypted local storage and handles:
- Saving/loading unfinished games
- Storing completed game history
- Managing best scores per difficulty

### Architecture

**Injected Dependencies**:
- `SecureStorageRepository`: Encrypted local storage (optional, defaults to new instance)

**Storage Keys**:
- `sudoku_saved_game_classic`: Classic mode saved game
- `sudoku_saved_game_rush`: Rush mode saved game
- `sudoku_completed_games`: History of completed games (last 100)
- `sudoku_best_scores_classic`: Best scores per difficulty (Classic)
- `sudoku_best_scores_rush`: Best scores per difficulty (Rush)

### Saved Games (Unfinished)

#### Save Game

**Method**: `saveSavedGame(SavedGame game)`

Saves an unfinished game to storage.

**Parameters**:
- `game`: SavedGame model with full game state

**Returns**: `bool` - Success/failure

**Storage**: JSON string of SavedGame serialization

**Logging**: Logs success/failure with 'SudokuPersistence' tag

#### Load Game

**Method**: `loadSavedGame(String mode)`

Loads a saved game by mode ('classic' or 'rush').

**Returns**: `SavedGame?` - Loaded game or null if not found

**Error Handling**: Returns null on error, logs error

#### Delete Saved Game

**Method**: `deleteSavedGame(String mode)`

Deletes a saved game by mode.

**Returns**: `bool` - Success/failure

**Use Case**: Called when game is completed (no longer needed)

#### Check Saved Game Exists

**Method**: `hasSavedGame(String mode)`

Checks if a saved game exists for the given mode.

**Returns**: `bool` - True if exists

**Use Case**: Show "Continue Game" vs "New Game" button

### Completed Games (History)

#### Save Completed Game

**Method**: `saveCompletedGame(CompletedGame game)`

Saves a completed game to history.

**Storage Limit**: Keeps only last 100 games to avoid storage bloat. When limit exceeded, removes oldest games.

**Returns**: `bool` - Success/failure

**Process**:
1. Load existing completed games
2. Add new game to list
3. If count > 100, remove oldest games
4. Serialize and save back to storage

#### Get Completed Games

**Method**: `getCompletedGames()`

Gets all completed games from history.

**Returns**: `List<CompletedGame>` - All games (max 100), or empty list on error

#### Get Completed Games by Mode

**Method**: `getCompletedGamesByMode(String mode)`

Gets completed games filtered by mode.

**Returns**: `List<CompletedGame>` - Filtered list

**Modes**: 'classic', 'rush', '1v1'

#### Get Completed Games by Difficulty

**Method**: `getCompletedGamesByDifficulty(SudokuDifficulty difficulty)`

Gets completed games filtered by difficulty.

**Returns**: `List<CompletedGame>` - Filtered list

#### Clear Completed Games

**Method**: `clearCompletedGames()`

Clears all completed game history.

**Returns**: `bool` - Success/failure

**Use Case**: User requests data reset

### Best Scores

#### Save Best Score

**Method**: `saveBestScore(String mode, SudokuDifficulty difficulty, int score)`

Saves best score for a difficulty/mode.

**Smart Update**: Only saves if it's a new high score (higher than current best).

**Returns**: `bool` - Success/failure

**Storage Format**: JSON map of difficulty name → score

Example:
```json
{
  "easy": 9500,
  "medium": 8700,
  "hard": 7200,
  "expert": 6100
}
```

#### Get Best Scores

**Method**: `getBestScores(String mode)`

Gets all best scores for a mode.

**Returns**: `Map<SudokuDifficulty, int>` - Map of difficulty → score, or empty map on error

#### Get Best Score

**Method**: `getBestScore(String mode, SudokuDifficulty difficulty)`

Gets best score for a specific difficulty/mode.

**Returns**: `int?` - Score or null if none exists

#### Clear Best Scores

**Method**: `clearBestScores(String mode)`

Clears all best scores for a mode.

**Returns**: `bool` - Success/failure

### General Operations

#### Clear All Data

**Method**: `clearAllData()`

Clears all Sudoku persistent data (for testing/reset).

**Deletes**:
- Both saved games (classic, rush)
- Completed games history
- Best scores (both modes)

**Returns**: `bool` - Success/failure

**Use Case**: Testing, user data reset

---

## Statistics Service

**File**: `lib/games/sudoku/services/sudoku_stats_service.dart`

Service for tracking detailed Sudoku statistics per mode and difficulty.

### Purpose

Tracks comprehensive statistics including:
- Games played/won
- Time statistics
- Mistake tracking
- Hints usage
- Win rates
- Perfect games (no mistakes, no hints)

### Architecture

**Injected Dependencies**:
- `SecureStorageRepository`: For local stats storage

**Storage Keys**:
- Per mode per difficulty: `sudoku_stats_{mode}_{difficulty}`
- Example: `sudoku_stats_classic_medium`

### Key Methods

#### Record Game Completion

**Method**: `recordGameCompletion(CompletedGame game)`

Records a completed game and updates statistics.

**Updates**:
- Total games played
- Games won (if victory)
- Total time played
- Best time (if new record)
- Total mistakes
- Total hints used
- Perfect games count (if no mistakes/hints)

**Returns**: `Future<void>`

#### Get Statistics

**Method**: `getStats(String mode, SudokuDifficulty difficulty)`

Gets statistics for a specific mode/difficulty.

**Returns**: `Future<SudokuStats>` - Stats object

**Default**: Returns empty stats if none exist

#### Reset Statistics

**Method**: `resetStats(String mode, SudokuDifficulty difficulty)`

Resets statistics for a specific mode/difficulty.

**Returns**: `Future<bool>` - Success/failure

#### Get All Statistics

**Method**: `getAllStats(String mode)`

Gets statistics for all difficulties in a mode.

**Returns**: `Future<Map<SudokuDifficulty, SudokuStats>>`

### Statistics Calculations

**Win Rate**: `(gamesWon / totalGames) × 100`

**Average Time**: `totalTimeSeconds / totalGames`

**Average Mistakes**: `totalMistakes / totalGames`

**Perfect Game Rate**: `(perfectGames / totalGames) × 100`

---

## Matchmaking Service

**File**: `lib/games/sudoku/services/matchmaking_service.dart`

Service for managing online 1v1 Sudoku matches with Firestore.

### Purpose

Handles all Firebase operations for online multiplayer:
- Creating match rooms
- Joining matches (random or by code)
- Real-time match updates
- Player board synchronization
- Connection state management
- Match lifecycle

### Architecture

**Injected Dependencies**:
- `FirebaseFirestore`: Firestore instance (optional, defaults to FirebaseFirestore.instance)

**Firestore Collection**: `sudoku_matches`

**Security**: Uses Firebase Security Rules (see `firestore.rules`)

### Match Creation

#### Create Match

**Method**: `createMatch(userId, displayName, difficulty)`

Creates a new match room and waits for opponent.

**Process**:
1. Generate new puzzle using SudokuGenerator
2. Generate unique 6-digit room code
3. Create MatchPlayer for player 1
4. Create MatchRoom document in Firestore
5. Set status to `waiting`

**Returns**: `Future<String>` - Match ID

**Room Code**: 6-digit PIN (e.g., "123456") for opponent to join

#### Join Available Match

**Method**: `joinAvailableMatch(userId, displayName, preferredDifficulty?)`

Finds and joins an available match.

**Query**: Searches for matches with:
- Status = `waiting`
- Optional: Specific difficulty
- Order: Oldest first (fairness)
- Limit: 1

**Process**:
1. Query for waiting matches
2. Check if found match
3. Verify user not already in match (can't join own room)
4. Create MatchPlayer for player 2
5. Update match: add player2, set status = `playing`, record startedAt

**Returns**: `Future<String?>` - Match ID or null if none available

**Note**: Returns null if user tries to join their own match

#### Quick Match

**Method**: `quickMatch(userId, displayName, difficulty)`

Finds available match or creates new one (convenience method).

**Process**:
1. Try to join existing match with preferred difficulty
2. If no match found, create new match

**Returns**: `Future<String>` - Match ID (always succeeds)

**Use Case**: "Quick Play" button - player doesn't care about room code

#### Join by Room Code

**Method**: `joinByRoomCode(roomCode, userId, displayName)`

Joins a match using a 6-digit room code.

**Query**: Searches for:
- roomCode = provided code
- status = `waiting`
- Limit: 1

**Validation**:
- Code must match existing room
- Room must be in `waiting` status
- User not already in match
- Room not full

**Returns**: `Future<String>` - Match ID

**Throws**: Exception if code invalid, room full, or user already in match

**Use Case**: Friend invites friend with code

### Match Monitoring

#### Watch Match

**Method**: `watchMatch(String matchId)`

Listens to match updates in real-time.

**Returns**: `Stream<MatchRoom>` - Real-time match updates

**Throws**: Exception if match not found

**Use Case**: Both players watch the same match document for live updates

**Implementation**: Uses Firestore snapshots for real-time sync

### Player Synchronization

#### Update Player Board

**Method**: `updatePlayerBoard(matchId, userId, board, isCompleted)`

Updates player's board state.

**Process**:
1. Get current match from Firestore
2. Identify if player1 or player2
3. Count filled cells from board
4. Create updated player state
5. Update Firestore document
6. If completed and first to finish: set winnerId, status = `completed`

**Updates**:
- `boardState`: 2D array of cell values
- `filledCells`: Count for progress tracking
- `isCompleted`: Boolean flag
- `completionTime`: Timestamp (if first completion)
- `lastActivityAt`: Track activity

**Winner Detection**: First player to complete sets `winnerId` and ends match

**Returns**: `Future<void>`

**Note**: This method includes full board state sync. For frequent updates, use `updatePlayerStats()` instead.

#### Update Player Stats

**Method**: `updatePlayerStats(matchId, userId, mistakeCount, hintsUsed)`

Lightweight update that only syncs stats, not full board state.

**Purpose**: Reduce Firestore writes by only syncing mistake/hint counters (not 81-cell board array)

**Updates**:
- `mistakeCount`: Number of mistakes
- `hintsUsed`: Number of hints used

**Returns**: `Future<void>`

**Cost Optimization**: Syncing stats only is ~80-90% cheaper than full board updates

#### Update Connection State

**Method**: `updateConnectionState(matchId, userId, isConnected)`

Updates lastSeenAt timestamp and isConnected flag.

**Updates**:
- `lastSeenAt`: Current timestamp
- `isConnected`: Boolean flag
- `lastActivityAt`: Match activity timestamp

**Returns**: `Future<void>`

**Use Case**: Heartbeat system (called every 5 seconds)

**Reconnection Grace Period**: 60 seconds before showing "disconnected"

### Match Lifecycle

#### Cancel Match

**Method**: `cancelMatch(String matchId)`

Cancels a match (for when player leaves before/during game).

**Updates**:
- `status` = `cancelled`
- `endedAt` = current timestamp

**Returns**: `Future<void>`

**Use Case**: Player exits before completion

#### Leave Match

**Method**: `leaveMatch(String matchId, String userId)`

Leaves a match room.

**Process**:
1. Get current match
2. If status is `waiting` or `playing`, cancel the match

**Returns**: `Future<void>`

**Note**: Only cancels if match is still active

#### Handle Timeout

**Method**: `handleTimeout(String matchId)`

Handles match timeout.

**Process**:
1. Check if match has timed out (default: 10 minutes)
2. If yes and no winner yet, determine winner by progress:
   - Player with most filled cells wins
   - If tied, no winner (draw)
3. Update match: status = `completed`, set winnerId (or null for tie)

**Returns**: `Future<void>`

**Use Case**: Background job to clean up abandoned matches

### Match Queries

#### Get Match

**Method**: `getMatch(String matchId)`

Gets match by ID (one-time read, not real-time).

**Returns**: `Future<MatchRoom?>` - Match or null if not found

**Use Case**: Initial load, verification

### Maintenance

#### Clean Up Old Matches

**Method**: `cleanupOldMatches()`

Cleans up old matches (completed/cancelled matches older than 24 hours).

**Process**:
1. Query for matches where `endedAt` < 24 hours ago
2. Delete all matching documents in batch

**Returns**: `Future<void>`

**Use Case**: Background maintenance job to prevent Firestore bloat

**Note**: Does not throw on error (cleanup is non-critical)

### Helper Functions

#### Generate Room Code

**Method**: `_generateRoomCode()`

Generates a unique 6-digit room code.

**Returns**: `String` - 6-digit code (e.g., "123456")

**Implementation**: Random number generation

#### Parse Difficulty

**Method**: `_parseDifficulty(String difficulty)`

Parses difficulty string to enum.

**Supports**: 'easy', 'medium', 'hard', 'expert' (case-insensitive)

**Default**: Falls back to `medium` for invalid input

---

## Sound Service

**File**: `lib/games/sudoku/services/sudoku_sound_service.dart`

Service for playing audio feedback during gameplay (Phase 6 feature).

### Purpose

Provides immersive audio feedback for all game actions.

### Architecture

**Injected Dependencies**:
- `SudokuSettingsProvider`: To check if sound is enabled
- Audio player package (e.g., `audioplayers`)

### Sound Effects

**Available Sounds**:
- `playSelectCell()`: Cell selection sound
- `playNumberEntry()`: Number placement sound
- `playNotesToggle()`: Pencil mark toggle sound
- `playErase()`: Cell erase sound
- `playUndo()`: Undo action sound
- `playHint()`: Hint usage sound
- `playError()`: Error/conflict sound
- `playVictory()`: Puzzle completion sound

### Implementation

Each method:
1. Checks if sound is enabled via `SudokuSettingsProvider`
2. If enabled, plays corresponding audio file
3. Handles errors gracefully (doesn't crash if audio fails)

**Audio Files**: Located in `assets/sounds/sudoku/`

### Volume Control

Respects user settings:
- User can toggle sound on/off in settings
- Uses system volume for playback
- Doesn't override system sound settings

---

## Haptic Service

**File**: `lib/games/sudoku/services/sudoku_haptic_service.dart`

Service for providing haptic (vibration) feedback during gameplay (Phase 6 feature).

### Purpose

Enhances tactile experience with vibration patterns.

### Architecture

**Injected Dependencies**:
- `SudokuSettingsProvider`: To check if haptics are enabled
- Platform-specific vibration API

### Haptic Patterns

**Available Patterns**:
- `lightTap()`: Light vibration (cell select, notes)
- `mediumTap()`: Medium vibration (number entry, undo, erase)
- `doubleTap()`: Double vibration (hint usage)
- `errorShake()`: Strong vibration (error detected)
- `successPattern()`: Victory vibration sequence

### Implementation

Each method:
1. Checks if haptics are enabled via `SudokuSettingsProvider`
2. If enabled, triggers vibration pattern
3. Handles platform differences (iOS/Android have different APIs)

**Vibration Intensities**:
- Light: 10-20ms
- Medium: 30-50ms
- Strong: 100ms
- Pattern: Custom sequences

### Platform Support

- **iOS**: Uses UIImpactFeedbackGenerator
- **Android**: Uses Vibrator API
- **Web**: No haptic support (silently ignored)

---

## Service Integration Example

### Complete Game Flow with All Services

```dart
// 1. User starts new game
await sudokuProvider.initializeGame(SudokuDifficulty.medium);

// 2. User makes a move
sudokuProvider.placeNumber(5);
  // → soundService.playNumberEntry()
  // → hapticService.mediumTap()
  // → persistenceService.saveGameState() (auto-save)

// 3. User makes a mistake (conflict detected)
  // → soundService.playError()
  // → hapticService.errorShake()

// 4. User uses a hint
sudokuProvider.useHint();
  // → soundService.playHint()
  // → hapticService.doubleTap()

// 5. User completes puzzle
  // → soundService.playVictory()
  // → hapticService.successPattern()
  // → persistenceService.saveCompletedGame(completedGame)
  // → persistenceService.saveBestScore(mode, difficulty, score)
  // → sudokuStatsService.recordGameCompletion(completedGame)
  // → persistenceService.deleteSavedGame(mode) // Clean up
```

### Online Match Flow with Services

```dart
// 1. Create match
final matchId = await matchmakingService.createMatch(
  userId: 'user123',
  displayName: 'Player1',
  difficulty: 'medium',
);
  // → Firestore: Create match document with puzzle

// 2. Opponent joins via code
final matchId = await matchmakingService.joinByRoomCode(
  roomCode: '123456',
  userId: 'user456',
  displayName: 'Player2',
);
  // → Firestore: Update match with player2

// 3. Both players watch match
matchmakingService.watchMatch(matchId).listen((matchRoom) {
  // Real-time updates
});

// 4. Player makes move
await matchmakingService.updatePlayerBoard(
  matchId: matchId,
  userId: userId,
  board: currentBoard,
  isCompleted: false,
);
  // → Firestore: Update player board state

// 5. Heartbeat (every 5 seconds)
await matchmakingService.updateConnectionState(
  matchId: matchId,
  userId: userId,
  isConnected: true,
);
  // → Firestore: Update lastSeenAt

// 6. Player completes first
await matchmakingService.updatePlayerBoard(
  matchId: matchId,
  userId: userId,
  board: completedBoard,
  isCompleted: true,
);
  // → Firestore: Set winnerId, status = completed
  // → Both players notified via watch stream
```

---

## Testing Strategy

### Persistence Service Tests

Mock `SecureStorageRepository`:
- Save/load operations work correctly
- Storage limit enforced (100 games)
- Best score logic (only saves new highs)
- Error handling

### Stats Service Tests

Mock `SecureStorageRepository`:
- Stats calculation correctness
- Accumulation across multiple games
- Win rate and averages
- Perfect game detection

### Matchmaking Service Tests

Mock `FirebaseFirestore`:
- Match creation with puzzle generation
- Join logic (random, by code)
- Player updates trigger correct Firestore writes
- Winner detection
- Timeout handling
- Connection state updates

### Sound/Haptic Service Tests

Mock settings provider:
- Sounds play when enabled
- Sounds skip when disabled
- Platform-specific implementations
- Error handling (missing audio files)

---

## Related Documentation

- [SUDOKU_ARCHITECTURE.md](SUDOKU_ARCHITECTURE.md) - Models and state management
- [SUDOKU_ALGORITHMS.md](SUDOKU_ALGORITHMS.md) - Core game logic
- [SERVICES_GUIDE.md](SERVICES_GUIDE.md) - Global services architecture
- [SECURITY.md](SECURITY.md) - Secure storage and Firebase security
