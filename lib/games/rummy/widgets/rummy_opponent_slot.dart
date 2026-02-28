import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/rummy_notifier.dart';
import 'rummy_opponent_widget.dart';

class RummyOpponentSlot extends ConsumerWidget {
  const RummyOpponentSlot({
    super.key,
    required this.playerIdx,
    this.horizontal = true,
  });

  final int playerIdx;
  final bool horizontal;

  @override
  Widget build(context, WidgetRef ref) {
    final s = ref.watch(rummyProvider.select((s) => (
      player: playerIdx < s.players.length ? s.players[playerIdx] : null,
      isCurrentTurn: s.currentPlayerIndex == playerIdx,
    )));
    if (s.player == null) {
      return const SizedBox.shrink();
    }
    return RummyOpponentWidget(
      player: s.player!,
      isCurrentTurn: s.isCurrentTurn,
      horizontal: horizontal,
    );
  }
}
