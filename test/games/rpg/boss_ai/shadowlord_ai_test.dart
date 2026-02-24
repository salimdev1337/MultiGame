import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/shadowlord_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

void main() {
  final bossPos = Vector2(300, 200);
  final playerFar = Vector2(100, 200);

  const params = BossPhaseParams(
    moveSpeed: 90,
    attackDamage: 14,
    attackCooldown: 1.8,
    windupDuration: 0.5,
  );

  group('ShadowlordAI', () {
    test('phase 0 delegates to Warden — emits charge or slam', () {
      final ai = ShadowlordAI();
      ai.tick(0.016, bossPos, playerFar, 0, params); // idle
      BossAttackCommand? cmd;
      for (int i = 0; i < 100 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 0, params);
        cmd = t.attack;
      }
      expect(cmd, isNotNull);
      expect(
        cmd!.type,
        isIn([AttackType.chargeAttack, AttackType.overheadSlam]),
      );
    });

    test('phase 1 delegates to Shaman — emits poison attack', () {
      final ai = ShadowlordAI();
      ai.onPhaseChange(1);
      BossAttackCommand? cmd;
      for (int i = 0; i < 200 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 1, params);
        cmd = t.attack;
      }
      expect(cmd, isNotNull);
      expect(
        cmd!.type,
        isIn([AttackType.poisonProjectile, AttackType.poisonPool]),
      );
    });

    test('phase 2 delegates to HollowKing — emits dash attack', () {
      final ai = ShadowlordAI();
      ai.onPhaseChange(2);
      ai.tick(0.016, bossPos, playerFar, 2, params); // hollow king idle
      BossAttackCommand? cmd;
      for (int i = 0; i < 100 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 2, params);
        cmd = t.attack;
      }
      expect(cmd, isNotNull);
      expect(
        cmd!.type,
        isIn([AttackType.dashSlash, AttackType.bladeTrail]),
      );
    });

    test('reset clears all sub-AIs — phase 0 behaviour restored', () {
      final ai = ShadowlordAI();
      ai.onPhaseChange(2);
      ai.reset();
      ai.tick(0.016, bossPos, playerFar, 0, params); // idle
      BossAttackCommand? cmd;
      for (int i = 0; i < 100 && cmd == null; i++) {
        final t = ai.tick(0.05, bossPos, playerFar, 0, params);
        cmd = t.attack;
      }
      expect(cmd, isNotNull);
      expect(
        cmd!.type,
        isIn([AttackType.chargeAttack, AttackType.overheadSlam]),
      );
    });
  });
}
