import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:multigame/games/infinite_runner/infinite_runner_game.dart';
import 'package:multigame/games/infinite_runner/state/game_mode.dart';
import 'package:multigame/games/infinite_runner/ui/overlays.dart';
import 'package:multigame/games/infinite_runner/ui/race_overlays.dart';
import 'package:multigame/games/infinite_runner/widgets/race_hud.dart';

/// Page that hosts the Infinite Runner game
/// Pass [mode] to enable race mode (default: solo).
class InfiniteRunnerPage extends StatefulWidget {
  const InfiniteRunnerPage({super.key, this.mode = GameMode.solo});

  final GameMode mode;

  @override
  State<InfiniteRunnerPage> createState() => _InfiniteRunnerPageState();
}

class _InfiniteRunnerPageState extends State<InfiniteRunnerPage> {
  late final InfiniteRunnerGame _game;

  @override
  void initState() {
    super.initState();
    _game = InfiniteRunnerGame(gameMode: widget.mode);
    // Set landscape orientation for better gameplay
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<InfiniteRunnerGame>(
            game: _game,
            overlayBuilderMap: {
              'loading': (context, game) => const LoadingOverlay(),
              'idle': (context, game) => IdleOverlay(game: game),
              'hud': (context, game) => GameHud(game: game),
              'paused': (context, game) => PausedOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              // Race mode overlays
              'countdown': (context, game) => CountdownOverlay(game: game),
              'raceHud': (context, game) => RaceHud(game: game),
              'raceFinish': (context, game) => RaceFinishOverlay(game: game),
            },
            initialActiveOverlays: const ['loading'],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _game.onRemove();
    // Restore portrait orientation when leaving game
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
