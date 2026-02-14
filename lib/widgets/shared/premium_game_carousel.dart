/// Premium Game Carousel Widget
/// Enhanced carousel with 3D-tilt cards and smooth animations
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/game_model.dart';
import 'package:multigame/widgets/shared/ds_button.dart';

/// Premium animated game carousel
class PremiumGameCarousel extends StatefulWidget {
  final Function(GameModel) onGameSelected;

  const PremiumGameCarousel({super.key, required this.onGameSelected});

  @override
  State<PremiumGameCarousel> createState() => _PremiumGameCarouselState();
}

class _PremiumGameCarouselState extends State<PremiumGameCarousel> {
  int _currentIndex = 0;
  final List<GameModel> _games = GameModel.getAvailableGames();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel
        CarouselSlider.builder(
          itemCount: _games.length,
          itemBuilder: (context, index, realIndex) {
            final game = _games[index];
            final isCurrent = index == _currentIndex;

            return AnimatedPremiumGameCard(
                  game: game,
                  isCurrent: isCurrent,
                  onTap: () => _handleGameTap(game),
                )
                .animate(delay: Duration(milliseconds: 100 * index))
                .fadeIn(
                  duration: DSAnimations.normal,
                  curve: DSAnimations.easeOut,
                )
                .slideY(
                  begin: 0.2,
                  duration: DSAnimations.normal,
                  curve: DSAnimations.easeOutCubic,
                );
          },
          options: CarouselOptions(
            height: 320,
            enlargeCenterPage: true,
            enlargeFactor: 0.25,
            enableInfiniteScroll: false,
            viewportFraction: 0.85,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),

        DSSpacing.gapVerticalMD,

        // Animated page indicators
        _buildPageIndicators(),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _games.asMap().entries.map((entry) {
        final isCurrent = entry.key == _currentIndex;

        return AnimatedContainer(
          duration: DSAnimations.fast,
          curve: DSAnimations.easeOutCubic,
          width: isCurrent ? 32 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: DSSpacing.borderRadiusFull,
            gradient: isCurrent ? DSColors.gradientPrimary : null,
            color: isCurrent
                ? null
                : DSColors.withOpacity(DSColors.primary, 0.3),
            boxShadow: isCurrent ? DSShadows.shadowPrimary : null,
          ),
        );
      }).toList(),
    );
  }

  void _handleGameTap(GameModel game) {
    if (game.isAvailable) {
      widget.onGameSelected(game);
    } else {
      _showComingSoonDialog(game);
    }
  }

  void _showComingSoonDialog(GameModel game) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child:
            Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: DSColors.surface,
                    borderRadius: DSSpacing.borderRadiusXL,
                    border: Border.all(
                      color: DSColors.withOpacity(DSColors.warning, 0.3),
                      width: 2,
                    ),
                    boxShadow: DSShadows.shadowXl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: DSSpacing.paddingLG,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DSColors.withOpacity(DSColors.warning, 0.2),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(DSSpacing.radiusXL),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: DSSpacing.paddingXS,
                              decoration: BoxDecoration(
                                color: DSColors.withOpacity(
                                  DSColors.warning,
                                  0.2,
                                ),
                                borderRadius: DSSpacing.borderRadiusMD,
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: DSColors.warning,
                                size: 32,
                              ),
                            ),
                            DSSpacing.gapHorizontalMD,
                            Expanded(
                              child: Text(
                                'Coming Soon!',
                                style: DSTypography.titleLarge,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: DSSpacing.paddingLG,
                        child: Text(
                          '${game.name} is not available yet. Stay tuned for updates!',
                          style: DSTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Close button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DSSpacing.lg,
                          0,
                          DSSpacing.lg,
                          DSSpacing.lg,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: DSButton.primary(
                            text: 'Got It',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .scale(
                  duration: DSAnimations.normal,
                  curve: DSAnimations.easeOutCubic,
                )
                .fadeIn(),
      ),
    );
  }
}

/// Animated premium game card with 3D tilt effect
class AnimatedPremiumGameCard extends StatefulWidget {
  final GameModel game;
  final bool isCurrent;
  final VoidCallback onTap;

  const AnimatedPremiumGameCard({
    super.key,
    required this.game,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<AnimatedPremiumGameCard> createState() =>
      _AnimatedPremiumGameCardState();
}

class _AnimatedPremiumGameCardState extends State<AnimatedPremiumGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _tiltOffset = Offset.zero;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: DSAnimations.fast);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.game.isAvailable) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;

    // Calculate tilt (-0.02 to 0.02)
    final dx = (localPosition.dx / size.width - 0.5) * 0.04;
    final dy = (localPosition.dy / size.height - 0.5) * 0.04;

    setState(() {
      _tiltOffset = Offset(dx, dy);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _tiltOffset = Offset.zero;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final gameColor = DSColors.getGameColor(widget.game.id);

    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: DSAnimations.fast,
        curve: DSAnimations.easeOutCubic,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltOffset.dy)
            ..rotateY(-_tiltOffset.dx),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: DSSpacing.xxs,
              vertical: DSSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: DSSpacing.borderRadiusXL,
              boxShadow: widget.game.isAvailable
                  ? DSShadows.custom(
                      color: gameColor,
                      opacity: widget.isCurrent ? 0.4 : 0.2,
                      blurRadius: widget.isCurrent ? 30 : 15,
                    )
                  : DSShadows.shadowMd,
            ),
            child: ClipRRect(
              borderRadius: DSSpacing.borderRadiusXL,
              child: Stack(
                children: [
                  // Background image
                  Positioned.fill(child: _buildBackground()),

                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            DSColors.withOpacity(Colors.black, 0.85),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Lock overlay for unavailable games
                  if (!widget.game.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: DSColors.withOpacity(Colors.black, 0.7),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                size: 64,
                                color: DSColors.textTertiary,
                              ),
                              DSSpacing.gapVerticalSM,
                              Text(
                                'Coming Soon',
                                style: DSTypography.titleMedium.copyWith(
                                  color: DSColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Help button (top right)
                  if (widget.game.isAvailable)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: DSSpacing.paddingXS,
                        decoration: BoxDecoration(
                          color: DSColors.withOpacity(Colors.black, 0.6),
                          borderRadius: DSSpacing.borderRadiusFull,
                          border: Border.all(
                            color: DSColors.withOpacity(gameColor, 0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: gameColor,
                          size: 24,
                        ),
                      ),
                    ),

                  // Content at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: DSSpacing.paddingLG,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Game title
                          Text(
                            widget.game.name,
                            style: DSTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              shadows: DSShadows.textShadowLg,
                            ),
                          ),

                          DSSpacing.gapVerticalXS,

                          // Description
                          Text(
                            widget.game.description,
                            style: DSTypography.bodyMedium.copyWith(
                              color: DSColors.withOpacity(Colors.white, 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          DSSpacing.gapVerticalMD,

                          // Play button
                          if (widget.game.isAvailable)
                            DSButton(
                              text: 'Play Now',
                              variant: DSButtonVariant.gradient,
                              gradient: LinearGradient(
                                colors: [gameColor, DSColors.primary],
                              ),
                              icon: Icons.play_arrow_rounded,
                              fullWidth: true,
                              onPressed: widget.onTap,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.game.imagePath.isNotEmpty) {
      return Image.asset(
        widget.game.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackBackground();
        },
      );
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    final gameColor = DSColors.getGameColor(widget.game.id);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DSColors.withOpacity(gameColor, 0.3),
            DSColors.surfaceElevated,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.games_rounded,
          size: 120,
          color: DSColors.withOpacity(gameColor, 0.5),
        ),
      ),
    );
  }
}
