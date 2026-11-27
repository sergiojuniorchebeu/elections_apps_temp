import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';

/// Initials in a soft circle ("AM").
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initials, this.size = AppSizes.avatar});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Text(
              initials,
              style: context.text.subtitle.copyWith(color: c.primary),
            ),
          ),
        ),
      ),
    );
  }
}
