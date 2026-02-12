/// Head-to-head challenge model for social features.
library;

enum ChallengeStatus { pending, active, completed, expired }

class Challenge {
  const Challenge({
    required this.id,
    required this.challengerId,
    required this.challengerName,
    required this.challengedId,
    required this.challengedName,
    required this.gameType,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.challengerScore,
    this.challengedScore,
    this.winnerId,
  });

  final String id;
  final String challengerId;
  final String challengerName;
  final String challengedId;
  final String challengedName;
  final String gameType;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int? challengerScore;
  final int? challengedScore;
  final String? winnerId;

  bool get isExpired =>
      status == ChallengeStatus.expired ||
      (status != ChallengeStatus.completed &&
          DateTime.now().isAfter(expiresAt));

  String? winnerName(String currentUserId) {
    if (winnerId == null) return null;
    return winnerId == challengerId ? challengerName : challengedName;
  }
}
