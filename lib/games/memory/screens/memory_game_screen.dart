import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';

import '../models/memory_card.dart';
import '../models/memory_game_state.dart';
import '../providers/memory_notifier.dart';

// ── Emoji palette — 20 distinct symbols ──────────────────────────────────────
const _kEmojis = [
  '🦊', '🐬', '🦋', '🌸', '🍕',
  '🎸', '🚀', '🌈', '⚡', '🎯',
  '🦄', '🐉', '🍀', '🔮', '🎭',
  '🏆', '🌙', '🔥', '💎', '🎪',
];

const _kAccent = DSColors.memoryPrimary;
const _kAccentAlt = DSColors.memoryAccent;

// ─────────────────────────────────────────────────────────────────────────────

class MemoryGamePage extends ConsumerStatefulWidget {
  const MemoryGamePage({super.key});

  @override
  ConsumerState<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends ConsumerState<MemoryGamePage> {
  bool _resultShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<MemoryGameState>(memoryProvider, (prev, next) {
      if (next.phase == MemoryGamePhase.won && !_resultShowing) {
        _resultShowing = true;
        _showWinDialog(next);
      }
    });

    final phase = ref.watch(memoryProvider.select((s) => s.phase));

    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: DSColors.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DSColors.textPrimary),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text(
          'MEMORY GAME',
          style: TextStyle(
            color: DSColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (phase != MemoryGamePhase.idle)
            IconButton(
              icon: const Icon(Icons.refresh, color: _kAccent),
              onPressed: () {
                _resultShowing = false;
                ref.read(memoryProvider.notifier).restart();
              },
            ),
        ],
      ),
      body: phase == MemoryGamePhase.idle
          ? const _IdleScreen()
          : const _GameBody(),
    );
  }

  void _showWinDialog(MemoryGameState s) {
    final notifier = ref.read(memoryProvider.notifier);

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: true,
        title: 'YOU WIN!',
        icon: const Text('🎉', style: TextStyle(fontSize: 52)),
        accentColor: _kAccent,
        accentGradient: const [_kAccent, _kAccentAlt],
        stats: [
          GameResultStat('Score', '${s.score}'),
          GameResultStat('Best', '${s.highScore}'),
          GameResultStat('Moves', '${s.moves}'),
        ],
        statsLayout: GameResultStatsLayout.cards,
        statCardValueFontSize: 24,
        statCardSpacing: 12,
        primary: GameResultAction(
          label: 'Play Again',
          onTap: () {
            _resultShowing = false;
            notifier.restart();
          },
        ),
        secondary: GameResultAction(
          label: 'Home',
          onTap: () {
            _resultShowing = false;
            notifier.reset();
          },
          style: GameResultButtonStyle.outline,
        ),
        presentation: GameResultPresentation.bottomSheet,
        animated: true,
      ),
    ).then((_) => _resultShowing = false);
  }
}

// ── Idle / start screen ───────────────────────────────────────────────────────

class _IdleScreen extends ConsumerWidget {
  const _IdleScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      memoryProvider.select((s) => s.difficulty),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'Memory Game',
              style: TextStyle(
                color: DSColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Match all pairs.\nWrong guess? Cards shuffle!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DSColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Difficulty selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: MemoryDifficulty.values.map((d) {
                final active = d == selected;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(memoryProvider.notifier).startGame(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? _kAccent.withValues(alpha: 0.2)
                            : DSColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? _kAccent : DSColors.surfaceHighlight,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        d.label,
                        style: TextStyle(
                          color: active ? _kAccent : DSColors.textSecondary,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Grid size hint
            Text(
              '${selected.cols}×${selected.rows} · ${selected.totalPairs} pairs',
              style: const TextStyle(
                color: DSColors.textTertiary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    ref.read(memoryProvider.notifier).startGame(selected),
                child: const Text(
                  'START',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game body (HUD + grid) ────────────────────────────────────────────────────

class _GameBody extends ConsumerWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cols = ref.watch(memoryProvider.select((s) => s.difficulty.cols));

    return Column(
      children: [
        const _HUD(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _CardGrid(cols: cols),
          ),
        ),
      ],
    );
  }
}

// ── HUD ───────────────────────────────────────────────────────────────────────

class _HUD extends ConsumerWidget {
  const _HUD();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(memoryProvider.select((s) => s.score));
    final streak = ref.watch(memoryProvider.select((s) => s.streak));
    final moves = ref.watch(memoryProvider.select((s) => s.moves));
    final highScore = ref.watch(memoryProvider.select((s) => s.highScore));

    return Container(
      color: DSColors.backgroundSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HudItem(label: 'SCORE', value: '$score'),
          _HudItem(label: 'BEST', value: '$highScore'),
          _HudItem(label: 'MOVES', value: '$moves'),
          _StreakBadge(streak: streak),
        ],
      ),
    );
  }
}

class _HudItem extends StatelessWidget {
  const _HudItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DSColors.textTertiary,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: DSColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final multiplier = (streak + 1).clamp(1, 4);
    final glow = multiplier >= 3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: glow ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: glow ? _kAccentAlt : _kAccent.withValues(alpha: 0.4),
          width: glow ? 1.5 : 1,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: _kAccent.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'STREAK',
            style: TextStyle(
              color: DSColors.textTertiary,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '×$multiplier',
            style: TextStyle(
              color: glow ? _kAccentAlt : _kAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card Grid ─────────────────────────────────────────────────────────────────

class _CardGrid extends ConsumerWidget {
  const _CardGrid({required this.cols});
  final int cols;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardCount = ref.watch(memoryProvider.select((s) => s.cards.length));

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: cardCount,
      itemBuilder: (context, index) {
        return _MemoryCardTile(index: index);
      },
    );
  }
}

// ── Card tile ─────────────────────────────────────────────────────────────────

class _MemoryCardTile extends ConsumerStatefulWidget {
  const _MemoryCardTile({required this.index});
  final int index;

  @override
  ConsumerState<_MemoryCardTile> createState() => _MemoryCardTileState();
}

class _MemoryCardTileState extends ConsumerState<_MemoryCardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  // Tracks the last known flip state so we can trigger the animation.
  bool _wasFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  MemoryCard _card(MemoryGameState s) => s.cards[widget.index];

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(
      memoryProvider.select((s) => _card(s)),
    );
    final phase = ref.watch(memoryProvider.select((s) => s.phase));

    // Drive flip animation whenever isFlipped changes.
    if (card.isFlipped != _wasFlipped) {
      _wasFlipped = card.isFlipped;
      if (card.isFlipped) {
        _flipCtrl.forward();
      } else {
        _flipCtrl.reverse();
      }
    }

    final canTap = phase == MemoryGamePhase.playing &&
        !card.isFlipped &&
        !card.isMatched;

    return GestureDetector(
      onTap: canTap
          ? () => ref.read(memoryProvider.notifier).flipCard(widget.index)
          : null,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, child) {
          final angle = _flipAnim.value * math.pi;
          final showFront = angle >= math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _FrontFace(card: card),
                  )
                : _BackFace(isMatched: card.isMatched),
          );
        },
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({required this.card});
  final MemoryCard card;

  @override
  Widget build(BuildContext context) {
    final emoji = _kEmojis[card.value % _kEmojis.length];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: card.isMatched
            ? DSColors.success.withValues(alpha: 0.15)
            : DSColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: card.isMatched ? DSColors.success : _kAccent,
          width: card.isMatched ? 2 : 1.5,
        ),
        boxShadow: card.isMatched
            ? [
                BoxShadow(
                  color: DSColors.success.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({required this.isMatched});
  final bool isMatched;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kAccent.withValues(alpha: 0.7),
            _kAccentAlt.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
