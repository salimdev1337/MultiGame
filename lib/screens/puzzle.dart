import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multigame/games/puzzle/index.dart';
import 'package:multigame/widgets/image_puzzle_piece.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _previewAnimationController;
  late Animation<double> _previewAnimation;
  final GlobalKey _hintButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _previewAnimation = CurvedAnimation(
      parent: _previewAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // Initialize game after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameNotifier = context.read<PuzzleGameNotifier>();
      final uiNotifier = context.read<PuzzleUIProvider>();

      uiNotifier.setLoading(true);
      gameNotifier.initializeGame().then((_) {
        uiNotifier.setLoading(false);
        if (mounted) {
          _showImagePreviewAnimation();
        }
      });
    });
  }

  @override
  void dispose() {
    _previewAnimationController.dispose();
    super.dispose();
  }

  void _showImagePreviewAnimation() {
    final uiNotifier = context.read<PuzzleUIProvider>();
    uiNotifier.setShowImagePreview(true);
    _previewAnimationController.reset();

    // Wait 3 seconds, then animate to hint button
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _previewAnimationController.forward().then((_) {
          if (mounted) {
            uiNotifier.setShowImagePreview(false);
          }
        });
      }
    });
  }

  void _showHintDialog() {
    final notifier = context.read<PuzzleGameNotifier>();
    final game = notifier.game;
    if (game == null) return;

    final imageUrl = game.pieces.firstWhere((p) => p.imageUrl != null).imageUrl;
    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF21242b),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF00d4ff), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00d4ff).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Image Preview',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00d4ff),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              height: 300,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF00d4ff),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CLOSE',
                          style: TextStyle(
                            color: Color(0xFF00d4ff),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _movePiece(int position) {
    final notifier = context.read<PuzzleGameNotifier>();
    final wasSolved = notifier.game?.isSolved ?? false;

    if (notifier.movePiece(position)) {
      // Check if game is now solved
      if (!wasSolved && notifier.game?.isSolved == true) {
        _showWinDialog();
      }
    }
  }

  Future<void> _showWinDialog() async {
    final notifier = context.read<PuzzleGameNotifier>();
    notifier.stopTimer();

    // Record game completion and check for achievements
    final newAchievements = await notifier.recordGameCompletion();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          children: [
            // Backdrop blur overlay
            Positioned.fill(
              child: Container(color: const Color(0xFF0a0b0e).withValues(alpha: 0.6)),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF21242b).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon with gold glow
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFffd700).withValues(alpha: 0.1),
                            border: Border.all(
                              color: const Color(0xFFffd700).withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🏆', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'YOU SOLVED IT!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'MASTERPIECE COMPLETE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'MOVES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Consumer<PuzzleGameNotifier>(
                                      builder: (context, notifier, _) {
                                        return Text(
                                          '${notifier.moveCount}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'TIME',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Consumer<PuzzleGameNotifier>(
                                      builder: (context, notifier, _) {
                                        return Text(
                                          notifier.formatTime(
                                            notifier.elapsedSeconds,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Achievement badge (if any)
                        if (newAchievements.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFffd700).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    newAchievements.first,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFffd700),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Next Level button
                        Material(
                          color: const Color(0xFFff5c00),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              final gameNotifier = context
                                  .read<PuzzleGameNotifier>();
                              final uiNotifier = context
                                  .read<PuzzleUIProvider>();

                              uiNotifier.setNewImageLoading(true);
                              gameNotifier.newImageGame().then((_) {
                                uiNotifier.setNewImageLoading(false);
                                if (mounted) {
                                  _showImagePreviewAnimation();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: const Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF8B3000),
                                    width: 4,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFff5c00,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'NEXT LEVEL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Back to menu button
                        Material(
                          color: const Color(0xFF21242b),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              final gameNotifier = context
                                  .read<PuzzleGameNotifier>();
                              gameNotifier.resetGame().then((_) {
                                if (mounted) {
                                  _showImagePreviewAnimation();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: const Border(
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'BACK TO MENU',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PuzzleGameNotifier, PuzzleUIProvider>(
      builder: (context, gameNotifier, uiNotifier, _) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Top App Bar
                    _buildTopAppBar(gameNotifier),

                    // Main Content
                    Expanded(
                      child: uiNotifier.isLoading
                          ? _buildLoadingScreen(gameNotifier)
                          : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    // Stats Section
                                    _buildStatsSection(gameNotifier),
                                    const SizedBox(height: 32),
                                    // Puzzle Grid
                                    _buildPuzzleGridContainer(gameNotifier),
                                    const SizedBox(height: 32),
                                    // Progress Section
                                    _buildProgressSection(gameNotifier),
                                    const SizedBox(height: 24),
                                    // Footer Controls
                                    _buildFooterControls(gameNotifier, uiNotifier),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),

                // Image Preview Overlay
                if (uiNotifier.showImagePreview)
                  _buildImagePreviewOverlay(gameNotifier),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(PuzzleGameNotifier notifier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181d).withValues(alpha: (0.8 * 255)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Settings Button
          _buildIconButton(Icons.settings, () {
            _showGridSizeDialog();
          }),
          const Spacer(),
          // Level Title
          Text(
            'LEVEL ${notifier.gridSize * notifier.gridSize}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: const Color(0xFF21242b),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF00d4ff), size: 20),
        ),
      ),
    );
  }

  Widget _buildStatsSection(PuzzleGameNotifier notifier) {
    return Row(
      children: [
        // Moves Card
        Expanded(child: _buildStatCard('MOVES', '${notifier.moveCount}')),
        const SizedBox(width: 16),
        // Time Card
        Expanded(
          child: _buildStatCard(
            'TIME',
            notifier.formatTime(notifier.elapsedSeconds),
          ),
        ),
        const SizedBox(width: 16),
        // Hint Button
        _buildHintButton(),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21242b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: (0.05 * 255))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (0.2 * 255)),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00d4ff),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton() {
    return GestureDetector(
      key: _hintButtonKey,
      onTap: _showHintDialog,
      child: Container(
        width: 64,
        height: 87,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF21242b),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: (0.05 * 255)),
          ),
        ),
        child: const Icon(
          Icons.lightbulb_outline,
          color: Color(0xFF00d4ff),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildPuzzleGridContainer(PuzzleGameNotifier notifier) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF21242b),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: (0.05 * 255)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: (0.5 * 255)),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _buildPuzzleGrid(notifier),
      ),
    );
  }

  Widget _buildPuzzleGrid(PuzzleGameNotifier notifier) {
    final game = notifier.game;
    if (game == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the size for each piece based on available space
        // Subtract the total spacing from available width
        final totalSpacing = 10.0 * (notifier.gridSize - 1);
        final availableWidth = constraints.maxWidth - totalSpacing;
        final pieceSize = availableWidth / notifier.gridSize;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: notifier.gridSize,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemCount: game.totalPieces,
          itemBuilder: (context, index) {
            final piece = game.pieces[index];
            return ImagePuzzlePiece(
              piece: piece,
              index: index,
              onTap: () => _movePiece(index),
              size: pieceSize,
              onDragStart: (draggedIndex) {
                // Optional: Add feedback when drag starts
              },
              onDragEnd: (draggedIndex, targetIndex) {
                _handleDrop(draggedIndex, targetIndex);
              },
            );
          },
        );
      },
    );
  }

  void _handleDrop(int fromIndex, int toIndex) {
    final notifier = context.read<PuzzleGameNotifier>();
    final game = notifier.game;
    if (game == null) return;

    // Only allow dropping on the empty space
    if (game.pieces[toIndex].isEmpty) {
      final wasSolved = game.isSolved;
      if (notifier.movePiece(fromIndex)) {
        // Check if game is now solved
        if (!wasSolved && game.isSolved) {
          _showWinDialog();
        }
      }
    }
  }

  Widget _buildProgressSection(PuzzleGameNotifier notifier) {
    final game = notifier.game;
    if (game == null) return const SizedBox.shrink();

    final progress = game.completionPercentage;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00d4ff),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF21242b),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: (0.05 * 255)),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00d4ff), Color(0xFF00a8cc)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00d4ff,
                          ).withValues(alpha: (0.4 * 255)),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterControls(PuzzleGameNotifier gameNotifier, PuzzleUIProvider uiNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21242b).withValues(alpha: (0.5 * 255)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: (0.05 * 255))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (0.3 * 255)),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              label: 'RESET',
              onPressed: () {
                gameNotifier.resetGame().then((_) {
                  if (mounted) {
                    _showImagePreviewAnimation();
                  }
                });
              },
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildFooterButton(
              label: 'PLAY AGAIN',
              onPressed: () {
                uiNotifier.setNewImageLoading(true);
                gameNotifier.newImageGame().then((_) {
                  uiNotifier.setNewImageLoading(false);
                  if (mounted) {
                    _showImagePreviewAnimation();
                  }
                });
              },
              isPrimary: true,
              isLoading: uiNotifier.isNewImageLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFFff5c00) : const Color(0xFF16181d),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: isPrimary ? const Color(0xFF8B3000) : Colors.black,
                width: 4,
              ),
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showGridSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF21242b),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Grid Size',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00d4ff),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<PuzzleGameNotifier>(
                  builder: (context, notifier, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGridSizeOption(3, notifier),
                        _buildGridSizeOption(4, notifier),
                        _buildGridSizeOption(5, notifier),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Color(0xFF00d4ff)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridSizeOption(int size, PuzzleGameNotifier notifier) {
    final isSelected = notifier.gridSize == size;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        final uiNotifier = context.read<PuzzleUIProvider>();
        uiNotifier.setLoading(true);
        notifier.changeGridSize(size).then((_) {
          uiNotifier.setLoading(false);
          if (mounted) {
            _showImagePreviewAnimation();
          }
        });
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00d4ff) : const Color(0xFF16181d),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00d4ff)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$size×$size',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(PuzzleGameNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00d4ff), Color(0xFF00a8cc)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00d4ff).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading Puzzle...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00d4ff),
            ),
          ),
          const SizedBox(height: 8),
          const Text('🇹🇳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Grid: ${notifier.gridSize}×${notifier.gridSize}',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewOverlay(PuzzleGameNotifier notifier) {
    final game = notifier.game;
    if (game == null) return const SizedBox.shrink();

    final imageUrl = game.pieces.firstWhere((p) => p.imageUrl != null).imageUrl;
    if (imageUrl == null) return const SizedBox.shrink();

    // Get hint button position
    RenderBox? hintBox;
    Offset? hintPosition;
    Size? hintSize;

    try {
      hintBox = _hintButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (hintBox != null) {
        hintPosition = hintBox.localToGlobal(Offset.zero);
        hintSize = hintBox.size;
      }
    } catch (e) {
      hintPosition = null;
      hintSize = null;
    }

    return AnimatedBuilder(
      animation: _previewAnimation,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final isAnimating = _previewAnimation.value > 0;

        // Start position: center of screen with large size
        final startLeft = screenSize.width * 0.1;
        final startTop = screenSize.height * 0.2;
        final startWidth = screenSize.width * 0.8;
        final startHeight = screenSize.width * 0.8;

        // End position: hint button position
        final endLeft = hintPosition?.dx ?? screenSize.width - 100;
        final endTop = hintPosition?.dy ?? 150;
        final endWidth = hintSize?.width ?? 64;
        final endHeight = hintSize?.height ?? 64;

        // Interpolate
        final currentLeft =
            startLeft + (endLeft - startLeft) * _previewAnimation.value;
        final currentTop =
            startTop + (endTop - startTop) * _previewAnimation.value;
        final currentWidth =
            startWidth + (endWidth - startWidth) * _previewAnimation.value;
        final currentHeight =
            startHeight + (endHeight - startHeight) * _previewAnimation.value;
        final currentOpacity = 1.0 - (_previewAnimation.value * 0.7);
        // final currentBlur = _previewAnimation.value * 10;

        return Stack(
          children: [
            // Dark overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.8 * (1 - _previewAnimation.value),
                ),
              ),
            ),

            // Animated image
            Positioned(
              left: currentLeft,
              top: currentTop,
              child: IgnorePointer(
                ignoring: isAnimating,
                child: Container(
                  width: currentWidth,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      24 - (_previewAnimation.value * 8),
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFF00d4ff,
                      ).withValues(alpha: currentOpacity),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF00d4ff,
                        ).withValues(alpha: 0.5 * currentOpacity),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      22 - (_previewAnimation.value * 8),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF21242b),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF00d4ff),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Hint text (only show before animation)
            if (!isAnimating)
              Positioned(
                left: 0,
                right: 0,
                bottom: screenSize.height * 0.15,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21242b),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00d4ff),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'Memorize this image! 💡',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00d4ff),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
