import 'package:flame/game.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/games/rpg/game/rpg_flame_game.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/providers/rpg_notifier.dart';
import 'package:multigame/games/rpg/widgets/boss_intro_overlay.dart';
import 'package:multigame/games/rpg/widgets/rpg_action_buttons.dart';
import 'package:multigame/games/rpg/widgets/rpg_hud.dart';
import 'package:multigame/games/rpg/widgets/rpg_joystick.dart';

class RpgGamePage extends ConsumerStatefulWidget {
  const RpgGamePage({super.key});

  @override
  ConsumerState<RpgGamePage> createState() => _RpgGamePageState();
}

class _RpgGamePageState extends ConsumerState<RpgGamePage> {
  late final RpgFlameGame _game;
  StreamSubscription<RpgEvent>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    final rpgState = ref.read(rpgProvider);
    final bossId = rpgState.selectedBoss ?? BossId.golem;
    _game = RpgFlameGame(
      bossId: bossId,
      playerStats: rpgState.playerStats,
      cycle: rpgState.cycle,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _listenToGameEvents();
  }

  void _listenToGameEvents() {
    _eventsSubscription = _game.events.listen((event) {
      if (event == RpgEvent.bossDefeated && mounted) {
        final bossId = ref.read(rpgProvider).selectedBoss ?? BossId.golem;
        ref.read(rpgProvider.notifier).onBossDefeated(bossId);
      }
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _game.onKeyDown(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _game.onKeyUp(event.logicalKey);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final bossId = ref.read(rpgProvider).selectedBoss ?? BossId.golem;
    final config = BossConfig.forId(bossId);

    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            GameWidget<RpgFlameGame>(
              game: _game,
              overlayBuilderMap: {
                'hud': (ctx, game) => RpgHud(game: game),
                'intro': (ctx, game) => BossIntroOverlay(
                  bossName: config.displayName,
                  onComplete: () {
                    game.startFight();
                    game.overlays.remove('intro');
                  },
                ),
                'victory': (ctx, game) =>
                    _VictoryOverlay(game: game, onContinue: _onVictory),
                'gameOver': (ctx, game) => _GameOverOverlay(
                  game: game,
                  onRetry: _onRetry,
                  onQuit: _onQuit,
                ),
              },
              initialActiveOverlays: const ['intro'],
            ),
            // Controls layer
            Positioned(
              bottom: 20,
              left: 20,
              child: RpgJoystick(
                onChanged: (dx, dy) => _game.setMovementInput(dx, dy),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Consumer(
                builder: (ctx, ref, _) {
                  final abilities = ref.watch(
                    rpgProvider.select((s) => s.playerStats.unlockedAbilities),
                  );
                  return RpgActionButtons(
                    unlockedAbilities: abilities,
                    onAttack: _game.triggerAttack,
                    onFireball: _game.triggerFireball,
                    onTimeSlow: _game.triggerTimeSlow,
                    onDodge: _game.triggerDodge,
                  );
                },
              ),
            ),
            // Keyboard hint overlay (desktop/web only)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: _KeyboardHint(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onVictory() {
    ref.read(rpgProvider.notifier).clearSelectedBoss();
    if (context.mounted) {
      context.go('/play/rpg/boss_select');
    }
  }

  void _onRetry() {
    if (context.mounted) {
      context.go('/play/rpg');
    }
  }

  void _onQuit() {
    ref.read(rpgProvider.notifier).clearSelectedBoss();
    if (context.mounted) {
      context.go('/play/rpg/boss_select');
    }
  }
}

class _KeyboardHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Arrows: Move   X: Attack   C: Fireball   Z/Space: Dodge   V: Time Slow',
        style: TextStyle(color: Colors.white54, fontSize: 10),
      ),
    );
  }
}

class _VictoryOverlay extends StatelessWidget {
  const _VictoryOverlay({required this.game, required this.onContinue});
  final RpgFlameGame game;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'BOSS DEFEATED!',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: onContinue,
              child: const Text(
                'CONTINUE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.game,
    required this.onRetry,
    required this.onQuit,
  });
  final RpgFlameGame game;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'YOU DIED',
              style: TextStyle(
                color: Color(0xFFCC2200),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC2200),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: onRetry,
                  child: const Text('RETRY', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: onQuit,
                  child: const Text('QUIT', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
