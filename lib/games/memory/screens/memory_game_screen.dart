import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
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

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kSpacing = 8.0;

// Player brand colors — distinct and vibrant.
const _kP1 = Color(0xFF00E5FF); // electric cyan
const _kP2 = Color(0xFFFF1493); // deep pink

// General accent for idle UI.
const _kAccent = Color(0xFF7B2FFF);

// Card surfaces.
const _kCardBack = Color(0xFF0D1B2A);
const _kCardSurface = Color(0xFF0D0D20);

// Per-pair hue using golden angle — each pair gets a unique, evenly spaced color.
Color _pairColor(int value) {
  final hue = (value * 137.508) % 360.0;
  return HSLColor.fromAHSL(1.0, hue, 0.80, 0.62).toColor();
}

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
      backgroundColor: const Color(0xFF060612),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_kP1, _kAccent],
          ).createShader(bounds),
          child: const Text(
            'MEMORY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (phase != MemoryGamePhase.idle)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
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
    final winner = s.winner;

    final title = winner == -1
        ? "IT'S A TIE!"
        : winner == 0
            ? 'P1 WINS!'
            : 'P2 WINS!';

    final iconEmoji = winner == -1 ? '🤝' : '🏆';
    final accentColor = winner == 0
        ? _kP1
        : winner == 1
            ? _kP2
            : _kAccent;

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: winner != -1,
        title: title,
        icon: Text(iconEmoji, style: const TextStyle(fontSize: 52)),
        accentColor: accentColor,
        accentGradient: winner == 0
            ? const [_kP1, Color(0xFF0099AA)]
            : winner == 1
                ? const [_kP2, Color(0xFFAA0055)]
                : const [_kAccent, Color(0xFF4A00E0)],
        stats: [
          GameResultStat('P1 Score', '${s.playerScores[0]}'),
          GameResultStat('P2 Score', '${s.playerScores[1]}'),
          GameResultStat('Moves', '${s.moves}'),
        ],
        statsLayout: GameResultStatsLayout.cards,
        statCardValueFontSize: 24,
        statCardSpacing: 12,
        primary: GameResultAction(
          label: 'Play Again',
          onTap: () {
            Navigator.of(context).pop();
            _resultShowing = false;
            notifier.restart();
          },
        ),
        secondary: GameResultAction(
          label: 'Home',
          onTap: () {
            Navigator.of(context).pop();
            _resultShowing = false;
            context.go(AppRoutes.home);
          },
          style: GameResultButtonStyle.outline,
        ),
        // Centered dialog — not a bottom sheet.
        presentation: GameResultPresentation.dialog,
        backdropBlur: true,
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
    final selected = ref.watch(memoryProvider.select((s) => s.difficulty));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060612), Color(0xFF0A0820)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing brain icon.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: 0.35),
                      blurRadius: 32,
                    ),
                  ],
                  border: Border.all(
                    color: _kAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('🧠', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MEMORY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2 PLAYERS · HOT SEAT',
                style: TextStyle(
                  color: _kAccent.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Take turns matching pairs.\nWrong guess? Cards shuffle!\nBest score wins.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 36),
              // Difficulty pills.
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
                          horizontal: 22,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? _kAccent.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: active
                                ? _kAccent
                                : Colors.white.withValues(alpha: 0.12),
                            width: active ? 1.5 : 1,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: _kAccent.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          d.label,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                '${selected.cols}×${selected.rows} · ${selected.totalPairs} pairs',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 200,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kAccent, Color(0xFF4A00E0)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: _kAccent.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () =>
                        ref.read(memoryProvider.notifier).startGame(selected),
                    child: const Text(
                      'START GAME',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    final difficulty = ref.watch(memoryProvider.select((s) => s.difficulty));
    return Container(
      color: const Color(0xFF060612),
      child: Column(
        children: [
          const _TwoPlayerHUD(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _CardGrid(cols: difficulty.cols, rows: difficulty.rows),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2-Player HUD ──────────────────────────────────────────────────────────────

class _TwoPlayerHUD extends ConsumerWidget {
  const _TwoPlayerHUD();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(memoryProvider.select((s) => (
          currentPlayer: s.currentPlayer,
          playerScores: s.playerScores,
          playerMatches: s.playerMatches,
          playerStreaks: s.playerStreaks,
          moves: s.moves,
        )));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1F),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _PlayerPanel(
              playerIndex: 0,
              score: s.playerScores[0],
              matches: s.playerMatches[0],
              streak: s.playerStreaks[0],
              isActive: s.currentPlayer == 0,
              alignRight: false,
            ),
          ),
          _MovesColumn(moves: s.moves),
          Expanded(
            child: _PlayerPanel(
              playerIndex: 1,
              score: s.playerScores[1],
              matches: s.playerMatches[1],
              streak: s.playerStreaks[1],
              isActive: s.currentPlayer == 1,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.playerIndex,
    required this.score,
    required this.matches,
    required this.streak,
    required this.isActive,
    required this.alignRight,
  });

  final int playerIndex;
  final int score;
  final int matches;
  final int streak;
  final bool isActive;
  final bool alignRight;

  Color get _color => playerIndex == 0 ? _kP1 : _kP2;
  String get _label => playerIndex == 0 ? 'P1' : 'P2';

  @override
  Widget build(BuildContext context) {
    final multiplier = (streak + 1).clamp(1, 4);
    final crossAxis =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;
    final color = _color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: crossAxis,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: alignRight
                ? [
                    if (isActive)
                      _ActiveDot(color: color),
                    if (isActive) const SizedBox(width: 5),
                    Text(
                      _label,
                      style: TextStyle(
                        color: isActive ? color : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ]
                : [
                    Text(
                      _label,
                      style: TextStyle(
                        color: isActive ? color : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    if (isActive) const SizedBox(width: 5),
                    if (isActive)
                      _ActiveDot(color: color),
                  ],
          ),
          const SizedBox(height: 3),
          Text(
            '$score',
            textAlign: textAlign,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$matches pairs  ×$multiplier',
            textAlign: textAlign,
            style: TextStyle(
              color: isActive
                  ? color.withValues(alpha: 0.8)
                  : Colors.white24,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDot extends StatefulWidget {
  const _ActiveDot({required this.color});
  final Color color;

  @override
  State<_ActiveDot> createState() => _ActiveDotState();
}

class _ActiveDotState extends State<_ActiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + 0.5 * _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6 * _anim.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesColumn extends StatelessWidget {
  const _MovesColumn({required this.moves});
  final int moves;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MOVES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 8,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$moves',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card Grid — Stack layout with arc swap animation ─────────────────────────

typedef _SwapData = ({Offset from, Offset to, bool arcUp});

class _CardGrid extends ConsumerStatefulWidget {
  const _CardGrid({required this.cols, required this.rows});
  final int cols;
  final int rows;

  @override
  ConsumerState<_CardGrid> createState() => _CardGridState();
}

class _CardGridState extends ConsumerState<_CardGrid>
    with TickerProviderStateMixin {
  AnimationController? _swapCtrl;
  Animation<double>? _swapAnim; // eased version of _swapCtrl
  Map<int, _SwapData> _swapMap = const {};
  double _cellSize = 0;

  ({
    List<MemoryCard> prevCards,
    List<MemoryCard> nextCards,
    List<(int, int)> swapPairs,
    MemoryDifficulty difficulty,
  })? _pendingSwap;

  @override
  void dispose() {
    _swapCtrl?.dispose();
    super.dispose();
  }

  Offset _positionFor(int cardIndex) {
    final col = cardIndex % widget.cols;
    final row = cardIndex ~/ widget.cols;
    return Offset(
      col * (_cellSize + _kSpacing),
      row * (_cellSize + _kSpacing),
    );
  }

  Offset _arcPosition(_SwapData data, double t) {
    final lerped = Offset.lerp(data.from, data.to, t)!;
    final distance = (data.to - data.from).distance;
    final arcHeight = distance * 0.38;
    final vert = data.arcUp
        ? -arcHeight * math.sin(t * math.pi)
        : arcHeight * math.sin(t * math.pi);
    return lerped + Offset(0, vert);
  }

  // Cards slightly lift at arc peak — gives tactile 3D feel.
  double _arcScale(double t) => 1.0 + 0.10 * math.sin(t * math.pi);

  void _startSwapAnimation({
    required List<MemoryCard> prevCards,
    required List<MemoryCard> nextCards,
    required List<(int, int)> swapPairs,
    required MemoryDifficulty difficulty,
  }) {
    _swapCtrl?.dispose();
    _swapCtrl = AnimationController(
      vsync: this,
      duration: difficulty.shuffleDuration,
    );
    // Smooth cubic ease — no more linear jank at endpoints.
    _swapAnim = CurvedAnimation(
      parent: _swapCtrl!,
      curve: Curves.easeInOutCubic,
    )..addListener(() => setState(() {}));

    final newSwapMap = <int, _SwapData>{};
    bool arcUp = true;

    for (final (idA, idB) in swapPairs) {
      final prevIdxA = prevCards.indexWhere((c) => c.id == idA);
      final nextIdxA = nextCards.indexWhere((c) => c.id == idA);
      final prevIdxB = prevCards.indexWhere((c) => c.id == idB);
      final nextIdxB = nextCards.indexWhere((c) => c.id == idB);

      if (prevIdxA != -1 && nextIdxA != -1) {
        newSwapMap[idA] = (
          from: _positionFor(prevIdxA),
          to: _positionFor(nextIdxA),
          arcUp: arcUp,
        );
      }
      if (prevIdxB != -1 && nextIdxB != -1) {
        newSwapMap[idB] = (
          from: _positionFor(prevIdxB),
          to: _positionFor(nextIdxB),
          arcUp: !arcUp,
        );
      }
      arcUp = !arcUp;
    }

    setState(() => _swapMap = newSwapMap);

    _swapCtrl!.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _swapMap = const {});
      _swapCtrl?.dispose();
      _swapCtrl = null;
      _swapAnim = null;
      ref.read(memoryProvider.notifier).onShuffleAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(memoryProvider.select((s) => s.cards));
    ref.watch(memoryProvider.select((s) => s.difficulty));

    ref.listen<MemoryGameState>(memoryProvider, (prev, next) {
      if (prev?.swapPairs == null && next.swapPairs != null && prev != null) {
        if (_cellSize > 0) {
          _startSwapAnimation(
            prevCards: prev.cards,
            nextCards: next.cards,
            swapPairs: next.swapPairs!,
            difficulty: next.difficulty,
          );
        } else {
          _pendingSwap = (
            prevCards: prev.cards,
            nextCards: next.cards,
            swapPairs: next.swapPairs!,
            difficulty: next.difficulty,
          );
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.maxHeight;
        final cellW = (availW - _kSpacing * (widget.cols - 1)) / widget.cols;
        final cellH = (availH - _kSpacing * (widget.rows - 1)) / widget.rows;
        _cellSize = math.min(cellW, cellH);

        if (_pendingSwap != null) {
          final pending = _pendingSwap!;
          _pendingSwap = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _startSwapAnimation(
                prevCards: pending.prevCards,
                nextCards: pending.nextCards,
                swapPairs: pending.swapPairs,
                difficulty: pending.difficulty,
              );
            }
          });
        }

        final totalW = widget.cols * _cellSize + (widget.cols - 1) * _kSpacing;
        final totalH = widget.rows * _cellSize + (widget.rows - 1) * _kSpacing;
        final offsetX = (availW - totalW) / 2;
        final offsetY = (availH - totalH) / 2;

        final t = _swapAnim?.value ?? 0.0;

        final staticCards = <Widget>[];
        final animatingCards = <Widget>[];

        for (int idx = 0; idx < cards.length; idx++) {
          final card = cards[idx];
          final swapData = _swapMap[card.id];

          final Offset pos;
          final double scale;
          if (swapData != null) {
            pos = _arcPosition(swapData, t) + Offset(offsetX, offsetY);
            scale = _arcScale(t);
          } else {
            pos = _positionFor(idx) + Offset(offsetX, offsetY);
            scale = 1.0;
          }

          final positioned = Positioned(
            key: ValueKey(card.id),
            left: pos.dx,
            top: pos.dy,
            width: _cellSize,
            height: _cellSize,
            child: Transform.scale(
              scale: scale,
              child: _MemoryCardTile(cardId: card.id),
            ),
          );

          if (swapData != null) {
            animatingCards.add(positioned);
          } else {
            staticCards.add(positioned);
          }
        }

        return SizedBox(
          width: availW,
          height: availH,
          child: Stack(children: [...staticCards, ...animatingCards]),
        );
      },
    );
  }
}

// ── Card tile ─────────────────────────────────────────────────────────────────

class _MemoryCardTile extends ConsumerStatefulWidget {
  const _MemoryCardTile({required this.cardId});
  final int cardId;

  @override
  ConsumerState<_MemoryCardTile> createState() => _MemoryCardTileState();
}

class _MemoryCardTileState extends ConsumerState<_MemoryCardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  bool _wasFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipCtrl,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(
      memoryProvider.select((s) {
        for (final c in s.cards) {
          if (c.id == widget.cardId) return c;
        }
        return MemoryCard(id: widget.cardId, value: 0);
      }),
    );
    final phase = ref.watch(memoryProvider.select((s) => s.phase));

    if (card.isFlipped != _wasFlipped) {
      _wasFlipped = card.isFlipped;
      card.isFlipped ? _flipCtrl.forward() : _flipCtrl.reverse();
    }

    final canTap = phase == MemoryGamePhase.playing &&
        !card.isFlipped &&
        !card.isMatched;

    return GestureDetector(
      onTap: canTap
          ? () => ref.read(memoryProvider.notifier).flipCard(widget.cardId)
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pre-warm emoji font — always built, never painted.
          Offstage(offstage: true, child: _FrontFace(card: card)),

          AnimatedBuilder(
            animation: _flipAnim,
            builder: (context, _) {
              final angle = _flipAnim.value * math.pi;
              final showFront = angle >= math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: showFront
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _FrontFace(card: card),
                      )
                    : const _BackFace(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Card faces ────────────────────────────────────────────────────────────────

class _FrontFace extends StatelessWidget {
  const _FrontFace({required this.card});
  final MemoryCard card;

  @override
  Widget build(BuildContext context) {
    final emoji = _kEmojis[card.value % _kEmojis.length];
    final color = _pairColor(card.value);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: card.isMatched
            ? color.withValues(alpha: 0.18)
            : _kCardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: card.isMatched ? color : color.withValues(alpha: 0.55),
          width: card.isMatched ? 2.5 : 1.5,
        ),
        boxShadow: card.isMatched
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.50),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBack,
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF111E32)],
        ),
        border: Border.all(
          color: Color(0xFF00E5FF).withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.memory_rounded,
          color: Colors.white.withValues(alpha: 0.12),
          size: 22,
        ),
      ),
    );
  }
}
