import 'package:material_ui/material_ui.dart';

/// Type scale. Read through `context.text.<style>`; colors are applied by
/// the theme (`ink`) and can be overridden with `.copyWith(color: ...)`.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.display,
    required this.title,
    required this.headline,
    required this.cardName,
    required this.subtitle,
    required this.body,
    required this.bodyStrong,
    required this.small,
    required this.label,
    required this.caption,
    required this.overline,
    required this.number,
  });

  /// Font bundled in assets/fonts (OFL). Change it here only.
  static const family = 'Outfit';

  /// "Your Day / Your Country"
  final TextStyle display;

  /// Screen titles ("Digital ID").
  final TextStyle title;

  /// Section titles ("Your Community").
  final TextStyle headline;

  /// Name on the citizen card.
  final TextStyle cardName;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle small;
  final TextStyle label;
  final TextStyle caption;

  /// "UPCOMING ELECTION", "DIGITAL CITIZEN ID"
  final TextStyle overline;

  /// Values that change (counts, dates in tiles): tabular figures.
  final TextStyle number;

  static AppTypography of(Color ink) {
    TextStyle s(double size, FontWeight w, {double? height, double ls = 0}) =>
        TextStyle(
          fontFamily: family,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: ls,
          color: ink,
        );
    return AppTypography(
      display: s(40, FontWeight.w400, height: 1.08, ls: -0.6),
      title: s(28, FontWeight.w400, height: 1.15, ls: -0.3),
      headline: s(22, FontWeight.w400, height: 1.2, ls: -0.2),
      cardName: s(30, FontWeight.w400, height: 1.1, ls: -0.3),
      subtitle: s(18, FontWeight.w400, height: 1.3),
      body: s(15, FontWeight.w400, height: 1.4),
      bodyStrong: s(15, FontWeight.w500, height: 1.4),
      small: s(13, FontWeight.w400, height: 1.35),
      label: s(14, FontWeight.w500, height: 1.2),
      caption: s(12, FontWeight.w400, height: 1.3),
      overline: s(11, FontWeight.w500, height: 1.2, ls: 0.6),
      number: s(15, FontWeight.w400, height: 1.2).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      display: l(display, other.display),
      title: l(title, other.title),
      headline: l(headline, other.headline),
      cardName: l(cardName, other.cardName),
      subtitle: l(subtitle, other.subtitle),
      body: l(body, other.body),
      bodyStrong: l(bodyStrong, other.bodyStrong),
      small: l(small, other.small),
      label: l(label, other.label),
      caption: l(caption, other.caption),
      overline: l(overline, other.overline),
      number: l(number, other.number),
    );
  }
}
