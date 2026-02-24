import 'package:flame/components.dart';
import 'package:multigame/games/rpg/logic/boss_ai/boss_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/golem_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/hollow_king_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/wraith_ai.dart';

/// The Shadowlord AI: delegates to the three previous boss AIs based on phase.
/// Phase 0 (>66%): Warden patterns (charge + slam).
/// Phase 1 (66-33%): Shaman patterns (orbit + projectiles + pools).
/// Phase 2 (<=33%): Hollow King patterns (dashes + blade trails) amplified.
class ShadowlordAI implements BossAI {
  ShadowlordAI()
      : _warden = WardenAI(),
        _shaman = ShamanAI(),
        _hollowKing = HollowKingAI();

  final WardenAI _warden;
  final ShamanAI _shaman;
  final HollowKingAI _hollowKing;
  int _phase = 0;

  @override
  void reset() {
    _warden.reset();
    _shaman.reset();
    _hollowKing.reset();
    _phase = 0;
  }

  @override
  void onPhaseChange(int newPhase) {
    _phase = newPhase;
    _warden.onPhaseChange(0);
    _shaman.onPhaseChange(0);
    _hollowKing.onPhaseChange(newPhase == 2 ? 2 : 0);
  }

  @override
  BossTick tick(
    double dt,
    Vector2 bossPos,
    Vector2 playerPos,
    int phase,
    BossPhaseParams params,
  ) {
    switch (_phase) {
      case 0:
        return _warden.tick(dt, bossPos, playerPos, 0, params);
      case 1:
        return _shaman.tick(dt, bossPos, playerPos, 0, params);
      case 2:
        return _hollowKing.tick(dt, bossPos, playerPos, 2, params);
      default:
        return BossTick(velocity: Vector2.zero());
    }
  }
}
