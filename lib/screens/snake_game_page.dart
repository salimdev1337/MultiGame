import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:multigame/providers/snake_game_provider.dart';

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  @override
  void initState() {
    super.initState();
    // Start the game when the page is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SnakeGameProvider>();
      if (!provider.initialized) {
        provider.startGame();
      }
    });
  }

  void _showGameOverDialog(int score, bool isWin) {
    final provider = context.read<SnakeGameProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
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
                                        provider.highScore.toString(),
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
                            Navigator.pop(context);
                            provider.startGame();
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.replay, size: 24),
                              const SizedBox(width: 8),
                              const Text(
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
                      // Main Menu Button
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
                            provider.gameMode == GameMode.classic
                                ? 'CLASSIC MODE'
                                : provider.gameMode == GameMode.wrap
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SnakeGameProvider>(
      builder: (context, provider, child) {
        // Check if game is over and show dialog
        // Only show dialog if game was initialized and is no longer playing
        if (provider.initialized && !provider.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Check if it's a win (you can customize this condition)
            final isWin = provider.score >= 100; // Win condition example
            _showGameOverDialog(provider.score, isWin);
          });
        }

        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                provider.changeDirection(Direction.up);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                provider.changeDirection(Direction.down);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                provider.changeDirection(Direction.left);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                provider.changeDirection(Direction.right);
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
                    'SCORE ${provider.score}',
                    style: const TextStyle(color: Color(0xFF00C2FF)),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<GameMode>(
                  icon: const Icon(Icons.settings),
                  onSelected: (m) {
                    provider.setGameMode(m);
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
                                  SnakeGameProvider.gridSize;
                              return Stack(
                                children: [
                                  CustomPaint(
                                    size: constraints.biggest,
                                    painter: GridPainter(),
                                  ),
                                  ...provider.snake.map(
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
                                    left: provider.food.dx * cell,
                                    top: provider.food.dy * cell,
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
                              () => provider.changeDirection(Direction.up),
                            ),
                          ),
                          Positioned(
                            top: 80,
                            left: 0,
                            child: _Arrow(
                              Icons.keyboard_arrow_left,
                              () => provider.changeDirection(Direction.left),
                            ),
                          ),
                          Positioned(
                            top: 80,
                            left: 80,
                            child: _Arrow(
                              Icons.keyboard_arrow_down,
                              () => provider.changeDirection(Direction.down),
                            ),
                          ),
                          Positioned(
                            top: 80,
                            left: 160,
                            child: _Arrow(
                              Icons.keyboard_arrow_right,
                              () => provider.changeDirection(Direction.right),
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
      },
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
