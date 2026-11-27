import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_dimens.dart';
import '../tokens/app_typography.dart';

/// Light and dark themes, built together from the same tokens.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final text = AppTypography.of(c.ink);
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: c.onPrimary,
      surface: c.surface,
      onSurface: c.ink,
      error: c.danger,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.family,
      scaffoldBackgroundColor: c.background,
      extensions: [c, text],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.subtitle,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.body.copyWith(color: c.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceMuted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.primary),
    );
  }
}

extension ThemeTokens on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTypography get text => Theme.of(this).extension<AppTypography>()!;

  /// "Reduce motion" is on: no decorative animation.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
