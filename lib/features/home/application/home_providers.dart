import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/offline_first.dart';
import '../domain/home_feed.dart';
import '../domain/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final homeFeedProvider = AsyncNotifierProvider<HomeFeedNotifier, HomeFeed>(
  HomeFeedNotifier.new,
);

class HomeFeedNotifier extends OfflineFirstNotifier<HomeFeed> {
  @override
  Future<HomeFeed?> peek() => ref.read(homeRepositoryProvider).peek();
  @override
  Future<HomeFeed> fetch() => ref.read(homeRepositoryProvider).feed();
}
