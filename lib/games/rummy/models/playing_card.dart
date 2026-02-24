import 'package:flutter/foundation.dart';

/// Suit constants
const int suitSpades = 0;
const int suitHearts = 1;
const int suitDiamonds = 2;
const int suitClubs = 3;
const int suitJoker = -1;

/// Rank constants
const int rankJoker = 0;
const int rankAce = 1;
const int rankJack = 11;
const int rankQueen = 12;
const int rankKing = 13;

@immutable
class PlayingCard {
  const PlayingCard({
    required this.id,
    required this.suit,
    required this.rank,
    required this.isJoker,
  });

  /// Unique identifier per card instance (e.g. "d1_1_1" = deck1, suit1, rank1)
  final String id;

  /// 0=spades 1=hearts 2=diamonds 3=clubs -1=joker
  final int suit;

  /// 1=A 2-10=pip 11=J 12=Q 13=K 0=joker
  final int rank;

  final bool isJoker;

  bool get isRed => suit == suitHearts || suit == suitDiamonds;

  String get suitSymbol {
    switch (suit) {
      case suitSpades:
        return '♠';
      case suitHearts:
        return '♥';
      case suitDiamonds:
        return '♦';
      case suitClubs:
        return '♣';
      default:
        return '★';
    }
  }

  String get rankLabel {
    if (isJoker) {
      return 'JKR';
    }
    switch (rank) {
      case rankAce:
        return 'A';
      case rankJack:
        return 'J';
      case rankQueen:
        return 'Q';
      case rankKing:
        return 'K';
      default:
        return '$rank';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'suit': suit,
        'rank': rank,
        'isJoker': isJoker,
      };

  factory PlayingCard.fromJson(Map<String, dynamic> json) => PlayingCard(
        id: json['id'] as String,
        suit: json['suit'] as int,
        rank: json['rank'] as int,
        isJoker: json['isJoker'] as bool,
      );

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => isJoker ? 'Joker($id)' : '$rankLabel$suitSymbol';
}
