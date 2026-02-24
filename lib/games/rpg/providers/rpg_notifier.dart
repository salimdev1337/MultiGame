import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/rpg/logic/progression_engine.dart';
import 'package:multigame/games/rpg/logic/skill_tree.dart';
import 'package:multigame/games/rpg/models/equipment.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/utils/secure_logger.dart';

class RpgState {
  const RpgState({
    this.playerStats = const PlayerStats(),
    this.defeatedBosses = const [],
    this.weapon,
    this.armor,
    this.selectedBoss,
    this.appliedNodes = const [],
    this.levelUpOptions = const [],
    this.pendingLevelUp = false,
    this.pendingEquipment,
  });

  final PlayerStats playerStats;
  final List<BossId> defeatedBosses;
  final Equipment? weapon;
  final Equipment? armor;
  final BossId? selectedBoss;
  final List<String> appliedNodes;

  // Level-up flow state
  final List<SkillNode> levelUpOptions;
  final bool pendingLevelUp;
  final Equipment? pendingEquipment;

  bool isBossDefeated(BossId id) => defeatedBosses.contains(id);

  bool isBossUnlocked(BossId id) {
    switch (id) {
      case BossId.warden:
        return true;
      case BossId.shaman:
        return isBossDefeated(BossId.warden);
      case BossId.hollowKing:
        return isBossDefeated(BossId.shaman);
      case BossId.shadowlord:
        return isBossDefeated(BossId.hollowKing);
    }
  }

  bool get allDefeated => defeatedBosses.length >= BossId.values.length;

  RpgState copyWith({
    PlayerStats? playerStats,
    List<BossId>? defeatedBosses,
    Equipment? weapon,
    Equipment? armor,
    BossId? selectedBoss,
    List<String>? appliedNodes,
    List<SkillNode>? levelUpOptions,
    bool? pendingLevelUp,
    Equipment? pendingEquipment,
    bool clearSelectedBoss = false,
    bool clearPendingEquipment = false,
  }) {
    return RpgState(
      playerStats: playerStats ?? this.playerStats,
      defeatedBosses: defeatedBosses ?? this.defeatedBosses,
      weapon: weapon ?? this.weapon,
      armor: armor ?? this.armor,
      selectedBoss: clearSelectedBoss ? null : selectedBoss ?? this.selectedBoss,
      appliedNodes: appliedNodes ?? this.appliedNodes,
      levelUpOptions: levelUpOptions ?? this.levelUpOptions,
      pendingLevelUp: pendingLevelUp ?? this.pendingLevelUp,
      pendingEquipment: clearPendingEquipment
          ? null
          : pendingEquipment ?? this.pendingEquipment,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerStats': playerStats.toJson(),
    'defeatedBosses': defeatedBosses.map((b) => b.index).toList(),
    'weapon': weapon?.toJson(),
    'armor': armor?.toJson(),
    'appliedNodes': appliedNodes,
  };

  factory RpgState.fromJson(Map<String, dynamic> json) {
    Equipment? weapon;
    Equipment? armor;
    final wJson = json['weapon'] as Map<String, dynamic>?;
    final aJson = json['armor'] as Map<String, dynamic>?;
    if (wJson != null) {
      weapon = Equipment.fromId(wJson['id'] as String? ?? '');
    }
    if (aJson != null) {
      armor = Equipment.fromId(aJson['id'] as String? ?? '');
    }

    return RpgState(
      playerStats: PlayerStats.fromJson(
        json['playerStats'] as Map<String, dynamic>? ?? {},
      ),
      defeatedBosses: (json['defeatedBosses'] as List?)
              ?.map((i) {
                final idx = i as int;
                return (idx >= 0 && idx < BossId.values.length)
                    ? BossId.values[idx]
                    : null;
              })
              .whereType<BossId>()
              .toList() ??
          [],
      weapon: weapon,
      armor: armor,
      appliedNodes: (json['appliedNodes'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

final rpgProvider = NotifierProvider.autoDispose<RpgNotifier, RpgState>(
  RpgNotifier.new,
);

class RpgNotifier extends GameStatsNotifier<RpgState> {
  static const _saveKey = 'rpg_save';
  final _rng = Random();

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  RpgState build() {
    Future.microtask(_loadProgress);
    return const RpgState();
  }

  Future<void> _loadProgress() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.read(_saveKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = RpgState.fromJson(json);
      }
    } catch (error, stackTrace) {
      SecureLogger.error(
        'Error loading RPG progress',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveProgress() async {
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.write(_saveKey, jsonEncode(state.toJson()));
    } catch (error, stackTrace) {
      SecureLogger.error(
        'Error saving RPG progress',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void selectBoss(BossId id) {
    state = state.copyWith(selectedBoss: id);
  }

  /// Called by game screen when boss dies.
  /// Marks boss defeated, generates level-up options, sets pending equipment.
  Future<void> onBossDefeated(BossId id) async {
    final newDefeated = List<BossId>.from(state.defeatedBosses);
    if (!newDefeated.contains(id)) {
      newDefeated.add(id);
    }

    final options = SkillTree.pickOptions(state.appliedNodes, _rng);
    final drop = ProgressionEngine.equipmentForBoss(id);

    state = state.copyWith(
      defeatedBosses: newDefeated,
      levelUpOptions: options,
      pendingLevelUp: true,
      pendingEquipment: drop,
    );

    await saveScore('rpg', newDefeated.length * 100);
  }

  /// Called when player picks a skill node from the level-up overlay.
  void selectLevelUpNode(String nodeId) {
    final updatedStats = SkillTree.applyNode(state.playerStats, nodeId);
    final updatedNodes = List<String>.from(state.appliedNodes)..add(nodeId);

    state = state.copyWith(
      playerStats: updatedStats,
      appliedNodes: updatedNodes,
      pendingLevelUp: false,
    );
  }

  /// Called when player taps "Equip" on the equipment overlay.
  void equipPending() {
    final gear = state.pendingEquipment;
    if (gear == null) {
      return;
    }

    Equipment? newWeapon = state.weapon;
    Equipment? newArmor = state.armor;
    PlayerStats updatedStats = state.playerStats;

    if (gear.slot == EquipmentSlot.weapon) {
      // Remove old weapon bonus first
      if (newWeapon != null) {
        updatedStats = updatedStats.copyWith(
          attack: updatedStats.attack - newWeapon.atkBonus,
        );
      }
      newWeapon = gear;
      updatedStats = ProgressionEngine.applyEquipment(
        updatedStats,
        gear,
        null,
      );
    } else {
      // Armor
      if (newArmor != null) {
        updatedStats = updatedStats.copyWith(
          maxHp: updatedStats.maxHp - newArmor.hpBonus,
          hp: (updatedStats.hp - newArmor.hpBonus).clamp(1, 999),
          ultimateStartCharge:
              (updatedStats.ultimateStartCharge - newArmor.ultimateStartCharge)
                  .clamp(0.0, 1.0),
        );
      }
      newArmor = gear;
      updatedStats = ProgressionEngine.applyEquipment(
        updatedStats,
        null,
        gear,
      );
    }

    // Heal to new max on equip
    updatedStats = updatedStats.copyWith(hp: updatedStats.maxHp);

    state = state.copyWith(
      playerStats: updatedStats,
      weapon: gear.slot == EquipmentSlot.weapon ? gear : state.weapon,
      armor: gear.slot == EquipmentSlot.armor ? gear : state.armor,
      clearPendingEquipment: true,
    );

    _saveProgress();
  }

  void skipEquip() {
    state = state.copyWith(clearPendingEquipment: true);
    _saveProgress();
  }

  void clearSelectedBoss() {
    state = state.copyWith(clearSelectedBoss: true);
  }

  Future<void> resetProgress() async {
    state = const RpgState();
    await _saveProgress();
  }
}
