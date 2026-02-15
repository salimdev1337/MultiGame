import 'package:flutter/foundation.dart';

@immutable
class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.value,
    this.isFlipped = false,
    this.isMatched = false,
  });

  /// Unique position index (stable identity key across shuffles).
  final int id;

  /// Pair identifier — two cards share the same value.
  final int value;

  final bool isFlipped;
  final bool isMatched;

  MemoryCard copyWith({
    bool? isFlipped,
    bool? isMatched,
  }) {
    return MemoryCard(
      id: id,
      value: value,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryCard &&
          id == other.id &&
          value == other.value &&
          isFlipped == other.isFlipped &&
          isMatched == other.isMatched;

  @override
  int get hashCode => Object.hash(id, value, isFlipped, isMatched);
}
