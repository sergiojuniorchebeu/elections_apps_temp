import 'package:material_ui/material_ui.dart';

import '../../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';

/// Centers content at [maxWidth] on tablets; phones are never affected.
class MaxWidth extends StatelessWidget {
  const MaxWidth({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// The soft lavender wash behind every page (as on the mockups).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.background, c.background, c.backgroundTint],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}

/// White rounded container. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.radius = AppRadius.lg,
    this.semanticLabel,
    this.bordered = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final String? semanticLabel;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final card = Material(
      color: color ?? c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: bordered ? BorderSide(color: c.border) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null && semanticLabel == null) return card;
    final labelled = Semantics(
      button: onTap != null,
      container: true,
      label: semanticLabel,
      child: card,
    );
    // A tappable card is read as one button, with the text it contains.
    return onTap == null ? labelled : MergeSemantics(child: labelled);
  }
}

/// Section title with an optional trailing action ("View all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(title, style: context.text.headline),
        ),
      ),
      ?action,
    ],
  );
}

/// One "label .... value" row (Personal details).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: context.text.small.copyWith(color: c.inkSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: context.text.small.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row with a leading icon tile, title, subtitle and trailing widget
/// (settings, lists). At least 48 pt tall.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.semanticLabel,
    this.footer,
  });

  /// Shown under the subtitle (status pill...).
  final Widget? footer;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touch + 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: AppSizes.touch - 8,
                      height: AppSizes.touch - 8,
                      decoration: BoxDecoration(
                        color: iconBackground ?? c.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: AppSizes.iconSm + 2,
                        color: iconColor ?? c.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.text.bodyStrong.copyWith(
                            color: titleColor ?? c.ink,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: context.text.small.copyWith(
                              color: c.inkSecondary,
                            ),
                          ),
                        if (footer != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet above everything (including the floating tab bar), sized
/// to its content, scrollable, keyboard-aware.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: dismissible,
  enableDrag: dismissible,
  constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      child: SafeArea(top: false, child: builder(context)),
    ),
  ),
);

/// Adaptive confirmation (Cupertino look on iOS, Material on Android).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showAdaptiveDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        adaptiveAction(context, CommonStrings.cancel, () => Navigator.pop(context, false)),
        adaptiveAction(
          context,
          confirmLabel,
          () => Navigator.pop(context, true),
          destructive: destructive,
        ),
      ],
    ),
  );
  return result ?? false;
}

Widget adaptiveAction(
  BuildContext context,
  String label,
  VoidCallback onPressed, {
  bool destructive = false,
}) {
  final style = destructive
      ? TextStyle(color: context.colors.danger)
      : null;
  return TextButton(
    onPressed: onPressed,
    child: Text(label, style: style),
  );
}
