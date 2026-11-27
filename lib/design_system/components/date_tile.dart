import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';

/// "NOV / 12" calendar tile. Formatting is done by the caller.
class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.month, required this.day, this.muted = false});

  final String month;
  final String day;

  /// Past dates.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = muted ? c.inkTertiary : c.primary;
    return Container(
      width: AppSizes.dateTile,
      decoration: BoxDecoration(
        color: muted ? c.surfaceMuted : c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: accent,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs / 2),
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: context.text.overline.copyWith(color: c.onPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Text(
              day,
              style: context.text.title.copyWith(
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
