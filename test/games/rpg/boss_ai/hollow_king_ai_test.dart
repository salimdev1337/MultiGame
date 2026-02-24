import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/hollow_king_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

void main() {
  final bossPos = Vector2(300, 200);
  final playerFar = Vector2(100, 200); // distance ~200 — dash range

  const params = BossPhaseParams(
    moveSpeed: 100,
    attackDamage: 16,
    attackCooldown: 2.0,
    windupDuration: 0.45,
  );

  group('HollowKingAI', () {
    test('starts idle — first tick returns zero velocity, no attack', () {
      final ai = HollowKingAI();
      final tick = ai.tick(0.016, bossPos, playerFar, 0, params);
      expect(tick.velocity, Vector2.zero());
      expect(tick.attack, isNull);
    });

    test('pursues player from pursue state', () {
      final ai = HollowKingAI();
      ai.tick(0.016, bossPos, playerFar, 0, params); // idle -> pursue
      final tick = ai.tick(0.016, bossPos, playerFar, 0, params);
      expect(tick.velocity.length, greaterThan(0));
    });

    test('emits dashSlash after windup completes', () {
      final ai = HollowKingAI();
      ai.tick(0.016, bossPos, playerFar, 0, params); // idle
      BossAttackCommand? cmd;
      for (int i = 0; i < 100 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 0, params);
        cmd = t.attack;
      }
      expect(cmd, isNotNull);
      expect(
        cmd!.type,
        isIn([AttackType.dashSlash, AttackType.bladeTrail]),
      );
    });

    test('phase 0 uses only cardinal dash directions', () {
      final ai = HollowKingAI();
      ai.tick(0.016, bossPos, playerFar, 0, params);
      BossAttackCommand? cmd;
      for (int i = 0; i < 100 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 0, params);
        if (t.attack?.type == AttackType.dashSlash) {
          cmd = t.attack;
        }
      }
      if (cmd != null) {
        // Cardinal: one component must be 0 (or near 0), other ±1
        final dir = cmd.direction;
        final isCardinal =
            (dir.x.abs() < 0.01 || dir.y.abs() < 0.01) &&
            dir.length > 0.9;
        expect(isCardinal, isTrue);
      }
    });

    test('phase 1 emits blade trail after dash', () {
      final ai = HollowKingAI();
      ai.onPhaseChange(1);
      ai.tick(0.016, bossPos, playerFar, 1, params);
      bool sawTrail = false;
      for (int i = 0; i < 200 && !sawTrail; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 1, params);
        if (t.attack?.type == AttackType.bladeTrail) {
          sawTrail = true;
        }
      }
      expect(sawTrail, isTrue);
    });

    test('onPhaseChange triggers enrage — velocity zero during enrage', () {
      final ai = HollowKingAI();
      ai.onPhaseChange(1);
      final tick = ai.tick(0.016, bossPos, playerFar, 1, params);
      expect(tick.velocity, Vector2.zero());
    });

    test('reset returns AI to idle behaviour', () {
      final ai = HollowKingAI();
      ai.onPhaseChange(1);
      ai.reset();
      final tick = ai.tick(0.016, bossPos, playerFar, 0, params);
      expect(tick.velocity, Vector2.zero());
      expect(tick.attack, isNull);
    });
  });
}
