import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/pagination/page.dart';
import '../../../core/state/app_resume.dart';
import '../../../core/state/connectivity.dart';
import '../../../core/state/paginated_notifier.dart';
import '../../../core/state/session_scope.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final notificationsProvider = NotifierProvider.autoDispose<
  NotificationsNotifier,
  PagedState<AppNotification>
>(NotificationsNotifier.new);

class NotificationsNotifier extends PaginatedNotifier<AppNotification> {
  @override
  Future<Page<AppNotification>> fetchPage(String? cursor) =>
      ref.read(notificationsRepositoryProvider).list(cursor: cursor);

  @override
  bool sameItem(AppNotification a, AppNotification b) => a.id == b.id;

  /// Optimistic: the dot disappears at once, comes back if it fails.
  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    try {
      await optimistic(
        (items) => [for (final i in items) i.id == n.id ? i.markedRead() : i],
        () => ref.read(notificationsRepositoryProvider).markRead(n.id),
      );
    } on Failure {
      // Reverted; the next refresh will tell.
    }
    ref.invalidate(unreadCountProvider);
  }

  Future<Failure?> markAllRead() async {
    try {
      await optimistic(
        (items) => [for (final i in items) i.markedRead()],
        () => ref.read(notificationsRepositoryProvider).markAllRead(),
      );
      return null;
    } on Failure catch (f) {
      return f;
    } finally {
      ref.invalidate(unreadCountProvider);
    }
  }
}

/// Unread badge on the bell (home and Digital ID).
final unreadCountProvider = FutureProvider<int>((ref) {
  ref.watch(sessionScopeProvider);
  ref.listen(appResumeProvider, (_, _) => ref.invalidateSelf());
  return guard(ref, () => ref.read(notificationsRepositoryProvider).unreadCount());
});
