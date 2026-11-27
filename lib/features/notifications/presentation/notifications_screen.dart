import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/paged_list.dart';
import '../application/notifications_providers.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static IconData iconOf(NotificationKind k) => switch (k) {
    NotificationKind.election => AppIcons.elections,
    NotificationKind.petition => AppIcons.petitions,
    NotificationKind.identity => AppIcons.identity,
    NotificationKind.security => Icons.shield_outlined,
    NotificationKind.service => Icons.account_balance_outlined,
    NotificationKind.unknown => AppIcons.notifications,
  };

  /// Where tapping a notification leads, if anywhere.
  static String? routeOf(AppNotification n) {
    final id = n.targetId;
    if (!Routes.isValidId(id)) {
      return n.kind == NotificationKind.identity || n.kind == NotificationKind.security
          ? Routes.digitalId
          : null;
    }
    return switch (n.kind) {
      NotificationKind.election => Routes.election(id!),
      NotificationKind.petition => Routes.petition(id!),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final hasUnread = state.items.any((n) => !n.read);
    return PageScaffold(
      title: NotificationStrings.title,
      actions: [
        if (hasUnread)
          CircleIconButton(
            icon: Icons.done_all_rounded,
            semanticLabel: NotificationStrings.markAllRead,
            elevated: false,
            onPressed: () async {
              final f = await notifier.markAllRead();
              if (f != null && context.mounted) showFailureSnack(context, f);
            },
          ),
      ],
      body: PagedList<AppNotification>(
        state: state,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        groupBy: (n) => Formats.dayHeader(n.at),
        empty: const StateView(
          icon: Icons.notifications_off_outlined,
          title: NotificationStrings.emptyTitle,
          message: NotificationStrings.emptyBody,
        ),
        itemBuilder: (context, n) => _NotificationTile(
          notification: n,
          onTap: () {
            notifier.markRead(n);
            final route = routeOf(n);
            if (route != null) context.push(route);
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final n = notification;
    return AppCard(
      color: n.read ? c.surface : c.surfaceMuted,
      semanticLabel: n.read ? null : NotificationStrings.unread,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
            child: Icon(NotificationsScreen.iconOf(n.kind), color: c.primary, size: AppSizes.iconSm + 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: n.read ? t.body : t.bodyStrong,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        Formats.relative(n.at),
                        textAlign: TextAlign.end,
                        style: t.caption.copyWith(color: c.inkTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  n.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: t.small.copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
          if (!n.read) ...[
            const SizedBox(width: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Container(
                width: AppSizes.dot,
                height: AppSizes.dot,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
