import 'home_feed.dart';

abstract interface class HomeRepository {
  Future<HomeFeed> feed();

  /// Last known feed (offline copy), or null. Never throws.
  Future<HomeFeed?> peek();
}
