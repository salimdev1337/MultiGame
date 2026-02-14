import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Game history entry model
class GameHistoryEntry {
  final String gameType;
  final int score;
  final DateTime timestamp;
  final bool isWin;
  final int? moves;
  final Duration? duration;

  GameHistoryEntry({
    required this.gameType,
    required this.score,
    required this.timestamp,
    this.isWin = false,
    this.moves,
    this.duration,
  });
}

/// Game history timeline with animated entries
class GameHistoryTimeline extends StatelessWidget {
  const GameHistoryTimeline({
    super.key,
    required this.history,
    this.maxEntries = 20,
  });

  final List<GameHistoryEntry> history;
  final int maxEntries;

  @override
  Widget build(BuildContext context) {
    final displayHistory = history.take(maxEntries).toList();

    return Container(
      padding: EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSSpacing.md),
        border: Border.all(
          color: DSColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Game History',
                style: DSTypography.titleMedium.copyWith(
                  color: DSColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${displayHistory.length} recent',
                style: DSTypography.labelMedium.copyWith(
                  color: DSColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: DSSpacing.lg),

          // Timeline
          if (displayHistory.isEmpty)
            _EmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayHistory.length,
              itemBuilder: (context, index) {
                return _TimelineEntry(
                  entry: displayHistory[index],
                  isLast: index == displayHistory.length - 1,
                  delay: Duration(milliseconds: index * 50),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Empty state for no history
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DSSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 64, color: DSColors.textTertiary),
            SizedBox(height: DSSpacing.md),
            Text(
              'No Game History',
              style: DSTypography.titleMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
            SizedBox(height: DSSpacing.xs),
            Text(
              'Start playing to see your history here',
              style: DSTypography.bodySmall.copyWith(
                color: DSColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual timeline entry
class _TimelineEntry extends StatefulWidget {
  const _TimelineEntry({
    required this.entry,
    required this.isLast,
    required this.delay,
  });

  final GameHistoryEntry entry;
  final bool isLast;
  final Duration delay;

  @override
  State<_TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends State<_TimelineEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: DSAnimations.slow, vsync: this);

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: DSAnimations.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getGameColor() {
    return DSColors.getGameColor(widget.entry.gameType);
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(widget.entry.timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGameColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline indicator
            Column(
              children: [
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),

                // Vertical line
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      color: DSColors.textTertiary.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
            SizedBox(width: DSSpacing.md),

            // Content card
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: DSSpacing.md),
                padding: EdgeInsets.all(DSSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(DSSpacing.sm),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Game type
                        Text(
                          widget.entry.gameType,
                          style: DSTypography.labelLarge.copyWith(
                            color: DSColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Win/Loss badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DSSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.entry.isWin
                                ? DSColors.success.withValues(alpha: 0.2)
                                : DSColors.textTertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DSSpacing.xs),
                          ),
                          child: Text(
                            widget.entry.isWin ? 'WIN' : 'PLAYED',
                            style: DSTypography.labelSmall.copyWith(
                              color: widget.entry.isWin
                                  ? DSColors.success
                                  : DSColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DSSpacing.xs),

                    // Score
                    Row(
                      children: [
                        Icon(Icons.stars_rounded, size: 16, color: color),
                        SizedBox(width: 4),
                        Text(
                          '${widget.entry.score} points',
                          style: DSTypography.bodyMedium.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Additional stats
                    if (widget.entry.moves != null ||
                        widget.entry.duration != null) ...[
                      SizedBox(height: DSSpacing.xs),
                      Row(
                        children: [
                          if (widget.entry.moves != null) ...[
                            Icon(
                              Icons.touch_app_rounded,
                              size: 14,
                              color: DSColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${widget.entry.moves} moves',
                              style: DSTypography.labelSmall.copyWith(
                                color: DSColors.textSecondary,
                              ),
                            ),
                            if (widget.entry.duration != null) ...[
                              SizedBox(width: DSSpacing.sm),
                              Text(
                                '•',
                                style: DSTypography.labelSmall.copyWith(
                                  color: DSColors.textTertiary,
                                ),
                              ),
                              SizedBox(width: DSSpacing.sm),
                            ],
                          ],
                          if (widget.entry.duration != null) ...[
                            Icon(
                              Icons.timer_rounded,
                              size: 14,
                              color: DSColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _formatDuration(widget.entry.duration!),
                              style: DSTypography.labelSmall.copyWith(
                                color: DSColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    SizedBox(height: DSSpacing.xs),

                    // Timestamp
                    Text(
                      _formatTimestamp(),
                      style: DSTypography.labelSmall.copyWith(
                        color: DSColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact history summary widget
class GameHistorySummary extends StatelessWidget {
  const GameHistorySummary({
    super.key,
    required this.totalGames,
    required this.totalWins,
    required this.bestScore,
    required this.totalPlayTime,
  });

  final int totalGames;
  final int totalWins;
  final int bestScore;
  final Duration totalPlayTime;

  double get winRate => totalGames > 0 ? totalWins / totalGames : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DSColors.primary.withValues(alpha: 0.1),
            DSColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DSSpacing.md),
        border: Border.all(
          color: DSColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.sports_esports_rounded,
            label: 'Games',
            value: totalGames.toString(),
            color: DSColors.primary,
          ),
          _SummaryItem(
            icon: Icons.emoji_events_rounded,
            label: 'Wins',
            value: totalWins.toString(),
            color: DSColors.success,
          ),
          _SummaryItem(
            icon: Icons.trending_up_rounded,
            label: 'Win Rate',
            value: '${(winRate * 100).toInt()}%',
            color: DSColors.warning,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: DSSpacing.xs),
        Text(
          value,
          style: DSTypography.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: DSTypography.labelSmall.copyWith(
            color: DSColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
