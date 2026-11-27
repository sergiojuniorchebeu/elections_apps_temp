import '../core/error/failure.dart';
import '../core/pagination/page.dart';

/// Cursor pagination over an in-memory list, like a server would do it.
Page<T> paginate<T>(List<T> all, String? cursor, {int size = defaultPageSize}) {
  var offset = 0;
  if (cursor != null) {
    final parsed = cursor.startsWith('o:') ? int.tryParse(cursor.substring(2)) : null;
    if (parsed == null || parsed < 0) {
      throw const ValidationFailure(message: 'Curseur de page invalide.');
    }
    offset = parsed;
  }
  final end = (offset + size).clamp(0, all.length);
  final items = offset >= all.length ? <T>[] : all.sublist(offset, end);
  return Page(items: items, nextCursor: end < all.length ? 'o:$end' : null);
}
