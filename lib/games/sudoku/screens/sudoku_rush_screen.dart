// Rush game screen - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const SudokuRushScreen({
    super.key,
    required this.difficulty,
  });

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
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        title: const Text(
          'Quit game?',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'The timer keeps running. Your progress will be lost.',
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
    final state = ref.watch(sudokuRushProvider);
    final uiState = ref.watch(sudokuUIProvider);
    final notifier = ref.read(sudokuRushProvider.notifier);

    // Manage timer pulse based on remaining time
    ref.listen<SudokuRushState>(sudokuRushProvider, (prev, next) {
      final wasAbove30 = prev == null || prev.remainingSeconds > 30;
      final isBelow30 = next.remainingSeconds <= 30 && next.remainingSeconds > 0;

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
                  _showVictorySheet(state);
                });
              }

              if (state.isDefeat && !uiState.showVictoryDialog) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showDefeatSheet(state);
                });
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  const headerHeight = 44.0;
                  const statsHeight = 100.0;
                  const controlButtonsHeight = 90.0;
                  const numberPadHeight = 60.0;
                  const spacing = 32.0;

                  final remainingHeight = constraints.maxHeight -
                      headerHeight -
                      statsHeight -
                      controlButtonsHeight -
                      numberPadHeight -
                      spacing;

                  final useCompactMode = constraints.maxHeight < 700;

                  final maxWidth = constraints.maxWidth - 32;
                  final gridSize =
                      (maxWidth < remainingHeight ? maxWidth : remainingHeight)
                          .clamp(250.0, 600.0);

                  return Stack(
                    children: [
                      Column(
                        children: [
                          _buildHeader(context),
                          _buildRushStatsPanel(state),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
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
                      ),
                      if (state.showPenalty) _buildPenaltyOverlay(),
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

  Widget _buildRushStatsPanel(SudokuRushState state) {
    Color timerColor;
    if (state.remainingSeconds > 120) {
      timerColor = _primaryCyan;
    } else if (state.remainingSeconds > 30) {
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
          // Pulsing timer
          ScaleTransition(
            scale: _timerPulseScale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: timerColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  state.formattedTime,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: timerColor,
                    shadows: state.remainingSeconds <= 30
                        ? [Shadow(color: timerColor.withValues(alpha: 0.5), blurRadius: 12)]
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
              _StatItem(
                icon: Icons.close,
                value: '${state.mistakes}',
                label: 'Errors',
                color: _dangerRed,
              ),
              _StatItem(
                icon: Icons.remove_circle_outline,
                value: '${state.penaltiesApplied}',
                label: 'Penalties',
                color: _warningOrange,
              ),
              _StatItem(
                icon: Icons.emoji_events,
                value: '${state.score}',
                label: 'Score',
                color: _primaryCyan,
              ),
            ],
          ),
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

  void _showVictorySheet(SudokuRushState state) {
    ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(true);
    _timerPulseController.stop();
    final notifier = ref.read(sudokuRushProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _ResultSheet(
        isVictory: true,
        title: 'Victory!',
        subtitle: 'You beat the clock!',
        accentColor: _primaryCyan,
        accentGradient: const [Color(0xFFfb923c), Color(0xFFef4444)],
        stats: [
          _SheetStat('Time Remaining', state.formattedTime, isHighlighted: true),
          _SheetStat('Mistakes', '${state.mistakes}'),
          _SheetStat('Penalties', '${state.penaltiesApplied}'),
          _SheetStat('Hints Used', '${state.hintsUsed}'),
          _SheetStat('Final Score', '${state.score}', isHighlighted: true),
        ],
        primaryLabel: 'PLAY AGAIN',
        secondaryLabel: 'NEW GAME',
        onPrimary: () {
          Navigator.pop(context);
          notifier.resetGame();
          ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(false);
        },
        onSecondary: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDefeatSheet(SudokuRushState state) {
    ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(true);
    _timerPulseController.stop();
    final notifier = ref.read(sudokuRushProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _ResultSheet(
        isVictory: false,
        title: "Time's Up!",
        subtitle: 'Better luck next time.',
        accentColor: _dangerRed,
        accentGradient: const [Color(0xFFef4444), Color(0xFF7f1d1d)],
        stats: [
          _SheetStat('Mistakes', '${state.mistakes}'),
          _SheetStat('Penalties', '${state.penaltiesApplied}', isHighlighted: true),
          _SheetStat('Hints Used', '${state.hintsUsed}'),
        ],
        primaryLabel: 'TRY AGAIN',
        secondaryLabel: 'NEW GAME',
        onPrimary: () {
          Navigator.pop(context);
          notifier.resetGame();
          ref.read(sudokuUIProvider.notifier).setShowVictoryDialog(false);
        },
        onSecondary: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
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

// ─── Result bottom sheet ─────────────────────────────────────────────────────

class _SheetStat {
  final String label;
  final String value;
  final bool isHighlighted;

  const _SheetStat(this.label, this.value, {this.isHighlighted = false});
}

class _ResultSheet extends StatefulWidget {
  final bool isVictory;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<Color> accentGradient;
  final List<_SheetStat> stats;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _ResultSheet({
    required this.isVictory,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.accentGradient,
    required this.stats,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<double> _iconScale;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1d24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 28),

            // Animated icon
            ScaleTransition(
              scale: _iconScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.accentGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isVictory ? Icons.emoji_events : Icons.timer_off,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 16),

            FadeTransition(
              opacity: _contentFade,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            FadeTransition(
              opacity: _contentFade,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: widget.stats.asMap().entries.map((entry) {
                    final i = entry.key;
                    final stat = entry.value;
                    return Column(
                      children: [
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stat.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                stat.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: stat.isHighlighted
                                      ? widget.accentColor
                                      : Colors.white,
                                  shadows: stat.isHighlighted
                                      ? [
                                          Shadow(
                                            color: widget.accentColor
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            FadeTransition(
              opacity: _contentFade,
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPrimary,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.accentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          widget.primaryLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            FadeTransition(
              opacity: _contentFade,
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onSecondary,
                  child: Text(
                    widget.secondaryLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Stat item (in-game stats row) ───────────────────────────────────────────

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
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
