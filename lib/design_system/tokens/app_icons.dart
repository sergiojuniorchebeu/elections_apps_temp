import 'package:material_ui/material_ui.dart';

/// The app's own icons: PNG drawings in `assets/icons` (black on
/// transparent, 512 px), tinted at runtime like any icon.
///
/// They are exposed as [IconData] so every component that takes an icon
/// (`AppButton`, `AppListTile`, `StateView`, the tab bar...) accepts them
/// unchanged: `icon: AppIcons.petitions`. Components draw icons through
/// [AppIcon], which swaps these codes for the matching image. Material
/// icons keep working everywhere else.
///
/// To change the set: replace the PNG files (same names), or add one here
/// and in [_assets].
abstract final class AppIcons {
  /// Not a real font: a tag that [AppIcon] recognises.
  static const family = 'AppImageIcons';

  static const home = IconData(0xF0001, fontFamily: family);
  static const identity = IconData(0xF0002, fontFamily: family);
  static const activity = IconData(0xF0003, fontFamily: family);
  static const profile = IconData(0xF0004, fontFamily: family);
  static const elections = IconData(0xF0005, fontFamily: family);
  static const petitions = IconData(0xF0006, fontFamily: family);
  static const documents = IconData(0xF0007, fontFamily: family);
  static const services = IconData(0xF0008, fontFamily: family);
  static const notifications = IconData(0xF0009, fontFamily: family);
  static const search = IconData(0xF000A, fontFamily: family);
  static const pen = IconData(0xF000B, fontFamily: family);

  static const _assets = {
    0xF0001: 'assets/icons/home.png',
    0xF0002: 'assets/icons/badge-didentite.png',
    0xF0003: 'assets/icons/activites.png',
    0xF0004: 'assets/icons/profile.png',
    0xF0005: 'assets/icons/elections.png',
    0xF0006: 'assets/icons/petitions.png',
    0xF0007: 'assets/icons/document.png',
    0xF0008: 'assets/icons/services.png',
    0xF0009: 'assets/icons/notifications.png',
    0xF000A: 'assets/icons/recherche.png',
    0xF000B: 'assets/icons/pince-a-stylo.png',
  };

  /// The image behind one of these icons, null for any other icon.
  static AssetImage? imageOf(IconData icon) {
    if (icon.fontFamily != family) return null;
    final path = _assets[icon.codePoint];
    return path == null ? null : AssetImage(path);
  }

  /// Every image, to warm the cache at start-up.
  static Iterable<AssetImage> get all => _assets.values.map(AssetImage.new);
}

/// Draws an icon: one of [AppIcons] (tinted image) or any Material icon.
/// Same size and color rules as [Icon].
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel});

  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final image = icon == null ? null : AppIcons.imageOf(icon);
    if (image == null) {
      return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    }
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    // The drawings fill their whole square; Material glyphs keep a margin.
    // Slightly smaller keeps both families the same visual weight.
    return SizedBox.square(
      dimension: s,
      child: Center(
        child: ImageIcon(
          image,
          size: s * 0.9,
          color: color ?? theme.color,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
