import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';
import '../tokens/app_icons.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// The only button of the app. While [loading], it keeps its width, shows
/// a spinner, ignores taps and tells screen readers it is busy.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.onPrimary, null),
      AppButtonVariant.secondary => (c.surface, c.ink, c.border),
      AppButtonVariant.ghost => (Colors.transparent, c.primary, null),
      AppButtonVariant.danger => (c.dangerSoft, c.danger, null),
    };
    final enabled = onPressed != null && !loading;
    final child = Stack(
      alignment: Alignment.center,
      children: [
        // Keeps the width of the label while the spinner shows.
        Opacity(
          opacity: loading ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcon(icon, size: AppSizes.iconSm, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
        if (loading)
          SizedBox.square(
            dimension: AppSizes.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
      ],
    );
    final button = Semantics(
      button: true,
      container: true,
      enabled: enabled,
      label: loading ? '$label, in progress' : label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null && !loading ? 0.45 : 1,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Center(widthFactor: 1, child: child),
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Round icon button (search, bell, back...). Always 48 × 48 to touch,
/// always labelled for screen readers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.badge = false,
    this.background,
    this.foreground,
    this.size = AppSizes.roundButton,
    this.elevated = true,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Small dot (unread notifications). Also announced to screen readers.
  final bool badge;
  final Color? background;
  final Color? foreground;
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      container: true,
      label: badge ? '$semanticLabel, new items' : semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size < AppSizes.touch ? AppSizes.touch : size,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: elevated ? AppShadows.soft(c.shadow) : null,
                ),
                child: Material(
                  color: background ?? c.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPressed,
                    child: SizedBox.square(
                      dimension: size,
                      child: AppIcon(
                        icon,
                        size: AppSizes.icon,
                        color: foreground ?? c.ink,
                      ),
                    ),
                  ),
                ),
              ),
              if (badge)
                PositionedDirectional(
                  top: AppSpacing.xxs / 2,
                  end: AppSpacing.xxs / 2,
                  child: Container(
                    width: AppSizes.dot,
                    height: AppSizes.dot,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded chip-button ("View all", "Manage").
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      container: true,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.touch),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: filled ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  label,
                  style: context.text.small.copyWith(
                    color: filled ? c.ink : c.inkSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text link (e.g. "Forgot password?"), 48 pt tall to touch.
class TextLink extends StatelessWidget {
  const TextLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    container: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.touch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: context.text.label.copyWith(color: context.colors.primary),
            ),
          ),
        ),
      ),
    ),
  );
}
