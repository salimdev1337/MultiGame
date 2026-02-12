import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/onboarding_page.dart';
import 'package:multigame/widgets/shared/ds_button.dart';

/// Swipe-through tutorial screen shown on first launch
class OnboardingTutorialScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<OnboardingPage> pages;

  const OnboardingTutorialScreen({
    super.key,
    required this.onComplete,
    List<OnboardingPage>? pages,
  }) : pages = pages ?? const [];

  @override
  State<OnboardingTutorialScreen> createState() =>
      _OnboardingTutorialScreenState();
}

class _OnboardingTutorialScreenState extends State<OnboardingTutorialScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _progressController;
  late List<AnimationController> _iconControllers;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: DSAnimations.slow,
      vsync: this,
    );

    // Create animation controllers for each page's icon
    final pages = widget.pages.isNotEmpty
        ? widget.pages
        : OnboardingPage.defaultPages;
    _iconControllers = List.generate(
      pages.length,
      (index) => AnimationController(
        duration: DSAnimations.normal,
        vsync: this,
      ),
    );

    // Animate first icon
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    for (final controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Animate icon for new page
    _iconControllers[page].forward();

    // Update progress
    _progressController.animateTo(
      (page + 1) / _pages.length,
      duration: DSAnimations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: DSAnimations.normal,
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipTutorial() {
    widget.onComplete();
  }

  List<OnboardingPage> get _pages =>
      widget.pages.isNotEmpty ? widget.pages : OnboardingPage.defaultPages;

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: DSSpacing.paddingMD,
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipTutorial,
                  style: TextButton.styleFrom(
                    foregroundColor: DSColors.textSecondary,
                  ),
                  child: Text(
                    'Skip',
                    style: DSTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: EdgeInsets.all(DSSpacing.lg),
              child: Column(
                children: [
                  // Page indicators
                  _buildPageIndicators(),
                  SizedBox(height: DSSpacing.xl),

                  // Action button
                  DSButton(
                    text: isLastPage ? 'Get Started' : 'Next',
                    icon: isLastPage ? Icons.check_rounded : Icons.arrow_forward,
                    variant: DSButtonVariant.gradient,
                    gradient: DSColors.gradientPrimary,
                    onPressed: _nextPage,
                    size: DSButtonSize.large,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DSSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: _iconControllers[index],
            builder: (context, child) {
              final scale = Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _iconControllers[index],
                  curve: Curves.elasticOut,
                ),
              );

              return Transform.scale(
                scale: scale.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        page.primaryColor.withValues(alpha: 0.2),
                        page.secondaryColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DSSpacing.radiusXXL),
                    border: Border.all(
                      color: page.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: 70,
                    color: page.primaryColor,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: DSSpacing.xxxl),

          // Title
          Text(
            page.title,
            style: DSTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: DSColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: DSSpacing.md),

          // Description
          Text(
            page.description,
            style: DSTypography.bodyLarge.copyWith(
              color: DSColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: DSAnimations.normal,
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: DSSpacing.xxxs),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: _currentPage == index
                ? DSColors.gradientPrimary
                : null,
            color: _currentPage == index
                ? null
                : DSColors.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DSSpacing.radiusFull),
          ),
        ),
      ),
    );
  }
}
