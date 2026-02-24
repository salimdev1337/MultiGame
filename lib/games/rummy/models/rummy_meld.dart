import 'package:flutter/foundation.dart';
import 'playing_card.dart';

enum MeldType { set, run }

@immutable
class RummyMeld {
  const RummyMeld({required this.type, required this.cards});

  final MeldType type;
  final List<PlayingCard> cards;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory RummyMeld.fromJson(Map<String, dynamic> json) => RummyMeld(
        type: MeldType.values.byName(json['type'] as String),
        cards: (json['cards'] as List)
            .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
