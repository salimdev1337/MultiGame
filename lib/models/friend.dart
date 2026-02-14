/// Friend and friend-request models for social features.
library;

enum FriendRequestStatus { pending, accepted, rejected }

class FriendStats {
  const FriendStats({
    required this.totalScore,
    required this.gamesPlayed,
    required this.winRate,
  });

  final int totalScore;
  final int gamesPlayed;
  final double winRate;

  static const FriendStats empty = FriendStats(
    totalScore: 0,
    gamesPlayed: 0,
    winRate: 0,
  );
}

class Friend {
  const Friend({
    required this.userId,
    required this.displayName,
    this.avatarId,
    required this.isOnline,
    this.lastSeen,
    this.stats = FriendStats.empty,
  });

  final String userId;
  final String displayName;
  final String? avatarId;
  final bool isOnline;
  final DateTime? lastSeen;
  final FriendStats stats;

  String get lastSeenLabel {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class FriendRequest {
  const FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.status,
    required this.createdAt,
  });

  final String requestId;
  final String fromUserId;
  final String fromDisplayName;
  final FriendRequestStatus status;
  final DateTime createdAt;
}
