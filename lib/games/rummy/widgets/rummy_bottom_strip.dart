import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import 'rummy_action_bar.dart';
import 'rummy_hand_widget.dart';
import 'rummy_sort_buttons.dart';

class RummyBottomStrip extends ConsumerWidget {
  const RummyBottomStrip({
    super.key,
    required this.notifier,
    this.handContainerKey,
  });

  final RummyNotifier notifier;
  final GlobalKey? handContainerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(rummyProvider.select((s) => (
      isHumanTurn: s.isHumanTurn,
      turnPhase: s.turnPhase,
      hasHumanPlayer: s.players.isNotEmpty,
      humanHand: s.players.isNotEmpty
          ? s.players[0].hand
          : const <PlayingCard>[],
      selectedCardIds: s.selectedCardIds,
      humanIsOpen: s.players.isNotEmpty && s.players[0].isOpen,
      canUndo: s.canUndo,
    )));
    final isMeldPhase = s.isHumanTurn && s.turnPhase == TurnPhase.meld;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMeldPhase)
          RummyActionBar(
            notifier: notifier,
            selectedCardIds: s.selectedCardIds,
            isOpen: s.humanIsOpen,
            canUndo: s.canUndo,
            humanHand: s.humanHand,
          ),
        if (s.hasHumanPlayer)
          Row(
            children: [
              const RummySortButtons(),
              Expanded(
                child: RummyHandWidget(
                  cards: s.humanHand,
                  selectedCardIds: s.selectedCardIds,
                  onCardTap: (card) {
                    if (s.turnPhase == TurnPhase.meld) {
                      notifier.toggleCardSelection(card.id);
                    }
                  },
                  onReorder: notifier.reorderHand,
                  isDragEnabled: isMeldPhase,
                  enabled: s.isHumanTurn,
                  containerKey: handContainerKey,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
