import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design_system/design_system.dart';
import '../../l10n/strings.dart';
import '../widgets/page_scaffold.dart';

/// Unknown route or invalid link.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.homeRoute});

  final String homeRoute;

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: CommonStrings.notFoundTitle,
    body: Center(
      child: StateView(
        icon: Icons.link_off_rounded,
        title: CommonStrings.notFoundHeading,
        message: CommonStrings.notFoundBody,
        actionLabel: CommonStrings.goHome,
        onAction: () => context.go(homeRoute),
      ),
    ),
  );
}
