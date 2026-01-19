import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Direction { up, down, left, right }

enum GameMode { classic, wrap, speed }

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  static const int gridSize = 20;

  List<Offset> snake = [const Offset(5, 10)];
  Offset food = const Offset(10, 10);

  Direction currentDirection = Direction.right;
  Direction nextDirection = Direction.right;

  GameMode gameMode = GameMode.classic;

  Timer? timer;
  bool playing = true;
  int score = 0;

  Duration get tickRate {
    switch (gameMode) {
      case GameMode.speed:
        return const Duration(milliseconds: 120);
      case GameMode.wrap:
      case GameMode.classic:
        return const Duration(milliseconds: 200);
    }
  }

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    timer?.cancel();
    setState(() {
      snake = [const Offset(5, 10)];
      currentDirection = Direction.right;
      nextDirection = Direction.right;
      score = 0;
      playing = true;
      _spawnFood();
    });

    timer = Timer.periodic(tickRate, (_) {
      if (playing) _tick();
    });
  }

  void _spawnFood() {
    final rand = Random();
    Offset pos;
    do {
      pos = Offset(
        rand.nextInt(gridSize).toDouble(),
        rand.nextInt(gridSize).toDouble(),
      );
    } while (snake.contains(pos));
    food = pos;
  }

  void _tick() {
    setState(() {
      currentDirection = nextDirection;
      final head = snake.first;
      Offset next;

      switch (currentDirection) {
        case Direction.up:
          next = Offset(head.dx, head.dy - 1);
          break;
        case Direction.down:
          next = Offset(head.dx, head.dy + 1);
          break;
        case Direction.left:
          next = Offset(head.dx - 1, head.dy);
          break;
        case Direction.right:
          next = Offset(head.dx + 1, head.dy);
          break;
      }

      if (gameMode == GameMode.wrap) {
        next = Offset(
          (next.dx + gridSize) % gridSize,
          (next.dy + gridSize) % gridSize,
        );
      } else {
        if (next.dx < 0 ||
            next.dy < 0 ||
            next.dx >= gridSize ||
            next.dy >= gridSize) {
          _gameOver();
          return;
        }
      }

      if (snake.contains(next)) {
        _gameOver();
        return;
      }

      snake.insert(0, next);

      if (next == food) {
        score += 10;
        _spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void _gameOver() {
    playing = false;
    timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111317),
        title: const Text(
          'GAME OVER',
          style: TextStyle(color: Color(0xFF55ff00)),
        ),
        content: Text(
          'Score: $score',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('PLAY AGAIN'),
          ),
        ],
      ),
    );
  }

  void _changeDirection(Direction d) {
    if ((currentDirection == Direction.up && d == Direction.down) ||
        (currentDirection == Direction.down && d == Direction.up) ||
        (currentDirection == Direction.left && d == Direction.right) ||
        (currentDirection == Direction.right && d == Direction.left)) {
      return;
    }
    nextDirection = d;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _changeDirection(Direction.up);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _changeDirection(Direction.down);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _changeDirection(Direction.left);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _changeDirection(Direction.right);
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
                style: TextStyle(color: Color(0xFF55ff00), letterSpacing: 2),
              ),
              Text(
                'SCORE $score',
                style: const TextStyle(color: Color(0xFF00C2FF)),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<GameMode>(
              icon: const Icon(Icons.settings),
              onSelected: (m) {
                gameMode = m;
                _startGame();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: GameMode.classic, child: Text('Classic')),
                PopupMenuItem(value: GameMode.wrap, child: Text('Wrap Around')),
                PopupMenuItem(value: GameMode.speed, child: Text('Speed Mode')),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                          final cell = constraints.maxWidth / gridSize;
                          return Stack(
                            children: [
                              CustomPaint(
                                size: constraints.biggest,
                                painter: GridPainter(),
                              ),
                              ...snake.map(
                                (p) => Positioned(
                                  left: p.dx * cell,
                                  top: p.dy * cell,
                                  child: Container(
                                    width: cell,
                                    height: cell,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF55ff00),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: food.dx * cell,
                                top: food.dy * cell,
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
                          () => _changeDirection(Direction.up),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        left: 0,
                        child: _Arrow(
                          Icons.keyboard_arrow_left,
                          () => _changeDirection(Direction.left),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        left: 80,
                        child: _Arrow(
                          Icons.keyboard_arrow_down,
                          () => _changeDirection(Direction.down),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        left: 160,
                        child: _Arrow(
                          Icons.keyboard_arrow_right,
                          () => _changeDirection(Direction.right),
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
