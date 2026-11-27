import '../../../core/pagination/page.dart';
import 'activity_entry.dart';

abstract interface class ActivityRepository {
  /// Newest first.
  Future<Page<ActivityEntry>> list({
    String? cursor,
    ActivityFilter filter = ActivityFilter.all,
  });
}
