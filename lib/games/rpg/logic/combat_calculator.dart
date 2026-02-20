import 'dart:math';

class CombatCalculator {
  const CombatCalculator._();

  static int calcDamage(int attackerAtk, int defenderDef) =>
      max(1, attackerAtk - (defenderDef ~/ 2));

  static int scaleBossHp(int baseHp, int cycle) =>
      (baseHp * pow(1.25, cycle)).round();

  static int scaleBossDmg(int baseDmg, int cycle) =>
      (baseDmg * pow(1.15, cycle)).round();

  static bool isCritical(double critChance) =>
      Random().nextDouble() < critChance;

  static int applyCrit(int damage) => (damage * 1.5).round();
}
