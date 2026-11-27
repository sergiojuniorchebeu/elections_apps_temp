import 'package:material_ui/material_ui.dart';

import '../../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';
import '../tokens/app_icons.dart';
import 'buttons.dart';

/// Placeholder block while loading. Pulses unless "reduce motion" is on;
/// stops when off screen (`TickerMode`).
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = AppSpacing.md,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
    child: Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: context.colors.skeleton,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// A list of skeleton rows for list screens.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: CommonStrings.loading,
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Skeleton(width: 44, height: 44, radius: AppRadius.pill),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14),
                      SizedBox(height: AppSpacing.xs),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: Skeleton(height: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Full-area message: empty list, error, nothing found.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.tone = StateTone.neutral,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final StateTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (tone) {
      StateTone.neutral => (c.primary, c.primarySoft),
      StateTone.danger => (c.danger, c.dangerSoft),
    };
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: AppIcon(icon, size: AppSizes.iconLg, color: fg),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.subtitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(color: c.inkSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.secondary,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum StateTone { neutral, danger }

/// Small rounded label with an icon ("Verified", "Expired"). Meaning is
/// carried by the text, never by the color alone.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.foreground,
    this.background,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? foreground;
  final Color? background;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = foreground ?? c.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.xs : AppSpacing.sm,
        vertical: dense ? AppSpacing.xxs / 2 : AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: background ?? c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: AppSizes.iconSm - 4, color: fg),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.small.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin progress bar (petition signatures).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.semanticsValue});

  final double value;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      value: semanticsValue,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: AppSizes.progressHeight,
          color: c.primary,
          backgroundColor: c.primarySoft,
        ),
      ),
    );
  }
}

/// Inline message inside a form or a card.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.danger = false,
  });

  final String message;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = danger ? c.danger : c.primary;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: danger ? c.dangerSoft : c.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: AppSizes.iconSm, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(message, style: context.text.small.copyWith(color: c.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
