import 'package:multigame/games/rpg/models/rpg_enums.dart';

class Ability {
  const Ability({
    required this.type,
    required this.damage,
    required this.cooldownSeconds,
    required this.range,
    required this.displayName,
  });

  final AbilityType type;
  final int damage;
  final double cooldownSeconds;
  final double range;
  final String displayName;

  static const Ability basicAttack = Ability(
    type: AbilityType.basicAttack,
    damage: 15,
    cooldownSeconds: 0.5,
    range: 80,
    displayName: 'Slash',
  );

  static const Ability fireball = Ability(
    type: AbilityType.fireball,
    damage: 20,
    cooldownSeconds: 3.0,
    range: 400,
    displayName: 'Fireball',
  );

  static const Ability timeSlow = Ability(
    type: AbilityType.timeSlow,
    damage: 0,
    cooldownSeconds: 8.0,
    range: 0,
    displayName: 'Time Slow',
  );

  static Ability forType(AbilityType type) {
    switch (type) {
      case AbilityType.basicAttack:
        return basicAttack;
      case AbilityType.fireball:
        return fireball;
      case AbilityType.timeSlow:
        return timeSlow;
    }
  }
}
