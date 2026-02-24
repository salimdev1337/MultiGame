import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:multigame/games/rpg/components/arena_component.dart';
import 'package:multigame/games/rpg/components/attack_component.dart';
import 'package:multigame/games/rpg/components/boss_component.dart';
import 'package:multigame/games/rpg/components/player_component.dart';
import 'package:multigame/games/rpg/components/rpg_particle.dart';
import 'package:multigame/games/rpg/logic/boss_ai/golem_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/hollow_king_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/shadowlord_ai.dart';
import 'package:multigame/games/rpg/logic/boss_ai/wraith_ai.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/player_stats.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

enum RpgEvent { bossPhaseChange, playerDeath, bossDefeated, bossDamaged, playerDamaged }

class RpgFlameGame extends FlameGame {
  RpgFlameGame({required this.bossId, required this.playerStats});

  final BossId bossId;
  final PlayerStats playerStats;

  RpgGamePhase _phase = RpgGamePhase.idle;
  RpgGamePhase get gamePhase => _phase;

  double _inputDx = 0;
  double _inputDy = 0;

  // Keyboard
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final Set<LogicalKeyboardKey> _justPressedKeys = {};

  bool _ready = false;

  late PlayerComponent _player;
  late BossComponent _boss;
  late ArenaComponent _arena;

  final List<AttackComponent> _attacks = [];

  // Hitstop: freeze for N frames on hit
  int _hitstopFrames = 0;

  // Screen shake
  double _shakeTimer = 0;
  double _shakeIntensity = 0;
  final _shakeRng = _SimpleRng(7);

  final _eventController = StreamController<RpgEvent>.broadcast();
  Stream<RpgEvent> get events => _eventController.stream;

  final ValueNotifier<int> gameTick = ValueNotifier<int>(0);
  double _tickAccum = 0;
  static const double _tickInterval = 0.05;

  int get playerHp => _ready ? _player.currentHp : 0;
  int get playerMaxHp => _ready ? _player.stats.maxHp : 1;
  int get bossHp => _ready ? _boss.currentHp : 0;
  int get bossMaxHp => _ready ? _boss.maxHp : 1;
  int get bossPhase => _ready ? _boss.currentPhase : 0;
  double get ultimateCharge => _ready ? _player.ultimate.charge : 0.0;
  int get staminaPips => _ready ? _player.stamina.currentPips : 0;
  int get maxStaminaPips => _ready ? _player.stamina.maxPips : 3;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _arena = ArenaComponent(bossId: bossId);
    await add(_arena);

    _player = PlayerComponent(
      position: Vector2(
        _arena.arenaMin.x + 80,
        size.y / 2 - 24,
      ),
      stats: playerStats,
    );
    await add(_player);

    final config = BossConfig.forId(bossId);
    _boss = BossComponent(
      position: Vector2(
        size.x - _arena.arenaMin.x - 80 - config.bossWidth,
        size.y / 2 - config.bossHeight / 2,
      ),
      config: config,
      ai: _buildAi(bossId),
    );
    _boss.onPhaseChange = (p) => _eventController.add(RpgEvent.bossPhaseChange);
    _boss.onDeath = () {
      _phase = RpgGamePhase.victory;
      _eventController.add(RpgEvent.bossDefeated);
      overlays.add('victory');
    };
    await add(_boss);

    overlays.add('hud');
    _ready = true;
  }

  void startFight() {
    _phase = RpgGamePhase.playing;
    overlays.remove('intro');
  }

  void setMovementInput(double dx, double dy) {
    _inputDx = dx;
    _inputDy = dy;
  }

  void onKeyDown(LogicalKeyboardKey key) {
    if (!_pressedKeys.contains(key)) {
      _justPressedKeys.add(key);
    }
    _pressedKeys.add(key);
  }

  void onKeyUp(LogicalKeyboardKey key) {
    _pressedKeys.remove(key);
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

  void triggerDodge() {
    if (_phase != RpgGamePhase.playing) {
      return;
    }
    _player.triggerDodge();
  }

  void triggerUltimate() {
    if (_phase != RpgGamePhase.playing) {
      return;
    }
    final aoe = _player.triggerUltimate();
    if (aoe != null) {
      _spawnAttack(aoe);
      _triggerScreenShake(0.5, 8.0);
    }
  }

  void _spawnAttack(AttackComponent atk) {
    _attacks.add(atk);
    add(atk);
  }

  void _triggerHitstop(int frames) {
    _hitstopFrames = frames;
  }

  void _triggerScreenShake(double duration, double intensity) {
    _shakeTimer = duration;
    _shakeIntensity = intensity;
  }

  @override
  void update(double dt) {
    // Hitstop: skip game logic for N frames
    if (_hitstopFrames > 0) {
      _hitstopFrames--;
      _updateHudTick(dt);
      return;
    }

    // Screen shake: offset camera
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      final dx = (_shakeRng.next() - 0.5) * _shakeIntensity;
      final dy = (_shakeRng.next() - 0.5) * _shakeIntensity;
      camera.viewfinder.position = Vector2(dx, dy);
    } else if (camera.viewfinder.position != Vector2.zero()) {
      camera.viewfinder.position = Vector2.zero();
    }

    super.update(dt);

    if (_phase != RpgGamePhase.playing) {
      _justPressedKeys.clear();
      return;
    }

    // Keyboard input
    double effectiveDx = _inputDx;
    double effectiveDy = _inputDy;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      effectiveDx = -1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      effectiveDx = 1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      effectiveDy = -1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      effectiveDy = 1.0;
    }
    if (_justPressedKeys.contains(LogicalKeyboardKey.keyX)) {
      triggerAttack();
    }
    if (_justPressedKeys.contains(LogicalKeyboardKey.keyZ) ||
        _justPressedKeys.contains(LogicalKeyboardKey.space)) {
      triggerDodge();
    }
    if (_justPressedKeys.contains(LogicalKeyboardKey.keyC)) {
      triggerUltimate();
    }
    _justPressedKeys.clear();

    // Player movement
    _player.applyMovement(
      effectiveDx,
      effectiveDy,
      dt,
      _arena.arenaMin,
      _arena.arenaMax,
    );

    // Boss AI tick
    final bossAtk = _boss.update2(dt, _player.center);
    if (bossAtk != null) {
      _spawnAttack(bossAtk);
    }

    // Collision: player attacks vs boss
    final bossCenter = _boss.center;
    final bossR = _boss.hitRadius;
    for (final atk in List.of(_attacks)) {
      if (atk.owner == 'player' && !atk.consumed) {
        if (atk.overlapsCircle(bossCenter, bossR)) {
          atk.consumed = true;
          _boss.takeDamage(atk.damage);
          _player.ultimate.onHitLanded();
          _triggerHitstop(playerStats.hitstopFrames);
          _eventController.add(RpgEvent.bossDamaged);
          add(HitParticle(position: bossCenter.clone(), isBossHit: true));
        }
      }
    }

    // Collision: boss attacks vs player
    final playerCenter = _player.center;
    final playerR = _player.hitRadius;
    for (final atk in List.of(_attacks)) {
      if (atk.owner == 'boss' && !atk.consumed) {
        final hit = atk.attackType == AttackType.poisonPool
            ? atk.overlapsCircle(playerCenter, playerR)
            : atk.overlapsCircle(playerCenter, playerR);

        if (hit) {
          if (atk.attackType == AttackType.poisonPool) {
            // Pool deals damage repeatedly — don't consume it
            _player.takePoisonDamage(atk.damage);
          } else {
            atk.consumed = true;
            _player.takeDamage(atk.damage);
            _triggerScreenShake(0.2, 4.0);
            _eventController.add(RpgEvent.playerDamaged);
            add(HitParticle(position: playerCenter.clone()));
          }
          if (_player.isDead) {
            _phase = RpgGamePhase.gameOver;
            _eventController.add(RpgEvent.playerDeath);
            overlays.add('gameOver');
          }
        }
      }
    }

    // Remove consumed / expired attacks
    _attacks.removeWhere((a) => a.isRemoved || a.consumed);

    _updateHudTick(dt);
  }

  void _updateHudTick(double dt) {
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

  static dynamic _buildAi(BossId id) {
    switch (id) {
      case BossId.warden:
        return WardenAI();
      case BossId.shaman:
        return ShamanAI();
      case BossId.hollowKing:
        return HollowKingAI();
      case BossId.shadowlord:
        return ShadowlordAI();
    }
  }
}

/// Simple deterministic pseudo-random for shake (avoids dart:math Random allocation in hot path).
class _SimpleRng {
  _SimpleRng(this._seed);
  int _seed;
  double next() {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed & 0xFFFF) / 0xFFFF;
  }
}
