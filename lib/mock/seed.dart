import 'dart:math';

/// Deterministic generator: the same seed gives the same demo world on
/// every launch and in every test.
final class MockSeed {
  MockSeed([this.seed = 42]) : _random = Random(seed);

  final int seed;
  final Random _random;

  int nextInt(int min, int maxInclusive) =>
      min + _random.nextInt(maxInclusive - min + 1);

  double nextDouble() => _random.nextDouble();

  bool chance(double p) => _random.nextDouble() < p;

  T pick<T>(List<T> items) => items[_random.nextInt(items.length)];

  /// A date [minDays]..[maxDays] away from [from] (negative = past).
  DateTime dayOffset(DateTime from, int minDays, int maxDays) => from.add(
    Duration(days: nextInt(minDays, maxDays), minutes: nextInt(0, 23 * 60)),
  );

  String firstName() => pick(_first);
  String lastName() => pick(_last);
  String fullName() => '${firstName()} ${lastName()}';
  String city() => pick(_cities);

  static const _first = [
    'Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Riley', 'Casey', 'Avery',
    'Jamie', 'Noa', 'Elena', 'Malik', 'Ines', 'Yuki', 'Omar', 'Lena',
    'Priya', 'Mateo', 'Chloé', 'Kofi', 'Hana', 'Lucas', 'Amara', 'Theo',
  ];
  static const _last = [
    'Morgan', 'Lee', 'Martin', 'Okafor', 'Garcia', 'Nguyen', 'Dubois',
    'Kowalski', 'Haddad', 'Silva', 'Novak', 'Mensah', 'Rossi', 'Tanaka',
    'Schmidt', 'Diallo', 'Andersen', 'Moreau', 'Costa', 'Ibrahim',
  ];
  static const _cities = [
    'Riverside', 'Northgate', 'Lakeview', 'Vieille Ville', 'Quartier du Port',
    'Greenfield', 'Hillcrest', 'Westbrook',
  ];

  /// Deliberately long, to test wrapping and truncation.
  static const longText =
      'Étendre le réseau cyclable le long de la rivière avec des pistes '
      'protégées, des passages plus sûrs près de chaque école, des abris '
      'vélos couverts dans les trois gares et un bilan public annuel des '
      'accidents, pour que les familles puissent rouler chaque jour sans crainte.';
}
