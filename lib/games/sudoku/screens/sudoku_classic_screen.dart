import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/sudoku_generator.dart';
import '../providers/sudoku_provider.dart';
import '../providers/sudoku_ui_provider.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/control_buttons.dart';
import '../widgets/stats_panel.dart';

// Color constants
const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _primaryCyan = Color(0xFF00d4ff);

/// Main game screen for Sudoku Classic Mode.
///
/// Assembles all widgets and handles game flow:
/// - Header with back/settings buttons
/// - Stats panel (glass morphism)
/// - Sudoku grid (9×9)
/// - Control buttons (Undo/Erase/Notes/Hint)
/// - Number pad (1-9)
///
/// Features:
/// - Auto-save after every move
/// - Victory dialog on completion
/// - Error shake animation
/// - Cell selection highlighting
class SudokuClassicScreen extends StatefulWidget {
  /// Difficulty level for this game
  final SudokuDifficulty difficulty;

  const SudokuClassicScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<SudokuClassicScreen> createState() => _SudokuClassicScreenState();
}

class _SudokuClassicScreenState extends State<SudokuClassicScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize game after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  /// Initializes the game with loading state
  Future<void> _initializeGame() async {
    final uiProvider = context.read<SudokuUIProvider>();
    final gameProvider = context.read<SudokuProvider>();

    uiProvider.setLoading(true);
    await gameProvider.initializeGame(widget.difficulty);
    uiProvider.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      body: SafeArea(
        child: Consumer2<SudokuProvider, SudokuUIProvider>(
          builder: (context, gameProvider, uiProvider, child) {
            // Show loading indicator during generation
            if (uiProvider.isLoading || gameProvider.currentBoard == null) {
              return _buildLoading();
            }

            // Show victory dialog if game won
            if (gameProvider.isVictory && !uiProvider.showVictoryDialog) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showVictoryDialog(gameProvider);
              });
            }

            // Use LayoutBuilder to detect available space
            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate space taken by fixed-height widgets
                const headerHeight = 44.0; // Header height
                const statsHeight = 80.0; // Stats panel height
                const controlButtonsHeight = 90.0; // Control buttons height
                const numberPadHeight = 60.0; // Number pad height (always inline)
                const spacing = 32.0; // Total spacing between widgets

                // Calculate remaining space for grid
                final remainingHeight = constraints.maxHeight -
                    headerHeight - statsHeight - controlButtonsHeight -
                    numberPadHeight - spacing;

                // Determine if we should use compact mode for number pad
                // Use compact mode on smaller screens for tighter spacing
                final useCompactMode = constraints.maxHeight < 700;

                // Calculate grid size (uses remaining space)
                // Grid should be square, so use the smaller of width or height
                final maxWidth = constraints.maxWidth - 32;
                final gridSize = (maxWidth < remainingHeight ? maxWidth : remainingHeight)
                    .clamp(250.0, 600.0);

                return Column(
                  children: [
                    // Header
                    _buildHeader(context),
                    // Stats panel
                    StatsPanel(
                      mistakes: gameProvider.mistakes,
                      score: gameProvider.score,
                      formattedTime: gameProvider.formattedTime,
                    ),
                    const SizedBox(height: 8),
                    // Sudoku grid - main focus
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: gridSize,
                            height: gridSize,
                            child: SudokuGrid(
                              board: gameProvider.currentBoard!,
                              selectedRow: gameProvider.selectedRow,
                              selectedCol: gameProvider.selectedCol,
                              selectedCellValue: gameProvider.selectedRow != null &&
                                      gameProvider.selectedCol != null
                                  ? gameProvider.currentBoard!
                                      .getCell(
                                        gameProvider.selectedRow!,
                                        gameProvider.selectedCol!,
                                      )
                                      .value
                                  : null,
                              onCellTap: gameProvider.selectCell,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Control buttons
                    ControlButtons(
                      notesMode: gameProvider.notesMode,
                      canUndo: gameProvider.canUndo,
                      canErase: gameProvider.canErase,
                      hintsRemaining: gameProvider.hintsRemaining,
                      onUndo: gameProvider.undo,
                      onErase: gameProvider.eraseCell,
                      onToggleNotes: gameProvider.toggleNotesMode,
                      onHint: gameProvider.useHint,
                    ),
                    // Number pad (always inline)
                    NumberPad(
                      board: gameProvider.currentBoard!,
                      onNumberTap: gameProvider.placeNumber,
                      useCompactMode: useCompactMode,
                    ),
                    SizedBox(height: useCompactMode ? 8 : 12),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds the header with back and settings buttons
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.white.withValues(alpha: 0.7 * 255),
            iconSize: 20,
          ),
          // Title
          const Text(
            'SUDOKU',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          // Settings button
          IconButton(
            onPressed: () {
              // TODO: Show settings dialog
            },
            icon: const Icon(Icons.settings),
            color: Colors.white.withValues(alpha: 0.7 * 255),
            iconSize: 22,
          ),
        ],
      ),
    );
  }

  /// Builds the loading indicator
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation(_primaryCyan),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating puzzle...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7 * 255),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the victory dialog
  void _showVictoryDialog(SudokuProvider gameProvider) {
    final uiProvider = context.read<SudokuUIProvider>();
    uiProvider.setShowVictoryDialog(true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _primaryCyan.withValues(alpha: 0.5 * 255),
            width: 2,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: _primaryCyan, size: 32),
            SizedBox(width: 12),
            Text(
              'Puzzle Solved!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VictoryStat(
              label: 'Time',
              value: gameProvider.formattedTime,
            ),
            const SizedBox(height: 12),
            _VictoryStat(
              label: 'Mistakes',
              value: '${gameProvider.mistakes}',
            ),
            const SizedBox(height: 12),
            _VictoryStat(
              label: 'Hints Used',
              value: '${gameProvider.hintsUsed}',
            ),
            const SizedBox(height: 12),
            _VictoryStat(
              label: 'Final Score',
              value: '${gameProvider.score}',
              isScore: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to difficulty screen
            },
            child: Text(
              'NEW GAME',
              style: TextStyle(
                color: _primaryCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              gameProvider.resetGame();
            },
            child: Text(
              'PLAY AGAIN',
              style: TextStyle(
                color: _primaryCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Victory dialog stat row
class _VictoryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isScore;

  const _VictoryStat({
    required this.label,
    required this.value,
    this.isScore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7 * 255),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isScore ? _primaryCyan : Colors.white,
          ),
        ),
      ],
    );
  }
}
