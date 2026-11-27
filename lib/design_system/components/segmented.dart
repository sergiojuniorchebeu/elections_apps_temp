import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';

/// Horizontal filter chips (All / Identity / Civic...). Scrolls when the
/// labels don't fit.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Semantics(
                button: true,
                selected: v == selected,
                container: true,
                label: labelOf(v),
                excludeSemantics: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSizes.touch),
                  child: Center(
                    child: Material(
                      color: v == selected ? c.ink : c.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: BorderSide(
                          color: v == selected ? c.ink : c.border,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onChanged(v),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            labelOf(v),
                            style: context.text.label.copyWith(
                              color: v == selected ? c.background : c.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
