import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/golem_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

void main() {
  final bossPos = Vector2(200, 100);
  final playerFar = Vector2(50, 100); // distance ~150 — charge range
  final playerClose = Vector2(180, 100); // distance ~20 — slam range

  const params = BossPhaseParams(
    moveSpeed: 120,
    attackDamage: 20,
    attackCooldown: 2.0,
    windupDuration: 0.5,
  );

  group('WardenAI', () {
    test('starts in idle — first tick returns zero velocity', () {
      final ai = WardenAI();
      final tick = ai.tick(0.016, bossPos, playerFar, 0, params);
      expect(tick.velocity, Vector2.zero());
      expect(tick.attack, isNull);
    });

    test('pursues player when far away', () {
      final ai = WardenAI();
      ai.tick(0.016, bossPos, playerFar, 0, params); // idle -> pursue
      final tick = ai.tick(0.016, bossPos, playerFar, 0, params);
      expect(tick.velocity.length, greaterThan(0));
    });

    test('winds up charge attack when player is far and cooldown clear', () {
      final ai = WardenAI();
      ai.tick(0.016, bossPos, playerFar, 0, params); // idle -> pursue
      // Advance past cooldown (starts at 0) and trigger windup
      BossAttackCommand? cmd;
      for (int i = 0; i < 80 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 0, params);
        cmd = t.attack;
      }
      expect(cmd, isNotNull);
      expect(
        cmd!.type,
        isIn([AttackType.chargeAttack, AttackType.overheadSlam]),
      );
    });

    test('emits overheadSlam when player is close', () {
      final ai = WardenAI();
      ai.tick(0.016, bossPos, playerClose, 0, params); // idle -> pursue
      BossAttackCommand? cmd;
      for (int i = 0; i < 80 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerClose, 0, params);
        cmd = t.attack;
      }
      expect(cmd?.type, AttackType.overheadSlam);
    });

    test('onPhaseChange triggers enrage — velocity is zero during enrage', () {
      final ai = WardenAI();
      ai.onPhaseChange(1);
      final tick = ai.tick(0.016, bossPos, playerFar, 1, params);
      expect(tick.velocity, Vector2.zero());
    });

    test('reset returns AI to idle behaviour', () {
      final ai = WardenAI();
      ai.onPhaseChange(1);
      ai.reset();
      // After reset, first tick should be idle (zero velocity, no attack)
      final tick = ai.tick(0.016, bossPos, playerFar, 0, params);
      expect(tick.velocity, Vector2.zero());
      expect(tick.attack, isNull);
    });
  });
}
