import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/page.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/state/cache_for.dart';
import '../../../core/state/offline_first.dart';
import '../../../core/state/paginated_notifier.dart';
import '../domain/election.dart';
import '../domain/elections_repository.dart';

final electionsRepositoryProvider = Provider<ElectionsRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final electionsProvider =
    NotifierProvider.autoDispose<ElectionsNotifier, PagedState<Election>>(
      ElectionsNotifier.new,
    );

class ElectionsNotifier extends PaginatedNotifier<Election> {
  @override
  Future<Page<Election>> fetchPage(String? cursor) =>
      ref.read(electionsRepositoryProvider).list(cursor: cursor);
  @override
  bool sameItem(Election a, Election b) => a.id == b.id;
}

final electionProvider = AsyncNotifierProvider.autoDispose
    .family<ElectionNotifier, Election, String>(ElectionNotifier.new);

class ElectionNotifier extends DetailNotifier<Election> {
  ElectionNotifier(super.id);

  @override
  Future<Election> build() {
    ref.cacheFor(const Duration(minutes: 5));
    return super.build();
  }

  @override
  Future<Election> fetch(String id) =>
      ref.read(electionsRepositoryProvider).get(id);
}

final reminderControllerProvider = NotifierProvider.autoDispose
    .family<ReminderController, ActionState<Election>, String>(
      ReminderController.new,
    );

class ReminderController extends ActionController<Election> {
  ReminderController(this.id);
  final String id;

  Future<Election?> toggle(bool enabled) async {
    final e = await run(
      (_) => ref.read(electionsRepositoryProvider).setReminder(id, enabled),
    );
    if (e != null) {
      ref.read(electionProvider(id).notifier).set(e);
      if (ref.read(electionsProvider.exists)) {
        ref.read(electionsProvider.notifier).replaceWhere(e);
      }
    }
    return e;
  }
}
