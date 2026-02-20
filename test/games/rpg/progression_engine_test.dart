import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/progression_engine.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

void main() {
  group('ProgressionEngine', () {
    const base = PlayerStats();

    test('golem reward adds 30 maxHp and fireball', () {
      final after = ProgressionEngine.applyReward(base, BossId.golem);
      expect(after.maxHp, 130);
      expect(after.hp, 130);
      expect(after.unlockedAbilities.contains(AbilityType.fireball), true);
    });

    test('wraith reward adds 40 maxHp, +2 attack, and timeSlow', () {
      final after = ProgressionEngine.applyReward(base, BossId.wraith);
      expect(after.maxHp, 140);
      expect(after.hp, 140);
      expect(after.attack, 12);
      expect(after.unlockedAbilities.contains(AbilityType.timeSlow), true);
    });

    test('applying rewards sequentially accumulates correctly', () {
      var stats = base;
      stats = ProgressionEngine.applyReward(stats, BossId.golem);
      stats = ProgressionEngine.applyReward(stats, BossId.wraith);
      expect(stats.maxHp, 170);
      expect(stats.attack, 12);
      expect(stats.unlockedAbilities.length, 3);
    });

    test('duplicate ability not added twice', () {
      var stats = ProgressionEngine.applyReward(base, BossId.golem);
      stats = ProgressionEngine.applyReward(stats, BossId.golem);
      final fireballCount =
          stats.unlockedAbilities.where((a) => a == AbilityType.fireball).length;
      expect(fireballCount, 1);
    });

    test('rewardForBoss returns correct reward for each boss', () {
      final golem = ProgressionEngine.rewardForBoss(BossId.golem);
      final wraith = ProgressionEngine.rewardForBoss(BossId.wraith);
      expect(golem.hpGain, 30);
      expect(wraith.hpGain, 40);
      expect(golem.newAbility, AbilityType.fireball);
      expect(wraith.newAbility, AbilityType.timeSlow);
    });
  });
}
