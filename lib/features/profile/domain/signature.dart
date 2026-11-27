/// A handwritten signature, stored as strokes rather than an image: it
/// is redrawn sharp at any size, animated stroke by stroke, and weighs a
/// few kilobytes.
///
/// Points are normalised to the signature box: x and y between 0 and 1,
/// the box being [aspect] times wider than tall. Any back-end stores it
/// as JSON (see `docs/api_contract.yaml`, `Signature`).
final class Signature {
  const Signature({required this.strokes, this.updatedAt});

  /// Width / height of the box the points refer to.
  static const aspect = 2.5;

  /// Each stroke is one finger-down -> finger-up line.
  final List<List<SignaturePoint>> strokes;
  final DateTime? updatedAt;

  int get pointCount => strokes.fold(0, (n, s) => n + s.length);
  bool get isEmpty => pointCount == 0;
}

final class SignaturePoint {
  const SignaturePoint(this.x, this.y);
  final double x;
  final double y;
}

/// Same rules in every implementation (field `signature`).
abstract final class SignatureRules {
  static const field = 'signature';
  static const minPoints = 12;

  /// Narrower than this share of the box = a dot or a tick, not a
  /// signature.
  static const minWidth = 0.15;

  static String? validate(Signature s) {
    if (s.pointCount < minPoints) return 'Votre signature est trop courte.';
    var minX = 1.0;
    var maxX = 0.0;
    for (final stroke in s.strokes) {
      for (final p in stroke) {
        if (p.x < 0 || p.x > 1 || p.y < 0 || p.y > 1) {
          return 'Votre signature sort du cadre.';
        }
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
      }
    }
    if (maxX - minX < minWidth) return 'Votre signature est trop courte.';
    return null;
  }
}

/// Signature contract. Throws only `Failure`s; a refused signature =
/// `ValidationFailure` keyed by [SignatureRules.field].
abstract interface class SignatureRepository {
  /// Null when none was saved yet.
  Future<Signature?> get();

  /// Replaces the saved signature.
  Future<Signature> save(Signature signature);

  Future<void> delete();
}
