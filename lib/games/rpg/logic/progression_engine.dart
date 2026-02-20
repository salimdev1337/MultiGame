import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class BossReward {
  const BossReward({
    required this.hpGain,
    required this.attackGain,
    required this.newAbility,
    required this.message,
  });

  final int hpGain;
  final int attackGain;
  final AbilityType? newAbility;
  final String message;
}

class ProgressionEngine {
  const ProgressionEngine._();

  static const BossReward golemReward = BossReward(
    hpGain: 30,
    attackGain: 0,
    newAbility: AbilityType.fireball,
    message: '+30 Max HP  •  Fireball unlocked!',
  );

  static const BossReward wraithReward = BossReward(
    hpGain: 40,
    attackGain: 2,
    newAbility: AbilityType.timeSlow,
    message: '+40 Max HP  •  +2 Attack  •  Time Slow unlocked!',
  );

  static BossReward rewardForBoss(BossId id) {
    switch (id) {
      case BossId.golem:
        return golemReward;
      case BossId.wraith:
        return wraithReward;
    }
  }

  static PlayerStats applyReward(PlayerStats stats, BossId bossId) {
    final reward = rewardForBoss(bossId);
    final newMaxHp = stats.maxHp + reward.hpGain;
    final newHp = newMaxHp;
    final newAttack = stats.attack + reward.attackGain;
    final newAbilities = List<AbilityType>.from(stats.unlockedAbilities);
    if (reward.newAbility != null &&
        !newAbilities.contains(reward.newAbility)) {
      newAbilities.add(reward.newAbility!);
    }
    return stats.copyWith(
      hp: newHp,
      maxHp: newMaxHp,
      attack: newAttack,
      unlockedAbilities: newAbilities,
    );
  }
}
