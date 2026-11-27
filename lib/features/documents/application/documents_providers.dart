import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/page.dart';
import '../../../core/state/cache_for.dart';
import '../../../core/state/offline_first.dart';
import '../../../core/state/paginated_notifier.dart';
import '../domain/civic_document.dart';
import '../domain/documents_repository.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final documentsProvider =
    NotifierProvider.autoDispose<DocumentsNotifier, PagedState<CivicDocument>>(
      DocumentsNotifier.new,
    );

class DocumentsNotifier extends PaginatedNotifier<CivicDocument> {
  @override
  Future<Page<CivicDocument>> fetchPage(String? cursor) =>
      ref.read(documentsRepositoryProvider).list(cursor: cursor);
}

final documentProvider = AsyncNotifierProvider.autoDispose
    .family<DocumentNotifier, CivicDocument, String>(DocumentNotifier.new);

class DocumentNotifier extends DetailNotifier<CivicDocument> {
  DocumentNotifier(super.id);

  @override
  Future<CivicDocument> build() {
    ref.cacheFor(const Duration(minutes: 5));
    return super.build();
  }

  @override
  Future<CivicDocument> fetch(String id) =>
      ref.read(documentsRepositoryProvider).get(id);
}
