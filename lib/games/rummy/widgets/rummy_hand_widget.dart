import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

class RummyHandWidget extends StatelessWidget {
  const RummyHandWidget({
    super.key,
    required this.cards,
    required this.selectedCardIds,
    required this.onCardTap,
    this.onReorder,
    this.isDragEnabled = false,
    this.enabled = true,
    this.containerKey,
  });

  final List<PlayingCard> cards;
  final List<String> selectedCardIds;
  final void Function(PlayingCard) onCardTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final bool isDragEnabled;
  final bool enabled;
  final GlobalKey? containerKey;

  static const double _cardVisibleWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final totalWidth = kCardWidth + (cards.length - 1) * _cardVisibleWidth;

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < cards.length; i++)
          Positioned(
            left: i * _cardVisibleWidth,
            top: 0,
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
      ],
    );

    final body = SizedBox(
      width: totalWidth,
      height: kCardHeight + 16,
      child: isDragEnabled && onReorder != null
          ? _HandReorderTarget(
              cards: cards,
              onReorder: onReorder!,
              cardVisibleWidth: _cardVisibleWidth,
              child: stack,
            )
          : stack,
    );

    return Center(
      key: containerKey,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: body,
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
          child: PlayingCardWidget(card: card, faceUp: true),
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
