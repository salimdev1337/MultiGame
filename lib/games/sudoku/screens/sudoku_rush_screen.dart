// Rush game screen - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';
import 'package:multigame/widgets/shared/game_stat_item.dart';
import '../logic/sudoku_generator.dart';
import '../providers/sudoku_rush_notifier.dart';
import '../providers/sudoku_ui_notifier.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/control_buttons.dart';

const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _primaryCyan = Color(0xFF00d4ff);
const _dangerRed = Color(0xFFef4444);
const _warningOrange = Color(0xFFfb923c);

class SudokuRushScreen extends ConsumerStatefulWidget {
  final SudokuDifficulty difficulty;

  const SudokuRushScreen({super.key, required this.difficulty});

  @override
  ConsumerState<SudokuRushScreen> createState() => _SudokuRushScreenState();
}

class _SudokuRushScreenState extends ConsumerState<SudokuRushScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseScale;

  @override
  void initState() {
    super.initState();

    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _timerPulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _timerPulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    ref.read(sudokuUIProvider.notifier).setLoading(true);
    await ref
        .read(sudokuRushProvider.notifier)
        .initializeGame(widget.difficulty);
    ref.read(sudokuUIProvider.notifier).setLoading(false);
  }

  @override
  void dispose() {
    _timerPulseController.dispose();
    super.dispose();
  }

  void _showQuitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        title: const Text(
          'Quit game?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'The timer keeps running. Your progress will be lost.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'RESUME',
              style: TextStyle(
                color: _primaryCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'QUIT',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Select only layout-relevant fields — excludes remainingSeconds so the
    // 81-cell grid doesn't rebuild every second. _RushStatsPanel (ConsumerWidget)
    // watches the timer fields independently.
    final state = ref.watch(
      sudokuRushProvider.select(
        (s) => (
          hasBoard: s.hasBoard,
          isVictory: s.isVictory,
          isDefeat: s.isDefeat,
          selectedRow: s.selectedRow,
          selectedCol: s.selectedCol,
          notesMode: s.notesMode,
          hintsRemaining: s.hintsRemaining,
          revision: s.revision,
          showPenalty: s.showPenalty,
        ),
      ),
    );
    final uiState = ref.watch(sudokuUIProvider);

    // Manage timer pulse based on remaining time
    ref.listen<SudokuRushState>(sudokuRushProvider, (prev, next) {
      final wasAbove30 = prev == null || prev.remainingSeconds > 30;
      final isBelow30 =
          next.remainingSeconds <= 30 && next.remainingSeconds > 0;

      if (isBelow30 && wasAbove30) {
        _timerPulseController.repeat(reverse: true);
      } else if (!isBelow30 && _timerPulseController.isAnimating) {
        _timerPulseController.stop();
        _timerPulseController.value = 0;
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showQuitConfirmation();
      },
      child: Scaffold(
        backgroundColor: _backgroundDark,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (uiState.isLoading || !state.hasBoard) {
                return _buildLoading();
              }

              if (state.isVictory && !uiState.showVictoryDialog) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showVictorySheet();
                });
              }

              if (state.isDefeat && !uiState.showVictoryDialog) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showDefeatSheet();
                });
              }

              return LayoutBuilder(
                builder: (context, constraints) => _buildLayout(
                  context,
                  constraints,
                  selectedRow: state.selectedRow,
                  selectedCol: state.selectedCol,
                  notesMode: state.notesMode,
                  hintsRemaining: state.hintsRemaining,
                  showPenalty: state.showPenalty,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    BoxConstraints constraints, {
    required int? selectedRow,
    required int? selectedCol,
    required bool notesMode,
    required int hintsRemaining,
    required bool showPenalty,
  }) {
    final notifier = ref.read(sudokuRushProvider.notifier);
    final isVeryCompact = constraints.maxHeight < 600;
    final isCompact = constraints.maxHeight < 700;

    final headerHeight = isVeryCompact ? 36.0 : 44.0;
    final statsHeight = isVeryCompact ? 78.0 : (isCompact ? 88.0 : 100.0);
    final controlButtonsHeight = isVeryCompact
        ? 68.0
        : (isCompact ? 78.0 : 90.0);
    final numberPadHeight = isVeryCompact ? 46.0 : (isCompact ? 52.0 : 60.0);
    final spacing = isVeryCompact ? 14.0 : (isCompact ? 22.0 : 32.0);

    final remainingHeight =
        constraints.maxHeight -
        headerHeight -
        statsHeight -
        controlButtonsHeight -
        numberPadHeight -
        spacing;

    final useCompactMode = isCompact;
    final maxWidth = constraints.maxWidth - 32;
    final minGrid = isVeryCompact ? 220.0 : 250.0;
    final gridSize = (maxWidth < remainingHeight ? maxWidth : remainingHeight)
        .clamp(minGrid, 600.0);

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(context),
            _RushStatsPanel(timerPulseScale: _timerPulseScale),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: gridSize,
                    height: gridSize,
                    child: SudokuGrid(
                      board: notifier.currentBoard!,
                      selectedRow: selectedRow,
                      selectedCol: selectedCol,
                      selectedCellValue:
                          selectedRow != null && selectedCol != null
                          ? notifier.currentBoard!
                                .getCell(selectedRow, selectedCol)
                                .value
                          : null,
                      onCellTap: notifier.selectCell,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ControlButtons(
              notesMode: notesMode,
              canUndo: notifier.canUndo,
              canErase: notifier.canErase,
              hintsRemaining: hintsRemaining,
              onUndo: notifier.undo,
              onErase: notifier.eraseCell,
              onToggleNotes: notifier.toggleNotesMode,
              onHint: notifier.useHint,
            ),
            NumberPad(
              board: notifier.currentBoard!,
              onNumberTap: notifier.placeNumber,
              useCompactMode: useCompactMode,
            ),
            SizedBox(height: useCompactMode ? 8 : 12),
          ],
        ),
        if (showPenalty) _buildPenaltyOverlay(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _showQuitConfirmation,
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.white.withValues(alpha: 0.7),
            iconSize: 20,
          ),
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
          _DifficultyBadge(difficulty: widget.difficulty),
        ],
      ),
    );
  }

  Widget _buildPenaltyOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: _dangerRed.withValues(alpha: 0.2),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: _surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _dangerRed, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _dangerRed.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _dangerRed,
                    size: 32,
                  ),
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
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showVictorySheet() {
    final state = ref.read(sudokuRushProvider);
    ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(true);
    _timerPulseController.stop();
    final notifier = ref.read(sudokuRushProvider.notifier);

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: true,
        title: 'Victory!',
        subtitle: Text(
          'You beat the clock!',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        icon: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFfb923c), Color(0xFFef4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x7Ffb923c),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.emoji_events, color: Colors.white, size: 40),
        ),
        accentColor: _primaryCyan,
        accentGradient: const [Color(0xFFfb923c), Color(0xFFef4444)],
        stats: [
          GameResultStat(
            'Time Remaining',
            state.formattedTime,
            isHighlighted: true,
          ),
          GameResultStat('Mistakes', '${state.mistakes}'),
          GameResultStat('Penalties', '${state.penaltiesApplied}'),
          GameResultStat('Hints Used', '${state.hintsUsed}'),
          GameResultStat('Final Score', '${state.score}', isHighlighted: true),
        ],
        primary: GameResultAction(
          label: 'PLAY AGAIN',
          onTap: () {
            Navigator.pop(context);
            notifier.resetGame();
            ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(false);
          },
          style: GameResultButtonStyle.gradient,
        ),
        secondary: GameResultAction(
          label: 'NEW GAME',
          onTap: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          style: GameResultButtonStyle.text,
        ),
        presentation: GameResultPresentation.bottomSheet,
        animated: true,
      ),
    );
  }

  void _showDefeatSheet() {
    final state = ref.read(sudokuRushProvider);
    ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(true);
    _timerPulseController.stop();
    final notifier = ref.read(sudokuRushProvider.notifier);

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: false,
        title: "Time's Up!",
        subtitle: Text(
          'Better luck next time.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        icon: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFef4444), Color(0xFF7f1d1d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x7Fef4444),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.timer_off, color: Colors.white, size: 40),
        ),
        accentColor: _dangerRed,
        accentGradient: const [Color(0xFFef4444), Color(0xFF7f1d1d)],
        stats: [
          GameResultStat('Mistakes', '${state.mistakes}'),
          GameResultStat(
            'Penalties',
            '${state.penaltiesApplied}',
            isHighlighted: true,
          ),
          GameResultStat('Hints Used', '${state.hintsUsed}'),
        ],
        primary: GameResultAction(
          label: 'TRY AGAIN',
          onTap: () {
            Navigator.pop(context);
            notifier.resetGame();
            ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(false);
          },
          style: GameResultButtonStyle.gradient,
        ),
        secondary: GameResultAction(
          label: 'NEW GAME',
          onTap: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          style: GameResultButtonStyle.text,
        ),
        presentation: GameResultPresentation.bottomSheet,
        animated: true,
      ),
    );
  }
}

// ─── Difficulty badge ────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final SudokuDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      SudokuDifficulty.easy => ('EASY', const Color(0xFF22c55e)),
      SudokuDifficulty.medium => ('MEDIUM', const Color(0xFFf59e0b)),
      SudokuDifficulty.hard => ('HARD', const Color(0xFFef4444)),
      SudokuDifficulty.expert => ('EXPERT', const Color(0xFF8b5cf6)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Rush stats panel ─────────────────────────────────────────────────────────
// Isolated ConsumerWidget so the countdown every second only rebuilds this
// small panel, not the 81-cell grid above it.

class _RushStatsPanel extends ConsumerWidget {
  final Animation<double> timerPulseScale;

  const _RushStatsPanel({required this.timerPulseScale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(
      sudokuRushProvider.select(
        (s) => (
          remainingSeconds: s.remainingSeconds,
          formattedTime: s.formattedTime,
          mistakes: s.mistakes,
          penaltiesApplied: s.penaltiesApplied,
          score: s.score,
        ),
      ),
    );

    Color timerColor;
    if (stats.remainingSeconds > 120) {
      timerColor = _primaryCyan;
    } else if (stats.remainingSeconds > 30) {
      timerColor = _warningOrange;
    } else {
      timerColor = _dangerRed;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: timerPulseScale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: timerColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  stats.formattedTime,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: timerColor,
                    shadows: stats.remainingSeconds <= 30
                        ? [
                            Shadow(
                              color: timerColor.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GameStatItemWithIcon(
                icon: Icons.close,
                value: '${stats.mistakes}',
                label: 'Errors',
                color: _dangerRed,
              ),
              GameStatItemWithIcon(
                icon: Icons.remove_circle_outline,
                value: '${stats.penaltiesApplied}',
                label: 'Penalties',
                color: _warningOrange,
              ),
              GameStatItemWithIcon(
                icon: Icons.emoji_events,
                value: '${stats.score}',
                label: 'Score',
                color: _primaryCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
