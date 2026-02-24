import 'package:flutter/foundation.dart';
import 'playing_card.dart';
import 'rummy_player.dart';

enum RummyPhase { idle, dealing, playing, declaring, roundEnd, gameOver }

enum TurnPhase { draw, meld, discard }

enum AiDifficulty { easy, medium, hard }

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

  PlayingCard? get topDiscard =>
      discardPile.isEmpty ? null : discardPile.last;

  RummyPlayer get currentPlayer => players[currentPlayerIndex];

  bool get isHumanTurn => currentPlayer.isHuman;

  int get activePlayers =>
      players.where((p) => !p.isEliminated).length;

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
    );
  }

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
      );
}

// Sentinel for nullable copyWith fields.
const _sentinel = Object();
