/// Daily challenge model for gamification features.
library;

/// Type of daily challenge.
enum DailyChallengeType { score, speed, streak, perfect, playCount }

/// A single daily challenge that expires at midnight.
class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.gameType,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.rewardXP,
    required this.expiresAt,
    this.isCompleted = false,
    this.progress = 0,
  });

  final String id;
  final String gameType;
  final String title;
  final String description;
  final DailyChallengeType type;
  final int targetValue;
  final int rewardXP;
  final DateTime expiresAt;
  final bool isCompleted;
  final int progress;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  double get progressPercent =>
      targetValue > 0 ? (progress / targetValue).clamp(0.0, 1.0) : 0.0;

  DailyChallenge copyWith({bool? isCompleted, int? progress}) {
    return DailyChallenge(
      id: id,
      gameType: gameType,
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      rewardXP: rewardXP,
      expiresAt: expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameType': gameType,
    'title': title,
    'description': description,
    'type': type.name,
    'targetValue': targetValue,
    'rewardXP': rewardXP,
    'expiresAt': expiresAt.toIso8601String(),
    'isCompleted': isCompleted,
    'progress': progress,
  };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      gameType: json['gameType'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: DailyChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DailyChallengeType.score,
      ),
      targetValue: json['targetValue'] as int,
      rewardXP: json['rewardXP'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      progress: json['progress'] as int? ?? 0,
    );
  }
}
