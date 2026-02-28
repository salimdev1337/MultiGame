import 'package:flutter/foundation.dart';
import 'playing_card.dart';
import 'rummy_meld.dart';

@immutable
class RummyPlayer {
  const RummyPlayer({
    required this.id,
    required this.name,
    required this.isHuman,
    required this.hand,
    required this.melds,
    required this.score,
    required this.isEliminated,
    this.isOpen = false,
  });

  final int id;
  final String name;
  final bool isHuman;
  final List<PlayingCard> hand;
  final List<RummyMeld> melds;
  final int score;
  final bool isEliminated;

  /// True once the player has met the opening minimum for this round.
  final bool isOpen;

  RummyPlayer copyWith({
    List<PlayingCard>? hand,
    List<RummyMeld>? melds,
    int? score,
    bool? isEliminated,
    bool? isOpen,
  }) {
    return RummyPlayer(
      id: id,
      name: name,
      isHuman: isHuman,
      hand: hand ?? this.hand,
      melds: melds ?? this.melds,
      score: score ?? this.score,
      isEliminated: isEliminated ?? this.isEliminated,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isHuman': isHuman,
        'hand': hand.map((c) => c.toJson()).toList(),
        'melds': melds.map((m) => m.toJson()).toList(),
        'score': score,
        'isEliminated': isEliminated,
        'isOpen': isOpen,
      };

  factory RummyPlayer.fromJson(Map<String, dynamic> json) => RummyPlayer(
        id: json['id'] as int,
        name: json['name'] as String,
        isHuman: json['isHuman'] as bool,
        hand: (json['hand'] as List)
            .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        melds: (json['melds'] as List)
            .map((m) => RummyMeld.fromJson(m as Map<String, dynamic>))
            .toList(),
        score: json['score'] as int,
        isEliminated: json['isEliminated'] as bool,
        isOpen: (json['isOpen'] as bool?) ?? false,
      );
}
