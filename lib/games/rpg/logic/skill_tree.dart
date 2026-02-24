import 'dart:math';

import 'package:multigame/games/rpg/models/player_stats.dart';

class SkillNode {
  const SkillNode({
    required this.id,
    required this.displayName,
    required this.description,
  });

  final String id;
  final String displayName;
  final String description;

  static const SkillNode maxHp = SkillNode(
    id: 'max_hp',
    displayName: '+15 Max HP',
    description: 'Increases maximum health by 15.',
  );
  static const SkillNode attack = SkillNode(
    id: 'attack',
    displayName: '+5 Attack',
    description: 'All attacks deal 5 more damage.',
  );
  static const SkillNode staminaPip = SkillNode(
    id: 'stamina_pip',
    displayName: '+1 Stamina Pip',
    description: 'Gain an extra dodge charge (max 4).',
  );
  static const SkillNode staminaRegen = SkillNode(
    id: 'stamina_regen',
    displayName: 'Iron Will',
    description: 'Stamina regens 50% faster.',
  );
  static const SkillNode comboWindow = SkillNode(
    id: 'combo_window',
    displayName: 'Fluid Strikes',
    description: 'Combo window extended by 0.2s.',
  );
  static const SkillNode ultHit = SkillNode(
    id: 'ult_hit',
    displayName: 'Aggressor',
    description: 'Ultimate charges faster when attacking.',
  );
  static const SkillNode ultDmg = SkillNode(
    id: 'ult_dmg',
    displayName: 'Resilience',
    description: 'Ultimate charges faster when taking damage.',
  );
  static const SkillNode heavyFinisher = SkillNode(
    id: 'heavy_finisher',
    displayName: 'Brutal Finisher',
    description: 'Combo finisher deals 30% more damage.',
  );
  static const SkillNode moveSpeed = SkillNode(
    id: 'move_speed',
    displayName: 'Swift Stride',
    description: '+20 movement speed.',
  );
  static const SkillNode quickRecovery = SkillNode(
    id: 'quick_recovery',
    displayName: 'Quick Recovery',
    description: 'Stamina regens 30% faster.',
  );
  static const SkillNode ironFist = SkillNode(
    id: 'iron_fist',
    displayName: 'Iron Fist',
    description: 'Hits feel heavier (+1 hitstop frame).',
  );
  static const SkillNode rugged = SkillNode(
    id: 'rugged',
    displayName: 'Rugged',
    description: 'Hazard and poison damage reduced by 30%.',
  );

  static const List<SkillNode> all = [
    maxHp,
    attack,
    staminaPip,
    staminaRegen,
    comboWindow,
    ultHit,
    ultDmg,
    heavyFinisher,
    moveSpeed,
    quickRecovery,
    ironFist,
    rugged,
  ];
}

class SkillTree {
  const SkillTree._();

  /// Returns 3 random nodes from the pool, excluding already applied node IDs.
  static List<SkillNode> pickOptions(
    List<String> applied,
    Random rng,
  ) {
    final pool =
        SkillNode.all.where((n) => !applied.contains(n.id)).toList();
    pool.shuffle(rng);
    return pool.take(3).toList();
  }

  /// Returns updated [PlayerStats] after applying the node with the given ID.
  static PlayerStats applyNode(PlayerStats stats, String nodeId) {
    switch (nodeId) {
      case 'max_hp':
        final newMax = stats.maxHp + 15;
        return stats.copyWith(maxHp: newMax, hp: stats.hp + 15);
      case 'attack':
        return stats.copyWith(attack: stats.attack + 5);
      case 'stamina_pip':
        return stats.copyWith(
          maxStaminaPips: (stats.maxStaminaPips + 1).clamp(3, 4),
        );
      case 'stamina_regen':
        return stats.copyWith(
          staminaRegenInterval: stats.staminaRegenInterval * 0.50,
        );
      case 'combo_window':
        return stats.copyWith(
          comboWindowBonus: stats.comboWindowBonus + 0.2,
        );
      case 'ult_hit':
        return stats.copyWith(
          ultimateHitChargeBonus: stats.ultimateHitChargeBonus + 0.025,
        );
      case 'ult_dmg':
        return stats.copyWith(
          ultimateDmgChargeBonus: stats.ultimateDmgChargeBonus + 0.05,
        );
      case 'heavy_finisher':
        return stats.copyWith(
          heavyFinisherBonus: stats.heavyFinisherBonus + 0.30,
        );
      case 'move_speed':
        return stats.copyWith(speed: stats.speed + 20);
      case 'quick_recovery':
        return stats.copyWith(
          staminaRegenInterval: stats.staminaRegenInterval * 0.70,
        );
      case 'iron_fist':
        return stats.copyWith(hitstopFrames: stats.hitstopFrames + 1);
      case 'rugged':
        return stats.copyWith(
          hazardResistance:
              (stats.hazardResistance + 0.30).clamp(0.0, 0.70),
        );
      default:
        return stats;
    }
  }
}
