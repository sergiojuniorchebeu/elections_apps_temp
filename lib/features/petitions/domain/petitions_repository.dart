import '../../../core/pagination/page.dart';
import 'petition.dart';

abstract interface class PetitionsRepository {
  /// Open petitions first (most signed first), then the others.
  Future<Page<Petition>> list({String? cursor});

  Future<Petition> get(String id);

  /// Signs once. The same [idempotencyKey] never counts twice. Throws
  /// `ConflictFailure` when the petition is closed or already signed.
  Future<Petition> sign(String id, {required String idempotencyKey});
}
