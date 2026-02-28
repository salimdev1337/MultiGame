import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

class RummyCenterPile extends StatefulWidget {
  const RummyCenterPile({
    super.key,
    required this.drawPileCount,
    required this.topDiscard,
    required this.canDraw,
    required this.onDrawFromDeck,
    required this.onDrawFromDiscard,
    this.canDropOnDiscard = false,
    this.onCardDroppedOnDiscard,
    this.deckWidgetKey,
    this.discardWidgetKey,
  });

  final int drawPileCount;
  final PlayingCard? topDiscard;
  final bool canDraw;
  final VoidCallback onDrawFromDeck;
  final VoidCallback onDrawFromDiscard;
  final bool canDropOnDiscard;
  final void Function(PlayingCard)? onCardDroppedOnDiscard;
  final GlobalKey? deckWidgetKey;
  final GlobalKey? discardWidgetKey;

  static const double _pileW = kCardWidth * 0.85;
  static const double _pileH = kCardHeight * 0.85;

  @override
  State<RummyCenterPile> createState() => _RummyCenterPileState();
}

class _RummyCenterPileState extends State<RummyCenterPile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    if (widget.canDraw) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RummyCenterPile old) {
    super.didUpdateWidget(old);
    if (widget.canDraw && !old.canDraw) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.canDraw && old.canDraw) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.canDraw ? widget.onDrawFromDeck : null,
          child: Stack(
            children: [
              RepaintBoundary(
                child: Stack(
                  key: widget.deckWidgetKey,
                  children: [
                    if (widget.drawPileCount > 1)
                      Positioned(
                        top: 2,
                        left: 2,
                        child: _blankCard(false),
                      ),
                    _blankCard(widget.canDraw),
                  ],
                ),
              ),
              if (widget.canDraw)
                IgnorePointer(
                  child: FadeTransition(
                    opacity: _pulseAnim,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: DSColors.rummyAccent.withValues(alpha: 0.55),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: RummyCenterPile._pileW,
                        height: RummyCenterPile._pileH,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          '${widget.drawPileCount}',
          style: DSTypography.labelSmall
              .copyWith(color: DSColors.textTertiary, fontSize: 9),
        ),
        const SizedBox(height: 6),
        _DiscardDropTarget(
          canDrop: widget.canDropOnDiscard,
          onCardDropped: widget.onCardDroppedOnDiscard,
          child: GestureDetector(
            key: widget.discardWidgetKey,
            onTap: widget.canDraw && widget.topDiscard != null
                ? widget.onDrawFromDiscard
                : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: KeyedSubtree(
                key: ValueKey(widget.topDiscard?.id),
                child: widget.topDiscard != null
                    ? PlayingCardWidget(
                        card: widget.topDiscard!,
                        faceUp: true,
                        width: RummyCenterPile._pileW,
                        height: RummyCenterPile._pileH,
                      )
                    : _emptyDiscardSlot(),
              ),
            ),
          ),
        ),
        Text(
          'Discard',
          style: DSTypography.labelSmall
              .copyWith(color: DSColors.textTertiary, fontSize: 9),
        ),
      ],
    );
  }

  Widget _blankCard(bool highlighted) {
    return Container(
      width: RummyCenterPile._pileW,
      height: RummyCenterPile._pileH,
      decoration: BoxDecoration(
        color: highlighted
            ? DSColors.rummyCardBack.withValues(alpha: 0.9)
            : DSColors.rummyCardBack.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlighted
              ? DSColors.rummyAccent
              : DSColors.rummyAccent.withValues(alpha: 0.4),
          width: highlighted ? 1.5 : 1,
        ),
      ),
    );
  }

  Widget _emptyDiscardSlot() {
    return Container(
      width: RummyCenterPile._pileW,
      height: RummyCenterPile._pileH,
      decoration: BoxDecoration(
        color: DSColors.rummyFelt.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: DSColors.rummyPrimary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: const Icon(Icons.add, color: Colors.white30, size: 16),
    );
  }
}

class _DiscardDropTarget extends StatefulWidget {
  const _DiscardDropTarget({
    required this.canDrop,
    required this.child,
    this.onCardDropped,
  });

  final bool canDrop;
  final Widget child;
  final void Function(PlayingCard)? onCardDropped;

  @override
  State<_DiscardDropTarget> createState() => _DiscardDropTargetState();
}

class _DiscardDropTargetState extends State<_DiscardDropTarget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.canDrop) {
      return widget.child;
    }
    return DragTarget<PlayingCard>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _hovering = false);
        widget.onCardDropped?.call(details.data);
      },
      builder: (_, _, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: _hovering
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: DSColors.rummyAccent.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 4,
                  ),
                ],
              )
            : null,
        child: widget.child,
      ),
    );
  }
}
