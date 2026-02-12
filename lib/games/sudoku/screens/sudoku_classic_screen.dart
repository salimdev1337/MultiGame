// Classic game screen - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';
import '../logic/sudoku_generator.dart';
import '../providers/sudoku_notifier.dart';
import '../providers/sudoku_ui_notifier.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/control_buttons.dart';
import '../widgets/stats_panel.dart';

const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _primaryCyan = Color(0xFF00d4ff);

class SudokuClassicScreen extends ConsumerStatefulWidget {
  final SudokuDifficulty difficulty;

  const SudokuClassicScreen({
    super.key,
    required this.difficulty,
  });

  @override
  ConsumerState<SudokuClassicScreen> createState() =>
      _SudokuClassicScreenState();
}

class _SudokuClassicScreenState extends ConsumerState<SudokuClassicScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    ref.read(sudokuUIProvider.notifier).setLoading(true);
    await ref
        .read(sudokuClassicProvider.notifier)
        .initializeGame(widget.difficulty);
    ref.read(sudokuUIProvider.notifier).setLoading(false);
  }

  void _showQuitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        title: const Text(
          'Quit game?',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('RESUME', style: TextStyle(color: _primaryCyan, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('QUIT', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Select only the fields that affect the grid / layout — intentionally
    // excludes elapsedSeconds so the 81-cell grid doesn't rebuild every second.
    // StatsPanel (ConsumerWidget) watches time/score/mistakes independently.
    final state = ref.watch(
      sudokuClassicProvider.select(
        (s) => (
          hasBoard: s.hasBoard,
          isVictory: s.isVictory,
          selectedRow: s.selectedRow,
          selectedCol: s.selectedCol,
          notesMode: s.notesMode,
          hintsRemaining: s.hintsRemaining,
          revision: s.revision,
        ),
      ),
    );
    final uiState = ref.watch(sudokuUIProvider);
    final notifier = ref.read(sudokuClassicProvider.notifier);

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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isVeryCompact = constraints.maxHeight < 600;
                  final isCompact = constraints.maxHeight < 700;

                  final headerHeight = isVeryCompact ? 36.0 : 44.0;
                  final statsHeight =
                      isVeryCompact ? 60.0 : (isCompact ? 70.0 : 80.0);
                  final controlButtonsHeight =
                      isVeryCompact ? 68.0 : (isCompact ? 78.0 : 90.0);
                  final numberPadHeight =
                      isVeryCompact ? 46.0 : (isCompact ? 52.0 : 60.0);
                  final spacing =
                      isVeryCompact ? 14.0 : (isCompact ? 22.0 : 32.0);

                  final remainingHeight = constraints.maxHeight -
                      headerHeight -
                      statsHeight -
                      controlButtonsHeight -
                      numberPadHeight -
                      spacing;

                  final useCompactMode = isCompact;

                  final maxWidth = constraints.maxWidth - 32;
                  final minGrid = isVeryCompact ? 220.0 : 250.0;
                  final gridSize =
                      (maxWidth < remainingHeight ? maxWidth : remainingHeight)
                          .clamp(minGrid, 600.0);

                  return Column(
                    children: [
                      _buildHeader(context),
                      const StatsPanel(),
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
                                selectedRow: state.selectedRow,
                                selectedCol: state.selectedCol,
                                selectedCellValue:
                                    state.selectedRow != null &&
                                            state.selectedCol != null
                                        ? notifier.currentBoard!
                                            .getCell(
                                              state.selectedRow!,
                                              state.selectedCol!,
                                            )
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
                        notesMode: state.notesMode,
                        canUndo: notifier.canUndo,
                        canErase: notifier.canErase,
                        hintsRemaining: state.hintsRemaining,
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
                  );
                },
              );
            },
          ),
        ),
      ),
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
          const Text(
            'SUDOKU',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          _DifficultyBadge(difficulty: widget.difficulty),
        ],
      ),
    );
  }

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
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showVictorySheet() {
    final state = ref.read(sudokuClassicProvider);
    ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(true);
    final notifier = ref.read(sudokuClassicProvider.notifier);

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: true,
        title: 'Puzzle Solved!',
        subtitle: Text(
          'Excellent work!',
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
              colors: [Color(0xFF00d4ff), Color(0xFF7c3aed)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x7300d4ff),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.emoji_events, color: Colors.white, size: 40),
        ),
        accentColor: _primaryCyan,
        accentGradient: const [Color(0xFF00d4ff), Color(0xFF7c3aed)],
        stats: [
          GameResultStat('Time', state.formattedTime),
          GameResultStat('Mistakes', '${state.mistakes}'),
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
}

// ─── Difficulty badge ────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final SudokuDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      SudokuDifficulty.easy   => ('EASY',   const Color(0xFF22c55e)),
      SudokuDifficulty.medium => ('MEDIUM', const Color(0xFFf59e0b)),
      SudokuDifficulty.hard   => ('HARD',   const Color(0xFFef4444)),
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
