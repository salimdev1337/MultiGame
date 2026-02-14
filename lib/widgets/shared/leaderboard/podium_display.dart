import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/widgets/shared/leaderboard/animated_crown.dart';
import 'package:multigame/widgets/shared/leaderboard/shimmer_trophy_icon.dart';

/// Displays top 3 players on a podium with 3D elevation effect
class PodiumDisplay extends StatelessWidget {
  final List<LeaderboardEntry> topThree;
  final String? currentUserId;
  final VoidCallback? onPlayerTap;

  const PodiumDisplay({
    super.key,
    required this.topThree,
    this.currentUserId,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ensure we have exactly 3 entries (fill with empty if needed)
    final entries = List<LeaderboardEntry?>.from(topThree);
    while (entries.length < 3) {
      entries.add(null);
    }

    // Arrange as: 2nd (left), 1st (center), 3rd (right)
    final second = entries.length > 1 ? entries[1] : null;
    final first = entries[0];
    final third = entries.length > 2 ? entries[2] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale podium base heights proportionally to available width
        final scale = (constraints.maxWidth / 360).clamp(0.75, 1.3);
        final base1 = (160 * scale).roundToDouble();
        final base2 = (120 * scale).roundToDouble();
        final base3 = (100 * scale).roundToDouble();

        return Padding(
          padding: DSSpacing.paddingLG,
          child: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        DSColors.primary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Podium items — aligned at bottom so bases touch the floor
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place (left)
                  if (second != null)
                    Expanded(
                      child: _PodiumItem(
                        entry: second,
                        rank: 2,
                        baseHeight: base2,
                        isCurrentUser: second.userId == currentUserId,
                        onTap: onPlayerTap,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  SizedBox(width: DSSpacing.md),
                  // 1st place (center, tallest)
                  Expanded(
                    child: _PodiumItem(
                      entry: first,
                      rank: 1,
                      baseHeight: base1,
                      isCurrentUser: first?.userId == currentUserId,
                      showCrown: true,
                      onTap: onPlayerTap,
                    ),
                  ),
                  SizedBox(width: DSSpacing.md),
                  // 3rd place (right)
                  if (third != null)
                    Expanded(
                      child: _PodiumItem(
                        entry: third,
                        rank: 3,
                        baseHeight: base3,
                        isCurrentUser: third.userId == currentUserId,
                        onTap: onPlayerTap,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PodiumItem extends StatefulWidget {
  final LeaderboardEntry? entry;
  final int rank;
  final double baseHeight;
  final bool isCurrentUser;
  final bool showCrown;
  final VoidCallback? onTap;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.baseHeight,
    this.isCurrentUser = false,
    this.showCrown = false,
    this.onTap,
  });

  @override
  State<_PodiumItem> createState() => _PodiumItemState();
}

class _PodiumItemState extends State<_PodiumItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger entrance based on rank
    Future.delayed(Duration(milliseconds: (widget.rank - 1) * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getPodiumColor() {
    switch (widget.rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return DSColors.surface;
    }
  }

  Gradient _getPodiumGradient() {
    switch (widget.rank) {
      case 1:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        );
      case 2:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
        );
      case 3:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
        );
      default:
        return LinearGradient(colors: [DSColors.surface, DSColors.surface]);
    }
  }

  static const _rankNames = ['', 'First', 'Second', 'Third'];

  @override
  Widget build(BuildContext context) {
    if (widget.entry == null) {
      return const SizedBox();
    }

    final rankName = widget.rank <= 3
        ? _rankNames[widget.rank]
        : '#${widget.rank}';
    final entry = widget.entry!;

    return Semantics(
      label: '$rankName place: ${entry.displayName}, ${entry.highScore} points',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Crown animation for 1st place
                  if (widget.showCrown) ...[
                    const AnimatedCrown(),
                    SizedBox(height: DSSpacing.xxs),
                  ],
                  // Trophy icon with shimmer
                  ShimmerTrophyIcon(
                    rank: widget.rank,
                    size: widget.rank == 1 ? 44 : 36,
                  ),
                  SizedBox(height: DSSpacing.xs),
                  // Player name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.entry!.displayName,
                      style: DSTypography.labelMedium.copyWith(
                        color: DSColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: DSSpacing.xxs),
                  // Score
                  Text(
                    widget.entry!.highScore.toString(),
                    style: DSTypography.titleMedium.copyWith(
                      color: _getPodiumColor(),
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: _getPodiumColor().withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: DSSpacing.xs),
                  // Podium base
                  Container(
                    height: widget.baseHeight,
                    decoration: BoxDecoration(
                      gradient: _getPodiumGradient(),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: widget.isCurrentUser
                            ? DSColors.primary
                            : Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getPodiumColor().withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        // 3D depth effect
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '#${widget.rank}',
                        style: DSTypography.displayLarge.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: widget.rank == 1 ? 52 : 40,
                          shadows: [
                            Shadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
