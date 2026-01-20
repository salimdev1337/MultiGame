import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multigame/providers/user_auth_provider.dart';
import 'package:multigame/services/firebase_stats_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // final FirebaseStatsService _statsService = FirebaseStatsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Blur effects background
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 256,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 16),
                child: Text(
                  'Leaderboards',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3,
                  indicator: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF00F0FF), width: 3),
                    ),
                  ),
                  labelColor: const Color(0xFF00F0FF),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '2048'),
                    Tab(text: 'Puzzle'),
                    Tab(text: 'Snake'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    LeaderboardTab(gameType: '2048'),
                    LeaderboardTab(gameType: 'puzzle'),
                    LeaderboardTab(gameType: 'snake'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  final String gameType;

  const LeaderboardTab({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<UserAuthProvider>();
    final statsService = FirebaseStatsService();

    return StreamBuilder<List<LeaderboardEntry>>(
      stream: statsService.leaderboardStream(gameType: gameType, limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: const Color(0xFF00F0FF)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    (context as Element).markNeedsBuild();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 80,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No scores yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to play!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        // Find current user's rank
        final userRank = authProvider.userId != null
            ? entries.indexWhere((e) => e.userId == authProvider.userId) + 1
            : -1;

        return Column(
          children: [
            const SizedBox(height: 24),
            // User's rank card (neon style)
            if (authProvider.isSignedIn && userRank > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  children: [
                    // Neon border container
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00F0FF).withValues(alpha: 0.5),
                            const Color(0xFF00F0FF).withValues(alpha: 0.2),
                            const Color(0xFF00F0FF).withValues(alpha: 0.5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00F0FF,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            _buildRankBadge(userRank, isUser: true),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURRENT RANK',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.withValues(alpha: 0.7),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authProvider.displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  entries[userRank - 1].highScore.toString(),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00F0FF),
                                    shadows: [
                                      Shadow(
                                        color: const Color(
                                          0xFF00F0FF,
                                        ).withValues(alpha: 0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Top ${((userRank / entries.length) * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(
                                      0xFF00F0FF,
                                    ).withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Inner glow
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 2,
                            colors: [
                              const Color(0xFF00F0FF).withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            // Leaderboard list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final rank = index + 1;
                  final isCurrentUser = authProvider.userId == entry.userId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentUser
                            ? const Color(0xFF00F0FF).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      boxShadow: isCurrentUser
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF00F0FF,
                                ).withValues(alpha: 0.15),
                                blurRadius: 15,
                                spreadRadius: -3,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildRankBadge(rank, isUser: isCurrentUser),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                entry.highScore.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: rank <= 3
                                      ? _getRankColor(rank)
                                      : (isCurrentUser
                                            ? const Color(0xFF00F0FF)
                                            : Colors.white),
                                ),
                              ),
                              if (entry.lastUpdated != null)
                                Text(
                                  _formatDate(entry.lastUpdated!),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.withValues(alpha: 0.6),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildRankBadge(int rank, {bool isUser = false}) {
    // Gold, Silver, Bronze gradients
    Gradient? gradient;
    Color? solidColor;

    if (rank == 1) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
      );
    } else if (rank == 2) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
      );
    } else if (rank == 3) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
      );
    } else {
      solidColor = isUser ? const Color(0xFF00F0FF) : const Color(0xFF1a1a1d);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        color: solidColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: rank <= 3
              ? Colors.white.withValues(alpha: 0.3)
              : (isUser
                    ? const Color(0xFF00F0FF).withValues(alpha: 0.5)
                    : Colors.transparent),
          width: 2,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: _getRankColor(rank).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.black : Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
