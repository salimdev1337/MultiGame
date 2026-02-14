/// Extended streak profile for gamification / season-pass features.
///
/// The core streak tracking (day counting, storage) lives in
/// [StreakService] from `lib/services/data/streak_service.dart`.
/// This model layers on XP, level, and milestone data.
library;

/// A milestone that unlocks when [currentStreak] reaches [days].
class StreakMilestone {
  const StreakMilestone({
    required this.days,
    required this.title,
    required this.reward,
    required this.isUnlocked,
  });

  final int days;
  final String title;
  final String reward;
  final bool isUnlocked;

  static const List<StreakMilestone> all = [
    StreakMilestone(
      days: 3,
      title: 'Warming Up',
      reward: '+50 XP',
      isUnlocked: false,
    ),
    StreakMilestone(
      days: 7,
      title: 'On Fire',
      reward: '+100 XP',
      isUnlocked: false,
    ),
    StreakMilestone(
      days: 14,
      title: 'Unstoppable',
      reward: '+200 XP',
      isUnlocked: false,
    ),
    StreakMilestone(
      days: 30,
      title: 'Legendary',
      reward: '+500 XP',
      isUnlocked: false,
    ),
    StreakMilestone(
      days: 60,
      title: 'Myth',
      reward: '+1000 XP',
      isUnlocked: false,
    ),
    StreakMilestone(
      days: 90,
      title: 'God Mode',
      reward: '+2000 XP',
      isUnlocked: false,
    ),
  ];
}

/// Extended streak profile with XP and gamification data.
class StreakProfile {
  const StreakProfile({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastPlayDate,
    required this.streakDates,
    required this.totalXP,
    required this.level,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPlayDate;
  final List<DateTime> streakDates;
  final int totalXP;
  final int level;

  static const StreakProfile empty = StreakProfile(
    currentStreak: 0,
    longestStreak: 0,
    lastPlayDate: null,
    streakDates: [],
    totalXP: 0,
    level: 1,
  );

  List<StreakMilestone> get milestones => StreakMilestone.all
      .map(
        (m) => StreakMilestone(
          days: m.days,
          title: m.title,
          reward: m.reward,
          isUnlocked: currentStreak >= m.days,
        ),
      )
      .toList();

  StreakMilestone? get nextMilestone {
    for (final m in StreakMilestone.all) {
      if (currentStreak < m.days) {
        return StreakMilestone(
          days: m.days,
          title: m.title,
          reward: m.reward,
          isUnlocked: false,
        );
      }
    }
    return null;
  }

  bool get isStreakAlive {
    if (lastPlayDate == null) return false;
    return DateTime.now().difference(lastPlayDate!).inDays <= 1;
  }

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastPlayDate': lastPlayDate?.toIso8601String(),
    'streakDates': streakDates.map((d) => d.toIso8601String()).toList(),
    'totalXP': totalXP,
    'level': level,
  };

  factory StreakProfile.fromJson(Map<String, dynamic> json) => StreakProfile(
    currentStreak: (json['currentStreak'] as int?) ?? 0,
    longestStreak: (json['longestStreak'] as int?) ?? 0,
    lastPlayDate: json['lastPlayDate'] != null
        ? DateTime.parse(json['lastPlayDate'] as String)
        : null,
    streakDates: (json['streakDates'] as List<dynamic>? ?? [])
        .map((d) => DateTime.parse(d as String))
        .toList(),
    totalXP: (json['totalXP'] as int?) ?? 0,
    level: (json['level'] as int?) ?? 1,
  );
}
