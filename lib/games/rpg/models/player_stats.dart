/// Immutable player stat snapshot. Skill tree nodes and equipment are
/// applied via copyWith to produce a new snapshot.
class PlayerStats {
  const PlayerStats({
    this.hp = 100,
    this.maxHp = 100,
    this.attack = 10,
    this.speed = 180,
    // Stamina
    this.maxStaminaPips = 3,
    this.staminaRegenInterval = 2.0,
    // Combo
    this.comboWindowBonus = 0.0,
    this.heavyFinisherBonus = 0.0,
    // Ultimate
    this.ultimateHitChargeBonus = 0.0,
    this.ultimateDmgChargeBonus = 0.0,
    this.ultimateStartCharge = 0.0,
    // Misc passives
    this.hitstopFrames = 3,
    this.hazardResistance = 0.0,
  });

  final int hp;
  final int maxHp;
  final int attack;
  final int speed;

  final int maxStaminaPips;
  final double staminaRegenInterval;

  final double comboWindowBonus;
  final double heavyFinisherBonus;

  final double ultimateHitChargeBonus;
  final double ultimateDmgChargeBonus;
  final double ultimateStartCharge;

  final int hitstopFrames;
  final double hazardResistance;

  PlayerStats copyWith({
    int? hp,
    int? maxHp,
    int? attack,
    int? speed,
    int? maxStaminaPips,
    double? staminaRegenInterval,
    double? comboWindowBonus,
    double? heavyFinisherBonus,
    double? ultimateHitChargeBonus,
    double? ultimateDmgChargeBonus,
    double? ultimateStartCharge,
    int? hitstopFrames,
    double? hazardResistance,
  }) {
    return PlayerStats(
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      speed: speed ?? this.speed,
      maxStaminaPips: maxStaminaPips ?? this.maxStaminaPips,
      staminaRegenInterval: staminaRegenInterval ?? this.staminaRegenInterval,
      comboWindowBonus: comboWindowBonus ?? this.comboWindowBonus,
      heavyFinisherBonus: heavyFinisherBonus ?? this.heavyFinisherBonus,
      ultimateHitChargeBonus:
          ultimateHitChargeBonus ?? this.ultimateHitChargeBonus,
      ultimateDmgChargeBonus:
          ultimateDmgChargeBonus ?? this.ultimateDmgChargeBonus,
      ultimateStartCharge: ultimateStartCharge ?? this.ultimateStartCharge,
      hitstopFrames: hitstopFrames ?? this.hitstopFrames,
      hazardResistance: hazardResistance ?? this.hazardResistance,
    );
  }

  Map<String, dynamic> toJson() => {
    'hp': hp,
    'maxHp': maxHp,
    'attack': attack,
    'speed': speed,
    'maxStaminaPips': maxStaminaPips,
    'staminaRegenInterval': staminaRegenInterval,
    'comboWindowBonus': comboWindowBonus,
    'heavyFinisherBonus': heavyFinisherBonus,
    'ultimateHitChargeBonus': ultimateHitChargeBonus,
    'ultimateDmgChargeBonus': ultimateDmgChargeBonus,
    'ultimateStartCharge': ultimateStartCharge,
    'hitstopFrames': hitstopFrames,
    'hazardResistance': hazardResistance,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    hp: (json['hp'] as int?) ?? 100,
    maxHp: (json['maxHp'] as int?) ?? 100,
    attack: (json['attack'] as int?) ?? 10,
    speed: (json['speed'] as int?) ?? 180,
    maxStaminaPips: (json['maxStaminaPips'] as int?) ?? 3,
    staminaRegenInterval:
        (json['staminaRegenInterval'] as num?)?.toDouble() ?? 2.0,
    comboWindowBonus: (json['comboWindowBonus'] as num?)?.toDouble() ?? 0.0,
    heavyFinisherBonus:
        (json['heavyFinisherBonus'] as num?)?.toDouble() ?? 0.0,
    ultimateHitChargeBonus:
        (json['ultimateHitChargeBonus'] as num?)?.toDouble() ?? 0.0,
    ultimateDmgChargeBonus:
        (json['ultimateDmgChargeBonus'] as num?)?.toDouble() ?? 0.0,
    ultimateStartCharge:
        (json['ultimateStartCharge'] as num?)?.toDouble() ?? 0.0,
    hitstopFrames: (json['hitstopFrames'] as int?) ?? 3,
    hazardResistance: (json['hazardResistance'] as num?)?.toDouble() ?? 0.0,
  );
}
