import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/sudoku_colors.dart';
import '../logic/sudoku_generator.dart';
import 'sudoku_classic_screen.dart';
import 'sudoku_rush_screen.dart';
import 'sudoku_online_matchmaking_screen.dart';

class ModernModeDifficultyScreen extends StatefulWidget {
  const ModernModeDifficultyScreen({super.key});

  @override
  State<ModernModeDifficultyScreen> createState() =>
      _ModernModeDifficultyScreenState();
}

class _ModernModeDifficultyScreenState extends State<ModernModeDifficultyScreen>
    with TickerProviderStateMixin {

  // Controllers
  late PageController _pageController;
  late AnimationController _buttonAnimationController;
  late Animation<Offset> _buttonSlideAnimation;

  // State
  int _currentPage = 0;
  SudokuDifficulty? _selectedDifficulty;
  bool _isOnlinePage = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  /// Handle page change
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _selectedDifficulty = null; // Clear selection on page change
      _isOnlinePage = page == 2; // Online is page 2

      // Hide button when changing pages
      _buttonAnimationController.reverse();
    });
  }

  /// Handle difficulty card selection
  void _onDifficultySelected(SudokuDifficulty difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
      // Show button
      _buttonAnimationController.forward();
    });
  }

  /// Handle online mode selection (no difficulty needed)
  void _onOnlineModeSelected() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SudokuOnlineMatchmakingScreen(),
      ),
    );
  }

  /// Handle start game button press
  void _onStartGame() {
    if (_selectedDifficulty == null) return;

    final difficulty = _selectedDifficulty!;
    Widget gameScreen;

    switch (_currentPage) {
      case 0: // Classic
        gameScreen = SudokuClassicScreen(difficulty: difficulty);
        break;
      case 1: // Rush
        gameScreen = SudokuRushScreen(difficulty: difficulty);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SudokuColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: SudokuColors.surfaceDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SUDOKU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),

                // Animated mode header
                _buildModeHeader(),

                const SizedBox(height: 24),

                // Carousel with pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildClassicPage(),
                      _buildRushPage(),
                      _buildOnlinePage(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Page indicators
                _buildPageIndicator(),

                const SizedBox(height: 80), // Space for button
              ],
            ),

            // Animated start button
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  /// Builds animated mode header
  Widget _buildModeHeader() {
    final modeData = _getModeData(_currentPage);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: modeData.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: modeData.gradient[0].withValues(alpha: 0.3 * 255),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              modeData.icon,
              key: ValueKey(_currentPage),
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              modeData.title,
              key: ValueKey(_currentPage),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds Classic mode page with difficulty grid
  Widget _buildClassicPage() {
    return _buildDifficultyGrid(
      difficulties: [
        _DifficultyData(
          difficulty: SudokuDifficulty.easy,
          name: 'EASY',
          description: '36-40 clues',
          icon: Icons.sentiment_satisfied,
          color: SudokuColors.easyColor,
        ),
        _DifficultyData(
          difficulty: SudokuDifficulty.medium,
          name: 'MEDIUM',
          description: '32-35 clues',
          icon: Icons.sentiment_neutral,
          color: SudokuColors.mediumColor,
        ),
        _DifficultyData(
          difficulty: SudokuDifficulty.hard,
          name: 'HARD',
          description: '28-31 clues',
          icon: Icons.sentiment_dissatisfied,
          color: SudokuColors.hardColor,
        ),
        _DifficultyData(
          difficulty: SudokuDifficulty.expert,
          name: 'EXPERT',
          description: '24-27 clues',
          icon: Icons.whatshot,
          color: SudokuColors.expertColor,
        ),
      ],
    );
  }

  /// Builds Rush mode page with difficulty grid
  Widget _buildRushPage() {
    return _buildDifficultyGrid(
      difficulties: [
        _DifficultyData(
          difficulty: SudokuDifficulty.easy,
          name: 'EASY',
          description: '36-40 clues',
          icon: Icons.sentiment_satisfied,
          color: SudokuColors.easyColor,
        ),
        _DifficultyData(
          difficulty: SudokuDifficulty.medium,
          name: 'MEDIUM',
          description: '32-35 clues',
          icon: Icons.sentiment_neutral,
          color: SudokuColors.mediumColor,
        ),
        _DifficultyData(
          difficulty: SudokuDifficulty.hard,
          name: 'HARD',
          description: '28-31 clues',
          icon: Icons.sentiment_dissatisfied,
          color: SudokuColors.hardColor,
        ),
        _DifficultyData(
          difficulty: SudokuDifficulty.expert,
          name: 'EXPERT',
          description: '24-27 clues',
          icon: Icons.whatshot,
          color: SudokuColors.expertColor,
        ),
      ],
    );
  }

  /// Builds Online mode page with single "Find Match" card
  Widget _buildOnlinePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GestureDetector(
          onTap: _onOnlineModeSelected,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: SudokuColors.onlineGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3 * 255),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: SudokuColors.onlineGradient[0].withValues(alpha: 0.4 * 255),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2 * 255),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'FIND MATCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Compete against players worldwide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9 * 255),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds difficulty selection grid (2x2)
  Widget _buildDifficultyGrid({required List<_DifficultyData> difficulties}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: difficulties.length,
        itemBuilder: (context, index) {
          final data = difficulties[index];
          final isSelected = _selectedDifficulty == data.difficulty;

          return _buildDifficultyCard(
            data: data,
            isSelected: isSelected,
            onTap: () => _onDifficultySelected(data.difficulty),
          );
        },
      ),
    );
  }

  /// Builds individual difficulty card with glassmorphism
  Widget _buildDifficultyCard({
    required _DifficultyData data,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(
          isSelected ? 1.05 : 1.0,
          isSelected ? 1.05 : 1.0,
          1.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    data.color.withValues(alpha: 0.2 * 255),
                    data.color.withValues(alpha: 0.1 * 255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? data.color
                      : Colors.white.withValues(alpha: 0.2 * 255),
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? data.color.withValues(alpha: 0.5 * 255)
                        : data.color.withValues(alpha: 0.2 * 255),
                    blurRadius: isSelected ? 25 : 12,
                    spreadRadius: isSelected ? 3 : 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.25 * 255),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data.icon,
                        color: data.color,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Difficulty name
                    Text(
                      data.name,
                      style: TextStyle(
                        color: isSelected ? data.color : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      data.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7 * 255),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds page indicator dots
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive
                ? _getModeData(_currentPage).gradient[0]
                : Colors.white.withValues(alpha: 0.3 * 255),
            borderRadius: BorderRadius.circular(5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _getModeData(_currentPage)
                          .gradient[0]
                          .withValues(alpha: 0.5 * 255),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }

  /// Builds animated start button
  Widget _buildStartButton() {
    final canStart = _selectedDifficulty != null && !_isOnlinePage;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _buttonSlideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SudokuColors.surfaceDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3 * 255),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canStart ? _onStartGame : null,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: canStart
                        ? LinearGradient(
                            colors: _getModeData(_currentPage).gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canStart ? null : Colors.grey.withValues(alpha: 0.3 * 255),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canStart
                        ? [
                            BoxShadow(
                              color: _getModeData(_currentPage)
                                  .gradient[0]
                                  .withValues(alpha: 0.4 * 255),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'START GAME',
                          style: TextStyle(
                            color: canStart
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5 * 255),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward,
                          color: canStart
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5 * 255),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get mode data for current page
  _ModeData _getModeData(int page) {
    switch (page) {
      case 0:
        return _ModeData(
          title: 'CLASSIC MODE',
          icon: Icons.grid_on,
          gradient: SudokuColors.classicGradient,
        );
      case 1:
        return _ModeData(
          title: 'RUSH MODE',
          icon: Icons.flash_on,
          gradient: SudokuColors.rushGradient,
        );
      case 2:
        return _ModeData(
          title: 'ONLINE 1v1',
          icon: Icons.people,
          gradient: SudokuColors.onlineGradient,
        );
      default:
        return _ModeData(
          title: 'CLASSIC MODE',
          icon: Icons.grid_on,
          gradient: SudokuColors.classicGradient,
        );
    }
  }
}

/// Data class for difficulty information
class _DifficultyData {
  final SudokuDifficulty difficulty;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  _DifficultyData({
    required this.difficulty,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Data class for mode information
class _ModeData {
  final String title;
  final IconData icon;
  final List<Color> gradient;

  _ModeData({
    required this.title,
    required this.icon,
    required this.gradient,
  });
}
