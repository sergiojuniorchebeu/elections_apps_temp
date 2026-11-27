import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/page.dart';
import '../../../core/state/paginated_notifier.dart';
import '../domain/activity_entry.dart';
import '../domain/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final activityFilterProvider =
    NotifierProvider<ActivityFilterController, ActivityFilter>(
      ActivityFilterController.new,
    );

class ActivityFilterController extends Notifier<ActivityFilter> {
  @override
  ActivityFilter build() => ActivityFilter.all;
  void select(ActivityFilter f) => state = f;
}

final activityProvider = NotifierProvider<ActivityNotifier, PagedState<ActivityEntry>>(
  ActivityNotifier.new,
);

class ActivityNotifier extends PaginatedNotifier<ActivityEntry> {
  @override
  PagedState<ActivityEntry> build() {
    ref.watch(activityFilterProvider);
    return super.build();
  }

  @override
  Future<Page<ActivityEntry>> fetchPage(String? cursor) => ref
      .read(activityRepositoryProvider)
      .list(cursor: cursor, filter: ref.read(activityFilterProvider));
}
