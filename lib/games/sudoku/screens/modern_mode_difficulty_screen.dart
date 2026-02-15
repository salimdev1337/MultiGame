// Mode/difficulty selection screen - see docs/SUDOKU_ARCHITECTURE.md

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _currentTab = 0;
  SudokuDifficulty? _selectedDifficulty;

  static const _difficulties = [
    _DifficultyData(
      difficulty: SudokuDifficulty.easy,
      name: 'Easy',
      description: '36–40 clues',
      icon: Icons.sentiment_satisfied,
      color: SudokuColors.easyColor,
    ),
    _DifficultyData(
      difficulty: SudokuDifficulty.medium,
      name: 'Medium',
      description: '32–35 clues',
      icon: Icons.sentiment_neutral,
      color: SudokuColors.mediumColor,
    ),
    _DifficultyData(
      difficulty: SudokuDifficulty.hard,
      name: 'Hard',
      description: '28–31 clues',
      icon: Icons.sentiment_dissatisfied,
      color: SudokuColors.hardColor,
    ),
    _DifficultyData(
      difficulty: SudokuDifficulty.expert,
      name: 'Expert',
      description: '24–27 clues',
      icon: Icons.whatshot,
      color: SudokuColors.expertColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
          _selectedDifficulty = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDifficultySelected(SudokuDifficulty difficulty) {
    setState(() => _selectedDifficulty = difficulty);
  }

  void _onStartGame() {
    if (_selectedDifficulty == null) return;

    Widget gameScreen;
    switch (_currentTab) {
      case 0:
        gameScreen = SudokuClassicScreen(difficulty: _selectedDifficulty!);
        break;
      case 1:
        gameScreen = SudokuRushScreen(difficulty: _selectedDifficulty!);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }

  void _onOnlineModeSelected() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SudokuOnlineMatchmakingScreen(),
      ),
    );
  }

  _ModeData get _currentMode => switch (_currentTab) {
    0 => const _ModeData(
      title: 'Classic',
      icon: Icons.grid_on,
      gradient: SudokuColors.classicGradient,
    ),
    1 => const _ModeData(
      title: 'Rush',
      icon: Icons.flash_on,
      gradient: SudokuColors.rushGradient,
    ),
    _ => const _ModeData(
      title: 'Online 1v1',
      icon: Icons.people,
      gradient: SudokuColors.onlineGradient,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final mode = _currentMode;
    final isOnline = _currentTab == 2;
    final canStart = _selectedDifficulty != null && !isOnline;

    return Scaffold(
      backgroundColor: SudokuColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: SudokuColors.surfaceDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'SUDOKU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Mode tabs
              _buildModeTabs(mode),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: isOnline
                    ? _buildOnlineCard()
                    : _buildDifficultyGrid(mode),
              ),

              const SizedBox(height: 12),

              // Start button
              _buildStartButton(mode, canStart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTabs(_ModeData mode) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: mode.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: mode.gradient[0].withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              const Tab(text: 'Classic'),
              const Tab(text: 'Rush'),
              Tab(
                child: Opacity(
                  opacity: 0.45,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text('Online'),
                      Positioned(
                        top: -10,
                        right: -20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Block touches on the Online tab (right third of the bar)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: constraints.maxWidth / 3,
                  child: const AbsorbPointer(child: SizedBox.expand()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyGrid(_ModeData mode) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: _difficulties.map((data) {
        final isSelected = _selectedDifficulty == data.difficulty;
        return _buildDifficultyCard(data: data, isSelected: isSelected);
      }).toList(),
    );
  }

  Widget _buildDifficultyCard({
    required _DifficultyData data,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onDifficultySelected(data.difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(
          isSelected ? 1.03 : 1.0,
          isSelected ? 1.03 : 1.0,
          1.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    data.color.withValues(alpha: isSelected ? 0.25 : 0.15),
                    data.color.withValues(alpha: isSelected ? 0.12 : 0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? data.color
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.color.withValues(
                      alpha: isSelected ? 0.45 : 0.15,
                    ),
                    blurRadius: isSelected ? 18 : 8,
                    spreadRadius: isSelected ? 1 : 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(data.icon, color: data.color, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.name,
                            style: TextStyle(
                              color: isSelected ? data.color : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: data.color, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineCard() {
    return Center(
      child: GestureDetector(
        onTap: _onOnlineModeSelected,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: SudokuColors.onlineGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: SudokuColors.onlineGradient[0].withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 18),
              const Text(
                'FIND MATCH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compete against players worldwide',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to find a match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(_ModeData mode, bool canStart) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canStart ? _onStartGame : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: canStart
                  ? LinearGradient(
                      colors: mode.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: canStart ? null : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: canStart
                  ? [
                      BoxShadow(
                        color: mode.gradient[0].withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    canStart ? 'START GAME' : 'SELECT DIFFICULTY',
                    style: TextStyle(
                      color: canStart
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (canStart) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyData {
  final SudokuDifficulty difficulty;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const _DifficultyData({
    required this.difficulty,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _ModeData {
  final String title;
  final IconData icon;
  final List<Color> gradient;

  const _ModeData({
    required this.title,
    required this.icon,
    required this.gradient,
  });
}
