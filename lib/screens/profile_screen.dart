import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/achievement_model.dart';
import 'package:multigame/repositories/stats_repository.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/streak_service.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/utils/input_validator.dart';
import 'package:multigame/utils/secure_logger.dart';
import 'package:multigame/widgets/profile/achievement_gallery.dart';
import 'package:multigame/widgets/profile/animated_profile_header.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final AchievementService _achievementService;
  late final NicknameService _nicknameService;
  late final StreakService _streakService;
  // Lazy so tests don't need GetIt set up unless Firebase is exercised.
  StatsRepository? _statsRepository;

  // Profile state
  String _nickname = 'Game Master';
  int _level = 1;
  int _currentXP = 0;
  int _xpToNextLevel = 500;
  String _rankLabel = 'Novice';
  int _currentStreak = 0;

  // Stats state
  Map<String, dynamic> _localStats = {};
  Map<String, dynamic> _stats2048 = {};
  Map<String, GameStats> _allGameStats = {};

  // Achievements
  List<AchievementModel> _achievements = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _achievementService = GetIt.instance<AchievementService>();
    _nicknameService = GetIt.instance<NicknameService>();
    _streakService = GetIt.instance<StreakService>();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Nickname uses SecureStorage which may be slow — load independently
    // so it never blocks the page from finishing the loading state.
    _fetchNickname()
        .catchError((e, st) {
          SecureLogger.error(
            'Failed to fetch nickname',
            error: e,
            stackTrace: st,
          );
        })
        .then((_) {
          if (mounted) setState(() {});
        });

    await Future.wait([
      _fetchStreakAndLevel().catchError((e, st) {
        SecureLogger.error(
          'Failed to fetch streak/level',
          error: e,
          stackTrace: st,
        );
      }),
      _fetchLocalStats().catchError((e, st) {
        SecureLogger.error(
          'Failed to fetch local stats',
          error: e,
          stackTrace: st,
        );
      }),
      _fetchAllGameStats().catchError((e, st) {
        SecureLogger.error(
          'Failed to fetch all game stats',
          error: e,
          stackTrace: st,
        );
      }),
    ]);

    // achievements depend on the other data, so run after
    try {
      await _fetchAchievements();
    } catch (e, st) {
      SecureLogger.error(
        'Failed to fetch achievements',
        error: e,
        stackTrace: st,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNickname() async {
    final nickname = await _nicknameService.getNickname();
    _nickname = nickname ?? 'Game Master';
  }

  Future<void> _fetchStreakAndLevel() async {
    final streakData = await _streakService.getStreakData();
    _currentStreak = streakData.currentStreak;

    final totalCompleted = await _achievementService.getTotalCompleted();
    _level = (totalCompleted ~/ 5) + 1;
    _currentXP = totalCompleted * 100;
    _xpToNextLevel = ((totalCompleted ~/ 5) + 1) * 500;

    if (_level >= 20) {
      _rankLabel = 'Legend';
    } else if (_level >= 10) {
      _rankLabel = 'Master';
    } else if (_level >= 5) {
      _rankLabel = 'Pro';
    } else {
      _rankLabel = 'Novice';
    }
  }

  Future<void> _fetchLocalStats() async {
    _localStats = await _achievementService.getAllStats();
    _stats2048 = await _achievementService.get2048Stats();
  }

  Future<void> _fetchAllGameStats() async {
    try {
      _statsRepository ??= GetIt.instance<StatsRepository>();
      final userId = await _nicknameService.getUserId();
      if (userId != null) {
        final userStats = await _statsRepository!.getUserStats(userId);
        if (userStats != null) {
          _allGameStats = userStats.gameStats;
        }
      }
    } catch (e, st) {
      SecureLogger.error(
        'Firebase unavailable or GetIt not set up in _fetchAllGameStats',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _fetchAchievements() async {
    final gamePlayCounts = <String, int>{};
    for (final entry in _allGameStats.entries) {
      gamePlayCounts[entry.key] = entry.value.gamesPlayed;
    }

    final unlockedStatus = await _achievementService.checkAllAchievements(
      currentStreak: _currentStreak,
      highestTile2048: _stats2048['highestTile'] as int? ?? 0,
      gamePlayCounts: gamePlayCounts,
    );

    _achievements = AchievementModel.getAllAchievements(
      unlockedStatus: unlockedStatus,
      totalCompleted: _localStats['totalCompleted'] as int? ?? 0,
      best3x3Moves: _localStats['best3x3Moves'] as int?,
      best4x4Moves: _localStats['best4x4Moves'] as int?,
      bestTime: _localStats['bestOverallTime'] as int?,
      currentStreak: _currentStreak,
      highestTile2048: _stats2048['highestTile'] as int? ?? 0,
      gamePlayCounts: gamePlayCounts,
    );
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '--';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  void _showNicknameDialog() {
    final controller = TextEditingController(text: _nickname);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DSColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSSpacing.lg),
        ),
        title: Text(
          'Edit Display Name',
          style: DSTypography.titleLarge.copyWith(color: DSColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: DSTypography.bodyMedium.copyWith(color: DSColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter nickname',
            hintStyle: DSTypography.bodyMedium.copyWith(
              color: DSColors.textTertiary,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.sm),
              borderSide: BorderSide(
                color: DSColors.primary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.sm),
              borderSide: BorderSide(color: DSColors.primary),
            ),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: DSTypography.labelLarge.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              final validation = InputValidator.validateNickname(newName);
              if (!validation.isValid) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(validation.error!)),
                  );
                }
                return;
              }
              await _nicknameService.saveNickname(validation.value as String);
              if (mounted && ctx.mounted) {
                setState(() => _nickname = validation.value as String);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Save',
              style: DSTypography.labelLarge.copyWith(color: DSColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: DSColors.primary,
          backgroundColor: DSColors.surface,
          child: _isLoading
              ? const _ProfileSkeleton()
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Animated profile header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(DSSpacing.lg),
                        child: AnimatedProfileHeader(
                          displayName: _nickname,
                          level: _level,
                          currentXP: _currentXP,
                          xpToNextLevel: _xpToNextLevel,
                          rank: _rankLabel,
                          onEditProfile: _showNicknameDialog,
                        ),
                      ),
                    ),

                    // Stats section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: DSSpacing.lg),
                        child: _StatsSection(
                          localStats: _localStats,
                          stats2048: _stats2048,
                          allGameStats: _allGameStats,
                          formatTime: _formatTime,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xl)),

                    // Achievement gallery section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: DSSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              icon: Icons.emoji_events_rounded,
                              title: 'Achievements',
                              subtitle:
                                  '${_achievements.where((a) => a.isUnlocked).length}/${_achievements.length} unlocked',
                            ),
                            SizedBox(height: DSSpacing.md),
                            AchievementGallery(
                              achievements: _achievements,
                              onAchievementTap: (achievement) {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => AchievementDetailModal(
                                    achievement: achievement,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xl)),

                    // Legal section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: DSSpacing.lg),
                        child: const _LegalSection(),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xxl)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: BorderRadius.circular(DSSpacing.lg),
            ),
          ),
          SizedBox(height: DSSpacing.lg),
          // Stats grid skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: DSSpacing.md,
            mainAxisSpacing: DSSpacing.md,
            childAspectRatio: 1.4,
            children: List.generate(
              6,
              (_) => Container(
                decoration: BoxDecoration(
                  color: DSColors.surface,
                  borderRadius: BorderRadius.circular(DSSpacing.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DSSpacing.xs),
          decoration: BoxDecoration(
            color: DSColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(DSSpacing.xs),
          ),
          child: Icon(icon, color: DSColors.primary, size: 20),
        ),
        SizedBox(width: DSSpacing.sm),
        Text(
          title,
          style: DSTypography.titleLarge.copyWith(
            color: DSColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const Spacer(),
          Text(
            subtitle!,
            style: DSTypography.labelMedium.copyWith(
              color: DSColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Stats section ─────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.localStats,
    required this.stats2048,
    required this.allGameStats,
    required this.formatTime,
  });

  final Map<String, dynamic> localStats;
  final Map<String, dynamic> stats2048;
  final Map<String, GameStats> allGameStats;
  final String Function(int?) formatTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.bar_chart_rounded, title: 'Game Stats'),
        SizedBox(height: DSSpacing.md),
        _StatsGrid(
          localStats: localStats,
          stats2048: stats2048,
          allGameStats: allGameStats,
          formatTime: formatTime,
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.localStats,
    required this.stats2048,
    required this.allGameStats,
    required this.formatTime,
  });

  final Map<String, dynamic> localStats;
  final Map<String, dynamic> stats2048;
  final Map<String, GameStats> allGameStats;
  final String Function(int?) formatTime;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _GameStatCard(
        icon: '🧩',
        title: 'Image Puzzle',
        color: DSColors.primary,
        stats: [
          _StatRow(
            label: 'Completed',
            value: '${localStats['totalCompleted'] ?? 0}',
          ),
          _StatRow(
            label: 'Best 3x3',
            value: formatTime(localStats['best3x3Time'] as int?),
          ),
          _StatRow(
            label: 'Best 3x3 Moves',
            value: localStats['best3x3Moves']?.toString() ?? '--',
          ),
        ],
      ),
      _GameStatCard(
        icon: '🔢',
        title: '2048',
        color: DSColors.success,
        stats: [
          _StatRow(
            label: 'Best Score',
            value: '${stats2048['bestScore'] ?? 0}',
          ),
          _StatRow(
            label: 'Highest Tile',
            value: '${stats2048['highestTile'] ?? 0}',
          ),
          _StatRow(
            label: 'Games Played',
            value: '${stats2048['gamesPlayed'] ?? 0}',
          ),
        ],
      ),
    ];

    // Firebase-tracked games
    final firebaseGames =
        <({String key, String label, String icon, Color color})>[
          (
            key: 'sudoku',
            label: 'Sudoku',
            icon: '🔢',
            color: DSColors.secondary,
          ),
          (
            key: 'snake',
            label: 'Snake',
            icon: '🐍',
            color: const Color(0xFF4CAF50),
          ),
          (
            key: 'runner',
            label: 'Infinite Runner',
            icon: '🏃',
            color: const Color(0xFF9C27B0),
          ),
          (
            key: 'bomberman',
            label: 'Bomberman',
            icon: '💣',
            color: const Color(0xFFFF5722),
          ),
          (
            key: 'memory',
            label: 'Memory',
            icon: '🃏',
            color: const Color(0xFF2196F3),
          ),
          (
            key: 'wordle',
            label: 'Wordle Duel',
            icon: '📝',
            color: const Color(0xFF795548),
          ),
          (
            key: 'connect_four',
            label: 'Connect Four',
            icon: '🔴',
            color: const Color(0xFFF44336),
          ),
        ];

    for (final game in firebaseGames) {
      final stats = allGameStats[game.key];
      cards.add(
        _GameStatCard(
          icon: game.icon,
          title: game.label,
          color: game.color,
          stats: [
            _StatRow(
              label: 'Games Played',
              value: stats != null ? '${stats.gamesPlayed}' : 'N/A',
            ),
            _StatRow(
              label: 'High Score',
              value: stats != null ? '${stats.highScore}' : 'N/A',
            ),
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: DSSpacing.md,
      mainAxisSpacing: DSSpacing.md,
      childAspectRatio: 0.95,
      children: cards,
    );
  }
}

class _StatRow {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});
}

class _GameStatCard extends StatelessWidget {
  const _GameStatCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.stats,
  });

  final String icon;
  final String title;
  final Color color;
  final List<_StatRow> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              SizedBox(width: DSSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: DSTypography.labelMedium.copyWith(
                    color: DSColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: DSSpacing.sm),
          ...stats.map(
            (s) => Padding(
              padding: EdgeInsets.only(bottom: DSSpacing.xxs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      s.label,
                      style: DSTypography.labelSmall.copyWith(
                        color: DSColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: DSSpacing.xs),
                  Text(
                    s.value,
                    style: DSTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
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

// ── Legal section ─────────────────────────────────────────────────────────────

class _LegalSection extends StatelessWidget {
  const _LegalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.gavel_rounded, title: 'Legal & Privacy'),
        SizedBox(height: DSSpacing.md),
        _LegalButton(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          url: 'https://salimdev1337.github.io/MultiGame/privacy.html',
        ),
        SizedBox(height: DSSpacing.sm),
        _LegalButton(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          url: 'https://salimdev1337.github.io/MultiGame/terms.html',
        ),
      ],
    );
  }
}

class _LegalButton extends StatelessWidget {
  const _LegalButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: DSColors.surface,
                    title: Text(
                      label,
                      style: DSTypography.titleMedium.copyWith(
                        color: DSColors.textPrimary,
                      ),
                    ),
                    content: SelectableText(
                      url,
                      style: DSTypography.bodySmall.copyWith(
                        color: DSColors.textSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Close',
                          style: DSTypography.labelLarge.copyWith(
                            color: DSColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not open $label'),
                  backgroundColor: DSColors.surface,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(DSSpacing.sm),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: DSSpacing.sm,
            horizontal: DSSpacing.md,
          ),
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSSpacing.sm),
            border: Border.all(
              color: DSColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: DSColors.primary, size: 20),
              SizedBox(width: DSSpacing.sm),
              Text(
                label,
                style: DSTypography.labelLarge.copyWith(
                  color: DSColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.open_in_new_rounded,
                color: DSColors.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
