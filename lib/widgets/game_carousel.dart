import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:multigame/models/game_model.dart';

class GameCarousel extends StatefulWidget {
  final Function(GameModel) onGameSelected;

  const GameCarousel({super.key, required this.onGameSelected});

  @override
  State<GameCarousel> createState() => _GameCarouselState();
}

class _GameCarouselState extends State<GameCarousel> {
  int _currentIndex = 0;
  final List<GameModel> _games = GameModel.getAvailableGames();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _games.length,
          itemBuilder: (context, index, realIndex) {
            final game = _games[index];
            return _buildGameCard(game);
          },
          options: CarouselOptions(
            height: 280,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            viewportFraction: 0.8,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _games.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == entry.key
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: (0.3 * 255)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGameCard(GameModel game) {
    return GestureDetector(
      onTap: () {
        if (game.isAvailable) {
          widget.onGameSelected(game);
        } else {
          _showComingSoonDialog(game);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: game.isAvailable
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: (0.3 * 255))
                  : Colors.black.withValues(alpha: (0.3 * 255)),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: game.isAvailable
                    ? Image.asset(
                        game.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Icon(
                              Icons.games,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: (0.5 * 255)),
                        child: Icon(
                          Icons.games,
                          size: 80,
                          color: Colors.grey.withValues(alpha: (0.5 * 255)),
                        ),
                      ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: (0.8 * 255)),
                      ],
                    ),
                  ),
                ),
              ),
              // How to Play button (top right)
              if (game.isAvailable)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      _showHowToPlayDialog(game);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              game.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!game.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(
                                  alpha: (0.9 * 255),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Coming Soon',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        game.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: (0.9 * 255)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: game.isAvailable
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          game.isAvailable ? 'Tap to Play' : 'Locked',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToPlayDialog(GameModel game) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF21242b),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'How to Play ${game.name}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _getGameInstructions(game),
                  ),
                ),
                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got It!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  List<Widget> _getGameInstructions(GameModel game) {
    List<Map<String, String>> instructions;

    switch (game.name) {
      case 'Puzzle':
        instructions = [
          {
            'emoji': '🎯',
            'text': 'Tap tiles next to the empty space to move them',
          },
          {'emoji': '🖼️', 'text': 'Arrange pieces to complete the image'},
          {'emoji': '⚙️', 'text': 'Use settings to change difficulty'},
        ];
        break;
      case '2048':
        instructions = [
          {'emoji': '⬆️', 'text': 'Swipe to move all tiles in that direction'},
          {'emoji': '➕', 'text': 'Same numbers merge and add up'},
          {'emoji': '🎯', 'text': 'Reach the target tile to win'},
        ];
        break;
      case 'Snake':
        instructions = [
          {'emoji': '🕹️', 'text': 'Use arrow keys or swipe to move'},
          {'emoji': '🍎', 'text': 'Eat food to grow and score points'},
          {'emoji': '💥', 'text': 'Don\'t hit walls or yourself'},
        ];
        break;
      case 'Sudoku':
        instructions = [
          {'emoji': '🔢', 'text': 'Fill the grid with numbers 1-9'},
          {'emoji': '✅', 'text': 'Each row, column, and box must have all digits'},
          {'emoji': '🎯', 'text': 'Choose Classic, Rush, or 1v1 mode'},
        ];
        break;
      default:
        instructions = [
          {'emoji': '🎮', 'text': 'Instructions coming soon!'},
        ];
    }

    return instructions.map((instruction) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(instruction['emoji']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                instruction['text']!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showComingSoonDialog(GameModel game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Coming Soon!'),
          ],
        ),
        content: Text(
          '${game.name} is not available yet. Stay tuned for updates!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
