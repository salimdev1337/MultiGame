// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:puzzle/game_logic.dart';
import 'package:puzzle/widgets/image_puzzle_piece.dart';
import 'package:puzzle/services/achievement_service.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage>
    with SingleTickerProviderStateMixin {
  late PuzzleGame game;
  int gridSize = 4;
  bool isLoading = true;
  bool isNewImageLoading = false;
  int moveCount = 0;
  int elapsedSeconds = 0;
  Timer? _timer;
  bool showImagePreview = false;
  late AnimationController _previewAnimationController;
  late Animation<double> _previewAnimation;
  final GlobalKey _hintButtonKey = GlobalKey();
  final AchievementService _achievementService = AchievementService();

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
    _initializeGame();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _previewAnimationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!game.isSolved) {
        setState(() {
          elapsedSeconds++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _initializeGame() async {
    setState(() {
      isLoading = true;
      moveCount = 0;
    });

    game = PuzzleGame(gridSize: gridSize);
    await game.loadPuzzleImages();
    _startTimer();

    setState(() => isLoading = false);

    // Show image preview after loading
    _showImagePreviewAnimation();
  }

  Future<void> _resetGame() async {
    setState(() {
      isNewImageLoading = false;
      moveCount = 0;
    });

    await game.loadPuzzleImages();
    _startTimer();
    _showImagePreviewAnimation();
    setState(() {});
  }

  Future<void> _newImageGame() async {
    setState(() {
      isNewImageLoading = true;
      moveCount = 0;
    });

    await game.loadNewPuzzle();
    _startTimer();
    _showImagePreviewAnimation();

    setState(() => isNewImageLoading = false);
  }

  Future<void> _changeGridSize(int newSize) async {
    setState(() {
      gridSize = newSize;
      isLoading = true;
      moveCount = 0;
    });

    game = PuzzleGame(gridSize: newSize);
    await game.loadPuzzleImages();
    _startTimer();
    _showImagePreviewAnimation();

    setState(() => isLoading = false);
  }

  void _showImagePreviewAnimation() {
    setState(() {
      showImagePreview = true;
    });
    _previewAnimationController.reset();

    // Wait 3 seconds, then animate to hint button
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _previewAnimationController.forward().then((_) {
          if (mounted) {
            setState(() {
              showImagePreview = false;
            });
          }
        });
      }
    });
  }

  void _showHintDialog() {
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
                      color: const Color(0xFF00d4ff).withOpacity(0.3),
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
    if (game.movePiece(position)) {
      setState(() {
        moveCount++;
      });

      if (game.isSolved) {
        _showWinDialog();
      }
    }
  }

  Future<void> _showWinDialog() async {
    _timer?.cancel();

    // Record game completion and check for achievements
    final newAchievements = await _achievementService.recordGameCompletion(
      gridSize: gridSize,
      moves: moveCount,
      seconds: elapsedSeconds,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                  '🎉 Puzzle Solved!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00d4ff),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16181d),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'MOVES',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$moveCount',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF00d4ff),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'TIME',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(elapsedSeconds),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF00d4ff),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (newAchievements.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFff5c00).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFff5c00).withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🏆', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              'New Achievement!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFff5c00),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...newAchievements.map(
                          (achievement) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              achievement,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Great job! You have successfully completed the puzzle. Play again',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogButton(
                        label: 'RESET',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetGame();
                        },
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildDialogButton(
                        label: 'PLAY AGAIN',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _newImageGame();
                        },
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFFff5c00) : const Color(0xFF16181d),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top App Bar
                _buildTopAppBar(),

                // Main Content
                Expanded(
                  child: isLoading
                      ? _buildLoadingScreen()
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                // Stats Section
                                _buildStatsSection(),
                                const SizedBox(height: 32),
                                // Puzzle Grid
                                _buildPuzzleGridContainer(),
                                const SizedBox(height: 32),
                                // Progress Section
                                _buildProgressSection(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                ),

                // Footer Controls
                _buildFooterControls(),
              ],
            ),

            // Image Preview Overlay
            if (showImagePreview) _buildImagePreviewOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181d).withValues(alpha: (0.8 * 255)),
      ),
      child: Row(
        children: [
          // Back Button
          _buildIconButton(Icons.arrow_back_ios_new, () {
            // Back action
          }),
          const SizedBox(width: 12),
          // Settings Button
          _buildIconButton(Icons.settings, () {
            _showGridSizeDialog();
          }),
          const Spacer(),
          // Level Title
          Text(
            'LEVEL ${gridSize * gridSize}',
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

  Widget _buildStatsSection() {
    return Row(
      children: [
        // Moves Card
        Expanded(child: _buildStatCard('MOVES', '$moveCount')),
        const SizedBox(width: 16),
        // Time Card
        Expanded(child: _buildStatCard('TIME', _formatTime(elapsedSeconds))),
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

  Widget _buildPuzzleGridContainer() {
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
        child: _buildPuzzleGrid(),
      ),
    );
  }

  Widget _buildPuzzleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the size for each piece based on available space
        // Subtract the total spacing from available width
        final totalSpacing = 10.0 * (gridSize - 1);
        final availableWidth = constraints.maxWidth - totalSpacing;
        final pieceSize = availableWidth / gridSize;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemCount: game.totalPieces,
          itemBuilder: (context, index) {
            final piece = game.pieces[index];
            return ImagePuzzlePiece(
              piece: piece,
              onTap: () => _movePiece(index),
              size: pieceSize,
            );
          },
        );
      },
    );
  }

  Widget _buildProgressSection() {
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
              '${(progress * 100)}%',
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

  Widget _buildFooterControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF21242b).withValues(alpha: (0.5 * 255)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: (0.05 * 255))),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (0.3 * 255)),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              label: 'RESET',
              onPressed: _resetGame,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildFooterButton(
              label: 'PLAY AGAIN',
              onPressed: _newImageGame,
              isPrimary: true,
              isLoading: isNewImageLoading,
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
          height: 64,
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
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGridSizeOption(3),
                    _buildGridSizeOption(4),
                    _buildGridSizeOption(5),
                  ],
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

  Widget _buildGridSizeOption(int size) {
    final isSelected = gridSize == size;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _changeGridSize(size);
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
                : Colors.white.withOpacity(0.1),
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

  Widget _buildLoadingScreen() {
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
                  color: const Color(0xFF00d4ff).withOpacity(0.4),
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
            'Grid: $gridSize×$gridSize',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewOverlay() {
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
      // Handle case where hint button is not yet rendered
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
                color: Colors.black.withOpacity(
                  0.8 * (1 - _previewAnimation.value),
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
                      ).withOpacity(currentOpacity),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF00d4ff,
                        ).withOpacity(0.5 * currentOpacity),
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
