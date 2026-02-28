// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'rummy_notifier.dart';

extension _RummyNotifierBot on RummyNotifier {
  void _scheduleNextBotTurn() {
    _cancelBotTimer();
    if (state.phase != RummyPhase.playing) {
      return;
    }
    if (state.isHumanTurn) {
      return;
    }
    _botTimer = Timer(const Duration(milliseconds: 600), _executeBotTurn);
  }

  void _executeBotTurn() {
    if (state.phase != RummyPhase.playing) {
      return;
    }
    if (state.isHumanTurn) {
      return;
    }

    final selfIdx = state.currentPlayerIndex;
    final self = state.players[selfIdx];
    if (self.isEliminated) {
      _advanceTurn();
      return;
    }

    // Phase 1: decide and execute the draw using the pre-draw hand.
    final preDrawDecisions = aiDecide(
      state.difficulty,
      self,
      state.topDiscard,
      state,
      selfIdx,
    );
    final drawAction =
        preDrawDecisions.isNotEmpty ? preDrawDecisions.first : null;
    if (drawAction is DrawFromDiscard) {
      _botDraw(selfIdx, fromDiscard: true);
    } else {
      _botDraw(selfIdx, fromDiscard: false);
    }

    // Phase 2: re-plan melds and discard with the post-draw hand.
    final postDrawDecisions = aiDecide(
      state.difficulty,
      state.players[selfIdx],
      state.topDiscard,
      state,
      selfIdx,
    );
    final meldAndDiscard = postDrawDecisions
        .where((d) => d is! DrawFromDeck && d is! DrawFromDiscard)
        .toList();

    _applyBotDecisions(meldAndDiscard, selfIdx);
  }

  void _applyBotDecisions(List<AiDecision> decisions, int selfIdx) {
    for (final decision in decisions) {
      if (state.phase != RummyPhase.playing) {
        return;
      }

      if (decision is DrawFromDeck) {
        _botDraw(selfIdx, fromDiscard: false);
      } else if (decision is DrawFromDiscard) {
        _botDraw(selfIdx, fromDiscard: true);
      } else if (decision is LayMeld) {
        _botLayMeld(selfIdx, decision.meld);
      } else if (decision is DiscardCard) {
        _botDiscard(selfIdx, decision.card);
        return; // discard ends turn
      } else if (decision is DeclareWin) {
        if (canDeclare(state.players[selfIdx].hand)) {
          _applyDeclare(selfIdx);
        }
        return;
      }
    }
    // If AI never discarded, fallback: discard highest value card.
    _botFallbackDiscard(selfIdx);
  }

  void _botDraw(int selfIdx, {required bool fromDiscard}) {
    if (fromDiscard && state.topDiscard != null) {
      final top = state.topDiscard!;
      final newDiscard = List<PlayingCard>.from(state.discardPile)..removeLast();
      final updatedPlayers = _updatePlayerHand(selfIdx, add: [top]);
      state = state.copyWith(
        players: updatedPlayers,
        discardPile: newDiscard,
        drawnCardThisTurn: top,
      );
    } else {
      if (state.drawPile.isEmpty) {
        _reshuffleDiscard();
      }
      if (state.drawPile.isEmpty) {
        return;
      }
      final draw = state.drawPile.last;
      final newDraw = List<PlayingCard>.from(state.drawPile)..removeLast();
      final updatedPlayers = _updatePlayerHand(selfIdx, add: [draw]);
      state = state.copyWith(
        players: updatedPlayers,
        drawPile: newDraw,
        drawnCardThisTurn: draw,
      );
    }
  }

  void _botLayMeld(int selfIdx, RummyMeld meld) {
    final player = state.players[selfIdx];
    final meldIds = meld.cards.map((c) => c.id).toSet();
    // Verify the player actually has these cards.
    final actualCards = player.hand.where((c) => meldIds.contains(c.id)).toList();
    if (actualCards.length != meld.cards.length) {
      return;
    }
    final type = validateMeld(actualCards);
    if (type == null) {
      return;
    }
    final validMeld = RummyMeld(type: type, cards: actualCards);
    final newHand = player.hand.where((c) => !meldIds.contains(c.id)).toList();
    final newMelds = [...player.melds, validMeld];

    final meldValue = deadwoodValue(actualCards);
    final newTurnTotal = state.turnMeldPoints + meldValue;

    // Compute opening in-memory — single state notification.
    final shouldOpen = !player.isOpen && newTurnTotal >= state.meldMinimum;
    final newMin = shouldOpen ? newTurnTotal + 1 : state.meldMinimum;

    final updatedPlayer = player.copyWith(
      hand: newHand,
      melds: newMelds,
      isOpen: shouldOpen ? true : player.isOpen,
    );
    final players = List<RummyPlayer>.from(state.players);
    players[selfIdx] = updatedPlayer;

    state = state.copyWith(
      players: players,
      turnMeldPoints: newTurnTotal,
      turnMeldCount: state.turnMeldCount + 1,
      meldMinimum: newMin,
    );

    _handleFullSets(state.players);

    if (canDeclare(newHand)) {
      _applyDeclare(selfIdx);
    }
  }

  void _botDiscard(int selfIdx, PlayingCard card) {
    // Step 1: Compute revert in-memory — no intermediate state assignment.
    var players = List<RummyPlayer>.from(state.players);
    var turnMeldPoints = state.turnMeldPoints;
    var turnMeldCount = state.turnMeldCount;

    if (!players[selfIdx].isOpen && turnMeldCount > 0) {
      final p = players[selfIdx];
      final meldedThisTurn = p.melds.sublist(p.melds.length - turnMeldCount);
      final revertedCards = meldedThisTurn.expand((m) => m.cards).toList();
      final revertedMelds = p.melds.sublist(0, p.melds.length - turnMeldCount);
      players[selfIdx] = p.copyWith(
        hand: [...p.hand, ...revertedCards],
        melds: revertedMelds,
      );
      turnMeldPoints = 0;
      turnMeldCount = 0;
    }

    // Step 2: Find the card in the (possibly reverted) hand.
    final currentPlayer = players[selfIdx];
    PlayingCard? actual;
    for (final c in currentPlayer.hand) {
      if (c.id == card.id) {
        actual = c;
        break;
      }
    }
    if (actual == null) {
      if (currentPlayer.hand.isEmpty) {
        _advanceTurn();
        return;
      }
      // Fallback inline: discard the highest-value card.
      final sorted = List<PlayingCard>.from(currentPlayer.hand)
        ..sort((a, b) => cardPointValue(b).compareTo(cardPointValue(a)));
      actual = sorted.first;
    }

    // Step 3: Apply discard — single state notification.
    final newHand = List<PlayingCard>.from(currentPlayer.hand)..remove(actual);
    players[selfIdx] = currentPlayer.copyWith(hand: newHand);
    final newDiscard = [...state.discardPile, actual];

    if (newHand.isEmpty) {
      state = state.copyWith(
        players: players,
        discardPile: newDiscard,
        lastDiscardByPlayer: selfIdx,
        lastDiscardedCard: actual,
        drawnCardThisTurn: null,
        selectedCardIds: [],
        turnMeldPoints: 0,
        turnMeldCount: 0,
      );
      _applyDeclare(selfIdx);
      return;
    }

    final next = nextActivePlayer(players, selfIdx);

    state = state.copyWith(
      players: players,
      discardPile: newDiscard,
      currentPlayerIndex: next,
      turnPhase: TurnPhase.draw,
      lastDiscardByPlayer: selfIdx,
      lastDiscardedCard: actual,
      drawnCardThisTurn: null,
      selectedCardIds: [],
      turnMeldPoints: 0,
      turnMeldCount: 0,
      statusMessage: players[next].isHuman
          ? 'Your turn — draw a card.'
          : '${players[next].name}\'s turn...',
    );

    _scheduleNextBotTurn();
  }

  void _botFallbackDiscard(int selfIdx) {
    final player = state.players[selfIdx];
    if (player.hand.isEmpty) {
      _advanceTurn();
      return;
    }
    final sorted = List<PlayingCard>.from(player.hand)
      ..sort((a, b) => cardPointValue(b).compareTo(cardPointValue(a)));
    _botDiscard(selfIdx, sorted.first);
  }

  void _advanceTurn() {
    final next = nextActivePlayer(state.players, state.currentPlayerIndex);
    state = state.copyWith(
      currentPlayerIndex: next,
      turnPhase: TurnPhase.draw,
      statusMessage: state.players[next].isHuman
          ? 'Your turn — draw a card.'
          : '${state.players[next].name}\'s turn...',
    );
    _scheduleNextBotTurn();
  }
}
