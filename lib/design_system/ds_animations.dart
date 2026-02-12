/// Design System - Animation Tokens
/// Consistent animation durations, curves, and configurations
library;

import 'package:flutter/material.dart';

/// Animation constants and utilities
class DSAnimations {
  DSAnimations._(); // Private constructor

  // ==========================================
  // Reduced Motion State (Accessibility)
  // ==========================================

  /// Internal flag for reduced motion state
  /// Set by AccessibilityProvider when user enables reduced motion
  static bool _reducedMotionEnabled = false;

  /// Get current reduced motion state
  static bool get isReducedMotionEnabled => _reducedMotionEnabled;

  /// Set reduced motion state (called by AccessibilityProvider)
  static void setReducedMotion(bool enabled) {
    _reducedMotionEnabled = enabled;
  }

  // ==========================================
  // Duration Constants
  // ==========================================

  /// Instant - 0ms (no animation)
  static const Duration instant = Duration.zero;

  /// Fastest - 100ms (micro-interactions)
  static const Duration fastest = Duration(milliseconds: 100);

  /// Faster - 150ms (quick feedback)
  static const Duration faster = Duration(milliseconds: 150);

  /// Fast - 200ms (default quick)
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal - 300ms (standard animations)
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow - 400ms (deliberate animations)
  static const Duration slow = Duration(milliseconds: 400);

  /// Slower - 500ms (attention-grabbing)
  static const Duration slower = Duration(milliseconds: 500);

  /// Slowest - 700ms (dramatic entrances)
  static const Duration slowest = Duration(milliseconds: 700);

  /// Very slow - 1000ms (major transitions)
  static const Duration verySlow = Duration(milliseconds: 1000);

  // ==========================================
  // Animation Curves (Easing Functions)
  // ==========================================

  /// Linear - no easing
  static const Curve linear = Curves.linear;

  /// Ease in - slow start
  static const Curve easeIn = Curves.easeIn;

  /// Ease out - slow end (recommended for entrances)
  static const Curve easeOut = Curves.easeOut;

  /// Ease in-out - slow start and end
  static const Curve easeInOut = Curves.easeInOut;

  /// Ease in cubic - smooth acceleration
  static const Curve easeInCubic = Curves.easeInCubic;

  /// Ease out cubic - smooth deceleration (best for exits)
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Ease in-out cubic - smooth both ends
  static const Curve easeInOutCubic = Curves.easeInOutCubic;

  /// Elastic out - bouncy effect (playful)
  static const Curve elasticOut = Curves.elasticOut;

  /// Elastic in - reverse bounce
  static const Curve elasticIn = Curves.elasticIn;

  /// Bounce out - multiple bounces at end
  static const Curve bounceOut = Curves.bounceOut;

  /// Bounce in - multiple bounces at start
  static const Curve bounceIn = Curves.bounceIn;

  /// Fast out, slow in - Material Design standard
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// Decelerate - Material Design decelerate
  static const Curve decelerate = Curves.decelerate;

  // ==========================================
  // Custom Curves
  // ==========================================

  /// Smooth curve for subtle animations
  static const Curve smooth = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Sharp curve for quick actions
  static const Curve sharp = Cubic(0.4, 0.0, 0.6, 1.0);

  /// Emphasized curve for important actions
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  // ==========================================
  // Stagger Delays (for list animations)
  // ==========================================

  /// Minimal stagger - 30ms
  static const Duration staggerMin = Duration(milliseconds: 30);

  /// Short stagger - 50ms (recommended)
  static const Duration staggerShort = Duration(milliseconds: 50);

  /// Medium stagger - 80ms
  static const Duration staggerMedium = Duration(milliseconds: 80);

  /// Long stagger - 100ms
  static const Duration staggerLong = Duration(milliseconds: 100);

  // ==========================================
  // Common Animation Configurations
  // ==========================================

  /// Button press animation
  static const AnimationConfig buttonPress = AnimationConfig(
    duration: fast,
    curve: easeOutCubic,
  );

  /// Page transition
  static const AnimationConfig pageTransition = AnimationConfig(
    duration: normal,
    curve: fastOutSlowIn,
  );

  /// Dialog appear
  static const AnimationConfig dialogAppear = AnimationConfig(
    duration: normal,
    curve: easeOutCubic,
  );

  /// Snackbar slide
  static const AnimationConfig snackbarSlide = AnimationConfig(
    duration: fast,
    curve: easeOut,
  );

  /// Card flip
  static const AnimationConfig cardFlip = AnimationConfig(
    duration: slow,
    curve: easeInOutCubic,
  );

  /// Bounce effect
  static const AnimationConfig bounce = AnimationConfig(
    duration: slower,
    curve: elasticOut,
  );

  /// Fade in/out
  static const AnimationConfig fade = AnimationConfig(
    duration: normal,
    curve: easeInOut,
  );

  /// Slide in
  static const AnimationConfig slideIn = AnimationConfig(
    duration: normal,
    curve: easeOutCubic,
  );

  /// Scale up/down
  static const AnimationConfig scale = AnimationConfig(
    duration: fast,
    curve: easeOutCubic,
  );

  /// Rotate
  static const AnimationConfig rotate = AnimationConfig(
    duration: slow,
    curve: easeInOutCubic,
  );

  /// Shimmer loading
  static const AnimationConfig shimmer = AnimationConfig(
    duration: Duration(milliseconds: 1500),
    curve: linear,
  );

  // ==========================================
  // Game-Specific Animations
  // ==========================================

  /// Sudoku cell selection
  static const AnimationConfig sudokuCellSelect = AnimationConfig(
    duration: faster,
    curve: easeOutCubic,
  );

  /// 2048 tile merge
  static const AnimationConfig tile2048Merge = AnimationConfig(
    duration: fast,
    curve: elasticOut,
  );

  /// Snake movement
  static const AnimationConfig snakeMove = AnimationConfig(
    duration: Duration(milliseconds: 150),
    curve: linear,
  );

  /// Puzzle piece snap
  static const AnimationConfig puzzleSnap = AnimationConfig(
    duration: faster,
    curve: easeOutCubic,
  );

  /// Achievement unlock
  static const AnimationConfig achievementUnlock = AnimationConfig(
    duration: slower,
    curve: elasticOut,
  );

  // ==========================================
  // Utility Methods
  // ==========================================

  /// Calculate stagger delay for list item
  static Duration staggerDelay(
    int index, {
    Duration baseDelay = staggerShort,
    int maxDelay = 500,
  }) {
    final delay = baseDelay.inMilliseconds * index;
    return Duration(
      milliseconds: delay.clamp(0, maxDelay),
    );
  }

  /// Create animation controller with standard duration
  static AnimationController createController(
    TickerProvider vsync, {
    Duration duration = normal,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration,
    );
  }

  /// Create tween animation
  static Animation<double> createTween(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = easeOutCubic,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create color tween animation
  static Animation<Color?> createColorTween(
    AnimationController controller, {
    required Color begin,
    required Color end,
    Curve curve = easeOutCubic,
  }) {
    return ColorTween(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create slide transition offset
  static Offset slideOffsetFromDirection(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.up:
        return const Offset(0, 1);
      case SlideDirection.down:
        return const Offset(0, -1);
      case SlideDirection.left:
        return const Offset(1, 0);
      case SlideDirection.right:
        return const Offset(-1, 0);
    }
  }
}

/// Animation configuration class
class AnimationConfig {
  final Duration duration;
  final Curve curve;

  const AnimationConfig({
    required this.duration,
    required this.curve,
  });
}

/// Slide direction enum
enum SlideDirection {
  up,
  down,
  left,
  right,
}

// ==========================================
// Animation Helper Extensions
// ==========================================

/// Extension for AnimationController convenience methods
extension AnimationControllerExtensions on AnimationController {
  /// Forward the animation and wait for completion
  Future<void> forwardAndComplete() async {
    await forward();
  }

  /// Reverse the animation and wait for completion
  Future<void> reverseAndComplete() async {
    await reverse();
  }

  /// Toggle animation between forward and reverse
  void toggle() {
    if (status == AnimationStatus.completed) {
      reverse();
    } else {
      forward();
    }
  }

  /// Reset to beginning
  void reset() {
    stop();
    value = 0.0;
  }
}

// ==========================================
// Accessibility-Aware Animation Utilities
// ==========================================

/// Get duration respecting reduced motion setting
/// If reduced motion is enabled, duration is reduced to 30% of original
Duration getDuration(Duration standard) {
  if (!DSAnimations.isReducedMotionEnabled) return standard;

  final reducedDuration = Duration(
    milliseconds: (standard.inMilliseconds * 0.3).round(),
  );

  // Ensure minimum duration of 50ms
  return reducedDuration.inMilliseconds < 50
      ? const Duration(milliseconds: 50)
      : reducedDuration;
}

/// Extension for Duration to support reduced motion
extension ReducedMotionDuration on Duration {
  /// Get this duration with reduced motion applied if enabled
  Duration get withReducedMotion {
    return getDuration(this);
  }
}

/// Create animation controller with reduced motion support
AnimationController createAccessibleController(
  TickerProvider vsync, {
  Duration duration = DSAnimations.normal,
}) {
  return AnimationController(
    vsync: vsync,
    duration: getDuration(duration),
  );
}

/// Create tween animation with reduced motion support
Animation<double> createAccessibleTween(
  AnimationController controller, {
  double begin = 0.0,
  double end = 1.0,
  Curve curve = DSAnimations.easeOutCubic,
}) {
  return Tween<double>(
    begin: begin,
    end: end,
  ).animate(
    CurvedAnimation(
      parent: controller,
      curve: curve,
    ),
  );
}
