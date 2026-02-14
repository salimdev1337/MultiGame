/// The four collectible abilities available in race mode
enum AbilityType {
  /// ⚡ +50% speed for 5 seconds
  speedBoost,

  /// 🛡 Negate the next obstacle hit
  shield,

  /// 🐢 Apply a 30% speed penalty for 4 seconds
  /// (Phase 2: applies to self; Phase 3: applies to opponents ahead)
  slowField,

  /// 🧱 Force-spawn 3 extra obstacles ahead of the current leader
  obstacleRain,
}

extension AbilityTypeExt on AbilityType {
  String get label {
    switch (this) {
      case AbilityType.speedBoost:
        return 'BOOST';
      case AbilityType.shield:
        return 'SHIELD';
      case AbilityType.slowField:
        return 'SLOW';
      case AbilityType.obstacleRain:
        return 'RAIN';
    }
  }

  String get emoji {
    switch (this) {
      case AbilityType.speedBoost:
        return '⚡';
      case AbilityType.shield:
        return '🛡';
      case AbilityType.slowField:
        return '🐢';
      case AbilityType.obstacleRain:
        return '🧱';
    }
  }

  /// ARGB hex color for this ability
  int get colorValue {
    switch (this) {
      case AbilityType.speedBoost:
        return 0xFFffd700; // Gold
      case AbilityType.shield:
        return 0xFF00d4ff; // Cyan
      case AbilityType.slowField:
        return 0xFF7c4dff; // Purple
      case AbilityType.obstacleRain:
        return 0xFFff6b35; // Orange
    }
  }
}
