import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import 'rummy_center_pile.dart';

class RummyLeftSidebar extends ConsumerWidget {
  const RummyLeftSidebar({
    super.key,
    required this.notifier,
    this.onCardDroppedOnDiscard,
    this.onDrawFromDeck,
    this.onDrawFromDiscard,
    this.deckWidgetKey,
    this.discardWidgetKey,
  });

  final RummyNotifier notifier;
  final void Function(PlayingCard)? onCardDroppedOnDiscard;
  final VoidCallback? onDrawFromDeck;
  final VoidCallback? onDrawFromDiscard;
  final GlobalKey? deckWidgetKey;
  final GlobalKey? discardWidgetKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(rummyProvider.select((s) => (
      drawPileCount: s.drawPile.length,
      topDiscard: s.topDiscard,
      isHumanTurn: s.isHumanTurn,
      turnPhase: s.turnPhase,
      statusMessage: s.statusMessage,
    )));
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RummyCenterPile(
            drawPileCount: s.drawPileCount,
            topDiscard: s.topDiscard,
            canDraw: s.isHumanTurn && s.turnPhase == TurnPhase.draw,
            onDrawFromDeck: onDrawFromDeck ?? notifier.drawFromDeck,
            onDrawFromDiscard: onDrawFromDiscard ?? notifier.drawFromDiscard,
            canDropOnDiscard: s.isHumanTurn && s.turnPhase == TurnPhase.meld,
            onCardDroppedOnDiscard: onCardDroppedOnDiscard,
            deckWidgetKey: deckWidgetKey,
            discardWidgetKey: discardWidgetKey,
          ),
          const SizedBox(height: 6),
          if (s.statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                s.statusMessage!,
                style: DSTypography.labelSmall
                    .copyWith(color: Colors.white60, fontSize: 8),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
