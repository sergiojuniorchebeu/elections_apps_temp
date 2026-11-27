import '../../../core/pagination/page.dart';
import 'election.dart';

abstract interface class ElectionsRepository {
  /// Upcoming first (soonest first), then past ones (latest first).
  Future<Page<Election>> list({String? cursor});

  /// Throws `NotFoundFailure` for an unknown id.
  Future<Election> get(String id);

  /// Throws `ConflictFailure` for a closed election.
  Future<Election> setReminder(String id, bool enabled);
}
