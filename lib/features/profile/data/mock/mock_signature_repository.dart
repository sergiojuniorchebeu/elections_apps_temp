import '../../../../core/error/failure.dart';
import '../../../../mock/mock_server.dart';
import '../../domain/signature.dart';

/// Simulated signatures, one per account, kept in memory. Same rules as
/// a real server ([SignatureRules]).
final class MockSignatureRepository implements SignatureRepository {
  MockSignatureRepository(this._server);
  final MockServer _server;
  final Map<String, Signature> _byUser = {};

  @override
  Future<Signature?> get() => _server.call((user) => _byUser[user!.id]);

  @override
  Future<Signature> save(Signature signature) =>
      _server.call(write: true, (user) {
        if (SignatureRules.validate(signature) case final error?) {
          throw ValidationFailure(fieldErrors: {SignatureRules.field: error});
        }
        final saved = Signature(strokes: signature.strokes, updatedAt: _server.clock());
        _byUser[user!.id] = saved;
        _server.record(
          user.id,
          kind: 'identity',
          title: 'Signature enregistrée',
          body: 'Elle sera utilisée pour signer les pétitions.',
        );
        return saved;
      });

  @override
  Future<void> delete() =>
      _server.call(write: true, (user) => _byUser.remove(user!.id));
}
