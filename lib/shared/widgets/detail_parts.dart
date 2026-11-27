import 'package:material_ui/material_ui.dart';

import '../../design_system/design_system.dart';

/// Big title + optional pill, top of a detail screen.
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.title, this.pill, this.overline});

  final String title;
  final Widget? pill;
  final String? overline;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (overline != null) ...[
        Text(overline!, style: context.text.overline.copyWith(color: context.colors.primary)),
        const SizedBox(height: AppSpacing.xxs),
      ],
      Semantics(header: true, child: Text(title, style: context.text.title)),
      if (pill != null) ...[const SizedBox(height: AppSpacing.sm), pill!],
    ],
  );
}

/// Small grey section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: context.text.label.copyWith(color: context.colors.inkSecondary),
      ),
    ),
  );
}
