import '../../../core/network/api_client.dart';
import '../domain/signature.dart';

/// `{"strokes": [[[x, y], ...], ...], "updated_at": "..."}`, x and y
/// between 0 and 1 (docs/api_contract.yaml, `Signature`).
abstract final class SignatureJson {
  static Signature decode(Map<String, Object?> m) => Signature(
    strokes: [
      for (final stroke in (m['strokes']! as List).cast<List<Object?>>())
        [
          for (final p in stroke.cast<List<Object?>>())
            SignaturePoint((p[0]! as num).toDouble(), (p[1]! as num).toDouble()),
        ],
    ],
    updatedAt: m.dateOrNull('updated_at'),
  );

  /// Three decimals: enough for any screen, half the size.
  static Map<String, Object?> encode(Signature s) => {
    'strokes': [
      for (final stroke in s.strokes)
        [
          for (final p in stroke) [_round(p.x), _round(p.y)],
        ],
    ],
  };

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;
}
