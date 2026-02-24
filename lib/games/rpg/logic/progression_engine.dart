import 'package:multigame/games/rpg/models/equipment.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class ProgressionEngine {
  const ProgressionEngine._();

  /// Returns the equipment dropped by the given boss (null for final boss).
  static Equipment? equipmentForBoss(BossId id) {
    switch (id) {
      case BossId.warden:
        return Equipment.wardenSword;
      case BossId.shaman:
        return Equipment.shamanCloak;
      case BossId.hollowKing:
        return Equipment.hollowCrown;
      case BossId.shadowlord:
        return null;
    }
  }

  /// Returns the next boss to unlock after defeating [id], or null if all beaten.
  static BossId? nextBossAfter(BossId id) {
    switch (id) {
      case BossId.warden:
        return BossId.shaman;
      case BossId.shaman:
        return BossId.hollowKing;
      case BossId.hollowKing:
        return BossId.shadowlord;
      case BossId.shadowlord:
        return null;
    }
  }

  /// Applies equipment bonuses to base stats, returning updated [PlayerStats].
  static PlayerStats applyEquipment(
    PlayerStats stats,
    Equipment? weapon,
    Equipment? armor,
  ) {
    var updated = stats;

    if (weapon != null) {
      updated = updated.copyWith(attack: updated.attack + weapon.atkBonus);
    }
    if (armor != null) {
      final newMaxHp = updated.maxHp + armor.hpBonus;
      updated = updated.copyWith(
        maxHp: newMaxHp,
        hp: (updated.hp + armor.hpBonus).clamp(0, newMaxHp),
        ultimateStartCharge:
            (updated.ultimateStartCharge + armor.ultimateStartCharge).clamp(
              0.0,
              0.5,
            ),
      );
    }

    return updated;
  }
}
