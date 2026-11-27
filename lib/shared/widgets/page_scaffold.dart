import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design_system/design_system.dart';
import '../../l10n/strings.dart';

/// Full-screen page above the tabs: back button, title, lavender
/// background, content centered on tablets.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  /// Pinned bottom area (main button), kept above the keyboard.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.of(context).canPop();
    return Scaffold(
      backgroundColor: context.colors.background,
      body: AppBackground(
        child: SafeArea(
          bottom: bottom == null,
          child: Column(
            children: [
              MaxWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      if (canPop)
                        CircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          semanticLabel: CommonStrings.back,
                          elevated: false,
                          onPressed: () => context.pop(),
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.subtitle,
                          ),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              ),
              Expanded(child: MaxWidth(child: body)),
              if (bottom != null)
                MaxWidth(
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.xs,
                        AppSpacing.gutter,
                        0,
                      ),
                      child: bottom,
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
