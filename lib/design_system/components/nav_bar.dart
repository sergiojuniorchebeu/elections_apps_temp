import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';
import '../tokens/app_icons.dart';

final class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Floating pill tab bar: the selected tab is a filled blue capsule.
/// Content scrolls behind it (see [AppNavBar.bottomInset]).
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Bottom padding a scrolling tab must add so its last item clears the
  /// bar.
  static double bottomInset(BuildContext context) =>
      AppSizes.navBarHeight +
      AppSizes.navBarMargin +
      MediaQuery.paddingOf(context).bottom +
      AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSizes.navBarMargin),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl + 8),
                border: Border.all(color: c.border),
                boxShadow: AppShadows.soft(c.shadow),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelect(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onPrimary : c.inkSecondary;
    // The bar keeps its height at large text sizes: labels shrink instead.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);
    return Semantics(
      button: true,
      selected: selected,
      container: true,
      label: item.label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: context.reduceMotion ? Duration.zero : AppDurations.medium,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: SizedBox(
              height: AppSizes.navBarHeight - AppSpacing.md,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(item.icon, size: AppSizes.icon, color: fg),
                  const SizedBox(height: AppSpacing.xxs / 2),
                  MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: scaler),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
