import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/skill_tree.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';

void main() {
  const base = PlayerStats();

  group('SkillTree.pickOptions', () {
    test('returns 3 nodes from the pool', () {
      final options = SkillTree.pickOptions([], Random(1));
      expect(options.length, 3);
    });

    test('excludes already-applied node IDs', () {
      final options = SkillTree.pickOptions(['max_hp', 'attack'], Random(1));
      final ids = options.map((n) => n.id).toList();
      expect(ids, isNot(contains('max_hp')));
      expect(ids, isNot(contains('attack')));
    });

    test('returns all remaining nodes when pool is small', () {
      final allIds = SkillNode.all.map((n) => n.id).toList();
      final applied = allIds.sublist(0, allIds.length - 3);
      final options = SkillTree.pickOptions(applied, Random(1));
      expect(options.length, 3);
    });

    test('returns fewer than 3 when fewer remain', () {
      final allIds = SkillNode.all.map((n) => n.id).toList();
      final applied = allIds.sublist(0, allIds.length - 2);
      final options = SkillTree.pickOptions(applied, Random(1));
      expect(options.length, 2);
    });
  });

  group('SkillTree.applyNode', () {
    test('max_hp adds 15 to maxHp and hp', () {
      final updated = SkillTree.applyNode(base, 'max_hp');
      expect(updated.maxHp, base.maxHp + 15);
      expect(updated.hp, base.hp + 15);
    });

    test('attack adds 5 to attack', () {
      final updated = SkillTree.applyNode(base, 'attack');
      expect(updated.attack, base.attack + 5);
    });

    test('stamina_pip clamps at 4', () {
      final stats = base.copyWith(maxStaminaPips: 4);
      final updated = SkillTree.applyNode(stats, 'stamina_pip');
      expect(updated.maxStaminaPips, 4);
    });

    test('stamina_pip adds 1 when below cap', () {
      final updated = SkillTree.applyNode(base, 'stamina_pip');
      expect(updated.maxStaminaPips, base.maxStaminaPips + 1);
    });

    test('stamina_regen halves regen interval', () {
      final updated = SkillTree.applyNode(base, 'stamina_regen');
      expect(
        updated.staminaRegenInterval,
        closeTo(base.staminaRegenInterval * 0.5, 0.001),
      );
    });

    test('combo_window adds 0.2 bonus', () {
      final updated = SkillTree.applyNode(base, 'combo_window');
      expect(updated.comboWindowBonus, closeTo(0.2, 0.001));
    });

    test('move_speed adds 20', () {
      final updated = SkillTree.applyNode(base, 'move_speed');
      expect(updated.speed, base.speed + 20);
    });

    test('iron_fist adds 1 hitstop frame', () {
      final updated = SkillTree.applyNode(base, 'iron_fist');
      expect(updated.hitstopFrames, base.hitstopFrames + 1);
    });

    test('rugged caps hazard resistance at 0.70', () {
      final capped = base.copyWith(hazardResistance: 0.50);
      final updated = SkillTree.applyNode(capped, 'rugged');
      expect(updated.hazardResistance, closeTo(0.70, 0.001));
    });

    test('unknown node id returns stats unchanged', () {
      final updated = SkillTree.applyNode(base, 'nonexistent_node');
      expect(updated.attack, base.attack);
      expect(updated.maxHp, base.maxHp);
    });
  });
}
