import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/snake/providers/snake_notifier.dart';
import 'package:multigame/utils/navigation_utils.dart';
import 'package:multigame/games/snake/widgets/snake_animations.dart';
import 'package:multigame/games/snake/widgets/snake_board_widget.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';

const _kGameTitle = 'NEON SNAKE';

class SnakeGamePage extends ConsumerStatefulWidget {
  const SnakeGamePage({super.key});

  @override
  ConsumerState<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends ConsumerState<SnakeGamePage> {
  bool _gameOverDialogShowing = false;

  /// Stable FocusNode — created once, not on every build.
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _showQuitConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1d24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text(
          'Quit game?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'RESUME',
              style: TextStyle(
                color: Color(0xFF55ff00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              NavigationUtils.goHome(context);
            },
            child: Text(
              'QUIT',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(int score, bool isWin) {
    if (_gameOverDialogShowing) return;
    _gameOverDialogShowing = true;
    final notifier = ref.read(snakeProvider.notifier);
    final highScore = ref.read(snakeProvider).highScore;
    final gameMode = ref.read(snakeProvider).gameMode;
    final accentColor = isWin
        ? const Color(0xFF55ff00)
        : const Color(0xFFBB2C2C);

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: isWin,
        title: isWin ? 'YOU WIN!' : 'GAME OVER',
        titleStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
          color: accentColor,
          shadows: [
            Shadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 10),
          ],
        ),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Icon(
            isWin
                ? Icons.emoji_events_outlined
                : Icons.sentiment_very_dissatisfied_outlined,
            size: 36,
            color: accentColor,
          ),
        ),
        subtitle: Text(
          isWin ? 'Perfect run! Maximum score!' : 'Your snake hit the wall!',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        accentColor: accentColor,
        stats: [
          GameResultStat('SCORE', score.toString()),
          GameResultStat(
            'BEST',
            highScore.toString(),
            cardDecoration: Icon(
              Icons.emoji_events,
              size: 14,
              color: Colors.yellow.withValues(alpha: 0.5),
            ),
          ),
        ],
        statsLayout: GameResultStatsLayout.cards,
        primary: GameResultAction(
          label: 'Try Again',
          icon: Icons.replay,
          onTap: () {
            notifier.startGame();
            Navigator.of(context).pop();
          },
          style: GameResultButtonStyle.solid,
          color: const Color(0xFFf52900),
        ),
        secondary: GameResultAction(
          label: 'Home',
          icon: Icons.home_outlined,
          onTap: () {
            Navigator.of(context).pop();
            ref.read(snakeProvider.notifier).reset();
            NavigationUtils.goHome(context);
          },
          style: GameResultButtonStyle.outline,
        ),
        footer: _SnakeGameModeChip(gameMode: gameMode),
        presentation: GameResultPresentation.dialog,
        backdropBlur: true,
        containerBorderRadius: 16,
        containerColor: const Color(0xFF17191c).withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.all(24),
      ),
    ).then((_) {
      if (mounted) setState(() => _gameOverDialogShowing = false);
    });
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111317),
        title: const Text(
          _kGameTitle,
          style: TextStyle(color: Color(0xFF55ff00), letterSpacing: 2),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Snake icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF55ff00).withAlpha((0.1 * 255).toInt()),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF55ff00,
                    ).withAlpha((0.3 * 255).toInt()),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.videogame_asset_rounded,
                size: 40,
                color: Color(0xFF55ff00),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              _kGameTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: Color(0xFF55ff00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Eat. Grow. Survive.',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 2,
                color: Colors.white.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: () => ref.read(snakeProvider.notifier).startGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF55ff00),
                  foregroundColor: const Color(0xFF111317),
                  elevation: 0,
                  shadowColor: const Color(
                    0xFF55ff00,
                  ).withAlpha((0.4 * 255).toInt()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'START GAME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the flags that determine screen layout — NOT the full state.
    // Score, snake positions, food etc. are handled by isolated child widgets.
    final (initialized, playing) = ref.watch(
      snakeProvider.select((s) => (s.initialized, s.playing)),
    );

    // Show game over dialog when the active game ends.
    if (initialized && !playing && !_gameOverDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final state = ref.read(snakeProvider);
          final isWin = state.score >= 100;
          _showGameOverDialog(state.score, isWin);
        }
      });
    }

    // Show start screen when game has not been started yet / was reset.
    if (!initialized) {
      return _buildStartScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showQuitConfirmation();
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            final notifier = ref.read(snakeProvider.notifier);
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              notifier.changeDirection(Direction.up);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              notifier.changeDirection(Direction.down);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              notifier.changeDirection(Direction.left);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              notifier.changeDirection(Direction.right);
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF111317),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111317),
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _kGameTitle,
                  style: TextStyle(color: Color(0xFF55ff00), letterSpacing: 2),
                ),
                // Isolated widget — only rebuilds when score changes.
                _SnakeScoreDisplay(),
              ],
            ),
            actions: [
              PopupMenuButton<GameMode>(
                icon: const Icon(Icons.settings),
                onSelected: (m) {
                  ref.read(snakeProvider.notifier).setGameMode(m);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: GameMode.classic,
                    child: Text('Classic'),
                  ),
                  PopupMenuItem(
                    value: GameMode.wrap,
                    child: Text('Wrap Around'),
                  ),
                  PopupMenuItem(
                    value: GameMode.speed,
                    child: Text('Speed Mode'),
                  ),
                ],
              ),
            ],
          ),
          body: SnakeBackgroundAnimation(
            child: Column(
              children: [
                // ─── GAME BOARD ───────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanEnd: (details) {
                      final vel = details.velocity.pixelsPerSecond;
                      final absX = vel.dx.abs();
                      final absY = vel.dy.abs();
                      if (absX < 100 && absY < 100) {
                        return;
                      } // ignore micro-swipes
                      final notifier = ref.read(snakeProvider.notifier);
                      if (absX > absY) {
                        notifier.changeDirection(
                          vel.dx > 0 ? Direction.right : Direction.left,
                        );
                      } else {
                        notifier.changeDirection(
                          vel.dy > 0 ? Direction.down : Direction.up,
                        );
                      }
                    },
                    child: _SnakeBoardContainer(
                      isDead: initialized && !playing,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ─── D-PAD CONTROLS ───────────────────────────────────────
                const Expanded(flex: 2, child: _SnakeDPad()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolated score display — rebuilds only when score changes.
// ─────────────────────────────────────────────────────────────────────────────

class _SnakeScoreDisplay extends ConsumerWidget {
  const _SnakeScoreDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(snakeProvider.select((s) => s.score));
    return Text(
      'SCORE $score',
      style: const TextStyle(color: Color(0xFF00C2FF)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Board container — pure decoration, never rebuilds; wraps SnakeBoardWidget.
// ─────────────────────────────────────────────────────────────────────────────

class _SnakeBoardContainer extends StatelessWidget {
  const _SnakeBoardContainer({required this.isDead});

  final bool isDead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: DeathAnimation(
          trigger: isDead,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0b0c0f),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF55ff00).withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF55ff00).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // 60 FPS canvas-based board with position interpolation.
              child: const SnakeBoardWidget(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// D-pad controls — stateless, never needs to rebuild.
// ─────────────────────────────────────────────────────────────────────────────

class _SnakeDPad extends ConsumerWidget {
  const _SnakeDPad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(snakeProvider.notifier);
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 82,
              child: _Arrow(
                Icons.keyboard_arrow_up,
                () => notifier.changeDirection(Direction.up),
              ),
            ),
            Positioned(
              top: 82,
              left: 0,
              child: _Arrow(
                Icons.keyboard_arrow_left,
                () => notifier.changeDirection(Direction.left),
              ),
            ),
            Positioned(
              top: 164,
              left: 82,
              child: _Arrow(
                Icons.keyboard_arrow_down,
                () => notifier.changeDirection(Direction.down),
              ),
            ),
            Positioned(
              top: 82,
              left: 164,
              child: _Arrow(
                Icons.keyboard_arrow_right,
                () => notifier.changeDirection(Direction.right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SnakeGameModeChip extends StatelessWidget {
  final GameMode gameMode;

  const _SnakeGameModeChip({required this.gameMode});

  @override
  Widget build(BuildContext context) {
    final label = gameMode == GameMode.classic
        ? 'CLASSIC MODE'
        : gameMode == GameMode.wrap
        ? 'WRAP MODE'
        : 'SPEED MODE';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Arrow(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onTap(),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha((0.08 * 255).toInt()),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
