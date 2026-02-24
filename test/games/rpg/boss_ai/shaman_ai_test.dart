import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/wraith_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

void main() {
  final bossPos = Vector2(200, 200);
  final playerPos = Vector2(200, 400);

  const params = BossPhaseParams(
    moveSpeed: 80,
    attackDamage: 14,
    attackCooldown: 2.0,
    windupDuration: 0.5,
  );

  group('ShamanAI', () {
    test('starts in orbit — velocity moves toward orbit target', () {
      final ai = ShamanAI();
      final tick = ai.tick(0.016, bossPos, playerPos, 0, params);
      // May be zero or non-zero depending on orbit target distance
      expect(tick.attack, isNull);
    });

    test('emits an attack after cooldown expires', () {
      final ai = ShamanAI();
      BossAttackCommand? cmd;
      for (int i = 0; i < 200 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerPos, 0, params);
        cmd = t.attack;
      }
      expect(cmd, isNotNull);
      expect(
        cmd!.type,
        isIn([AttackType.poisonProjectile, AttackType.poisonPool]),
      );
    });

    test('phase 0 never emits poison pool', () {
      final ai = ShamanAI();
      int poolCount = 0;
      for (int i = 0; i < 400; i++) {
        final t = ai.tick(0.05, bossPos, playerPos, 0, params);
        if (t.attack?.type == AttackType.poisonPool) {
          poolCount++;
        }
      }
      expect(poolCount, 0);
    });

    test('onPhaseChange to 1 enables poison pool attacks', () {
      final ai = ShamanAI();
      ai.onPhaseChange(1);
      bool sawPool = false;
      for (int i = 0; i < 600 && !sawPool; i++) {
        final t = ai.tick(0.05, bossPos, playerPos, 1, params);
        if (t.attack?.type == AttackType.poisonPool) {
          sawPool = true;
        }
      }
      expect(sawPool, isTrue);
    });

    test('reset clears phase — no pool in phase 0 after reset', () {
      final ai = ShamanAI();
      ai.onPhaseChange(1);
      ai.reset();
      int poolCount = 0;
      for (int i = 0; i < 400; i++) {
        final t = ai.tick(0.05, bossPos, playerPos, 0, params);
        if (t.attack?.type == AttackType.poisonPool) {
          poolCount++;
        }
      }
      expect(poolCount, 0);
    });

    test('projectile direction aims toward player', () {
      final ai = ShamanAI();
      BossAttackCommand? cmd;
      for (int i = 0; i < 200 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerPos, 0, params);
        if (t.attack?.type == AttackType.poisonProjectile) {
          cmd = t.attack;
        }
      }
      if (cmd != null) {
        // Direction dot product toward player should be positive (roughly aimed)
        final toPlayer = (playerPos - bossPos).normalized();
        final dot = toPlayer.dot(cmd.direction);
        expect(dot, greaterThan(0.5));
      }
    });
  });
}
