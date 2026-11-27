import 'package:material_ui/material_ui.dart';

/// Brand palette. Changing the identity of the app = changing the values
/// below (and the font in `app_typography.dart`), nothing else.
///
/// Widgets never hard-code a color: they read `context.colors.<token>`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundTint,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.onPrimary,
    required this.cardFrom,
    required this.cardTo,
    required this.onCard,
    required this.onCardMuted,
    required this.cardLine,
    required this.band,
    required this.bandButton,
    required this.onBand,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.onDanger,
    required this.shadow,
    required this.scrim,
    required this.skeleton,
  });

  /// Page background and the soft lavender wash behind it.
  final Color background;
  final Color backgroundTint;

  final Color surface;
  final Color surfaceMuted;
  final Color border;

  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;

  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;
  final Color onPrimary;

  /// Citizen card gradient.
  final Color cardFrom;
  final Color cardTo;
  final Color onCard;
  final Color onCardMuted;
  final Color cardLine;

  /// Dark band of the Digital ID screen (Show code / Share ID).
  final Color band;
  final Color bandButton;
  final Color onBand;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color onDanger;

  final Color shadow;
  final Color scrim;
  final Color skeleton;

  static const light = AppColors(
    background: Color(0xFFF6F7FC),
    backgroundTint: Color(0xFFE6EAFB),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F3FB),
    border: Color(0xFFE5E8F2),
    ink: Color(0xFF111833),
    inkSecondary: Color(0xFF5D6478),
    inkTertiary: Color(0xFF8A90A3),
    primary: Color(0xFF3446DB),
    primaryPressed: Color(0xFF2636C2),
    primarySoft: Color(0xFFE8EBFD),
    onPrimary: Color(0xFFFFFFFF),
    cardFrom: Color(0xFF17207A),
    cardTo: Color(0xFF3A50D8),
    onCard: Color(0xFFFFFFFF),
    onCardMuted: Color(0xCCFFFFFF),
    cardLine: Color(0x1FFFFFFF),
    band: Color(0xFF1C2233),
    bandButton: Color(0xFF2A3145),
    onBand: Color(0xFFFFFFFF),
    success: Color(0xFF16875A),
    successSoft: Color(0xFFE3F5EC),
    warning: Color(0xFFA35F00),
    warningSoft: Color(0xFFFFF1DC),
    danger: Color(0xFFC62E3C),
    dangerSoft: Color(0xFFFCE7E9),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x14243078),
    scrim: Color(0x66111833),
    skeleton: Color(0xFFE7EAF3),
  );

  static const dark = AppColors(
    background: Color(0xFF0B0F1E),
    backgroundTint: Color(0xFF151C3D),
    surface: Color(0xFF151A2D),
    surfaceMuted: Color(0xFF1C2238),
    border: Color(0xFF262D45),
    ink: Color(0xFFF1F3FA),
    inkSecondary: Color(0xFFA9AFC4),
    inkTertiary: Color(0xFF7E859C),
    primary: Color(0xFF6C7CFF),
    primaryPressed: Color(0xFF5566F2),
    primarySoft: Color(0xFF232B56),
    onPrimary: Color(0xFFFFFFFF),
    cardFrom: Color(0xFF141B66),
    cardTo: Color(0xFF3446C8),
    onCard: Color(0xFFFFFFFF),
    onCardMuted: Color(0xCCFFFFFF),
    cardLine: Color(0x1FFFFFFF),
    band: Color(0xFF060914),
    bandButton: Color(0xFF1B2133),
    onBand: Color(0xFFFFFFFF),
    success: Color(0xFF4CC98E),
    successSoft: Color(0xFF12301F),
    warning: Color(0xFFF2B252),
    warningSoft: Color(0xFF33260F),
    danger: Color(0xFFFF6B77),
    dangerSoft: Color(0xFF3A1519),
    onDanger: Color(0xFF1A0508),
    shadow: Color(0x40000000),
    scrim: Color(0x99000000),
    skeleton: Color(0xFF1F2640),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      backgroundTint: l(backgroundTint, other.backgroundTint),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      ink: l(ink, other.ink),
      inkSecondary: l(inkSecondary, other.inkSecondary),
      inkTertiary: l(inkTertiary, other.inkTertiary),
      primary: l(primary, other.primary),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      primarySoft: l(primarySoft, other.primarySoft),
      onPrimary: l(onPrimary, other.onPrimary),
      cardFrom: l(cardFrom, other.cardFrom),
      cardTo: l(cardTo, other.cardTo),
      onCard: l(onCard, other.onCard),
      onCardMuted: l(onCardMuted, other.onCardMuted),
      cardLine: l(cardLine, other.cardLine),
      band: l(band, other.band),
      bandButton: l(bandButton, other.bandButton),
      onBand: l(onBand, other.onBand),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      onDanger: l(onDanger, other.onDanger),
      shadow: l(shadow, other.shadow),
      scrim: l(scrim, other.scrim),
      skeleton: l(skeleton, other.skeleton),
    );
  }
}
