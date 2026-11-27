import '../../../../core/storage/offline_store.dart';
import '../../../../mock/mock_server.dart';
import '../../domain/home_feed.dart';
import '../../domain/home_repository.dart';
import '../home_json.dart';

/// Simulated home feed. The election and petition come from the other
/// simulated features, wired in `backend.dart`.
final class MockHomeRepository implements HomeRepository {
  MockHomeRepository(
    this._server,
    this._offline, {
    required this.nextElection,
    required this.featuredPetition,
  });

  final MockServer _server;
  final OfflineStore _offline;
  final ElectionTeaser? Function() nextElection;
  final PetitionTeaser? Function(String userId) featuredPetition;

  @override
  Future<HomeFeed> feed() => _server.call((user) async {
    final n = user!.citizenNumber;
    final feed = HomeFeed(
      firstName: user.firstName,
      lastName: user.lastName,
      idLast4: n.substring(n.length - 4),
      idVerified: user.verified,
      nextElection: _server.emptyLists ? null : nextElection(),
      featuredPetition: _server.emptyLists ? null : featuredPetition(user.id),
    );
    await _offline.write(HomeJson.offlineKey, HomeJson.encode(feed));
    return feed;
  });

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
