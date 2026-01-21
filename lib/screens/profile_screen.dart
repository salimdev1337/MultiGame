import 'package:flutter/material.dart';
import 'package:multigame/services/achievement_service.dart';
import 'package:multigame/services/nickname_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AchievementService _achievementService = AchievementService();
  final NicknameService _nicknameService = NicknameService();
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _stats2048 = {};
  bool _isLoading = true;
  String _nickname = 'Puzzle Master';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final nickname = await _nicknameService.getNickname();
    setState(() {
      _nickname = nickname ?? 'Puzzle Master';
    });
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final stats = await _achievementService.getAllStats();
    final stats2048 = await _achievementService.get2048Stats();

    setState(() {
      _stats = stats;
      _stats2048 = stats2048;
      _isLoading = false;
    });
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '--';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: Theme.of(context).colorScheme.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Profile Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: (0.3 * 255)),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '\ud83c\udfae',
                                  style: TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _nickname,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_stats['totalCompleted'] ?? 0} Puzzles Completed',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 2048 Game Stats Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '2048 Game Stats',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _build2048StatCard(
                              title: '2048 Achievements',
                              icon: Icons.stars,
                              stats: [
                                _StatItem(
                                  label: 'Best Score',
                                  value: '${_stats2048['bestScore'] ?? 0}',
                                ),
                                _StatItem(
                                  label: 'Highest Tile',
                                  value: '${_stats2048['highestTile'] ?? 0}',
                                ),
                                _StatItem(
                                  label: 'Games Played',
                                  value: '${_stats2048['gamesPlayed'] ?? 0}',
                                ),
                                _StatItem(
                                  label: 'Last Level',
                                  value:
                                      _stats2048['lastLevelPassed']
                                          ?.toString() ??
                                      'None',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    // Achievements Badges
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    // Statistics Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Text(
                          'Puzzle Game Stats',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Best Times
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildStatCard(
                          title: 'Best Times',
                          icon: Icons.timer,
                          stats: [
                            _StatItem(
                              label: '3x3 Grid',
                              value: _formatTime(_stats['best3x3Time']),
                            ),
                            _StatItem(
                              label: '4x4 Grid',
                              value: _formatTime(_stats['best4x4Time']),
                            ),
                            _StatItem(
                              label: '5x5 Grid',
                              value: _formatTime(_stats['best5x5Time']),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    // Best Moves
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildStatCard(
                          title: 'Best Moves',
                          icon: Icons.trending_up,
                          stats: [
                            _StatItem(
                              label: '3x3 Grid',
                              value: _stats['best3x3Moves']?.toString() ?? '--',
                            ),
                            _StatItem(
                              label: '4x4 Grid',
                              value: _stats['best4x4Moves']?.toString() ?? '--',
                            ),
                            _StatItem(
                              label: '5x5 Grid',
                              value: _stats['best5x5Moves']?.toString() ?? '--',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required List<_StatItem> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: (0.3 * 255)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: (0.7 * 255)),
                    ),
                  ),
                  Text(
                    stat.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build2048StatCard({
    required String title,
    required IconData icon,
    required List<_StatItem> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1e26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF19e6a2).withValues(alpha: (0.3 * 255)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF19e6a2), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: (0.7 * 255)),
                    ),
                  ),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF19e6a2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem({required this.label, required this.value});
}
