import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/signature.dart';
import '../signature_json.dart';

/// Reference REST implementation (docs/api_contract.yaml, `/me/signature`).
final class RestSignatureRepository implements SignatureRepository {
  RestSignatureRepository(this._api);
  final ApiClient _api;

  static const _path = '/me/signature';

  @override
  Future<Signature?> get() async {
    try {
      return await _api.get(_path, decode: (j) => SignatureJson.decode(asMap(j)));
    } on NotFoundFailure {
      return null; // none saved yet
    }
  }

  @override
  Future<Signature> save(Signature signature) => _api.put(
    _path,
    body: SignatureJson.encode(signature),
    decode: (j) => SignatureJson.decode(asMap(j)),
  );

  @override
  Future<void> delete() => _api.delete(_path, decode: (_) {});
}
