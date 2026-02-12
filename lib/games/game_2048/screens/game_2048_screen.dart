import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/game_2048/providers/game_2048_notifier.dart';

class Game2048Page extends ConsumerStatefulWidget {
  const Game2048Page({super.key});

  @override
  ConsumerState<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends ConsumerState<Game2048Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

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
    _animationController.dispose();
    super.dispose();
  }

  void _move(String direction) {
    final moved = ref.read(game2048Provider.notifier).move(direction);

    if (moved) {
      _animationController.forward(from: 0);

      // Check if game is over
      if (ref.read(game2048Provider).gameOver) {
        // If user reached at least the minimum objective show win dialog
        if (ref.read(game2048Provider.notifier).hasReachedObjective()) {
          _showObjectiveCompleteDialog();
        } else {
          _showGameOverDialog();
        }
      }
    }
  }

  Future<void> _showGameOverDialog() async {
    final score = ref.read(game2048Provider).score;
    final notifier = ref.read(game2048Provider.notifier);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1e26),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: (0.1 * 255)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black..withValues(alpha: (0.5 * 255)),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Broken heart icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFff6b6b).withValues(alpha: (0.1 * 255)),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.heart_broken,
                  color: Color(0xFFff6b6b),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Message with score
              Column(
                children: [
                  Text(
                    'Tough luck! You reached a final score of',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score points',
                    style: const TextStyle(
                      color: Color(0xFFff6b6b),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Try Again Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    notifier.initializeGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff6b6b),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(
                      0xFFff6b6b,
                    ).withValues(alpha: (0.3 * 255)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.replay, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'TRY AGAIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    final notifier = ref.read(game2048Provider.notifier);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1e26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: const Color(0xFF19e6a2).withValues(alpha: (0.6 * 255)),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF19e6a2).withValues(alpha: (0.1 * 255)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              title: const Text(
                'Reset Game',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Start a new game',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: (0.6 * 255)),
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                notifier.initializeGame();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF19e6a2)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showObjectiveCompleteDialog() async {
    final notifier = ref.read(game2048Provider.notifier);
    final state = ref.read(game2048Provider);

    // Save achievement
    await notifier.recordGameCompletion();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1e26),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1 * 255),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3 * 255),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon with decorative elements
              SizedBox(
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF19e6a2,
                        ).withValues(alpha: (0.2 * 255)),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF19e6a2),
                        size: 48,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: 8,
                      child: Icon(
                        Icons.celebration,
                        color: const Color(0xFF0ea5e9),
                        size: 24,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 8,
                      child: Icon(
                        Icons.auto_awesome,
                        color: const Color(0xFFa855f7),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'YOU WIN!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Target '),
                    TextSpan(
                      text: '${state.currentObjective}',
                      style: const TextStyle(
                        color: Color(0xFF19e6a2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' reached!'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Next Level Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (state.currentObjectiveIndex <
                        Game2048State.objectives.length - 1) {
                      notifier.nextObjective();
                      notifier.initializeGame();
                    } else {
                      // All objectives complete, reset
                      notifier.resetObjective();
                      notifier.initializeGame();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19e6a2),
                    foregroundColor: const Color(0xFF101318),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(
                      0xFF19e6a2,
                    ).withValues(alpha: (0.3 * 255)),
                  ),
                  child: Text(
                    state.currentObjectiveIndex <
                            Game2048State.objectives.length - 1
                        ? 'NEXT LEVEL'
                        : 'RESTART',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 0:
        return const Color(0xFF101318).withValues(alpha: (0.4 * 255));
      case 2:
        return const Color(0xFF2d343f);
      case 4:
        return const Color(0xFF3e4a5b);
      case 8:
        return const Color(0xFF19e6a2);
      case 16:
        return const Color(0xFF14b8a6);
      case 32:
        return const Color(0xFF0ea5e9);
      case 64:
        return const Color(0xFF6366f1);
      case 128:
        return const Color(0xFFa855f7);
      case 256:
        return const Color(0xFFec4899);
      case 512:
        return const Color(0xFFf43f5e);
      case 1024:
        return const Color(0xFFf97316);
      case 2048:
        return const Color(0xFFeab308);
      default:
        return const Color(0xFF19e6a2);
    }
  }

  Color _getTextColor(int value) {
    if (value == 0) return Colors.transparent;
    if (value <= 4) return Colors.white.withValues(alpha: (0.9 * 255));
    return const Color(0xFF101318);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(game2048Provider);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _move('left');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _move('right');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _move('up');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _move('down');
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101318),
        body: SafeArea(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _move('right');
              } else if (details.primaryVelocity! < 0) {
                _move('left');
              }
            },
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _move('down');
              } else if (details.primaryVelocity! < 0) {
                _move('up');
              }
            },
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _showSettingsDialog,
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
                const SizedBox(height: 16),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Target Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1e26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(
                                alpha: (0.2 * 255),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TARGET',
                                style: TextStyle(
                                  color: Colors.grey.withValues(
                                    alpha: (0.7 * 255),
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: Color(0xFF19e6a2),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${state.currentObjective}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Score Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19e6a2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF19e6a2,
                                ).withValues(alpha: (0.2 * 255)),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SCORE',
                                style: TextStyle(
                                  color: const Color(
                                    0xFF101318,
                                  ).withValues(alpha: (0.6 * 255)),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.bolt,
                                    color: Color(0xFF101318),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${state.score}',
                                    style: const TextStyle(
                                      color: Color(0xFF101318),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Game Grid
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
                            int row = index ~/ 4;
                            int col = index % 4;
                            int value = state.grid[row][col];

                            return AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: value != 0
                                      ? 1.0 -
                                            (_animationController.value *
                                                0.1)
                                      : 1.0,
                                  child: child,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getTileColor(value),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: value >= 8 && value != 0
                                      ? [
                                          BoxShadow(
                                            color: _getTileColor(value)
                                                .withValues(
                                                  alpha: (0.4 * 255),
                                                ),
                                            blurRadius: value >= 512
                                                ? 20
                                                : 12,
                                            spreadRadius: value >= 512
                                                ? 2
                                                : 0,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: value != 0
                                      ? Text(
                                          '$value',
                                          style: TextStyle(
                                            fontSize: value >= 1024
                                                ? 20
                                                : value >= 128
                                                ? 24
                                                : 28,
                                            fontWeight: FontWeight.w800,
                                            color: _getTextColor(value),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
