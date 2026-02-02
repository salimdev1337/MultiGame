import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/sudoku_generator.dart';
import '../providers/sudoku_rush_provider.dart';
import '../providers/sudoku_ui_provider.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/control_buttons.dart';

// Color constants
const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _primaryCyan = Color(0xFF00d4ff);
const _dangerRed = Color(0xFFef4444);
const _warningOrange = Color(0xFFfb923c);

/// Main game screen for Sudoku Rush Mode.
///
/// Rush Mode features:
/// - 5-minute countdown timer
/// - -10 second penalty per wrong entry
/// - Time-based scoring system
/// - Lose condition when timer reaches zero
///
/// Reuses most UI components from Classic Mode but adds:
/// - Countdown timer display
/// - Penalty animation
/// - Failure dialog
/// - Rush-specific victory stats
class SudokuRushScreen extends StatefulWidget {
  /// Difficulty level for this game
  final SudokuDifficulty difficulty;

  const SudokuRushScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<SudokuRushScreen> createState() => _SudokuRushScreenState();
}

class _SudokuRushScreenState extends State<SudokuRushScreen> {
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
    final gameProvider = context.read<SudokuRushProvider>();

    uiProvider.setLoading(true);
    await gameProvider.initializeGame(widget.difficulty);
    uiProvider.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      body: SafeArea(
        child: Consumer2<SudokuRushProvider, SudokuUIProvider>(
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

            // Show defeat dialog if time ran out
            if (gameProvider.isDefeat && !uiProvider.showVictoryDialog) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showDefeatDialog(gameProvider);
              });
            }

            // Use LayoutBuilder to detect available space
            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate space taken by fixed-height widgets
                const headerHeight = 44.0;
                const statsHeight = 100.0; // Slightly taller for Rush stats
                const controlButtonsHeight = 90.0;
                const numberPadHeight = 60.0;
                const spacing = 32.0;

                // Calculate remaining space for grid
                final remainingHeight = constraints.maxHeight -
                    headerHeight -
                    statsHeight -
                    controlButtonsHeight -
                    numberPadHeight -
                    spacing;

                // Determine if we should use compact mode
                final useCompactMode = constraints.maxHeight < 700;

                // Calculate grid size
                final maxWidth = constraints.maxWidth - 32;
                final gridSize = (maxWidth < remainingHeight ? maxWidth : remainingHeight)
                    .clamp(250.0, 600.0);

                return Stack(
                  children: [
                    Column(
                      children: [
                        // Header
                        _buildHeader(context),
                        // Rush Mode stats panel
                        _buildRushStatsPanel(gameProvider),
                        const SizedBox(height: 8),
                        // Sudoku grid
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
                        // Number pad
                        NumberPad(
                          board: gameProvider.currentBoard!,
                          onNumberTap: gameProvider.placeNumber,
                          useCompactMode: useCompactMode,
                        ),
                        SizedBox(height: useCompactMode ? 8 : 12),
                      ],
                    ),
                    // Penalty overlay
                    if (gameProvider.showPenalty) _buildPenaltyOverlay(),
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
          const Column(
            children: [
              Text(
                'SUDOKU',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'RUSH MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _dangerRed,
                  letterSpacing: 1.5,
                ),
              ),
            ],
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

  /// Builds the Rush Mode stats panel with countdown timer
  Widget _buildRushStatsPanel(SudokuRushProvider provider) {
    // Determine timer color based on remaining time
    Color timerColor;
    if (provider.remainingSeconds > 120) {
      timerColor = _primaryCyan; // > 2 minutes: cyan
    } else if (provider.remainingSeconds > 60) {
      timerColor = _warningOrange; // 1-2 minutes: orange
    } else {
      timerColor = _dangerRed; // < 1 minute: red
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.6 * 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1 * 255),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Countdown timer (large and prominent)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: timerColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                provider.formattedTime,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: timerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.close,
                value: '${provider.mistakes}',
                label: 'Errors',
                color: _dangerRed,
              ),
              _StatItem(
                icon: Icons.remove_circle_outline,
                value: '${provider.penaltiesApplied}',
                label: 'Penalties',
                color: _warningOrange,
              ),
              _StatItem(
                icon: Icons.emoji_events,
                value: '${provider.score}',
                label: 'Score',
                color: _primaryCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the penalty overlay animation
  Widget _buildPenaltyOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: _dangerRed.withValues(alpha: 0.2 * 255),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: _surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _dangerRed, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _dangerRed.withValues(alpha: 0.5 * 255),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: _dangerRed, size: 32),
                  SizedBox(width: 12),
                  Text(
                    '-10 SECONDS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _dangerRed,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the loading indicator
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_primaryCyan),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating Rush puzzle...',
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
  void _showVictoryDialog(SudokuRushProvider gameProvider) {
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
              'Victory!',
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
              label: 'Time Remaining',
              value: gameProvider.formattedTime,
              color: _primaryCyan,
            ),
            const SizedBox(height: 12),
            _VictoryStat(
              label: 'Mistakes',
              value: '${gameProvider.mistakes}',
            ),
            const SizedBox(height: 12),
            _VictoryStat(
              label: 'Penalties',
              value: '${gameProvider.penaltiesApplied}',
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
              Navigator.pop(context); // Return to mode selection
            },
            child: const Text(
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
              context.read<SudokuUIProvider>().setShowVictoryDialog(false);
            },
            child: const Text(
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

  /// Shows the defeat dialog when time runs out
  void _showDefeatDialog(SudokuRushProvider gameProvider) {
    final uiProvider = context.read<SudokuUIProvider>();
    uiProvider.setShowVictoryDialog(true); // Reuse flag to prevent multiple dialogs

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _dangerRed.withValues(alpha: 0.5 * 255),
            width: 2,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: _dangerRed, size: 32),
            SizedBox(width: 12),
            Text(
              'Time\'s Up!',
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
            Text(
              'You ran out of time!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7 * 255),
              ),
            ),
            const SizedBox(height: 20),
            _VictoryStat(
              label: 'Mistakes',
              value: '${gameProvider.mistakes}',
            ),
            const SizedBox(height: 12),
            _VictoryStat(
              label: 'Penalties',
              value: '${gameProvider.penaltiesApplied}',
              color: _dangerRed,
            ),
            const SizedBox(height: 12),
            _VictoryStat(
              label: 'Hints Used',
              value: '${gameProvider.hintsUsed}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to mode selection
            },
            child: const Text(
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
              context.read<SudokuUIProvider>().setShowVictoryDialog(false);
            },
            child: const Text(
              'TRY AGAIN',
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

/// Stat item widget for Rush Mode stats panel
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5 * 255),
          ),
        ),
      ],
    );
  }
}

/// Victory/defeat dialog stat row
class _VictoryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isScore;
  final Color? color;

  const _VictoryStat({
    required this.label,
    required this.value,
    this.isScore = false,
    this.color,
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
            color: color ?? (isScore ? _primaryCyan : Colors.white),
          ),
        ),
      ],
    );
  }
}
