import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memory_card.dart';
import '../models/memory_game_state.dart';
import '../providers/memory_notifier.dart';

const _kSpacing = 8.0;
const _kCardBack = Color(0xFF0D1B2A);
const _kCardSurface = Color(0xFF0D0D20);

const _kEmojis = [
  '🦊', '🐬', '🦋', '🌸', '🍕',
  '🎸', '🚀', '🌈', '⚡', '🎯',
  '🦄', '🐉', '🍀', '🔮', '🎭',
  '🏆', '🌙', '🔥', '💎', '🎪',
];

Color _pairColor(int value) {
  final hue = (value * 137.508) % 360.0;
  return HSLColor.fromAHSL(1.0, hue, 0.80, 0.62).toColor();
}

typedef _SwapData = ({Offset from, Offset to, bool arcUp});

class MemoryCardGrid extends ConsumerStatefulWidget {
  const MemoryCardGrid({super.key, required this.cols, required this.rows});
  final int cols;
  final int rows;

  @override
  ConsumerState<MemoryCardGrid> createState() => _MemoryCardGridState();
}

class _MemoryCardGridState extends ConsumerState<MemoryCardGrid>
    with TickerProviderStateMixin {
  AnimationController? _swapCtrl;
  Animation<double>? _swapAnim;
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
      if (!mounted) {
        return;
      }
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
              child: MemoryCardTile(cardId: card.id),
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

class MemoryCardTile extends ConsumerStatefulWidget {
  const MemoryCardTile({super.key, required this.cardId});
  final int cardId;

  @override
  ConsumerState<MemoryCardTile> createState() => _MemoryCardTileState();
}

class _MemoryCardTileState extends ConsumerState<MemoryCardTile>
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
          if (c.id == widget.cardId) {
            return c;
          }
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
          Offstage(offstage: true, child: MemoryFrontFace(card: card)),
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
                        child: MemoryFrontFace(card: card),
                      )
                    : const MemoryBackFace(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MemoryFrontFace extends StatelessWidget {
  const MemoryFrontFace({super.key, required this.card});
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

class MemoryBackFace extends StatelessWidget {
  const MemoryBackFace({super.key});

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
          color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
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
