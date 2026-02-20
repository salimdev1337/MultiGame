import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/combat_calculator.dart';

void main() {
  group('CombatCalculator', () {
    test('damage is attack minus half defense', () {
      expect(CombatCalculator.calcDamage(10, 4), 8); // 10 - 4/2 = 8
      expect(CombatCalculator.calcDamage(10, 5), 8); // 10 - (5~/ 2)=10-2=8
      expect(CombatCalculator.calcDamage(10, 6), 7); // 10 - 6/2 = 7
    });

    test('minimum damage is 1', () {
      expect(CombatCalculator.calcDamage(1, 100), 1);
      expect(CombatCalculator.calcDamage(0, 0), 1);
    });

    test('scaleBossHp grows by 25% per cycle', () {
      expect(CombatCalculator.scaleBossHp(400, 0), 400);
      expect(CombatCalculator.scaleBossHp(400, 1), 500);
      expect(CombatCalculator.scaleBossHp(400, 2), 625);
    });

    test('scaleBossDmg grows by 15% per cycle', () {
      expect(CombatCalculator.scaleBossDmg(100, 0), 100);
      expect(CombatCalculator.scaleBossDmg(100, 1), 115);
      expect(CombatCalculator.scaleBossDmg(100, 2), 132);
    });

    test('applyCrit multiplies damage by 1.5', () {
      expect(CombatCalculator.applyCrit(10), 15);
      expect(CombatCalculator.applyCrit(20), 30);
    });
  });
}
