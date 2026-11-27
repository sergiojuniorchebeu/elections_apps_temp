import 'package:elections_app/features/auth/domain/auth_repository.dart';
import 'package:elections_app/features/auth/domain/auth_rules.dart';
import 'package:elections_app/features/identity/domain/citizen_id.dart';
import 'package:elections_app/features/identity/domain/identity_rules.dart';
import 'package:elections_app/features/petitions/domain/petition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 27);

  test('sign-up rules', () {
    final errors = AuthRules.signUp(
      SignUpRequest(
        firstName: ' ',
        lastName: 'Lee',
        email: 'bad',
        password: 'short',
        dateOfBirth: DateTime(2015),
        acceptedTerms: false,
      ),
      now,
    );
    expect(errors.keys, containsAll([
      AuthFields.firstName,
      AuthFields.email,
      AuthFields.password,
      AuthFields.dateOfBirth,
      AuthFields.acceptedTerms,
    ]));
    expect(errors.containsKey(AuthFields.lastName), isFalse);
  });

  test('age is computed on the birthday, not the year', () {
    expect(AuthRules.dateOfBirth(DateTime(2010, 11, 28), now), isNotNull);
    expect(AuthRules.dateOfBirth(DateTime(2010, 11, 27), now), isNull);
  });

  test('contact rules', () {
    expect(IdentityRules.contact(const ContactUpdate(phone: '+1 555 0134', address: '18 Harbor St')), isEmpty);
    expect(IdentityRules.contact(const ContactUpdate(phone: 'abc', address: 'x')).length, 2);
    expect(IdentityRules.code('SHR-123456'), isNull);
    expect(IdentityRules.code('<script>'), isNotNull);
  });

  test('petition progress is clamped', () {
    Petition p(int s, int g) => Petition(
      id: 'p', title: 't', summary: 's', author: 'a', signatures: s, goal: g,
      status: PetitionStatus.open, deadline: now,
    );
    expect(p(50, 100).progress, 0.5);
    expect(p(150, 100).progress, 1);
    expect(p(1, 0).progress, 0);
  });
}
