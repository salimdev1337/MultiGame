import 'package:flutter/foundation.dart';
import 'playing_card.dart';
import 'rummy_player.dart';

enum RummyPhase { idle, dealing, playing, declaring, roundEnd, gameOver }

enum TurnPhase { draw, meld, discard }

enum AiDifficulty { easy, medium, hard }

enum HandSortMode { none, bySuit, byRank, byColor }

enum RummyGameMode { normal, forced }

const int kRummyEliminationScore = 1200;
const int kRummyHandSize = 14;
const int kRummyPlayerCount = 4;
const int kRummyMinMeldsToDeclare = 2;

@immutable
class RummyGameState {
  const RummyGameState({
    this.players = const [],
    this.drawPile = const [],
    this.discardPile = const [],
    this.currentPlayerIndex = 0,
    this.phase = RummyPhase.idle,
    this.turnPhase = TurnPhase.draw,
    this.lastDiscardByPlayer,
    this.lastDiscardedCard,
    this.roundNumber = 0,
    this.statusMessage,
    this.eliminatedPlayers = const [],
    this.difficulty = AiDifficulty.medium,
    this.drawnCardThisTurn,
    this.selectedCardIds = const [],
    this.handSortMode = HandSortMode.none,
    this.meldMinimum = 71,
    this.turnMeldPoints = 0,
    this.turnMeldCount = 0,
    this.completingMeldIds = const <String>{},
    this.drawnFromDiscard = false,
    this.preTurnMeldMinimum = 71,
    this.preTurnPlayerOpen = false,
    this.isMultiplayer = false,
    this.localPlayerId = 0,
    this.gameMode = RummyGameMode.normal,
  });

  final List<RummyPlayer> players;
  final List<PlayingCard> drawPile;
  final List<PlayingCard> discardPile;
  final int currentPlayerIndex;
  final RummyPhase phase;
  final TurnPhase turnPhase;

  /// Index of player who made the last discard (for +50 penalty tracking).
  final int? lastDiscardByPlayer;

  /// The card that was last discarded (for penalty check).
  final PlayingCard? lastDiscardedCard;

  final int roundNumber;
  final String? statusMessage;
  final List<int> eliminatedPlayers;
  final AiDifficulty difficulty;

  /// Card drawn this turn (null if not yet drawn).
  final PlayingCard? drawnCardThisTurn;

  /// IDs of cards the human has selected for meld placement.
  final List<String> selectedCardIds;

  /// Current hand sort mode (none = manual order).
  final HandSortMode handSortMode;

  /// Points required for a player's first meld(s) in this round.
  final int meldMinimum;

  /// Running total of meld point value laid by the current player this turn.
  final int turnMeldPoints;

  /// Number of melds laid by the current player this turn (for revert).
  final int turnMeldCount;

  /// First-card IDs of melds currently in their flash-then-remove window.
  final Set<String> completingMeldIds;

  /// True when the current human draw came from the discard pile (enables undo).
  final bool drawnFromDiscard;

  /// Snapshot of meldMinimum at the start of this human turn draw (for undo-open revert).
  final int preTurnMeldMinimum;

  /// Snapshot of human player's isOpen at the start of this turn draw (for undo).
  final bool preTurnPlayerOpen;

  /// True when the game is running over a local WiFi connection.
  final bool isMultiplayer;

  /// The player index on this device (0 = host, 1+ = guest).
  final int localPlayerId;

  /// Solo game mode: normal (free opening) or forced (must open with discard card).
  final RummyGameMode gameMode;

  PlayingCard? get topDiscard =>
      discardPile.isEmpty ? null : discardPile.last;

  RummyPlayer get currentPlayer => players[currentPlayerIndex];

  bool get isHumanTurn => currentPlayer.isHuman;

  int get activePlayers =>
      players.where((p) => !p.isEliminated).length;

  /// True in forced mode when the human's drawn-from-discard card has already
  /// been used in a meld this turn. Unlocks add-to-meld before the opening
  /// minimum is reached.
  bool get drawnCardMeldedThisTurn {
    if (!isHumanTurn || gameMode != RummyGameMode.forced) return false;
    if (!drawnFromDiscard || drawnCardThisTurn == null) return false;
    return !currentPlayer.hand.any((c) => c.id == drawnCardThisTurn!.id);
  }

  /// True when the human can undo their last action this turn.
  bool get canUndo =>
      !isMultiplayer &&
      isHumanTurn &&
      turnPhase == TurnPhase.meld &&
      (turnMeldCount > 0 || drawnFromDiscard);

  RummyGameState copyWith({
    List<RummyPlayer>? players,
    List<PlayingCard>? drawPile,
    List<PlayingCard>? discardPile,
    int? currentPlayerIndex,
    RummyPhase? phase,
    TurnPhase? turnPhase,
    Object? lastDiscardByPlayer = _sentinel,
    Object? lastDiscardedCard = _sentinel,
    int? roundNumber,
    Object? statusMessage = _sentinel,
    List<int>? eliminatedPlayers,
    AiDifficulty? difficulty,
    Object? drawnCardThisTurn = _sentinel,
    List<String>? selectedCardIds,
    HandSortMode? handSortMode,
    int? meldMinimum,
    int? turnMeldPoints,
    int? turnMeldCount,
    Set<String>? completingMeldIds,
    bool? drawnFromDiscard,
    int? preTurnMeldMinimum,
    bool? preTurnPlayerOpen,
    bool? isMultiplayer,
    int? localPlayerId,
    RummyGameMode? gameMode,
  }) {
    return RummyGameState(
      players: players ?? this.players,
      drawPile: drawPile ?? this.drawPile,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      turnPhase: turnPhase ?? this.turnPhase,
      lastDiscardByPlayer: lastDiscardByPlayer == _sentinel
          ? this.lastDiscardByPlayer
          : lastDiscardByPlayer as int?,
      lastDiscardedCard: lastDiscardedCard == _sentinel
          ? this.lastDiscardedCard
          : lastDiscardedCard as PlayingCard?,
      roundNumber: roundNumber ?? this.roundNumber,
      statusMessage: statusMessage == _sentinel
          ? this.statusMessage
          : statusMessage as String?,
      eliminatedPlayers: eliminatedPlayers ?? this.eliminatedPlayers,
      difficulty: difficulty ?? this.difficulty,
      drawnCardThisTurn: drawnCardThisTurn == _sentinel
          ? this.drawnCardThisTurn
          : drawnCardThisTurn as PlayingCard?,
      selectedCardIds: selectedCardIds ?? this.selectedCardIds,
      handSortMode: handSortMode ?? this.handSortMode,
      meldMinimum: meldMinimum ?? this.meldMinimum,
      turnMeldPoints: turnMeldPoints ?? this.turnMeldPoints,
      turnMeldCount: turnMeldCount ?? this.turnMeldCount,
      completingMeldIds: completingMeldIds ?? this.completingMeldIds,
      drawnFromDiscard: drawnFromDiscard ?? this.drawnFromDiscard,
      preTurnMeldMinimum: preTurnMeldMinimum ?? this.preTurnMeldMinimum,
      preTurnPlayerOpen: preTurnPlayerOpen ?? this.preTurnPlayerOpen,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      localPlayerId: localPlayerId ?? this.localPlayerId,
      gameMode: gameMode ?? this.gameMode,
    );
  }

  /// Serializes state for network broadcast.
  /// The [viewingPlayerId] receives their own hand face-up;
  /// all other players' hands are stripped (empty list) with a [handCount] field.
  Map<String, dynamic> toSanitizedJson(int viewingPlayerId) {
    final sanitizedPlayers = players.map((p) {
      final json = p.toJson();
      if (p.id != viewingPlayerId) {
        json['hand'] = <Map<String, dynamic>>[];
        json['handCount'] = p.hand.length;
      }
      return json;
    }).toList();

    return {
      'players': sanitizedPlayers,
      'drawPile': <Map<String, dynamic>>[],
      'drawPileCount': drawPile.length,
      'discardPile': discardPile.map((c) => c.toJson()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'phase': phase.name,
      'turnPhase': turnPhase.name,
      'lastDiscardByPlayer': lastDiscardByPlayer,
      'lastDiscardedCard': lastDiscardedCard?.toJson(),
      'roundNumber': roundNumber,
      'statusMessage': statusMessage,
      'eliminatedPlayers': eliminatedPlayers,
      'difficulty': difficulty.name,
      'drawnCardThisTurn': viewingPlayerId == currentPlayerIndex
          ? drawnCardThisTurn?.toJson()
          : null,
      'selectedCardIds': <String>[],
      'handSortMode': handSortMode.name,
      'meldMinimum': meldMinimum,
      'turnMeldPoints': turnMeldPoints,
      'turnMeldCount': turnMeldCount,
      'drawnFromDiscard': drawnFromDiscard,
      'preTurnMeldMinimum': preTurnMeldMinimum,
      'preTurnPlayerOpen': preTurnPlayerOpen,
      'isMultiplayer': true,
      'localPlayerId': viewingPlayerId,
      'gameMode': gameMode.name,
    };
  }

  static RummyGameState fromMultiplayerJson(
    Map<String, dynamic> json,
    int localPlayerId,
  ) {
    final players = (json['players'] as List).map((p) {
      final map = Map<String, dynamic>.from(p as Map);
      if (map['hand'] == null || (map['hand'] as List).isEmpty) {
        final count = (map['handCount'] as int?) ?? 0;
        map['hand'] = List.generate(count, (_) => _placeholderCardJson());
        map.remove('handCount');
      }
      return RummyPlayer.fromJson(map);
    }).toList();

    return RummyGameState(
      players: players,
      drawPile: const [],
      discardPile: (json['discardPile'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      phase: RummyPhase.values.byName(json['phase'] as String),
      turnPhase: TurnPhase.values.byName(json['turnPhase'] as String),
      lastDiscardByPlayer: json['lastDiscardByPlayer'] as int?,
      lastDiscardedCard: json['lastDiscardedCard'] == null
          ? null
          : PlayingCard.fromJson(json['lastDiscardedCard'] as Map<String, dynamic>),
      roundNumber: json['roundNumber'] as int,
      statusMessage: json['statusMessage'] as String?,
      eliminatedPlayers: (json['eliminatedPlayers'] as List).cast<int>(),
      difficulty: AiDifficulty.values.byName(json['difficulty'] as String),
      drawnCardThisTurn: json['drawnCardThisTurn'] == null
          ? null
          : PlayingCard.fromJson(json['drawnCardThisTurn'] as Map<String, dynamic>),
      selectedCardIds: (json['selectedCardIds'] as List?)?.cast<String>() ?? const [],
      handSortMode: json['handSortMode'] != null
          ? HandSortMode.values.byName(json['handSortMode'] as String)
          : HandSortMode.none,
      meldMinimum: (json['meldMinimum'] as int?) ?? 71,
      turnMeldPoints: (json['turnMeldPoints'] as int?) ?? 0,
      turnMeldCount: (json['turnMeldCount'] as int?) ?? 0,
      drawnFromDiscard: (json['drawnFromDiscard'] as bool?) ?? false,
      preTurnMeldMinimum: (json['preTurnMeldMinimum'] as int?) ?? 71,
      preTurnPlayerOpen: (json['preTurnPlayerOpen'] as bool?) ?? false,
      isMultiplayer: true,
      localPlayerId: localPlayerId,
      gameMode: RummyGameMode.values.byName(
          (json['gameMode'] as String?) ?? 'normal'),
    );
  }

  /// Generates a placeholder card JSON for opponents' hidden hands.
  /// Uses suit=-1 (joker slot) as a sentinel; the card painter shows the back.
  static Map<String, dynamic> _placeholderCardJson() => {
        'id': 'hidden_${DateTime.now().microsecondsSinceEpoch}',
        'suit': -2,
        'rank': -1,
        'isJoker': false,
      };

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'phase': phase.name,
        'turnPhase': turnPhase.name,
        'lastDiscardByPlayer': lastDiscardByPlayer,
        'lastDiscardedCard': lastDiscardedCard?.toJson(),
        'roundNumber': roundNumber,
        'statusMessage': statusMessage,
        'eliminatedPlayers': eliminatedPlayers,
        'difficulty': difficulty.name,
        'drawnCardThisTurn': drawnCardThisTurn?.toJson(),
        'selectedCardIds': selectedCardIds,
        'handSortMode': handSortMode.name,
        'meldMinimum': meldMinimum,
        'turnMeldPoints': turnMeldPoints,
        'turnMeldCount': turnMeldCount,
        'drawnFromDiscard': drawnFromDiscard,
        'preTurnMeldMinimum': preTurnMeldMinimum,
        'preTurnPlayerOpen': preTurnPlayerOpen,
        'isMultiplayer': isMultiplayer,
        'localPlayerId': localPlayerId,
        'gameMode': gameMode.name,
      };

  factory RummyGameState.fromJson(Map<String, dynamic> json) => RummyGameState(
        players: (json['players'] as List)
            .map((p) => RummyPlayer.fromJson(p as Map<String, dynamic>))
            .toList(),
        drawPile: (json['drawPile'] as List)
            .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        discardPile: (json['discardPile'] as List)
            .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        currentPlayerIndex: json['currentPlayerIndex'] as int,
        phase: RummyPhase.values.byName(json['phase'] as String),
        turnPhase: TurnPhase.values.byName(json['turnPhase'] as String),
        lastDiscardByPlayer: json['lastDiscardByPlayer'] as int?,
        lastDiscardedCard: json['lastDiscardedCard'] == null
            ? null
            : PlayingCard.fromJson(
                json['lastDiscardedCard'] as Map<String, dynamic>),
        roundNumber: json['roundNumber'] as int,
        statusMessage: json['statusMessage'] as String?,
        eliminatedPlayers:
            (json['eliminatedPlayers'] as List).cast<int>(),
        difficulty:
            AiDifficulty.values.byName(json['difficulty'] as String),
        drawnCardThisTurn: json['drawnCardThisTurn'] == null
            ? null
            : PlayingCard.fromJson(
                json['drawnCardThisTurn'] as Map<String, dynamic>),
        selectedCardIds:
            (json['selectedCardIds'] as List).cast<String>(),
        handSortMode: json['handSortMode'] != null
            ? HandSortMode.values.byName(json['handSortMode'] as String)
            : HandSortMode.none,
        meldMinimum: (json['meldMinimum'] as int?) ?? 71,
        turnMeldPoints: (json['turnMeldPoints'] as int?) ?? 0,
        turnMeldCount: (json['turnMeldCount'] as int?) ?? 0,
        drawnFromDiscard: (json['drawnFromDiscard'] as bool?) ?? false,
        preTurnMeldMinimum: (json['preTurnMeldMinimum'] as int?) ?? 71,
        preTurnPlayerOpen: (json['preTurnPlayerOpen'] as bool?) ?? false,
        isMultiplayer: (json['isMultiplayer'] as bool?) ?? false,
        localPlayerId: (json['localPlayerId'] as int?) ?? 0,
        gameMode: RummyGameMode.values.byName(
            (json['gameMode'] as String?) ?? 'normal'),
      );
}

// Sentinel for nullable copyWith fields.
const _sentinel = Object();
