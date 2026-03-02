// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'rummy_notifier.dart';

extension RummyNotifierMultiplayer on RummyNotifier {
  // ── Host startup ────────────────────────────────────────────────────────────

  void startMultiplayerHost({
    required RummyServer server,
    required RummyClient client,
    required List<({int id, String name})> players,
  }) {
    _cancelBotTimer();
    _server = server;
    _client = client;
    _localPlayerId = 0;

    server.onMessage = _handleHostMessage;
    server.onClientDisconnected = _onClientDisconnected;

    final deck = shuffle(generateDeck());
    final dealt = dealHands(deck, players.length, kRummyHandSize);
    var remaining = dealt.remaining;
    final firstDiscardIdx = remaining.indexWhere((c) => !c.isJoker);
    final firstDiscard = remaining.removeAt(firstDiscardIdx == -1 ? 0 : firstDiscardIdx);

    final rummyPlayers = players.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      return RummyPlayer(
        id: p.id,
        name: p.name,
        isHuman: true,
        hand: dealt.hands[i],
        melds: const [],
        score: 0,
        isEliminated: false,
        isConnected: true,
      );
    }).toList();

    state = RummyGameState(
      players: rummyPlayers,
      drawPile: remaining,
      discardPile: [firstDiscard],
      currentPlayerIndex: 0,
      phase: RummyPhase.playing,
      turnPhase: TurnPhase.draw,
      roundNumber: 1,
      statusMessage: 'Draw a card to begin.',
      meldMinimum: 71,
      turnMeldPoints: 0,
      turnMeldCount: 0,
      isMultiplayer: true,
      localPlayerId: 0,
    );

    _broadcastStateToAll();
  }

  // ── Guest startup ───────────────────────────────────────────────────────────

  void connectAsGuest({
    required RummyClient client,
    required int localPlayerId,
  }) {
    _cancelBotTimer();
    _client = client;
    _localPlayerId = localPlayerId;

    client.onMessage = _handleGuestMessage;
    client.onDisconnected = () {
      state = state.copyWith(statusMessage: 'Disconnected from host.');
    };
  }

  // ── Host message handler ────────────────────────────────────────────────────

  void _handleHostMessage(RummyMessage msg, int fromPlayerId) {
    // Verify the sender is the current player before acting on game actions.
    final isCurrentPlayer = fromPlayerId == state.currentPlayerIndex;

    switch (msg.type) {
      case RummyMessageType.drawDeck:
        if (!isCurrentPlayer) {
          _server!.sendTo(fromPlayerId, RummyMessage.actionError('Not your turn.').encode());
          return;
        }
        drawFromDeck();
      case RummyMessageType.drawDiscard:
        if (!isCurrentPlayer) {
          _server!.sendTo(fromPlayerId, RummyMessage.actionError('Not your turn.').encode());
          return;
        }
        drawFromDiscard();
      case RummyMessageType.layMeld:
        if (!isCurrentPlayer) {
          _server!.sendTo(fromPlayerId, RummyMessage.actionError('Not your turn.').encode());
          return;
        }
        final ids = (msg.payload['cardIds'] as List).cast<String>();
        _selectCardsAndLayMeld(fromPlayerId, ids);
      case RummyMessageType.addToMeld:
        if (!isCurrentPlayer) {
          _server!.sendTo(fromPlayerId, RummyMessage.actionError('Not your turn.').encode());
          return;
        }
        final ids = (msg.payload['cardIds'] as List).cast<String>();
        final meldIdx = msg.payload['meldIdx'] as int;
        _selectCardsAndAddToMeld(fromPlayerId, ids, meldIdx);
      case RummyMessageType.discard:
        if (!isCurrentPlayer) {
          _server!.sendTo(fromPlayerId, RummyMessage.actionError('Not your turn.').encode());
          return;
        }
        _discardById(fromPlayerId, msg.payload['cardId'] as String);
      case RummyMessageType.declare:
        if (!isCurrentPlayer) {
          _server!.sendTo(fromPlayerId, RummyMessage.actionError('Not your turn.').encode());
          return;
        }
        declare();
      case RummyMessageType.sortHand:
        final mode = HandSortMode.values.byName(msg.payload['mode'] as String);
        _sortHandForPlayer(fromPlayerId, mode);
      case RummyMessageType.reorderHand:
        final oldIdx = msg.payload['oldIndex'] as int;
        final newIdx = msg.payload['newIndex'] as int;
        _reorderHandForPlayer(fromPlayerId, oldIdx, newIdx);
      default:
        break;
    }
  }

  // ── Guest message handler ───────────────────────────────────────────────────

  void _handleGuestMessage(RummyMessage msg) {
    switch (msg.type) {
      case RummyMessageType.stateUpdate:
        final json = msg.payload['state'] as Map<String, dynamic>;
        state = RummyGameState.fromMultiplayerJson(json, _localPlayerId!);
      case RummyMessageType.actionError:
        state = state.copyWith(statusMessage: msg.payload['message'] as String?);
      default:
        break;
    }
  }

  // ── Broadcast ───────────────────────────────────────────────────────────────

  void _broadcastStateToAll() {
    if (_server == null) {
      return;
    }
    for (var i = 0; i < state.players.length; i++) {
      if (!state.players[i].isConnected) {
        continue;
      }
      final sanitized = state.toSanitizedJson(i);
      _server!.sendTo(i, RummyMessage.stateUpdate(sanitized).encode());
    }
  }

  // ── Disconnect ──────────────────────────────────────────────────────────────

  void _onClientDisconnected(int playerId) {
    if (playerId < 0 || playerId >= state.players.length) {
      return;
    }
    final updated = state.players.map((p) {
      if (p.id != playerId) {
        return p;
      }
      return p.copyWith(isConnected: false, isEliminated: true);
    }).toList();
    state = state.copyWith(
      players: updated,
      statusMessage: '${state.players[playerId].name} disconnected.',
    );
    _broadcastStateToAll();
  }

  // ── Private helpers for host-side action dispatch ──────────────────────────

  void _selectCardsAndLayMeld(int playerIdx, List<String> cardIds) {
    state = state.copyWith(selectedCardIds: cardIds);
    final err = laySelectedMeld();
    if (err != null && _server != null) {
      _server!.sendTo(playerIdx, RummyMessage.actionError(err).encode());
    }
  }

  void _selectCardsAndAddToMeld(int playerIdx, List<String> cardIds, int meldIdx) {
    state = state.copyWith(selectedCardIds: cardIds);
    final err = addSelectedCardsToMeld(meldIdx);
    if (err != null && _server != null) {
      _server!.sendTo(playerIdx, RummyMessage.actionError(err).encode());
    }
  }

  void _discardById(int playerIdx, String cardId) {
    final player = state.players[playerIdx];
    final card = player.hand.where((c) => c.id == cardId).firstOrNull;
    if (card == null) {
      _server?.sendTo(playerIdx, RummyMessage.actionError('Card not found in hand.').encode());
      return;
    }
    discard(card);
  }

  void _sortHandForPlayer(int playerIdx, HandSortMode mode) {
    if (playerIdx < 0 || playerIdx >= state.players.length) {
      return;
    }
    final player = state.players[playerIdx];
    final hand = List<PlayingCard>.from(player.hand);

    switch (mode) {
      case HandSortMode.bySuit:
        hand.sort((a, b) {
          final suitCmp = a.suit.compareTo(b.suit);
          return suitCmp != 0 ? suitCmp : a.rank.compareTo(b.rank);
        });
      case HandSortMode.byRank:
        hand.sort((a, b) {
          final rankCmp = a.rank.compareTo(b.rank);
          return rankCmp != 0 ? rankCmp : a.suit.compareTo(b.suit);
        });
      case HandSortMode.byColor:
        hand.sort((a, b) {
          final aRed = a.isRed ? 0 : 1;
          final bRed = b.isRed ? 0 : 1;
          final colorCmp = aRed.compareTo(bRed);
          if (colorCmp != 0) {
            return colorCmp;
          }
          final suitCmp = a.suit.compareTo(b.suit);
          return suitCmp != 0 ? suitCmp : a.rank.compareTo(b.rank);
        });
      case HandSortMode.none:
        return;
    }

    final players = List<RummyPlayer>.from(state.players);
    players[playerIdx] = player.copyWith(hand: hand);
    state = state.copyWith(players: players);
    _broadcastStateToAll();
  }

  void _reorderHandForPlayer(int playerIdx, int oldIndex, int newIndex) {
    if (playerIdx < 0 || playerIdx >= state.players.length) {
      return;
    }
    final player = state.players[playerIdx];
    final hand = List<PlayingCard>.from(player.hand);
    if (oldIndex < 0 || oldIndex >= hand.length || newIndex < 0 || newIndex >= hand.length) {
      return;
    }
    final card = hand.removeAt(oldIndex);
    hand.insert(newIndex, card);
    final players = List<RummyPlayer>.from(state.players);
    players[playerIdx] = player.copyWith(hand: hand);
    state = state.copyWith(players: players);
    _broadcastStateToAll();
  }
}
