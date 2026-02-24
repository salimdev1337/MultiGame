import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/game_2048/providers/game_2048_notifier.dart';

import '../widgets/game_2048_dialogs.dart';
import '../widgets/game_2048_footer.dart';
import '../widgets/game_2048_hud.dart';
import '../widgets/game_2048_milestone_banner.dart';
import '../widgets/game_2048_tile.dart';

class Game2048Page extends ConsumerStatefulWidget {
  const Game2048Page({super.key});

  @override
  ConsumerState<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends ConsumerState<Game2048Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  OverlayEntry? _bannerEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _bannerEntry?.remove();
    _bannerEntry = null;
    _animationController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _move('left');
      case LogicalKeyboardKey.arrowRight:
        _move('right');
      case LogicalKeyboardKey.arrowUp:
        _move('up');
      case LogicalKeyboardKey.arrowDown:
        _move('down');
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _onHorizontalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity == null) return;
    if (velocity > 0) {
      _move('right');
    } else if (velocity < 0) {
      _move('left');
    }
  }

  void _onVerticalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity == null) return;
    if (velocity > 0) {
      _move('down');
    } else if (velocity < 0) {
      _move('up');
    }
  }

  void _move(String direction) {
    final prevState = ref.read(game2048Provider);
    final moved = ref.read(game2048Provider.notifier).move(direction);

    if (moved) {
      _animationController.forward(from: 0);
      final newState = ref.read(game2048Provider);

      if (newState.gameOver) {
        _showGameOver(newState);
      } else if (newState.highestMilestoneIndex > prevState.highestMilestoneIndex) {
        _showMilestoneBanner(newState.highestMilestoneIndex);
      }
    }
  }

  void _showMilestoneBanner(int milestoneIndex) {
    _bannerEntry?.remove();
    _bannerEntry = null;

    final tile = Game2048State.milestones[milestoneIndex];
    final label = Game2048State.milestoneLabels[milestoneIndex];

    _bannerEntry = OverlayEntry(
      builder: (context) => Game2048MilestoneBanner(
        tile: tile,
        label: label,
        onDismissed: () {
          _bannerEntry?.remove();
          _bannerEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_bannerEntry!);
  }

  Future<void> _showGameOver(Game2048State state) async {
    await showGame2048GameOverDialog(
      context,
      state: state,
      notifier: ref.read(game2048Provider.notifier),
    );
  }

  void _showSettings() {
    showGame2048SettingsDialog(
      context,
      notifier: ref.read(game2048Provider.notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(game2048Provider);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: const Color(0xFF101318),
        body: SafeArea(
          child: GestureDetector(
            onHorizontalDragEnd: _onHorizontalDrag,
            onVerticalDragEnd: _onVerticalDrag,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _showSettings,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1e26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const Text(
                        '2048 Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Game2048Hud(state: state),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1e26),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: 16,
                          itemBuilder: (context, index) {
                            final value = state.grid[index ~/ 4][index % 4];
                            return Game2048Tile(
                              value: value,
                              animController: _animationController,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Game2048Footer(
                  onReset: () =>
                      ref.read(game2048Provider.notifier).initializeGame(),
                  onMainMenu: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
