import 'package:material_ui/material_ui.dart';

/// Spacing scale (4 pt grid). Screens use these, never raw numbers.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Horizontal page margin.
  static const gutter = 24.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const pulse = Duration(milliseconds: 1100);
}

abstract final class AppSizes {
  /// Minimum touch target (Android 48, iOS 44: the larger wins).
  static const touch = 48.0;
  static const iconSm = 18.0;
  static const icon = 22.0;
  static const iconLg = 28.0;
  static const buttonHeight = 54.0;
  static const avatar = 52.0;
  static const roundButton = 48.0;
  static const navBarHeight = 72.0;
  static const navBarMargin = 16.0;

  /// Content width on tablets (centered).
  static const maxContentWidth = 640.0;
  static const cardAspect = 1.62;
  static const progressHeight = 3.0;
  static const dot = 8.0;
  static const handleWidth = 36.0;
  static const handleHeight = 4.0;
  static const dateTile = 64.0;
  static const mascot = 120.0;
}

abstract final class AppShadows {
  static List<BoxShadow> soft(Color c) => [
    BoxShadow(color: c, blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 6)),
  ];
}
