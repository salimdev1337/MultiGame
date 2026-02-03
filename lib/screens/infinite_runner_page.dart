import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:multigame/games/infinite_runner/infinite_runner_game.dart';
import 'package:multigame/games/infinite_runner/ui/overlays.dart';

/// Page that hosts the Infinite Runner game
/// Integrates with the multigame app architecture
class InfiniteRunnerPage extends StatefulWidget {
  const InfiniteRunnerPage({super.key});

  @override
  State<InfiniteRunnerPage> createState() => _InfiniteRunnerPageState();
}

class _InfiniteRunnerPageState extends State<InfiniteRunnerPage> {
  late final InfiniteRunnerGame _game;

  @override
  void initState() {
    super.initState();
    _game = InfiniteRunnerGame();
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
