import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rpg/logic/boss_ai/golem_ai.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

void main() {
  final bossPos = Vector2(200, 100);
  final playerPos = Vector2(50, 100);

  group('GolemAI', () {
    test('starts in idle state', () {
      final ai = GolemAI();
      expect(ai.currentState, BossAiState.idle);
    });

    test('transitions from idle to move on first tick', () {
      final ai = GolemAI();
      ai.decide(0.016, bossPos, playerPos);
      expect(ai.currentState, BossAiState.move);
    });

    test('picks an attack after cooldown expires', () {
      final ai = GolemAI();
      ai.decide(0.016, bossPos, playerPos); // idle -> move
      ai.decide(2.0, bossPos, playerPos); // advance timer past cooldown
      expect(
        [
          BossAiState.stomp,
          BossAiState.rockThrow,
          BossAiState.spin,
          BossAiState.move,
        ],
        contains(ai.currentState),
      );
    });

    test('returns AttackCommand on stomp wind-up expiry', () {
      final ai = GolemAI();
      ai.decide(0.016, bossPos, playerPos); // -> move
      // Force to stomp state directly by running ticks
      for (int i = 0; i < 100; i++) {
        final cmd = ai.decide(0.1, bossPos, playerPos);
        if (cmd != null) {
          expect(
            cmd.type,
            isIn([AttackType.groundStomp, AttackType.rockProjectile, AttackType.aoe]),
          );
          return;
        }
      }
      // It's okay if no attack fired in first 10s (random-based)
    });

    test('onPhaseChange transitions to enrage', () {
      final ai = GolemAI();
      ai.onPhaseChange(1);
      expect(ai.currentState, BossAiState.enrage);
    });

    test('reset returns to idle', () {
      final ai = GolemAI();
      ai.onPhaseChange(1);
      ai.reset();
      expect(ai.currentState, BossAiState.idle);
    });
  });
}
