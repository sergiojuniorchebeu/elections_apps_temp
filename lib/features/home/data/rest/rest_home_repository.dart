import '../../../../core/network/api_client.dart';
import '../../../../core/storage/offline_store.dart';
import '../../domain/home_feed.dart';
import '../../domain/home_repository.dart';
import '../home_json.dart';

final class RestHomeRepository implements HomeRepository {
  RestHomeRepository(this._api, this._offline);
  final ApiClient _api;
  final OfflineStore _offline;

  @override
  Future<HomeFeed> feed() =>
      _api.get('/home', offlineKey: HomeJson.offlineKey, decode: HomeJson.feed);

  @override
  Future<HomeFeed?> peek() async {
    try {
      final copy = await _offline.read(HomeJson.offlineKey);
      return copy == null ? null : HomeJson.feed(copy.data);
    } on Object {
      return null;
    }
  }
}
