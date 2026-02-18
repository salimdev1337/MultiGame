import 'package:multigame/games/rpg/models/rpg_enums.dart';

class PlayerStats {
  const PlayerStats({
    this.hp = 100,
    this.maxHp = 100,
    this.attack = 10,
    this.defense = 5,
    this.speed = 200,
    this.level = 1,
    this.unlockedAbilities = const [AbilityType.basicAttack],
  });

  final int hp;
  final int maxHp;
  final int attack;
  final int defense;
  final int speed;
  final int level;
  final List<AbilityType> unlockedAbilities;

  PlayerStats copyWith({
    int? hp,
    int? maxHp,
    int? attack,
    int? defense,
    int? speed,
    int? level,
    List<AbilityType>? unlockedAbilities,
  }) {
    return PlayerStats(
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      level: level ?? this.level,
      unlockedAbilities: unlockedAbilities ?? this.unlockedAbilities,
    );
  }

  Map<String, dynamic> toJson() => {
    'hp': hp,
    'maxHp': maxHp,
    'attack': attack,
    'defense': defense,
    'speed': speed,
    'level': level,
    'unlockedAbilities': unlockedAbilities.map((a) => a.index).toList(),
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    hp: (json['hp'] as int?) ?? 100,
    maxHp: (json['maxHp'] as int?) ?? 100,
    attack: (json['attack'] as int?) ?? 10,
    defense: (json['defense'] as int?) ?? 5,
    speed: (json['speed'] as int?) ?? 200,
    level: (json['level'] as int?) ?? 1,
    unlockedAbilities: (json['unlockedAbilities'] as List?)
            ?.map((i) => AbilityType.values[i as int])
            .toList() ??
        [AbilityType.basicAttack],
  );
}
