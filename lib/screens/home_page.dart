import 'package:flutter/material.dart';
import 'package:puzzle/models/achievement_model.dart';
import 'package:puzzle/models/game_model.dart';
import 'package:puzzle/services/achievement_service.dart';
import 'package:puzzle/widgets/achievement_card.dart';
import 'package:puzzle/widgets/game_carousel.dart';

class HomePage extends StatefulWidget {
  final Function(GameModel) onGameSelected;

  const HomePage({super.key, required this.onGameSelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AchievementService _achievementService = AchievementService();
  List<AchievementModel> _achievements = [];
  bool _isLoading = true;
  int _totalCompleted = 0;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    final stats = await _achievementService.getAllStats();
    final unlockedStatus = await _achievementService.checkAchievements();

    _totalCompleted = stats['totalCompleted'] ?? 0;

    final achievements = AchievementModel.getAllAchievements(
      unlockedStatus: unlockedStatus,
      totalCompleted: _totalCompleted,
      best3x3Moves: stats['best3x3Moves'],
      best4x4Moves: stats['best4x4Moves'],
      bestTime: stats['bestOverallTime'],
    );

    setState(() {
      _achievements = achievements;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAchievements,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Welcome Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Puzzle Master',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '👑 $_totalCompleted',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Game Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: GameCarousel(onGameSelected: widget.onGameSelected),
                ),
              ),
              // Achievements Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    children: [
                      const Text(
                        'Your Achievements',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🏆',
                        style: TextStyle(
                          fontSize: 24,
                          shadows: [
                            Shadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Achievements List
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_achievements.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No achievements yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete puzzles to unlock achievements!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return AchievementCard(achievement: _achievements[index]);
                    }, childCount: _achievements.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
