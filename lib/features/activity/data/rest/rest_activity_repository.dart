import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_json.dart';
import '../../../../core/pagination/page.dart';
import '../../domain/activity_entry.dart';
import '../../domain/activity_repository.dart';
import '../activity_json.dart';

final class RestActivityRepository implements ActivityRepository {
  RestActivityRepository(this._api);
  final ApiClient _api;

  @override
  Future<Page<ActivityEntry>> list({
    String? cursor,
    ActivityFilter filter = ActivityFilter.all,
  }) => _api.get(
    '/activity',
    query: {
      'cursor': cursor,
      'limit': defaultPageSize,
      if (filter != ActivityFilter.all) 'kind': filter.name,
    },
    decode: (j) => decodePage(j, ActivityJson.item),
  );
}
