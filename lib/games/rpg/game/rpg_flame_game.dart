import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:multigame/games/rpg/components/arena_component.dart';
import 'package:multigame/games/rpg/components/attack_component.dart';
import 'package:multigame/games/rpg/components/boss_component.dart';
import 'package:multigame/games/rpg/components/player_component.dart';
import 'package:multigame/games/rpg/logic/boss_ai/golem_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/wraith_ai.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

enum RpgEvent { bossPhaseChange, playerDeath, bossDefeated, bossDamaged, playerDamaged }

class RpgFlameGame extends FlameGame with HasCollisionDetection {
  RpgFlameGame({
    required this.bossId,
    required this.playerStats,
    required this.cycle,
  });

  final BossId bossId;
  final PlayerStats playerStats;
  final int cycle;

  RpgGamePhase _phase = RpgGamePhase.idle;
  RpgGamePhase get gamePhase => _phase;

  double _inputDx = 0;
  double _inputDy = 0;
  double timeScale = 1.0;
  double _timeSlowTimer = 0;

  late PlayerComponent _player;
  late BossComponent _boss;
  late ArenaComponent _arena;

  final List<AttackComponent> _attacks = [];

  final _eventController = StreamController<RpgEvent>.broadcast();
  Stream<RpgEvent> get events => _eventController.stream;

  final ValueNotifier<int> gameTick = ValueNotifier<int>(0);
  double _tickAccum = 0;
  static const double _tickInterval = 0.05;

  int get playerHp => _player.currentHp;
  int get playerMaxHp => _player.stats.maxHp;
  int get bossHp => _boss.currentHp;
  int get bossMaxHp => _boss.maxHp;
  int get bossPhase => _boss.currentPhase;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _arena = ArenaComponent(bossId: bossId == BossId.golem ? 'golem' : 'wraith');
    await add(_arena);

    final config = BossConfig.forId(bossId);
    final ai = bossId == BossId.golem ? GolemAI() : WraithAI();

    _player = PlayerComponent(
      position: Vector2(80, size.y - 180),
      stats: playerStats,
    );
    await add(_player);

    _boss = BossComponent(
      position: Vector2(size.x - 160, size.y - 220),
      config: config,
      ai: ai,
      scaledHp: config.scaledHp(cycle),
    );
    _boss.onPhaseChange = (p) => _eventController.add(RpgEvent.bossPhaseChange);
    _boss.onDeath = () {
      _phase = RpgGamePhase.victory;
      _eventController.add(RpgEvent.bossDefeated);
      overlays.add('victory');
    };
    await add(_boss);

    overlays.add('hud');
  }

  void startFight() {
    _phase = RpgGamePhase.playing;
    overlays.remove('intro');
  }

  void setMovementInput(double dx, double dy) {
    _inputDx = dx;
    _inputDy = dy;
  }

  void triggerAttack() {
    if (_phase != RpgGamePhase.playing) {
      return;
    }
    final atk = _player.triggerAttack();
    if (atk != null) {
      _spawnAttack(atk);
    }
  }

  void triggerFireball() {
    if (_phase != RpgGamePhase.playing) {
      return;
    }
    if (!playerStats.unlockedAbilities.contains(AbilityType.fireball)) {
      return;
    }
    final fb = _player.triggerFireball();
    if (fb != null) {
      _spawnAttack(fb);
    }
  }

  void triggerTimeSlow() {
    if (_phase != RpgGamePhase.playing) {
      return;
    }
    if (!playerStats.unlockedAbilities.contains(AbilityType.timeSlow)) {
      return;
    }
    timeScale = 0.3;
    _timeSlowTimer = 3.0;
  }

  void _spawnAttack(AttackComponent atk) {
    _attacks.add(atk);
    add(atk);
  }

  @override
  void update(double dt) {
    final scaledDt = dt * timeScale;
    super.update(scaledDt);

    if (_timeSlowTimer > 0) {
      _timeSlowTimer -= dt;
      if (_timeSlowTimer <= 0) {
        timeScale = 1.0;
      }
    }

    if (_phase != RpgGamePhase.playing) {
      return;
    }

    // Build platform rects from arena
    final platformRects = _arena.platforms.map((p) => p.rect).toList();

    // Move player
    _player.applyMovement(_inputDx, _inputDy, scaledDt, platformRects);

    // Boss AI tick
    final bossCmd = _boss.update2(scaledDt, _player.position);
    if (bossCmd != null) {
      final atk = _boss.spawnAttack(bossCmd, cycle);
      if (atk != null) {
        _spawnAttack(atk);
      }
    }

    // Collision: player attacks vs boss
    for (final atk in List.of(_attacks)) {
      if (atk.owner == 'player' && !atk.consumed) {
        final atkRect = Rect.fromLTWH(
          atk.position.x, atk.position.y, atk.size.x, atk.size.y,
        );
        final bossRect = Rect.fromLTWH(
          _boss.position.x, _boss.position.y, _boss.size.x, _boss.size.y,
        );
        if (atkRect.overlaps(bossRect)) {
          atk.consumed = true;
          _boss.takeDamage(atk.damage);
          _eventController.add(RpgEvent.bossDamaged);
        }
      }
    }

    // Collision: boss attacks vs player
    for (final atk in List.of(_attacks)) {
      if (atk.owner == 'boss' && !atk.consumed) {
        final atkRect = Rect.fromLTWH(
          atk.position.x, atk.position.y, atk.size.x, atk.size.y,
        );
        final playerRect = Rect.fromLTWH(
          _player.position.x, _player.position.y, _player.size.x, _player.size.y,
        );
        if (atkRect.overlaps(playerRect)) {
          atk.consumed = true;
          _player.takeDamage(atk.damage);
          _eventController.add(RpgEvent.playerDamaged);
          if (_player.isDead) {
            _phase = RpgGamePhase.gameOver;
            _eventController.add(RpgEvent.playerDeath);
            overlays.add('gameOver');
          }
        }
      }
    }

    // Remove consumed/expired attacks
    _attacks.removeWhere((a) => a.isRemoved || a.consumed);

    // HUD tick throttle
    _tickAccum += dt;
    if (_tickAccum >= _tickInterval) {
      _tickAccum = 0;
      gameTick.value++;
    }
  }

  @override
  void onRemove() {
    _eventController.close();
    gameTick.dispose();
    super.onRemove();
  }
}
