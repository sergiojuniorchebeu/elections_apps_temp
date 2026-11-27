import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../application/notifications_providers.dart';

/// Bell with the unread dot, used in the headers of several tabs.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return CircleIconButton(
      icon: Icons.notifications_none_rounded,
      semanticLabel: CommonStrings.notifications,
      badge: unread > 0,
      onPressed: () => context.push(Routes.notifications),
    );
  }
}
