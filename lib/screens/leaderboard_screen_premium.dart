import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/user_auth_notifier.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/services/data/rank_history_service.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/widgets/shared/premium_leaderboard_widgets.dart';
import 'package:multigame/games/sudoku/screens/sudoku_online_matchmaking_screen.dart';

/// Phase 5: Premium Leaderboard Screen
///
/// Features:
/// - Top 3 podium display with 3D elevation
/// - Animated crown for #1 player
/// - Trophy icons with shimmer effect
/// - Time period selector (Daily, Weekly, All-Time)
/// - Pull-to-refresh with custom animation
/// - Sticky rank card at bottom with rank change indicator
/// - Smooth animations and transitions

class LeaderboardScreenPremium extends StatefulWidget {
  const LeaderboardScreenPremium({super.key});

  @override
  State<LeaderboardScreenPremium> createState() =>
      _LeaderboardScreenPremiumState();
}

class _LeaderboardScreenPremiumState extends State<LeaderboardScreenPremium>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimePeriod _selectedPeriod = TimePeriod.allTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.backgroundTertiary,
      body: Stack(
        children: [
          // Background blur effects
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 256,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    DSColors.primary.withValues(alpha: 0.1),
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
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 8,
                ),
                child: Text(
                  'Leaderboards',
                  style: DSTypography.displaySmall.copyWith(
                    color: DSColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    shadows: DSShadows.textShadowGlow(DSColors.primary),
                  ),
                ),
              ),
              // Time period selector
              TimePeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
              ),
              SizedBox(height: DSSpacing.sm),
              // Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: DSSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: DSColors.textTertiary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3,
                  indicator: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: DSColors.primary, width: 3),
                    ),
                  ),
                  labelColor: DSColors.primary,
                  unselectedLabelColor: DSColors.textSecondary,
                  labelStyle: DSTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: DSTypography.labelLarge,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Sudoku'),
                    Tab(text: '2048'),
                    Tab(text: 'Puzzle'),
                    Tab(text: 'Snake'),
                    Tab(text: 'Runner'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    LeaderboardTab(gameType: 'sudoku'),
                    LeaderboardTab(gameType: '2048'),
                    LeaderboardTab(gameType: 'puzzle'),
                    LeaderboardTab(gameType: 'snake'),
                    LeaderboardTab(gameType: 'infinite_runner'),
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

class LeaderboardTab extends ConsumerStatefulWidget {
  final String gameType;

  const LeaderboardTab({super.key, required this.gameType});

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab> {
  late final FirebaseStatsService _statsService;
  final RankHistoryService _rankHistoryService = RankHistoryService();
  int? _previousRank;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _statsService = FirebaseStatsService();
  }

  /// Track rank changes and load previous rank
  Future<void> _trackRankChange({
    required String userId,
    required int currentRank,
    required int totalPlayers,
  }) async {
    // Load previous rank
    final prevRank = await _rankHistoryService.getPreviousRank(
      gameType: widget.gameType,
      userId: userId,
    );

    // Save current rank snapshot
    await _rankHistoryService.saveRankSnapshot(
      gameType: widget.gameType,
      userId: userId,
      currentRank: currentRank,
      totalPlayers: totalPlayers,
    );

    // Update state with previous rank
    if (mounted && prevRank != _previousRank) {
      setState(() {
        _previousRank = prevRank;
      });
    }
  }

  /// Handle challenge/multiplayer mode navigation
  void _handleChallengeTap(BuildContext context) {
    // Map gameType to game-specific logic
    switch (widget.gameType) {
      case 'sudoku':
        // Navigate to Sudoku online matchmaking
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SudokuOnlineMatchmakingScreen(),
          ),
        );
        break;
      case '2048':
      case 'puzzle':
      case 'snake':
      case 'infinite_runner':
        // Show coming soon message for games without multiplayer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Multiplayer mode coming soon for ${_getGameName(widget.gameType)}!',
            ),
            backgroundColor: DSColors.info,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: 100,
              left: DSSpacing.md,
              right: DSSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: DSSpacing.borderRadiusLG,
            ),
          ),
        );
        break;
      default:
        // Fallback for unknown game types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Challenge mode coming soon!'),
            backgroundColor: DSColors.info,
          ),
        );
    }
  }

  /// Get user-friendly game name
  String _getGameName(String gameType) {
    switch (gameType) {
      case 'sudoku':
        return 'Sudoku';
      case '2048':
        return '2048';
      case 'puzzle':
        return 'Puzzle';
      case 'snake':
        return 'Snake';
      case 'infinite_runner':
        return 'Runner';
      default:
        return gameType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = ref.watch(userAuthProvider);

    return StreamBuilder<List<LeaderboardEntry>>(
      key: ValueKey(_refreshKey),
      stream: _statsService.leaderboardStream(
        gameType: widget.gameType,
        limit: 100,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: DSColors.primary,
              strokeWidth: 3,
            ),
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
                  color: DSColors.error.withValues(alpha: 0.7),
                ),
                SizedBox(height: DSSpacing.sm),
                Text(
                  'Error loading leaderboard',
                  style: DSTypography.titleMedium.copyWith(
                    color: DSColors.textSecondary,
                  ),
                ),
                SizedBox(height: DSSpacing.xs),
                Text(
                  snapshot.error.toString(),
                  style: DSTypography.bodySmall.copyWith(
                    color: DSColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DSSpacing.md),
                ElevatedButton(
                  onPressed: () => setState(() => _refreshKey++),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.primary,
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
                  color: DSColors.textTertiary.withValues(alpha: 0.3),
                ),
                SizedBox(height: DSSpacing.md),
                Text(
                  'No scores yet',
                  style: DSTypography.titleLarge.copyWith(
                    color: DSColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: DSSpacing.xs),
                Text(
                  'Be the first to play!',
                  style: DSTypography.bodyMedium.copyWith(
                    color: DSColors.textTertiary,
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

        // Track rank changes and load previous rank
        if (authProvider.userId != null && userRank > 0) {
          _trackRankChange(
            userId: authProvider.userId!,
            currentRank: userRank,
            totalPlayers: entries.length,
          );
        }

        // Get top 3 for podium
        final topThree = entries.take(3).toList();

        return Stack(
          children: [
            CustomRefreshIndicator(
              onRefresh: () async {
                setState(() => _refreshKey++);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  // Podium display
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: DSSpacing.md),
                      child: PodiumDisplay(
                        topThree: topThree,
                        currentUserId: authProvider.userId,
                      ),
                    ),
                  ),
                  // Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DSSpacing.md,
                        vertical: DSSpacing.sm,
                      ),
                      child: Text(
                        'All Rankings',
                        style: DSTypography.titleMedium.copyWith(
                          color: DSColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Leaderboard list
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: DSSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = entries[index];
                        final rank = index + 1;
                        final isCurrentUser =
                            authProvider.userId == entry.userId;

                        return _LeaderboardListItem(
                          entry: entry,
                          rank: rank,
                          isCurrentUser: isCurrentUser,
                        );
                      }, childCount: entries.length),
                    ),
                  ),
                  // Bottom padding for sticky rank card
                  SliverToBoxAdapter(
                    child: SizedBox(height: DSSpacing.xxxxl * 2),
                  ),
                ],
              ),
            ),
            // Sticky rank card at bottom
            if (authProvider.isSignedIn && userRank > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: StickyRankCard(
                  currentRank: userRank,
                  previousRank: _previousRank,
                  displayName: authProvider.displayName,
                  score: entries[userRank - 1].highScore,
                  totalPlayers: entries.length,
                  onChallengeTap: () => _handleChallengeTap(context),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LeaderboardListItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const _LeaderboardListItem({
    required this.entry,
    required this.rank,
    required this.isCurrentUser,
  });

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return DSColors.textPrimary;
    }
  }

  Widget _buildRankBadge(int rank) {
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
      solidColor = isCurrentUser ? DSColors.primary : DSColors.surface;
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
              : (isCurrentUser
                    ? DSColors.primary.withValues(alpha: 0.5)
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
          style: DSTypography.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.black : DSColors.textPrimary,
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: DSSpacing.sm),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSSpacing.borderRadiusLG,
        border: Border.all(
          color: isCurrentUser
              ? DSColors.primary.withValues(alpha: 0.3)
              : DSColors.textTertiary.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: isCurrentUser ? DSShadows.shadowPrimary : DSShadows.shadowSm,
      ),
      child: Padding(
        padding: DSSpacing.paddingMD,
        child: Row(
          children: [
            _buildRankBadge(rank),
            SizedBox(width: DSSpacing.sm),
            Expanded(
              child: Text(
                entry.displayName,
                style: DSTypography.bodyLarge.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                  color: DSColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.highScore.toString(),
                  style: DSTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3
                        ? _getRankColor(rank)
                        : (isCurrentUser
                              ? DSColors.primary
                              : DSColors.textPrimary),
                  ),
                ),
                if (entry.lastUpdated != null)
                  Text(
                    _formatDate(entry.lastUpdated!),
                    style: DSTypography.labelSmall.copyWith(
                      color: DSColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
