import 'package:elections_app/core/core_providers.dart';
import 'package:elections_app/core/error/failure.dart';
import 'package:elections_app/core/network/reachability.dart';
import 'package:elections_app/core/pagination/page.dart';
import 'package:elections_app/core/state/action_controller.dart';
import 'package:elections_app/core/state/connectivity.dart';
import 'package:elections_app/core/state/paginated_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Reach implements Reachability {
  bool ok = true;
  @override
  Future<bool> check() async => ok;
}

/// Serves pages of ints; can be told to fail.
class _Source {
  Failure? fail;
  int calls = 0;
  Future<Page<int>> page(String? cursor) async {
    calls++;
    await Future<void>.delayed(Duration.zero);
    if (fail != null) throw fail!;
    final start = cursor == null ? 0 : int.parse(cursor);
    final items = [for (var i = start; i < start + 10 && i < 25; i++) i];
    return Page(items: items, nextCursor: start + 10 < 25 ? '${start + 10}' : null);
  }
}

final _source = _Source();

class _Ints extends PaginatedNotifier<int> {
  @override
  Future<Page<int>> fetchPage(String? cursor) => _source.page(cursor);
}

final _intsProvider = NotifierProvider<_Ints, PagedState<int>>(_Ints.new);

class _Save extends ActionController<String> {}

final _saveProvider = NotifierProvider<_Save, ActionState<String>>(_Save.new);

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [reachabilityProvider.overrideWithValue(_Reach())],
    retry: (_, _) => null,
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  setUp(() {
    _source
      ..fail = null
      ..calls = 0;
  });

  group('PaginatedNotifier', () {
    test('first page, then the next ones until the end', () async {
      final c = _container();
      c.listen(_intsProvider, (_, _) {});
      await _settle();
      expect(c.read(_intsProvider).items.length, 10);
      await c.read(_intsProvider.notifier).loadMore();
      await c.read(_intsProvider.notifier).loadMore();
      final s = c.read(_intsProvider);
      expect(s.items, List.generate(25, (i) => i));
      expect(s.hasMore, isFalse);
    });

    test('a failed refresh keeps the list', () async {
      final c = _container();
      c.listen(_intsProvider, (_, _) {});
      await _settle();
      _source.fail = const ServerFailure();
      final f = await c.read(_intsProvider.notifier).refresh();
      expect(f, isA<ServerFailure>());
      expect(c.read(_intsProvider).items.length, 10);
      expect(c.read(_intsProvider).isBlockingError, isFalse);
    });

    test('a failing first page is a blocking error', () async {
      _source.fail = const NetworkFailure();
      final c = _container();
      c.listen(_intsProvider, (_, _) {});
      await _settle();
      expect(c.read(_intsProvider).isBlockingError, isTrue);
      expect(c.read(connectivityProvider).online, isFalse);
    });

    test('optimistic update is reverted on failure', () async {
      final c = _container();
      c.listen(_intsProvider, (_, _) {});
      await _settle();
      final n = c.read(_intsProvider.notifier);
      await expectLater(
        n.optimistic((items) => items.skip(1).toList(), () async => throw const ConflictFailure()),
        throwsA(isA<ConflictFailure>()),
      );
      expect(c.read(_intsProvider).items.first, 0);
    });
  });

  group('ActionController', () {
    test('refuses a second call while the first runs', () async {
      final c = _container();
      final n = c.read(_saveProvider.notifier);
      var runs = 0;
      Future<String> slow(String _) async {
        runs++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 'ok';
      }

      final a = n.run(slow);
      final b = n.run(slow);
      expect(await b, isNull);
      expect(await a, 'ok');
      expect(runs, 1);
    });

    test('same idempotency key on retry, new one after success', () async {
      final c = _container();
      final n = c.read(_saveProvider.notifier);
      final keys = <String>[];
      await n.run((k) async {
        keys.add(k);
        throw const TimeoutFailure();
      });
      await n.run((k) async {
        keys.add(k);
        return 'ok';
      });
      await n.run((k) async {
        keys.add(k);
        return 'ok';
      });
      expect(keys[0], keys[1]);
      expect(keys[2], isNot(keys[1]));
    });

    test('writes are refused offline', () async {
      final c = _container();
      c.read(connectivityProvider.notifier).markOffline();
      final n = c.read(_saveProvider.notifier);
      expect(await n.run((_) async => 'x'), isNull);
      expect(c.read(_saveProvider), isA<ActionFailed<String>>());
    });
  });
}
