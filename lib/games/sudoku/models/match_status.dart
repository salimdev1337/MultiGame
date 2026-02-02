/// Status of an online 1v1 match
enum MatchStatus {
  /// Waiting for second player to join
  waiting,

  /// Both players joined, game in progress
  playing,

  /// Match completed (someone won or timeout)
  completed,

  /// Match cancelled (player left during waiting/playing)
  cancelled,
}

/// Extension to convert MatchStatus to/from string for Firestore
extension MatchStatusExtension on MatchStatus {
  /// Convert enum to string for storage
  String toJson() => name;

  /// Create enum from string
  static MatchStatus fromJson(String value) {
    return MatchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchStatus.cancelled,
    );
  }
}
