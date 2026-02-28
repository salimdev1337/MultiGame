import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import 'rummy_opponent_slot.dart';
import 'rummy_table_widget.dart';

class RummyCenterArea extends ConsumerWidget {
  const RummyCenterArea({
    super.key,
    required this.notifier,
  });

  final RummyNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(rummyProvider.select((s) => (
      playerCount: s.players.length,
      players: s.players,
      meldMinimum: s.meldMinimum,
      completingMeldIds: s.completingMeldIds,
      isHumanTurn: s.isHumanTurn,
      turnPhase: s.turnPhase,
      selectedCardIds: s.selectedCardIds,
      humanIsOpen: s.players.isNotEmpty && s.players[0].isOpen,
    )));
    final canInteractWithMelds = s.isHumanTurn &&
        s.turnPhase == TurnPhase.meld &&
        s.playerCount > 0 &&
        s.humanIsOpen;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.playerCount > 1) const RummyOpponentSlot(playerIdx: 1),
              if (s.playerCount > 2) const RummyOpponentSlot(playerIdx: 2),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: RummyTableWidget(
              players: s.players,
              meldMinimum: s.meldMinimum,
              completingMeldIds: s.completingMeldIds,
              highlightOwnMelds:
                  canInteractWithMelds && s.selectedCardIds.isNotEmpty,
              onOwnMeldTap:
                  canInteractWithMelds && s.selectedCardIds.isNotEmpty
                      ? (meldIdx) => _onMeldTap(context, meldIdx)
                      : null,
              onCardDroppedOnMeld: canInteractWithMelds
                  ? (card, meldIdx) => _onMeldDrop(context, card, meldIdx)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  void _onMeldTap(BuildContext context, int meldIdx) {
    final error = notifier.addSelectedCardsToMeld(meldIdx);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _onMeldDrop(BuildContext context, PlayingCard card, int meldIdx) {
    final error = notifier.dropCardOnMeld(card, meldIdx);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
