import 'package:multigame/games/rpg/models/rpg_enums.dart';

class BossPhaseConfig {
  const BossPhaseConfig({
    required this.hpThreshold,
    required this.moveSpeed,
    required this.attackDamage,
    required this.attackCooldown,
    required this.windupDuration,
  });

  /// HP ratio at which this phase activates (1.0 = full HP).
  final double hpThreshold;
  final double moveSpeed;
  final int attackDamage;
  final double attackCooldown;
  final double windupDuration;
}

class BossConfig {
  const BossConfig({
    required this.id,
    required this.displayName,
    required this.title,
    required this.baseHp,
    required this.phases,
    required this.bossWidth,
    required this.bossHeight,
  });

  final BossId id;
  final String displayName;
  final String title;
  final int baseHp;
  final List<BossPhaseConfig> phases;
  final double bossWidth;
  final double bossHeight;

  static const BossConfig warden = BossConfig(
    id: BossId.warden,
    displayName: 'The Warden',
    title: 'Corrupted Knight',
    baseHp: 300,
    bossWidth: 64,
    bossHeight: 64,
    phases: [
      BossPhaseConfig(
        hpThreshold: 1.0,
        moveSpeed: 80,
        attackDamage: 12,
        attackCooldown: 2.2,
        windupDuration: 0.55,
      ),
      BossPhaseConfig(
        hpThreshold: 0.50,
        moveSpeed: 115,
        attackDamage: 16,
        attackCooldown: 1.6,
        windupDuration: 0.40,
      ),
    ],
  );

  static const BossConfig shaman = BossConfig(
    id: BossId.shaman,
    displayName: 'The Plague Shaman',
    title: 'Cursed Witch',
    baseHp: 450,
    bossWidth: 56,
    bossHeight: 64,
    phases: [
      BossPhaseConfig(
        hpThreshold: 1.0,
        moveSpeed: 70,
        attackDamage: 14,
        attackCooldown: 2.0,
        windupDuration: 0.50,
      ),
      BossPhaseConfig(
        hpThreshold: 0.50,
        moveSpeed: 90,
        attackDamage: 18,
        attackCooldown: 1.4,
        windupDuration: 0.35,
      ),
    ],
  );

  static const BossConfig hollowKing = BossConfig(
    id: BossId.hollowKing,
    displayName: 'The Hollow King',
    title: 'Undead Sovereign',
    baseHp: 600,
    bossWidth: 72,
    bossHeight: 72,
    phases: [
      BossPhaseConfig(
        hpThreshold: 1.0,
        moveSpeed: 100,
        attackDamage: 16,
        attackCooldown: 2.0,
        windupDuration: 0.45,
      ),
      BossPhaseConfig(
        hpThreshold: 0.66,
        moveSpeed: 125,
        attackDamage: 18,
        attackCooldown: 1.6,
        windupDuration: 0.35,
      ),
      BossPhaseConfig(
        hpThreshold: 0.33,
        moveSpeed: 155,
        attackDamage: 22,
        attackCooldown: 1.2,
        windupDuration: 0.28,
      ),
    ],
  );

  static const BossConfig shadowlord = BossConfig(
    id: BossId.shadowlord,
    displayName: 'The Shadowlord',
    title: 'Source of Corruption',
    baseHp: 900,
    bossWidth: 80,
    bossHeight: 80,
    phases: [
      BossPhaseConfig(
        hpThreshold: 1.0,
        moveSpeed: 90,
        attackDamage: 14,
        attackCooldown: 1.8,
        windupDuration: 0.50,
      ),
      BossPhaseConfig(
        hpThreshold: 0.66,
        moveSpeed: 115,
        attackDamage: 18,
        attackCooldown: 1.5,
        windupDuration: 0.40,
      ),
      BossPhaseConfig(
        hpThreshold: 0.33,
        moveSpeed: 145,
        attackDamage: 22,
        attackCooldown: 1.1,
        windupDuration: 0.30,
      ),
    ],
  );

  static BossConfig forId(BossId id) {
    switch (id) {
      case BossId.warden:
        return warden;
      case BossId.shaman:
        return shaman;
      case BossId.hollowKing:
        return hollowKing;
      case BossId.shadowlord:
        return shadowlord;
    }
  }
}
