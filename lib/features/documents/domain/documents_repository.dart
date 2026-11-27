import '../../../core/pagination/page.dart';
import 'civic_document.dart';

abstract interface class DocumentsRepository {
  Future<Page<CivicDocument>> list({String? cursor});
  Future<CivicDocument> get(String id);
}
