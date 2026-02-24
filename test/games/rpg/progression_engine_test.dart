import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/progression_engine.dart';
import 'package:multigame/games/rpg/models/equipment.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

void main() {
  group('ProgressionEngine.equipmentForBoss', () {
    test('warden drops wardenSword', () {
      final drop = ProgressionEngine.equipmentForBoss(BossId.warden);
      expect(drop, isNotNull);
      expect(drop!.id, 'warden_sword');
      expect(drop.slot, EquipmentSlot.weapon);
      expect(drop.atkBonus, 8);
    });

    test('shaman drops shamanCloak', () {
      final drop = ProgressionEngine.equipmentForBoss(BossId.shaman);
      expect(drop, isNotNull);
      expect(drop!.id, 'shaman_cloak');
      expect(drop.slot, EquipmentSlot.armor);
      expect(drop.hpBonus, 25);
    });

    test('hollowKing drops hollowCrown', () {
      final drop = ProgressionEngine.equipmentForBoss(BossId.hollowKing);
      expect(drop, isNotNull);
      expect(drop!.id, 'hollow_crown');
      expect(drop.slot, EquipmentSlot.armor);
      expect(drop.ultimateStartCharge, 0.20);
    });

    test('shadowlord drops nothing (final boss)', () {
      final drop = ProgressionEngine.equipmentForBoss(BossId.shadowlord);
      expect(drop, isNull);
    });
  });

  group('ProgressionEngine.nextBossAfter', () {
    test('warden -> shaman', () {
      expect(ProgressionEngine.nextBossAfter(BossId.warden), BossId.shaman);
    });

    test('shaman -> hollowKing', () {
      expect(
        ProgressionEngine.nextBossAfter(BossId.shaman),
        BossId.hollowKing,
      );
    });

    test('hollowKing -> shadowlord', () {
      expect(
        ProgressionEngine.nextBossAfter(BossId.hollowKing),
        BossId.shadowlord,
      );
    });

    test('shadowlord -> null (end of chain)', () {
      expect(ProgressionEngine.nextBossAfter(BossId.shadowlord), isNull);
    });
  });

  group('ProgressionEngine.applyEquipment', () {
    const base = PlayerStats();

    test('weapon atkBonus is added to attack', () {
      final updated = ProgressionEngine.applyEquipment(
        base,
        Equipment.wardenSword,
        null,
      );
      expect(updated.attack, base.attack + 8);
    });

    test('armor hpBonus increases maxHp and hp', () {
      final updated = ProgressionEngine.applyEquipment(
        base,
        null,
        Equipment.shamanCloak,
      );
      expect(updated.maxHp, base.maxHp + 25);
      expect(updated.hp, base.hp + 25);
    });

    test('hollowCrown adds ultimateStartCharge', () {
      final updated = ProgressionEngine.applyEquipment(
        base,
        null,
        Equipment.hollowCrown,
      );
      expect(
        updated.ultimateStartCharge,
        closeTo(base.ultimateStartCharge + 0.20, 0.001),
      );
    });

    test('weapon + armor both applied', () {
      final updated = ProgressionEngine.applyEquipment(
        base,
        Equipment.wardenSword,
        Equipment.shamanCloak,
      );
      expect(updated.attack, base.attack + 8);
      expect(updated.maxHp, base.maxHp + 25);
    });

    test('null weapon and armor leaves stats unchanged', () {
      final updated = ProgressionEngine.applyEquipment(base, null, null);
      expect(updated.attack, base.attack);
      expect(updated.maxHp, base.maxHp);
    });
  });
}
