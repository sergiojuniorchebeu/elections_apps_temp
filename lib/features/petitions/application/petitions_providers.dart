import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/page.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/state/cache_for.dart';
import '../../../core/state/offline_first.dart';
import '../../../core/state/paginated_notifier.dart';
import '../domain/petition.dart';
import '../domain/petitions_repository.dart';

final petitionsRepositoryProvider = Provider<PetitionsRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final petitionsProvider =
    NotifierProvider.autoDispose<PetitionsNotifier, PagedState<Petition>>(
      PetitionsNotifier.new,
    );

class PetitionsNotifier extends PaginatedNotifier<Petition> {
  @override
  Future<Page<Petition>> fetchPage(String? cursor) =>
      ref.read(petitionsRepositoryProvider).list(cursor: cursor);
  @override
  bool sameItem(Petition a, Petition b) => a.id == b.id;
}

final petitionProvider = AsyncNotifierProvider.autoDispose
    .family<PetitionNotifier, Petition, String>(PetitionNotifier.new);

class PetitionNotifier extends DetailNotifier<Petition> {
  PetitionNotifier(super.id);

  @override
  Future<Petition> build() {
    ref.cacheFor(const Duration(minutes: 5));
    return super.build();
  }

  @override
  Future<Petition> fetch(String id) =>
      ref.read(petitionsRepositoryProvider).get(id);
}

final signControllerProvider = NotifierProvider.autoDispose
    .family<SignController, ActionState<Petition>, String>(SignController.new);

/// Signing: one idempotency key per attempt, so a retry after a lost
/// answer never counts twice.
class SignController extends ActionController<Petition> {
  SignController(this.id);
  final String id;

  Future<Petition?> sign() async {
    final p = await run(
      (key) => ref.read(petitionsRepositoryProvider).sign(id, idempotencyKey: key),
    );
    if (p != null) {
      ref.read(petitionProvider(id).notifier).set(p);
      if (ref.read(petitionsProvider.exists)) {
        ref.read(petitionsProvider.notifier).replaceWhere(p);
      }
    }
    return p;
  }
}
