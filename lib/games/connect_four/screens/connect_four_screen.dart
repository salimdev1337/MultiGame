import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/connect_four_enums.dart';
import '../models/connect_four_state.dart';
import '../providers/connect_four_notifier.dart';

// ── Local palette ─────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D1117);
const _kBoard = Color(0xFF1565C0);
const _kCell = Color(0xFF0D47A1);
const _kP1 = DSColors.connectFourPlayer1; // yellow
const _kP2 = DSColors.connectFourPlayer2; // red
const _kEmpty = Color(0xFF0A2472);

// ── Screen ────────────────────────────────────────────────────────────────────

class ConnectFourScreen extends ConsumerWidget {
  const ConnectFourScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(connectFourProvider.select((s) => s.phase));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: switch (phase) {
          ConnectFourPhase.idle => const _IdleScreen(),
          _ => const _GameBody(),
        },
      ),
    );
  }
}

// ── Idle / Mode selection ─────────────────────────────────────────────────────

class _IdleScreen extends ConsumerStatefulWidget {
  const _IdleScreen();

  @override
  ConsumerState<_IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends ConsumerState<_IdleScreen> {
  ConnectFourDifficulty _difficulty = ConnectFourDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Center(
                  child: _GradientText(
                    'CONNECT FOUR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const _GradientText(
                  'CONNECT\nFOUR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DROP PIECES · CONNECT 4 · WIN',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 48),

                // Difficulty selector
                _DifficultySelector(
                  selected: _difficulty,
                  onChanged: (d) => setState(() => _difficulty = d),
                ),
                const SizedBox(height: 24),

                // VS AI button
                _ActionButton(
                  label: 'VS COMPUTER',
                  icon: Icons.smart_toy_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0099CC), Color(0xFF58A6FF)],
                  ),
                  onTap: () => ref
                      .read(connectFourProvider.notifier)
                      .startSolo(_difficulty),
                ),
                const SizedBox(height: 16),

                // Pass-and-play button
                _ActionButton(
                  label: 'PASS & PLAY',
                  icon: Icons.people_outline,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                  ),
                  onTap: () =>
                      ref.read(connectFourProvider.notifier).startPassAndPlay(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Game body ─────────────────────────────────────────────────────────────────

class _GameBody extends ConsumerWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectFourProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        final leave = await _confirmLeave(context);
        if (leave && context.mounted) {
          ref.read(connectFourProvider.notifier).goToIdle();
        }
      },
      child: Column(
        children: [
          _GameHeader(state: state),
          const SizedBox(height: 8),
          _TurnIndicator(state: state),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: _Board(state: state),
            ),
          ),
          const SizedBox(height: 16),
          if (state.isOver) _GameOverBar(state: state),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Quit game?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Your progress will be lost.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('QUIT',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _GameHeader extends ConsumerWidget {
  const _GameHeader({required this.state});
  final ConnectFourState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () async {
              final leave = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF161B22),
                  title: const Text('Quit game?',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('Your progress will be lost.',
                      style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('CANCEL',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('QUIT',
                          style: TextStyle(color: Color(0xFFE53935))),
                    ),
                  ],
                ),
              );
              if ((leave ?? false) && context.mounted) {
                ref.read(connectFourProvider.notifier).goToIdle();
              }
            },
          ),
          const Expanded(
            child: Center(
              child: _GradientText(
                'CONNECT FOUR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ── Turn indicator ────────────────────────────────────────────────────────────

class _TurnIndicator extends StatelessWidget {
  const _TurnIndicator({required this.state});
  final ConnectFourState state;

  @override
  Widget build(BuildContext context) {
    if (state.phase == ConnectFourPhase.won) {
      // The player who just won is the one whose turn it no longer is
      final winnerPlayer = state.currentPlayer == 1 ? 2 : 1;
      final color = winnerPlayer == 1 ? _kP1 : _kP2;
      final label = state.mode == ConnectFourMode.solo
          ? (winnerPlayer == 1 ? 'YOU WIN!' : 'COMPUTER WINS!')
          : 'PLAYER $winnerPlayer WINS!';
      return _StatusPill(label: label, color: color);
    }
    if (state.phase == ConnectFourPhase.draw) {
      return const _StatusPill(label: "IT'S A DRAW!", color: Colors.white54);
    }

    final isBot = state.isBotTurn;
    final label = isBot
        ? 'COMPUTER THINKING...'
        : state.mode == ConnectFourMode.passAndPlay
            ? 'PLAYER ${state.currentPlayer}\'S TURN'
            : 'YOUR TURN';
    final color = state.currentPlayer == 1 ? _kP1 : _kP2;
    return _StatusPill(label: label, color: color);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Board ─────────────────────────────────────────────────────────────────────

class _Board extends ConsumerWidget {
  const _Board({required this.state});
  final ConnectFourState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kBoard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kBoard.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column tap targets (arrows on top)
          if (!state.isOver && !state.isBotTurn)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(kCFCols, (col) {
                return GestureDetector(
                  onTap: () =>
                      ref.read(connectFourProvider.notifier).dropInColumn(col),
                  child: SizedBox(
                    width: 44,
                    height: 24,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: state.currentPlayer == 1
                          ? _kP1.withValues(alpha: 0.6)
                          : _kP2.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                );
              }),
            )
          else
            const SizedBox(height: 24),

          // Grid rows (row 5 at top = highest = displayed first)
          for (var row = kCFRows - 1; row >= 0; row--)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(kCFCols, (col) {
                return GestureDetector(
                  onTap: () {
                    if (!state.isOver && !state.isBotTurn) {
                      ref
                          .read(connectFourProvider.notifier)
                          .dropInColumn(col);
                    }
                  },
                  child: _Cell(
                    col: col,
                    row: row,
                    value: state.grid.isNotEmpty ? state.grid[col][row] : 0,
                    isWinCell: state.winLine
                        .any((w) => w.$1 == col && w.$2 == row),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

// ── Cell ──────────────────────────────────────────────────────────────────────

class _Cell extends StatefulWidget {
  const _Cell({
    required this.col,
    required this.row,
    required this.value,
    required this.isWinCell,
  });

  final int col;
  final int row;
  final int value; // 0=empty, 1=p1, 2=p2
  final bool isWinCell;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(_Cell old) {
    super.didUpdateWidget(old);
    if (widget.value != 0 && old.value == 0) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.value == 1
        ? _kP1
        : widget.value == 2
            ? _kP2
            : null;

    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _kCell,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: ScaleTransition(
          scale: widget.value != 0 ? _scaleAnim : const AlwaysStoppedAnimation(1),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color ?? _kEmpty,
              shape: BoxShape.circle,
              boxShadow: widget.isWinCell && color != null
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.8),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
              border: widget.isWinCell
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Game over bar ─────────────────────────────────────────────────────────────

class _GameOverBar extends ConsumerWidget {
  const _GameOverBar({required this.state});
  final ConnectFourState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _GradientButton(
              label: 'PLAY AGAIN',
              icon: Icons.refresh,
              gradient: const LinearGradient(
                colors: [Color(0xFF0099CC), Color(0xFF58A6FF)],
              ),
              onTap: () =>
                  ref.read(connectFourProvider.notifier).restartGame(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GradientButton(
              label: 'MENU',
              icon: Icons.home_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ),
              onTap: () =>
                  ref.read(connectFourProvider.notifier).goToIdle(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF58A6FF), Color(0xFF3FB950)],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    required this.selected,
    required this.onChanged,
  });

  final ConnectFourDifficulty selected;
  final ValueChanged<ConnectFourDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: ConnectFourDifficulty.values.map((d) {
          final isSelected = d == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF58A6FF).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF58A6FF).withValues(alpha: 0.5))
                      : null,
                ),
                child: Text(
                  d.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF58A6FF)
                        : Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
