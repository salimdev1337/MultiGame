/// Design System - Spacing & Layout Tokens
/// Consistent spacing using 4px grid system
library;

import 'package:flutter/material.dart';

/// Spacing constants based on 4px grid
class DSSpacing {
  DSSpacing._(); // Private constructor

  // ==========================================
  // Base Spacing Units (4px grid)
  // ==========================================

  /// 4px - Minimum spacing
  static const double xxxs = 4.0;

  /// 8px - Tight spacing
  static const double xxs = 8.0;

  /// 12px - Compact spacing
  static const double xs = 12.0;

  /// 16px - Standard spacing (default)
  static const double sm = 16.0;

  /// 20px - Medium spacing
  static const double md = 20.0;

  /// 24px - Comfortable spacing
  static const double lg = 24.0;

  /// 32px - Large spacing
  static const double xl = 32.0;

  /// 40px - Extra large spacing
  static const double xxl = 40.0;

  /// 48px - Huge spacing
  static const double xxxl = 48.0;

  /// 64px - Massive spacing
  static const double xxxxl = 64.0;

  // ==========================================
  // Semantic Spacing (Named by purpose)
  // ==========================================

  /// Card padding
  static const double cardPadding = sm;

  /// Dialog padding
  static const double dialogPadding = lg;

  /// Screen padding (horizontal)
  static const double screenHorizontal = lg;

  /// Screen padding (vertical)
  static const double screenVertical = sm;

  /// List item spacing
  static const double listItemGap = xs;

  /// Section spacing
  static const double sectionGap = xl;

  /// Button padding (horizontal)
  static const double buttonHorizontal = lg;

  /// Button padding (vertical)
  static const double buttonVertical = xs;

  /// Icon size (extra small) — used by small buttons
  static const double iconXSmall = 18.0;

  /// Icon size (small)
  static const double iconSmall = 20.0;

  /// Icon size (medium)
  static const double iconMedium = 24.0;

  /// Icon size (large)
  static const double iconLarge = 32.0;

  /// Icon size (extra large)
  static const double iconXLarge = 48.0;

  // ==========================================
  // Border Radius
  // ==========================================

  /// Tiny radius - 4px
  static const double radiusXS = 4.0;

  /// Small radius - 8px
  static const double radiusSM = 8.0;

  /// Medium radius - 12px
  static const double radiusMD = 12.0;

  /// Large radius - 16px
  static const double radiusLG = 16.0;

  /// Extra large radius - 20px
  static const double radiusXL = 20.0;

  /// Huge radius - 24px
  static const double radiusXXL = 24.0;

  /// Full circle
  static const double radiusFull = 9999.0;

  // ==========================================
  // Border Radius Presets
  // ==========================================

  static const BorderRadius borderRadiusXS = BorderRadius.all(
    Radius.circular(radiusXS),
  );

  static const BorderRadius borderRadiusSM = BorderRadius.all(
    Radius.circular(radiusSM),
  );

  static const BorderRadius borderRadiusMD = BorderRadius.all(
    Radius.circular(radiusMD),
  );

  static const BorderRadius borderRadiusLG = BorderRadius.all(
    Radius.circular(radiusLG),
  );

  static const BorderRadius borderRadiusXL = BorderRadius.all(
    Radius.circular(radiusXL),
  );

  static const BorderRadius borderRadiusXXL = BorderRadius.all(
    Radius.circular(radiusXXL),
  );

  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ==========================================
  // Border Width
  // ==========================================

  /// Hairline border - 1px
  static const double borderThin = 1.0;

  /// Standard border - 2px
  static const double borderMedium = 2.0;

  /// Thick border - 3px
  static const double borderThick = 3.0;

  // ==========================================
  // EdgeInsets Presets
  // ==========================================

  /// No padding
  static const EdgeInsets paddingNone = EdgeInsets.zero;

  /// XXS padding - 4px all
  static const EdgeInsets paddingXXS = EdgeInsets.all(xxxs);

  /// XS padding - 8px all
  static const EdgeInsets paddingXS = EdgeInsets.all(xxs);

  /// SM padding - 12px all
  static const EdgeInsets paddingSM = EdgeInsets.all(xs);

  /// MD padding - 16px all
  static const EdgeInsets paddingMD = EdgeInsets.all(sm);

  /// LG padding - 24px all
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);

  /// XL padding - 32px all
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  /// Standard card padding
  static const EdgeInsets paddingCard = EdgeInsets.all(cardPadding);

  /// Screen padding (horizontal + vertical)
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  /// Horizontal padding only (MD)
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(
    horizontal: sm,
  );

  /// Vertical padding only (MD)
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(
    vertical: sm,
  );

  /// Bottom sheet padding
  static const EdgeInsets paddingBottomSheet = EdgeInsets.only(
    left: lg,
    right: lg,
    top: lg,
    bottom: xxxl, // Extra space for safe area
  );

  // ==========================================
  // SizedBox Presets
  // ==========================================

  /// Vertical gap - XXS (4px)
  static const Widget gapVerticalXXS = SizedBox(height: xxxs);

  /// Vertical gap - XS (8px)
  static const Widget gapVerticalXS = SizedBox(height: xxs);

  /// Vertical gap - SM (12px)
  static const Widget gapVerticalSM = SizedBox(height: xs);

  /// Vertical gap - MD (16px)
  static const Widget gapVerticalMD = SizedBox(height: sm);

  /// Vertical gap - LG (24px)
  static const Widget gapVerticalLG = SizedBox(height: lg);

  /// Vertical gap - XL (32px)
  static const Widget gapVerticalXL = SizedBox(height: xl);

  /// Horizontal gap - XXS (4px)
  static const Widget gapHorizontalXXS = SizedBox(width: xxxs);

  /// Horizontal gap - XS (8px)
  static const Widget gapHorizontalXS = SizedBox(width: xxs);

  /// Horizontal gap - SM (12px)
  static const Widget gapHorizontalSM = SizedBox(width: xs);

  /// Horizontal gap - MD (16px)
  static const Widget gapHorizontalMD = SizedBox(width: sm);

  /// Horizontal gap - LG (24px)
  static const Widget gapHorizontalLG = SizedBox(width: lg);

  /// Horizontal gap - XL (32px)
  static const Widget gapHorizontalXL = SizedBox(width: xl);

  // ==========================================
  // Touch Target Sizes (Accessibility)
  // ==========================================

  /// Minimum touch target (44x44 - iOS HIG)
  static const double touchTargetMin = 44.0;

  /// Recommended touch target (48x48 - Material)
  static const double touchTargetRecommended = 48.0;

  // ==========================================
  // Constraints
  // ==========================================

  /// Max width for content (mobile)
  static const double maxContentWidthMobile = 600.0;

  /// Max width for dialogs
  static const double maxDialogWidth = 400.0;

  /// Max width for bottom sheets
  static const double maxBottomSheetWidth = 640.0;

  /// Card max width
  static const double maxCardWidth = 400.0;

  // ==========================================
  // Breakpoints (Responsive)
  // ==========================================

  /// Mobile breakpoint
  static const double breakpointMobile = 600.0;

  /// Tablet breakpoint
  static const double breakpointTablet = 960.0;

  /// Desktop breakpoint
  static const double breakpointDesktop = 1280.0;

  // ==========================================
  // Utility Methods
  // ==========================================

  /// Create custom EdgeInsets
  static EdgeInsets custom({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    }

    if (horizontal != null && vertical != null) {
      return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
    }

    return EdgeInsets.only(
      top: top ?? 0,
      bottom: bottom ?? 0,
      left: left ?? 0,
      right: right ?? 0,
    );
  }

  /// Create custom SizedBox (vertical)
  static Widget gapVertical(double height) => SizedBox(height: height);

  /// Create custom SizedBox (horizontal)
  static Widget gapHorizontal(double width) => SizedBox(width: width);

  /// Check if screen width is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointMobile;
  }

  /// Check if screen width is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointMobile && width < breakpointDesktop;
  }

  /// Check if screen width is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }
}
