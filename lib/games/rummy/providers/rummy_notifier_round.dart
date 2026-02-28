// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'rummy_notifier.dart';

extension _RummyNotifierRound on RummyNotifier {
  void _applyDeclare(int declarerIdx) {
    state = state.copyWith(
      phase: RummyPhase.declaring,
      statusMessage: '${state.players[declarerIdx].name} declares!',
    );

    // Check discard penalty for previous discard.
    var players = List<RummyPlayer>.from(state.players);
    final declarer = players[declarerIdx];

    if (state.lastDiscardByPlayer != null &&
        state.drawnCardThisTurn != null &&
        checkDiscardPenalty(
            state, declarerIdx, state.drawnCardThisTurn!, declarer)) {
      final penaltyIdx = state.lastDiscardByPlayer!;
      final penalized = players[penaltyIdx];
      players[penaltyIdx] =
          penalized.copyWith(score: penalized.score + 50);
    }

    // Compute round penalties.
    final penalties = computeRoundPenalties(
      state.copyWith(players: players),
      declarerIdx,
    );

    for (final entry in penalties.entries) {
      final p = players[entry.key];
      players[entry.key] = p.copyWith(score: p.score + entry.value);
    }

    // Mark eliminated players (reached 1200).
    final newEliminated = List<int>.from(state.eliminatedPlayers);
    for (var i = 0; i < players.length; i++) {
      if (!players[i].isEliminated &&
          players[i].score >= kRummyEliminationScore) {
        players[i] = players[i].copyWith(isEliminated: true);
        newEliminated.add(i);
      }
    }

    // Check game over (only 0 or 1 active players left).
    final activeCount = players.where((p) => !p.isEliminated).length;
    if (activeCount <= 1) {
      state = state.copyWith(
        players: players,
        eliminatedPlayers: newEliminated,
        phase: RummyPhase.gameOver,
        statusMessage: _buildWinMessage(players),
      );
      // Save score for the winner(s).
      final winners = players.where((p) => !p.isEliminated).toList();
      if (winners.length == 1 && winners.first.isHuman) {
        saveScore('rummy', 1);
      }
      return;
    }

    // Otherwise start a new round.
    state = state.copyWith(
      players: players,
      eliminatedPlayers: newEliminated,
      phase: RummyPhase.roundEnd,
      statusMessage: _buildRoundEndMessage(penalties, declarerIdx, players),
    );

    Timer(const Duration(seconds: 3), _startNewRound);
  }

  void _startNewRound() {
    final deck = shuffle(generateDeck());
    final dealt = dealHands(deck, kRummyPlayerCount, kRummyHandSize);
    var remaining = dealt.remaining;
    final firstDiscard = remaining.removeAt(0);

    final players = state.players.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      return RummyPlayer(
        id: p.id,
        name: p.name,
        isHuman: p.isHuman,
        hand: p.isEliminated ? const [] : dealt.hands[i],
        melds: const [],
        score: p.score,
        isEliminated: p.isEliminated,
      );
    }).toList();

    // First active player leads.
    var startIdx = 0;
    for (var i = 0; i < players.length; i++) {
      if (!players[i].isEliminated) {
        startIdx = i;
        break;
      }
    }

    state = state.copyWith(
      players: players,
      drawPile: remaining,
      discardPile: [firstDiscard],
      currentPlayerIndex: startIdx,
      phase: RummyPhase.playing,
      turnPhase: TurnPhase.draw,
      lastDiscardByPlayer: null,
      lastDiscardedCard: null,
      roundNumber: state.roundNumber + 1,
      drawnCardThisTurn: null,
      selectedCardIds: [],
      meldMinimum: 71,
      turnMeldPoints: 0,
      turnMeldCount: 0,
      statusMessage: players[startIdx].isHuman
          ? 'Round ${state.roundNumber + 1} — draw a card.'
          : '${players[startIdx].name}\'s turn...',
    );

    _scheduleNextBotTurn();
  }

  String _buildWinMessage(List<RummyPlayer> players) {
    final winners = players.where((p) => !p.isEliminated).toList();
    if (winners.isEmpty) {
      return 'Game Over! No winners.';
    }
    final names = winners.map((p) => p.name).join(' & ');
    return 'Game Over! $names win!';
  }

  String _buildRoundEndMessage(
    Map<int, int> penalties,
    int declarerIdx,
    List<RummyPlayer> players,
  ) {
    final buffer = StringBuffer('${players[declarerIdx].name} declared!\n');
    for (final entry in penalties.entries) {
      buffer.write('+${entry.value} pts for ${players[entry.key].name}. ');
    }
    return buffer.toString().trim();
  }
}
