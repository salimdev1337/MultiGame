import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/games/rpg/game/rpg_flame_game.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/providers/rpg_notifier.dart';
import 'package:multigame/games/rpg/widgets/boss_intro_overlay.dart';
import 'package:multigame/games/rpg/widgets/equipment_overlay.dart';
import 'package:multigame/games/rpg/widgets/level_up_overlay.dart';
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
    final bossId = rpgState.selectedBoss ?? BossId.warden;
    _game = RpgFlameGame(
      bossId: bossId,
      playerStats: rpgState.playerStats,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _listenToGameEvents();
  }

  void _listenToGameEvents() {
    _eventsSubscription = _game.events.listen((event) async {
      if (event == RpgEvent.bossDefeated && mounted) {
        final bossId = ref.read(rpgProvider).selectedBoss ?? BossId.warden;
        await ref.read(rpgProvider.notifier).onBossDefeated(bossId);
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
    final bossId = ref.read(rpgProvider).selectedBoss ?? BossId.warden;
    final config = BossConfig.forId(bossId);

    // Watch for level-up / equipment overlays
    final pendingLevelUp = ref.watch(rpgProvider.select((s) => s.pendingLevelUp));
    final pendingEquipment = ref.watch(rpgProvider.select((s) => s.pendingEquipment));
    final levelUpOptions = ref.watch(rpgProvider.select((s) => s.levelUpOptions));

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
                'victory': (ctx, game) => _VictoryScreen(
                  bossName: config.displayName,
                  onContinue: _showLevelUp,
                ),
                'gameOver': (ctx, game) => _GameOverScreen(
                  onRetry: _onRetry,
                  onQuit: _onQuit,
                ),
              },
              initialActiveOverlays: const ['intro'],
            ),

            // Controls
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
              child: ValueListenableBuilder<int>(
                valueListenable: _game.gameTick,
                builder: (_, value, child) => RpgActionButtons(
                  onAttack: _game.triggerAttack,
                  onDodge: _game.triggerDodge,
                  onUltimate: _game.triggerUltimate,
                  ultimateReady: _game.ultimateCharge >= 1.0,
                ),
              ),
            ),

            // Keyboard hint
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(child: _KeyboardHint()),
            ),

            // Level-up overlay (shown after boss death)
            if (pendingLevelUp && levelUpOptions.isNotEmpty)
              LevelUpOverlay(
                options: levelUpOptions,
                onSelected: (nodeId) {
                  ref.read(rpgProvider.notifier).selectLevelUpNode(nodeId);
                },
              ),

            // Equipment overlay (shown after level-up)
            if (!pendingLevelUp && pendingEquipment != null)
              EquipmentOverlay(
                equipment: pendingEquipment,
                onEquip: () {
                  ref.read(rpgProvider.notifier).equipPending();
                  _onVictory();
                },
                onSkip: () {
                  ref.read(rpgProvider.notifier).skipEquip();
                  _onVictory();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showLevelUp() {
    // Level-up overlay is driven by provider state — no manual trigger needed
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
        'Arrows: Move   X: Attack   Z/Space: Dodge   C: Ultimate',
        style: TextStyle(color: Colors.white38, fontSize: 10),
      ),
    );
  }
}

class _VictoryScreen extends StatelessWidget {
  const _VictoryScreen({required this.bossName, required this.onContinue});
  final String bossName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'BOSS DEFEATED',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bossName,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
              ),
              onPressed: onContinue,
              child: const Text(
                'CONTINUE',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverScreen extends StatelessWidget {
  const _GameOverScreen({required this.onRetry, required this.onQuit});
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
                      horizontal: 28,
                      vertical: 12,
                    ),
                  ),
                  onPressed: onRetry,
                  child: const Text('RETRY', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                  ),
                  onPressed: onQuit,
                  child: const Text('QUIT', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
