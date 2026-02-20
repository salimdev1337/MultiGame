import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/rpg/logic/progression_engine.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RpgState {
  const RpgState({
    this.playerStats = const PlayerStats(),
    this.defeatedBosses = const [],
    this.cycle = 0,
    this.selectedBoss,
    this.lastReward,
  });

  final PlayerStats playerStats;
  final List<BossId> defeatedBosses;
  final int cycle;
  final BossId? selectedBoss;
  final String? lastReward;

  bool isBossDefeated(BossId id) => defeatedBosses.contains(id);

  bool get allDefeated =>
      defeatedBosses.contains(BossId.golem) &&
      defeatedBosses.contains(BossId.wraith);

  RpgState copyWith({
    PlayerStats? playerStats,
    List<BossId>? defeatedBosses,
    int? cycle,
    BossId? selectedBoss,
    String? lastReward,
    bool clearSelectedBoss = false,
    bool clearLastReward = false,
  }) {
    return RpgState(
      playerStats: playerStats ?? this.playerStats,
      defeatedBosses: defeatedBosses ?? this.defeatedBosses,
      cycle: cycle ?? this.cycle,
      selectedBoss: clearSelectedBoss ? null : selectedBoss ?? this.selectedBoss,
      lastReward: clearLastReward ? null : lastReward ?? this.lastReward,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerStats': playerStats.toJson(),
    'defeatedBosses': defeatedBosses.map((b) => b.index).toList(),
    'cycle': cycle,
  };

  factory RpgState.fromJson(Map<String, dynamic> json) => RpgState(
    playerStats: PlayerStats.fromJson(json['playerStats'] as Map<String, dynamic>? ?? {}),
    defeatedBosses: (json['defeatedBosses'] as List?)
        ?.map((i) => BossId.values[i as int])
        .toList() ?? [],
    cycle: (json['cycle'] as int?) ?? 0,
  );
}

final rpgProvider = NotifierProvider.autoDispose<RpgNotifier, RpgState>(
  RpgNotifier.new,
);

class RpgNotifier extends GameStatsNotifier<RpgState> {
  static const _saveKey = 'rpg_save';

  @override
  FirebaseStatsService get statsService => ref.read(firebaseStatsServiceProvider);

  @override
  RpgState build() {
    _loadProgress();
    return const RpgState();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_saveKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = RpgState.fromJson(json);
      }
    } catch (_) {
      // Corrupted save — start fresh
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_saveKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void selectBoss(BossId id) {
    state = state.copyWith(selectedBoss: id);
  }

  Future<void> onBossDefeated(BossId id) async {
    final newStats = ProgressionEngine.applyReward(state.playerStats, id);
    final reward = ProgressionEngine.rewardForBoss(id);
    final newDefeated = List<BossId>.from(state.defeatedBosses);
    if (!newDefeated.contains(id)) {
      newDefeated.add(id);
    }

    int newCycle = state.cycle;
    if (newDefeated.length >= BossId.values.length &&
        newDefeated.length > state.defeatedBosses.length) {
      // Check if this completes a full cycle
      final hadAll = BossId.values.every((b) => state.defeatedBosses.contains(b));
      if (!hadAll) {
        final nowAll = BossId.values.every((b) => newDefeated.contains(b));
        if (nowAll) {
          newCycle = state.cycle + 1;
        }
      }
    }

    state = state.copyWith(
      playerStats: newStats,
      defeatedBosses: newDefeated,
      cycle: newCycle,
      lastReward: reward.message,
    );

    await _saveProgress();
    await saveScore('rpg', newStats.maxHp);
  }

  void clearLastReward() {
    state = state.copyWith(clearLastReward: true);
  }

  void clearSelectedBoss() {
    state = state.copyWith(clearSelectedBoss: true);
  }

  Future<void> resetProgress() async {
    state = const RpgState();
    await _saveProgress();
  }
}
