import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/games/snake/providers/snake_notifier.dart';

class SnakeGamePage extends ConsumerStatefulWidget {
  const SnakeGamePage({super.key});

  @override
  ConsumerState<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends ConsumerState<SnakeGamePage> {
  bool _gameOverDialogShowing = false;

  @override
  void initState() {
    super.initState();
  }

  void _showGameOverDialog(int score, bool isWin) {
    if (_gameOverDialogShowing) return;
    _gameOverDialogShowing = true;
    final notifier = ref.read(snakeProvider.notifier);
    final highScore = ref.read(snakeProvider).highScore;
    final gameMode = ref.read(snakeProvider).gameMode;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: const Color(0xFF17191c).withAlpha((0.6 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((0.05 * 255).toInt()),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.5 * 255).toInt()),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      const SizedBox(height: 8),
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (isWin
                                      ? const Color(0xFF55ff00)
                                      : const Color(0xFFBB2C2C))
                                  .withAlpha((0.1 * 255).toInt()),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isWin
                                          ? const Color(0xFF55ff00)
                                          : const Color(0xFFBB2C2C))
                                      .withAlpha((0.2 * 255).toInt()),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          isWin
                              ? Icons.emoji_events_outlined
                              : Icons.sentiment_very_dissatisfied_outlined,
                          size: 36,
                          color: isWin
                              ? const Color(0xFF55ff00)
                              : const Color(0xFFBB2C2C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        isWin ? 'YOU WIN!' : 'GAME OVER',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: isWin
                              ? const Color(0xFF55ff00)
                              : const Color(0xFFBB2C2C),
                          shadows: [
                            Shadow(
                              color:
                                  (isWin
                                          ? const Color(0xFF55ff00)
                                          : const Color(0xFFBB2C2C))
                                      .withAlpha((0.5 * 255).toInt()),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        isWin
                            ? 'Perfect run! Maximum score!'
                            : 'Your snake hit the wall!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 24),
                      // Stats Section
                      Row(
                        children: [
                          // Current Score
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(
                                  (0.05 * 255).toInt(),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha(
                                    (0.05 * 255).toInt(),
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'SCORE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    score.toString(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // High Score
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(
                                  (0.05 * 255).toInt(),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha(
                                    (0.05 * 255).toInt(),
                                  ),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'BEST',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color: const Color(
                                            0xFFf52900,
                                          ).withAlpha((0.8 * 255).toInt()),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        highScore.toString(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(
                                      Icons.emoji_events,
                                      size: 14,
                                      color: Colors.yellow.withAlpha(
                                        (0.5 * 255).toInt(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Separator
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withAlpha((0.1 * 255).toInt()),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons
                      // Try Again Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            notifier.startGame(); // start first so state is playing=true before pop
                            Navigator.of(dialogContext).pop(); // use dialog's own context
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFf52900),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(
                              0xFFf52900,
                            ).withAlpha((0.3 * 255).toInt()),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.replay, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Home Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(snakeProvider.notifier).reset();
                            Navigator.of(dialogContext).pop();
                            context.go(AppRoutes.home);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(
                                (0.4 * 255).toInt(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            gameMode == GameMode.classic
                                ? 'CLASSIC MODE'
                                : gameMode == GameMode.wrap
                                ? 'WRAP MODE'
                                : 'SPEED MODE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(
                                (0.4 * 255).toInt(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(
                                (0.4 * 255).toInt(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
          'NEON SNAKE',
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
                    color: const Color(0xFF55ff00).withAlpha((0.3 * 255).toInt()),
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
              'NEON SNAKE',
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
                onPressed: () =>
                    ref.read(snakeProvider.notifier).startGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF55ff00),
                  foregroundColor: const Color(0xFF111317),
                  elevation: 0,
                  shadowColor:
                      const Color(0xFF55ff00).withAlpha((0.4 * 255).toInt()),
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
    final state = ref.watch(snakeProvider);

    // Show game over dialog when the active game ends
    if (state.initialized && !state.playing && !_gameOverDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final isWin = state.score >= 100;
          _showGameOverDialog(state.score, isWin);
        }
      });
    }

    // Show start screen when game has not been started yet / was reset
    if (!state.initialized) {
      return _buildStartScreen();
    }

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            ref.read(snakeProvider.notifier).changeDirection(Direction.up);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            ref.read(snakeProvider.notifier).changeDirection(Direction.down);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            ref.read(snakeProvider.notifier).changeDirection(Direction.left);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            ref.read(snakeProvider.notifier).changeDirection(Direction.right);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111317),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111317),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NEON SNAKE',
                style: TextStyle(
                  color: Color(0xFF55ff00),
                  letterSpacing: 2,
                ),
              ),
              Text(
                'SCORE ${state.score}',
                style: const TextStyle(color: Color(0xFF00C2FF)),
              ),
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
        body: Column(
          children: [
            // 🎮 GAME AREA (FIXED HEIGHT)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0b0c0f),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(
                          0xFF55ff00,
                        ).withAlpha((0.2 * 255).toInt()),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF55ff00,
                          ).withAlpha((0.2 * 255).toInt()),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          final cell =
                              constraints.maxWidth /
                              SnakeState.gridSize;
                          return Stack(
                            children: [
                              CustomPaint(
                                size: constraints.biggest,
                                painter: GridPainter(),
                              ),
                              ...state.snake.map(
                                (p) => Positioned(
                                  left: p.dx * cell,
                                  top: p.dy * cell,
                                  child: Container(
                                    width: cell,
                                    height: cell,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF55ff00),
                                      borderRadius: BorderRadius.circular(
                                        4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: state.food.dx * cell,
                                top: state.food.dy * cell,
                                child: Container(
                                  width: cell,
                                  height: cell,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00C2FF),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ⬅⬆⬇➡ CONTROLS
            Expanded(
              flex: 2,
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 80,
                        child: _Arrow(
                          Icons.keyboard_arrow_up,
                          () => ref.read(snakeProvider.notifier).changeDirection(Direction.up),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        left: 0,
                        child: _Arrow(
                          Icons.keyboard_arrow_left,
                          () => ref.read(snakeProvider.notifier).changeDirection(Direction.left),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        left: 80,
                        child: _Arrow(
                          Icons.keyboard_arrow_down,
                          () => ref.read(snakeProvider.notifier).changeDirection(Direction.down),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        left: 160,
                        child: _Arrow(
                          Icons.keyboard_arrow_right,
                          () => ref.read(snakeProvider.notifier).changeDirection(Direction.right),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha((0.08 * 255).toInt()),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF55ff00).withAlpha((0.08 * 255).toInt())
      ..strokeWidth = 0.5;

    const grid = 20;
    final cellW = size.width / grid;
    final cellH = size.height / grid;

    for (int i = 0; i <= grid; i++) {
      canvas.drawLine(
        Offset(i * cellW, 0),
        Offset(i * cellW, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * cellH),
        Offset(size.width, i * cellH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
