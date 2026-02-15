# Sudoku Architecture Guide

**Related Files**:
- [lib/games/sudoku/models/](../lib/games/sudoku/models/)
- [lib/games/sudoku/providers/](../lib/games/sudoku/providers/)
- [lib/games/sudoku/widgets/](../lib/games/sudoku/widgets/)
- [lib/games/sudoku/screens/](../lib/games/sudoku/screens/)

**See Also**:
- [SUDOKU_ALGORITHMS.md](SUDOKU_ALGORITHMS.md)
- [SUDOKU_SERVICES.md](SUDOKU_SERVICES.md)
- [STATE_MANAGEMENT_GUIDE.md](STATE_MANAGEMENT_GUIDE.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)

## Table of Contents
1. [Overview](#overview)
2. [Game Modes](#game-modes)
3. [Data Models](#data-models)
4. [State Management](#state-management)
5. [UI Components](#ui-components)
6. [Screens](#screens)

## Overview

The Sudoku game features a layered architecture following MultiGame patterns:

```
Screens (UI)
     ↓
Providers (State Management)
     ↓
Services (Business Logic)
     ↓
Logic (Pure Functions)
     ↓
Models (Data)
```

### Key Architectural Principles

1. **Separation of Concerns**: Game state separate from UI state
2. **Dependency Injection**: Services injected via GetIt
3. **Pure Logic Layer**: Generator, solver, validator have no dependencies
4. **Provider Pattern**: Separate providers for Classic, Rush, Online, UI, and Settings
5. **Auto-save**: Games automatically persist progress

---

## Game Modes

The Sudoku game supports three distinct modes:

### Classic Mode
Traditional sudoku with difficulty levels (Easy, Medium, Hard, Expert).
- Single-player
- Untimed (tracked for stats)
- 3 hints available
- Error highlighting
- Undo functionality

### Rush Mode
Time-limited challenges with progressive difficulty.
- Single-player
- Time-limited rounds
- Progressive difficulty scaling
- Score-based gameplay
- High score tracking

### 1v1 Online Mode
Real-time multiplayer via Firebase.
- Two players compete on same puzzle
- Room code matchmaking
- Live opponent stats sync
- Connection state tracking
- Hints system (3 per game)
- First to complete wins

---

## Data Models

### Core Models

#### SudokuCell

**File**: `lib/games/sudoku/models/sudoku_cell.dart`

Represents a single cell in a Sudoku grid.

**Properties**:
- `value` (int?): The current value of the cell (1-9), or null if empty
- `isFixed` (bool): Whether this cell is part of the initial puzzle (cannot be edited)
- `notes` (Set<int>): Pencil marks/notes for this cell (numbers 1-9), used by players to track possible values
- `isError` (bool): Whether this cell has a validation error (conflict with row/column/box), used for visual feedback

**Key Methods**:
- `isEmpty`: Returns true if the cell is empty (no value)
- `hasValue`: Returns true if the cell has a value
- `hasNotes`: Returns true if the cell has any notes
- `isValidValue`: Returns true if the value is valid (null or 1-9)
- `copyWith()`: Creates a copy with specified properties changed
- `clear()`: Clears the cell value (keeps notes and fixed status)
- `toJson()` / `fromJson()`: Serialization for storage

#### SudokuBoard

**File**: `lib/games/sudoku/models/sudoku_board.dart`

Represents a complete 9x9 Sudoku board.

**Structure**:
The board is organized as a 2D grid where:
- `grid[row][col]` accesses a specific cell
- Rows and columns are indexed 0-8
- The board is divided into nine 3x3 boxes (also indexed 0-8)

**Box Numbering**:
```
0 | 1 | 2
--+---+--
3 | 4 | 5
--+---+--
6 | 7 | 8
```

**Properties**:
- `grid` (List<List<SudokuCell>>): The 9x9 grid of cells

**Constructors**:
- `SudokuBoard()`: Creates a board with optional initial grid
- `SudokuBoard.empty()`: Creates an empty 9x9 board (all cells empty)
- `SudokuBoard.fromValues(values)`: Creates from 2D integer array (0=empty, 1-9=fixed clues)
- `SudokuBoard.fromJson(json)`: Deserializes from JSON

**Key Methods**:
- `getCell(row, col)`: Gets the cell at the specified position
- `setCell(row, col, cell)`: Sets a cell at the specified position
- `getRow(row)`: Returns all cells in the specified row (0-8)
- `getColumn(col)`: Returns all cells in the specified column (0-8)
- `getBox(row, col)`: Returns all cells in the 3x3 box containing the specified position
- `getBoxByIndex(boxIndex)`: Returns all cells in the specified box by box index (0-8)
- `isFull`: Returns true if all cells have values
- `hasEmptyCells`: Returns true if the board has at least one empty cell
- `emptyCount`: Counts the number of empty cells
- `filledCount`: Counts the number of filled cells (81 - emptyCount)
- `reset()`: Resets all non-fixed cells (clears user entries, keeps puzzle clues)
- `clearErrors()`: Clears all error flags on the board
- `clone()`: Creates a deep copy of this board
- `toValues()`: Converts to 2D integer array (for saving/loading)
- `toJson()` / `fromJson()`: Serialization
- `toString()`: String representation (useful for debugging)

### Action and History Models

#### SudokuAction

**File**: `lib/games/sudoku/models/sudoku_action.dart`

Represents a user action for undo functionality.

**Action Types**:
- `setValue`: User placed a number
- `clearValue`: User erased a cell
- `addNote`: User added a pencil mark
- `removeNote`: User removed a pencil mark

**Properties**:
- `type`: The action type
- `row`, `col`: Cell position
- `value`: The value involved (if applicable)
- `previousValue`: Previous cell value (for undo)
- `previousNotes`: Previous notes state (for undo)

### Game State Models

#### SavedGame

**File**: `lib/games/sudoku/models/saved_game.dart`

Represents a saved in-progress game for persistence.

**Properties**:
- `id`: Unique identifier
- `mode`: Game mode ('classic', 'rush', '1v1')
- `difficulty`: Difficulty level
- `currentBoard`: Current game state
- `originalBoard`: Initial puzzle (for reset)
- `solvedBoard`: Pre-solved board (for hints)
- `elapsedSeconds`: Time played
- `mistakes`: Mistake count
- `hintsUsed`: Hints used count
- `hintsRemaining`: Hints remaining
- `selectedRow`, `selectedCol`: Current selection
- `notesMode`: Whether notes mode is active
- `actionHistory`: List of actions for undo
- `savedAt`: Timestamp of save

**Serialization**: Supports `toJson()` / `fromJson()` and `toJsonString()` / `fromJsonString()`

#### CompletedGame

**File**: `lib/games/sudoku/models/completed_game.dart`

Represents a completed game for history tracking.

**Properties**:
- `id`: Unique identifier
- `mode`: Game mode
- `difficulty`: Difficulty level
- `score`: Final score
- `timeSeconds`: Time taken
- `mistakes`: Total mistakes
- `hintsUsed`: Total hints used
- `victory`: Whether won or lost
- `completedAt`: Timestamp of completion

**Serialization**: Supports `toJson()` / `fromJson()`

### Online Multiplayer Models

#### MatchRoom

**File**: `lib/games/sudoku/models/match_room.dart`

Represents a Firebase online match room.

**Properties**:
- `matchId`: Unique match identifier
- `roomCode`: 6-digit PIN for joining
- `puzzleData`: The puzzle both players solve
- `difficulty`: Difficulty level
- `player1`, `player2`: Player states
- `status`: Match status (waiting, playing, completed, cancelled)
- `winnerId`: User ID of winner
- `createdAt`, `startedAt`, `endedAt`: Timestamps
- `timeLimit`: Time limit in seconds (default: 600)

**Key Methods**:
- `hasPlayer(userId)`: Check if user is in match
- `isFull`: Check if both players joined
- `hasTimedOut`: Check if time limit exceeded

#### MatchPlayer

**File**: `lib/games/sudoku/models/match_player.dart`

Represents a player in an online match.

**Properties**:
- `userId`: Firebase user ID
- `displayName`: Player name
- `boardState`: Current board state (2D array)
- `filledCells`: Number of filled cells
- `mistakeCount`: Number of mistakes
- `hintsUsed`: Number of hints used
- `isCompleted`: Whether finished puzzle
- `completionTime`: When completed
- `lastSeenAt`: Last connection timestamp
- `isConnected`: Connection status

**Factory Methods**:
- `MatchPlayer.initial()`: Create initial player state
- `copyWith()`: Update specific properties

#### MatchStatus

**File**: `lib/games/sudoku/models/match_status.dart`

Match lifecycle states:
- `waiting`: Room created, waiting for opponent
- `playing`: Both players joined, game in progress
- `completed`: Game finished
- `cancelled`: Match cancelled

#### ConnectionState

**File**: `lib/games/sudoku/models/connection_state.dart`

Player connection states:
- `online`: Currently connected
- `offline`: Disconnected
- `reconnecting`: Attempting to reconnect

### Statistics Models

#### SudokuStats

**File**: `lib/games/sudoku/models/sudoku_stats.dart`

Tracks player statistics per mode/difficulty.

**Properties**:
- Total games played
- Games won
- Total time played
- Average time per game
- Best time
- Total mistakes
- Average mistakes per game
- Hints used
- Win rate
- Perfect games (no mistakes, no hints)

---

## State Management

### Provider Architecture

Sudoku uses **multiple providers** following the separation of game state and UI state pattern:

```
SudokuProvider (Classic game logic)
SudokuRushProvider (Rush game logic)
SudokuOnlineProvider (1v1 game logic)
SudokuUIProvider (UI state for all modes)
SudokuSettingsProvider (User preferences)
```

### SudokuProvider (Classic Mode)

**File**: `lib/games/sudoku/providers/sudoku_provider.dart`

Main provider for Sudoku Classic Mode game state and logic.

**Architecture Notes**:
- Uses `GameStatsMixin` for Firebase score saving
- Injects services via GetIt dependency injection
- Separates game logic from UI state (UI state in SudokuUIProvider)

**Injected Services**:
- `FirebaseStatsService`: Global stats saving
- `SudokuPersistenceService`: Save/load games
- `SudokuStatsService`: Sudoku-specific stats
- `SudokuSoundService`: Audio feedback (Phase 6)
- `SudokuHapticService`: Vibration feedback (Phase 6)

**Game State**:
- `currentBoard`: Current board state
- `originalBoard`: Initial puzzle (for reset)
- `solvedBoard`: Cached solution for hints
- `difficulty`: Current difficulty level

**Selection State**:
- `selectedRow`, `selectedCol`: Currently selected cell
- `notesMode`: Whether in pencil marks mode

**Game Progress**:
- `mistakes`: Mistake count
- `hintsUsed`: Hints used
- `hintsRemaining`: Hints remaining (max 3)
- `elapsedSeconds`: Time elapsed
- `isGameOver`: Game finished flag
- `isVictory`: Won/lost flag

**Action History**:
- `actionHistory`: List of SudokuAction for undo functionality

**Settings**:
- `errorHighlightEnabled`: Whether to highlight errors in real-time

**Key Methods**:

*Game Initialization*:
- `initializeGame(difficulty)`: Start new game at specified difficulty
- `resetGame()`: Reset to original puzzle state
- `loadGameState()`: Load saved game from persistence
- `saveGameState()`: Auto-save current game
- `hasSavedGame()`: Check if saved game exists

*Timer Management*:
- `pauseTimer()`: Pause the game timer
- `resumeTimer()`: Resume the game timer

*Cell Selection*:
- `selectCell(row, col)`: Select a cell (plays sound/haptic feedback)
- `clearSelection()`: Deselect current cell

*Gameplay*:
- `placeNumber(number)`: Place number in selected cell (or toggle note in notes mode)
- `eraseCell()`: Clear selected cell
- `toggleNotesMode()`: Switch between value and notes mode
- `useHint()`: Use a hint to reveal one cell
- `undo()`: Undo last action
- `toggleErrorHighlighting(enabled)`: Enable/disable error highlights

*Internal Logic*:
- `_placeValue(number)`: Place value (not notes)
- `_toggleNote(number)`: Toggle pencil mark
- `_validateAndHighlightErrors()`: Check board for conflicts and mark errors
- `_checkWinCondition()`: Check if puzzle solved correctly
- `_handleVictory()`: Handle game completion (save score, achievements, stats)
- `_calculateScore()`: Calculate final score based on time, mistakes, hints

**Score Calculation**:
```
baseScore = 10000
mistakePenalty = mistakes × 100
hintPenalty = hintsUsed × 200
timePenalty = elapsedSeconds
finalScore = clamp(baseScore - mistakePenalty - hintPenalty - timePenalty, 0, 10000)
```

**Phase 6 Sound/Haptic Feedback**:
- Cell selection: Light tap + select sound
- Number entry: Medium tap + number sound
- Notes toggle: Light tap + notes sound
- Erase: Medium tap + erase sound
- Hint: Double tap + hint sound
- Undo: Medium tap + undo sound
- Error: Error shake + error sound
- Victory: Success pattern + victory sound

**Persistence**:
The provider automatically saves game state via `SudokuPersistenceService`. Games can be loaded on app restart.

### SudokuRushProvider

**File**: `lib/games/sudoku/providers/sudoku_rush_provider.dart`

Provider for Rush Mode (time-limited challenges).

**Additional State** (vs Classic):
- Time limit per round
- Progressive difficulty scaling
- Round counter
- Rush-specific scoring

**Key Differences**:
- Timer counts down instead of up
- New puzzle generated when solved
- Difficulty increases with rounds
- Higher score multipliers

### SudokuOnlineProvider

**File**: `lib/games/sudoku/providers/sudoku_online_provider.dart`

Provider for 1v1 Online Mode.

**Additional State**:
- `matchRoom`: Current match state
- `currentUserId`: Local player ID
- `isHost`: Whether player created the room
- `opponentStats`: Opponent's live stats
- Connection state tracking
- Heartbeat monitoring

**Multiplayer Features**:
- Room code matchmaking
- Real-time opponent sync with debounced Firestore writes (80-90% cost reduction)
- Hints system (3 per game, pre-solved board)
- Connection handling with automatic reconnection (60s grace period)
- Heartbeat monitoring (5-second intervals)
- Opponent stats tracking (mistakes, hints, connection state)
- Live connection status indicators

**Key Methods**:
- `createMatch()`: Create new match room
- `joinMatch(roomCode)`: Join via room code
- `quickMatch()`: Auto-match with available player
- `watchMatch()`: Listen to real-time updates
- `updatePlayerBoard()`: Sync board state (debounced)
- `updatePlayerStats()`: Sync stats only (lightweight)
- `updateConnectionState()`: Update heartbeat
- `leaveMatch()`: Leave match room

### SudokuUIProvider

**File**: `lib/games/sudoku/providers/sudoku_ui_provider.dart`

Manages UI-specific state (loading, dialogs, animations) separate from game logic.

**UI State**:
- `isLoading`: Loading indicator
- `showingDialog`: Dialog visibility
- `animationStates`: UI animation states

**Why Separate UI Provider?**
- Keeps game logic pure and testable
- UI changes don't trigger game state rebuilds
- Cleaner separation of concerns

### SudokuSettingsProvider

**File**: `lib/games/sudoku/providers/sudoku_settings_provider.dart`

Manages user preferences (injected via GetIt).

**Settings**:
- Sound enabled/disabled
- Haptics enabled/disabled
- Theme preferences
- Error highlighting preference

**Persistence**:
Settings are persisted via SecureStorageRepository and loaded on app start.

---

## UI Components

### Widgets

#### SudokuGrid

**File**: `lib/games/sudoku/widgets/sudoku_grid.dart`

Main grid component rendering the 9x9 Sudoku board.

**Features**:
- Renders all 81 cells
- Highlights selected cell
- Shows related cells (same row/column/box)
- Box borders (3x3 grouping)
- Touch/tap handling for cell selection

#### SudokuCellWidget

**File**: `lib/games/sudoku/widgets/sudoku_cell_widget.dart`

Individual cell rendering.

**Visual States**:
- Empty cell
- Filled cell (user-entered or fixed)
- Selected cell
- Related cell (same row/column/box as selected)
- Error cell (conflict detected)
- Notes mode (small pencil marks)

**Styling**:
- Fixed cells: Bold, darker color
- User cells: Regular weight, lighter color
- Error cells: Red background/border
- Selected cell: Blue highlight

#### NumberPad

**File**: `lib/games/sudoku/widgets/number_pad.dart`

Input control for placing numbers 1-9.

**Features**:
- 3x3 grid of number buttons
- Shows count of each number already used
- Disables numbers when 9 placed
- Visual feedback on tap

#### ControlButtons

**File**: `lib/games/sudoku/widgets/control_buttons.dart`

Game control buttons.

**Buttons**:
- Undo: Revert last action
- Erase: Clear selected cell
- Notes: Toggle pencil marks mode
- Hint: Reveal correct value for random cell

**State**:
- Undo disabled when history empty
- Erase disabled when no cell selected or cell is fixed
- Hint disabled when no hints remaining
- Notes button shows active state

#### StatsPanel

**File**: `lib/games/sudoku/widgets/stats_panel.dart`

Displays game statistics during play.

**Displayed Stats**:
- Timer (MM:SS format)
- Mistakes count
- Hints remaining
- Difficulty level

**Online Mode Additions**:
- Opponent name
- Opponent progress (filled cells)
- Opponent mistakes
- Opponent hints used
- Connection status indicator

---

## Screens

### Mode Selection Screen

**File**: `lib/games/sudoku/screens/modern_mode_difficulty_screen.dart`

Entry point for Sudoku - choose game mode:
- Classic Mode
- Rush Mode
- 1v1 Online Mode

### Difficulty Selection Screen

**File**: `lib/games/sudoku/screens/modern_mode_difficulty_screen.dart`

Choose difficulty level:
- Easy
- Medium
- Hard
- Expert

Shows best score for each difficulty.

### Classic Game Screen

**File**: `lib/games/sudoku/screens/sudoku_classic_screen.dart`

Main gameplay screen for Classic Mode.

**Layout**:
- App bar with pause/settings
- Stats panel (timer, mistakes, hints)
- Sudoku grid (9x9)
- Control buttons (undo, erase, notes, hint)
- Number pad (1-9)

**Features**:
- Auto-save on every move
- Load saved game on launch
- Pause menu
- Victory dialog
- Settings access

### Rush Game Screen

**File**: `lib/games/sudoku/screens/sudoku_rush_screen.dart`

Main gameplay screen for Rush Mode.

**Differences from Classic**:
- Countdown timer (not countup)
- Round counter
- Progressive difficulty display
- No save/load (continuous gameplay)

### Online Matchmaking Screen

**File**: `lib/games/sudoku/screens/sudoku_online_matchmaking_screen.dart`

Matchmaking lobby for 1v1 mode.

**Options**:
- Create Room: Generate room code and wait
- Join Room: Enter 6-digit code
- Quick Match: Auto-match with available player

**Features**:
- Room code display/input
- Difficulty selection
- Waiting indicator
- Cancel option

### Online Game Screen

**File**: `lib/games/sudoku/screens/sudoku_online_game_screen.dart`

Main gameplay screen for 1v1 Online Mode.

**Layout**: Similar to Classic with additions:
- Opponent info panel
- Connection status indicators
- Opponent progress bar
- Real-time opponent stats

**Features**:
- Live opponent board sync
- Connection state monitoring
- Heartbeat system
- Disconnect handling
- Victory/defeat detection

### Online Result Screen

**File**: `lib/games/sudoku/screens/sudoku_online_result_screen.dart`

Post-game results for 1v1 mode.

**Displays**:
- Winner/loser
- Final times
- Mistakes comparison
- Hints used comparison
- Score breakdown

**Actions**:
- Rematch (create new room)
- Return to mode selection

### Settings Screen

**File**: `lib/games/sudoku/screens/sudoku_settings_screen.dart`

Sudoku-specific settings.

**Options**:
- Sound effects: On/Off
- Haptic feedback: On/Off
- Error highlighting: On/Off
- Reset statistics
- Clear saved games

---

## Architecture Flow Examples

### Starting a New Classic Game

```
1. User taps "Classic Mode" → Navigate to difficulty screen
2. User selects "Medium" → SudokuProvider.initializeGame(SudokuDifficulty.medium)
3. Provider generates puzzle via SudokuGenerator
4. Provider pre-solves for hints via SudokuSolver
5. Provider starts timer
6. Navigate to SudokuClassicScreen
7. Screen watches SudokuProvider
8. User makes moves → Provider updates state → Screen rebuilds
9. Provider auto-saves after each move
10. User completes puzzle → Provider validates → Handle victory
```

### Using a Hint

```
1. User taps "Hint" button
2. ControlButtons calls SudokuProvider.useHint()
3. Provider checks hints remaining > 0
4. Provider finds random empty cell
5. Provider looks up correct value from solved board
6. Provider records action in history (for undo)
7. Provider places value and selects cell
8. Provider decrements hints remaining
9. Provider plays sound/haptic feedback
10. Provider re-validates board
11. Provider checks win condition
12. Provider notifies listeners → UI rebuilds
```

### Online Match Flow

```
1. User taps "Create Room"
2. OnlineMatchmakingScreen calls MatchmakingService.createMatch()
3. Service generates puzzle + room code
4. Service creates MatchRoom in Firestore
5. Screen shows "Waiting for opponent..." with room code
6. Opponent enters code and joins
7. MatchmakingService updates room status to "playing"
8. Both players navigate to SudokuOnlineGameScreen
9. Each player's moves trigger SudokuOnlineProvider.updatePlayerBoard()
10. Provider debounces writes and updates Firestore
11. Both providers watch match via MatchmakingService.watchMatch()
12. Real-time updates flow: Firestore → Provider → UI
13. First player to complete triggers winnerId update
14. Both providers detect completion → Navigate to result screen
```

---

## Testing Strategy

### Model Tests

Test data structures and serialization:
- SudokuBoard creation and manipulation
- SudokuCell state changes
- SavedGame serialization
- MatchRoom Firebase format

### Provider Tests

Test state management with mocked services:
- Game initialization
- Move validation
- Score calculation
- Undo functionality
- Victory detection
- Auto-save triggers

### Widget Tests

Test UI components with mock providers:
- Grid rendering
- Cell selection
- Number pad input
- Control button states

### Integration Tests

Test complete flows:
- Start game → Make moves → Complete puzzle
- Use hint → Undo → Complete
- Create match → Join → Play → Finish

---

## Related Documentation

- [SUDOKU_ALGORITHMS.md](SUDOKU_ALGORITHMS.md) - Detailed algorithm explanations
- [SUDOKU_SERVICES.md](SUDOKU_SERVICES.md) - Persistence, stats, matchmaking services
- [STATE_MANAGEMENT_GUIDE.md](STATE_MANAGEMENT_GUIDE.md) - Provider patterns
- [CODE_PATTERNS.md](CODE_PATTERNS.md) - DI and architectural patterns
