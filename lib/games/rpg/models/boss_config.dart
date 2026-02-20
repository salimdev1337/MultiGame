import 'dart:math';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

class BossPhaseConfig {
  const BossPhaseConfig({
    required this.hpThreshold,
    required this.attacks,
    required this.moveSpeed,
    required this.attackDamage,
  });

  final double hpThreshold;
  final List<AttackType> attacks;
  final double moveSpeed;
  final int attackDamage;
}

class BossConfig {
  const BossConfig({
    required this.id,
    required this.displayName,
    required this.baseHp,
    required this.phases,
    required this.hpScaleFactor,
    required this.dmgScaleFactor,
  });

  final BossId id;
  final String displayName;
  final int baseHp;
  final List<BossPhaseConfig> phases;
  final double hpScaleFactor;
  final double dmgScaleFactor;

  int scaledHp(int cycle) => (baseHp * pow(hpScaleFactor, cycle)).round();

  static const BossConfig golem = BossConfig(
    id: BossId.golem,
    displayName: 'Iron Golem',
    baseHp: 400,
    hpScaleFactor: 1.25,
    dmgScaleFactor: 1.15,
    phases: [
      BossPhaseConfig(
        hpThreshold: 1.0,
        attacks: [AttackType.groundStomp, AttackType.rockProjectile],
        moveSpeed: 80,
        attackDamage: 12,
      ),
      BossPhaseConfig(
        hpThreshold: 0.5,
        attacks: [AttackType.aoe, AttackType.rockProjectile],
        moveSpeed: 120,
        attackDamage: 16,
      ),
    ],
  );

  static const BossConfig wraith = BossConfig(
    id: BossId.wraith,
    displayName: 'Shadow Wraith',
    baseHp: 600,
    hpScaleFactor: 1.25,
    dmgScaleFactor: 1.15,
    phases: [
      BossPhaseConfig(
        hpThreshold: 1.0,
        attacks: [AttackType.shadowBolt, AttackType.dashAttack],
        moveSpeed: 100,
        attackDamage: 14,
      ),
      BossPhaseConfig(
        hpThreshold: 0.66,
        attacks: [AttackType.shadowBolt, AttackType.dashAttack],
        moveSpeed: 130,
        attackDamage: 16,
      ),
      BossPhaseConfig(
        hpThreshold: 0.33,
        attacks: [AttackType.shadowBolt, AttackType.aoe],
        moveSpeed: 160,
        attackDamage: 18,
      ),
    ],
  );

  static BossConfig forId(BossId id) {
    switch (id) {
      case BossId.golem:
        return golem;
      case BossId.wraith:
        return wraith;
    }
  }
}
