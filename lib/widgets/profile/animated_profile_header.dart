import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Animated profile header with level ring, XP bar, and rank display
class AnimatedProfileHeader extends StatefulWidget {
  const AnimatedProfileHeader({
    super.key,
    required this.displayName,
    required this.level,
    required this.currentXP,
    required this.xpToNextLevel,
    this.rank,
    this.avatarUrl,
    this.onEditProfile,
  });

  final String displayName;
  final int level;
  final int currentXP;
  final int xpToNextLevel;
  final String? rank;
  final String? avatarUrl;
  final VoidCallback? onEditProfile;

  @override
  State<AnimatedProfileHeader> createState() => _AnimatedProfileHeaderState();
}

class _AnimatedProfileHeaderState extends State<AnimatedProfileHeader>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _xpController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _xpAnimation;

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Scale animation for entrance
    _scaleController = AnimationController(
      duration: DSAnimations.slow,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: DSAnimations.elasticOut),
    );

    // XP bar animation
    _xpController = AnimationController(
      duration: DSAnimations.slower,
      vsync: this,
    );
    _xpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeInOut),
    );

    // Start animations with stagger
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _xpController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Color _getLevelGradientColor() {
    if (widget.level >= 50) return DSColors.rarityLegendary;
    if (widget.level >= 30) return DSColors.rarityEpic;
    if (widget.level >= 15) return DSColors.rarityRare;
    return DSColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(DSSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getLevelGradientColor().withValues(alpha: 0.1),
                DSColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(DSSpacing.lg),
            border: Border.all(
              color: _getLevelGradientColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Avatar with level ring
              _AnimatedAvatarWithLevel(
                level: widget.level,
                avatarUrl: widget.avatarUrl,
                levelColor: _getLevelGradientColor(),
              ),
              SizedBox(height: DSSpacing.md),

              // Display name
              Text(
                widget.displayName,
                style: DSTypography.headlineMedium.copyWith(
                  color: DSColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: DSSpacing.xs),

              // Rank badge
              if (widget.rank != null) ...[
                _RankBadge(rank: widget.rank!),
                SizedBox(height: DSSpacing.md),
              ],

              // XP Progress bar
              AnimatedBuilder(
                animation: _xpAnimation,
                builder: (context, child) {
                  return _XPProgressBar(
                    currentXP: (widget.currentXP * _xpAnimation.value).toInt(),
                    totalXP: widget.xpToNextLevel,
                    color: _getLevelGradientColor(),
                  );
                },
              ),
              SizedBox(height: DSSpacing.md),

              // Edit profile button
              if (widget.onEditProfile != null)
                _EditProfileButton(onPressed: widget.onEditProfile!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated avatar with rotating level ring
class _AnimatedAvatarWithLevel extends StatefulWidget {
  const _AnimatedAvatarWithLevel({
    required this.level,
    required this.levelColor,
    this.avatarUrl,
  });

  final int level;
  final String? avatarUrl;
  final Color levelColor;

  @override
  State<_AnimatedAvatarWithLevel> createState() =>
      __AnimatedAvatarWithLevelState();
}

class __AnimatedAvatarWithLevelState extends State<_AnimatedAvatarWithLevel>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating ring
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: LevelRingPainter(
                    color: widget.levelColor,
                    progress: 1.0,
                  ),
                ),
              );
            },
          ),

          // Avatar circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.levelColor.withValues(alpha: 0.3),
                  widget.levelColor.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.levelColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: widget.avatarUrl != null
                  ? Image.network(
                      widget.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _DefaultAvatar(level: widget.level),
                    )
                  : _DefaultAvatar(level: widget.level),
            ),
          ),

          // Level badge
          Positioned(
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: DSSpacing.sm,
                vertical: DSSpacing.xxs,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.levelColor, widget.levelColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(DSSpacing.sm),
                boxShadow: [
                  BoxShadow(
                    color: widget.levelColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                'LV ${widget.level}',
                style: DSTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Default avatar with user icon
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.surface,
      child: Icon(
        Icons.person_rounded,
        size: 50,
        color: DSColors.textSecondary,
      ),
    );
  }
}

/// Level ring painter
class LevelRingPainter extends CustomPainter {
  final Color color;
  final double progress;

  LevelRingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius - 2, paint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.5)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(LevelRingPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

/// Rank badge display
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final String rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: DSColors.gradientGold,
        borderRadius: BorderRadius.circular(DSSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: DSColors.warning.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.military_tech_rounded,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: DSSpacing.xxs),
          Text(
            rank,
            style: DSTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP Progress bar with glow effect
class _XPProgressBar extends StatelessWidget {
  const _XPProgressBar({
    required this.currentXP,
    required this.totalXP,
    required this.color,
  });

  final int currentXP;
  final int totalXP;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = totalXP > 0 ? (currentXP / totalXP).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // XP label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Experience',
              style: DSTypography.labelMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
            Text(
              '$currentXP / $totalXP XP',
              style: DSTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: DSSpacing.xs),

        // Progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSSpacing.sm),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DSSpacing.sm),
            child: Stack(
              children: [
                // Progress fill
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ),

                // Glow effect
                if (progress > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
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
}

/// Edit profile button with scale animation
class _EditProfileButton extends StatefulWidget {
  const _EditProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_EditProfileButton> createState() => __EditProfileButtonState();
}

class __EditProfileButtonState extends State<_EditProfileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(DSSpacing.md),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DSSpacing.lg,
              vertical: DSSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: DSColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DSSpacing.md),
              border: Border.all(
                color: DSColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: DSColors.primary,
                ),
                SizedBox(width: DSSpacing.xs),
                Text(
                  'Edit Profile',
                  style: DSTypography.labelLarge.copyWith(
                    color: DSColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
