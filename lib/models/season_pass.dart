/// Season pass model for gamification features.
library;

enum SeasonPassRewardType { avatar, theme, badge, title }

class SeasonPassReward {
  const SeasonPassReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.isUnlocked,
  });

  final String id;
  final String name;
  final String description;
  final SeasonPassRewardType type;
  final bool isUnlocked;
}

class SeasonPassTier {
  const SeasonPassTier({
    required this.tier,
    required this.requiredXP,
    required this.rewards,
    required this.isUnlocked,
  });

  final int tier;
  final int requiredXP;
  final List<SeasonPassReward> rewards;
  final bool isUnlocked;
}

class SeasonPass {
  const SeasonPass({
    required this.season,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.tiers,
    required this.currentTier,
    required this.currentXP,
  });

  final int season;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<SeasonPassTier> tiers;
  final int currentTier;
  final int currentXP;

  int get xpToNextTier {
    if (currentTier >= tiers.length) return 0;
    return tiers[currentTier].requiredXP - currentXP;
  }

  int get daysRemaining {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff.clamp(0, 999);
  }

  double get progressInCurrentTier {
    if (currentTier >= tiers.length) return 1.0;
    final tier = tiers[currentTier];
    final prevXP = currentTier > 0 ? tiers[currentTier - 1].requiredXP : 0;
    final range = tier.requiredXP - prevXP;
    if (range <= 0) return 1.0;
    return ((currentXP - prevXP) / range).clamp(0.0, 1.0);
  }
}
