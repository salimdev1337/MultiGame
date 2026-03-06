import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playing_card.dart';
import '../providers/rummy_notifier.dart';
import 'playing_card_widget.dart';

class RummyHandWidget extends ConsumerWidget {
  const RummyHandWidget({
    super.key,
    required this.cards,
    required this.onCardTap,
    this.onReorder,
    this.isDragEnabled = false,
    this.enabled = true,
    this.containerKey,
  });

  final List<PlayingCard> cards;
  final void Function(PlayingCard) onCardTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final bool isDragEnabled;
  final bool enabled;
  final GlobalKey? containerKey;

  static const double _cardVisibleWidth = 28.0;
  static const double _maxAngle = 0.06; // ~3.4 degrees at edges
  static const double _maxLift = 10.0; // max vertical offset at edges
  static const double _selectedLift = kCardHeight * 0.15; // 13.5px — matches AnimatedSlide offset

  static double _arcAngle(int i, int count) {
    if (count <= 1) {
      return 0;
    }
    final t = (i / (count - 1)) * 2 - 1; // -1..1
    return t * _maxAngle;
  }

  static double _arcY(int i, int count) {
    if (count <= 1) {
      return 0;
    }
    final t = (i / (count - 1)) * 2 - 1; // -1..1
    return t * t * _maxLift; // parabolic: edges high, center low
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCardIds =
        ref.watch(rummyProvider.select((s) => s.selectedCardIds));

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final totalWidth = kCardWidth + (cards.length - 1) * _cardVisibleWidth;

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < cards.length; i++)
          Positioned(
            key: ValueKey(cards[i].id),
            left: i * _cardVisibleWidth,
            top: _selectedLift + _arcY(i, cards.length),
            child: Transform.rotate(
              angle: _arcAngle(i, cards.length),
              alignment: Alignment.bottomCenter,
              child: isDragEnabled
                  ? _DraggableCard(
                      card: cards[i],
                      isSelected: selectedCardIds.contains(cards[i].id),
                      onTap: enabled ? () => onCardTap(cards[i]) : null,
                    )
                  : _StaticCard(
                      index: i,
                      card: cards[i],
                      isSelected: selectedCardIds.contains(cards[i].id),
                      onTap: enabled ? () => onCardTap(cards[i]) : null,
                      onReorder: onReorder,
                      totalCards: cards.length,
                    ),
            ),
          ),
      ],
    );

    final body = SizedBox(
      width: totalWidth,
      height: kCardHeight + _maxLift + _selectedLift + 6,
      child: isDragEnabled && onReorder != null
          ? _HandReorderTarget(
              cards: cards,
              onReorder: onReorder!,
              cardVisibleWidth: _cardVisibleWidth,
              child: stack,
            )
          : stack,
    );

    return RepaintBoundary(
      child: Center(
        key: containerKey,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: body,
        ),
      ),
    );
  }
}

// ── Draggable card — used when isDragEnabled (meld phase) ────────────────────

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.card,
    required this.isSelected,
    this.onTap,
  });

  final PlayingCard card;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<PlayingCard>(
      data: card,
      delay: const Duration(milliseconds: 250),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.12,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 8,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: PlayingCardWidget(card: card, faceUp: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: PlayingCardWidget(card: card, faceUp: true, isSelected: isSelected),
      ),
      child: PlayingCardWidget(
        card: card,
        faceUp: true,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }
}

// ── Static card — horizontal-drag reorder, used outside meld phase ───────────

class _StaticCard extends StatefulWidget {
  const _StaticCard({
    required this.index,
    required this.card,
    required this.isSelected,
    required this.totalCards,
    this.onTap,
    this.onReorder,
  });

  final int index;
  final PlayingCard card;
  final bool isSelected;
  final VoidCallback? onTap;
  final void Function(int, int)? onReorder;
  final int totalCards;

  @override
  State<_StaticCard> createState() => _StaticCardState();
}

class _StaticCardState extends State<_StaticCard> {
  double _dragDx = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.onReorder == null) {
      return PlayingCardWidget(
        card: widget.card,
        faceUp: true,
        isSelected: widget.isSelected,
        onTap: widget.onTap,
      );
    }
    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
      onHorizontalDragEnd: (_) {
        final moved = (_dragDx / RummyHandWidget._cardVisibleWidth).round();
        if (moved != 0) {
          final newIdx = (widget.index + moved).clamp(0, widget.totalCards - 1);
          if (newIdx != widget.index) {
            widget.onReorder!(widget.index, newIdx);
          }
        }
        _dragDx = 0;
      },
      child: PlayingCardWidget(
        card: widget.card,
        faceUp: true,
        isSelected: widget.isSelected,
      ),
    );
  }
}

// ── DragTarget that covers the hand for drop-to-reorder ──────────────────────

class _HandReorderTarget extends StatelessWidget {
  const _HandReorderTarget({
    required this.cards,
    required this.onReorder,
    required this.cardVisibleWidth,
    required this.child,
  });

  final List<PlayingCard> cards;
  final void Function(int, int) onReorder;
  final double cardVisibleWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlayingCard>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = box.globalToLocal(details.offset).dx;
        final newIdx = (localX / cardVisibleWidth).floor().clamp(0, cards.length - 1);
        final oldIdx = cards.indexWhere((c) => c.id == details.data.id);
        if (oldIdx != -1 && newIdx != oldIdx) {
          onReorder(oldIdx, newIdx);
        }
      },
      builder: (_, _, _) => child,
    );
  }
}
