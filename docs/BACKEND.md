# Plug your back-end

The screens only know **interfaces** (`lib/features/*/domain/*_repository.dart`).
Plugging a back-end = writing one implementation per interface and
declaring it in `lib/backend.dart`. No screen, no controller changes.

| Interface | File |
| --- | --- |
| `AuthRepository` | `features/auth/domain/auth_repository.dart` |
| `IdentityRepository` | `features/identity/domain/identity_repository.dart` |
| `HomeRepository` | `features/home/domain/home_repository.dart` |
| `NotificationsRepository` | `features/notifications/domain/notifications_repository.dart` |
| `ActivityRepository` | `features/activity/domain/activity_repository.dart` |
| `ElectionsRepository` | `features/elections/domain/elections_repository.dart` |
| `PetitionsRepository` | `features/petitions/domain/petitions_repository.dart` |
| `DocumentsRepository` | `features/documents/domain/documents_repository.dart` |
| `ServicesRepository` | `features/services/domain/services_repository.dart` |
| `SearchRepository` | `features/search/domain/search_result.dart` |
| `Reachability` | `core/network/reachability.dart` (offline banner) |

## Option A — your server speaks the REST contract

Implement [`api_contract.yaml`](api_contract.yaml). Then:

```sh
flutter run --dart-define=BACKEND=rest --dart-define=API_BASE_URL=https://api.example.org/v1
```

What the contract fixes, so the app works unchanged:

- **Errors**: `{"error": {"code", "message", "fields"}}` with the status
  codes listed in the contract (422 field errors, 401 `session_ended` /
  `invalid_credentials`, 409 conflict, 429 + `Retry-After`…), and an
  `X-Request-Id` header shown to users for support.
- **Pagination**: `?cursor=&limit=` → `{"items": [...], "next_cursor": "…" | null}`.
- **Session**: short access token (Bearer) + single-use refresh token
  (`POST /auth/refresh`). The app renews once on 401 and replays; a network
  error during renewal never signs out.
- **Idempotency**: sensitive writes carry `Idempotency-Key`; the same key
  must return the same result without doing the action twice.

## Option B — any other back-end (Firebase, Supabase, GraphQL…)

### 1. Implement the interfaces

```dart
// lib/features/petitions/data/firebase/firebase_petitions_repository.dart
final class FirebasePetitionsRepository implements PetitionsRepository {
  FirebasePetitionsRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<Page<Petition>> list({String? cursor}) => _guard(() async {
    var q = _db.collection('petitions').orderBy('signatures', descending: true).limit(defaultPageSize);
    if (cursor != null) q = q.startAfterDocument(await _db.doc('petitions/$cursor').get());
    final snap = await q.get();
    return Page(
      items: snap.docs.map(_fromDoc).toList(),
      nextCursor: snap.docs.length < defaultPageSize ? null : snap.docs.last.id,
    );
  });

  @override
  Future<Petition> sign(String id, {required String idempotencyKey}) => _guard(() async {
    // A transaction keyed by idempotencyKey: signing twice counts once.
    ...
  });
  // get(...)
}
```

### 2. Translate errors into `Failure`

Nothing else may leave a repository (`lib/core/error/failure.dart`):

```dart
Future<T> _guard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on FirebaseException catch (e) {
    throw switch (e.code) {
      'unavailable' => const NetworkFailure(),
      'deadline-exceeded' => const TimeoutFailure(),
      'unauthenticated' => const AuthFailure(sessionEnded: true),
      'permission-denied' => const AuthFailure(),
      'not-found' => const NotFoundFailure(),
      'already-exists' || 'failed-precondition' => const ConflictFailure(),
      'resource-exhausted' => const RateLimitFailure(),
      'invalid-argument' => ValidationFailure(message: e.message),
      _ => const ServerFailure(),
    };
  }
}
```

Field errors go in `ValidationFailure(fieldErrors: {'email': '…'})` with
the field names of the domain (`AuthFields`, `IdentityFields`,
`ServiceFields`): the form shows them under the right field.

Sessions: if your SDK manages tokens itself (Firebase, Supabase), store
whatever identifies the session in `Session` and make `renew` refresh it;
throw `AuthFailure(sessionEnded: true)` when it is gone for good.

### 3. Declare it in `lib/backend.dart`

```dart
enum BackendKind { mock, rest, firebase }   // core/config/app_config.dart

List<Override> backendOverrides(AppConfig config) => switch (config.backend) {
  BackendKind.mock => mockOverrides(),
  BackendKind.rest => restOverrides(config),
  BackendKind.firebase => [
    petitionsRepositoryProvider.overrideWith(
      (ref) => FirebasePetitionsRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
    ),
    // … one line per interface
  ],
};
```

Firebase config files (`google-services.json`, `GoogleService-Info.plist`)
are git-ignored: each person adds their own.

### 4. Run the contract tests

`test/contract/contract_suites.dart` holds the behaviour every
implementation must have (pagination, `Failure` translation, idempotency,
session renewal). Add an environment for yours and run it:

```dart
// test/contract/my_backend_contract_test.dart
final class MyEnv extends ContractEnv { /* build your repositories */ }

void main() => runContractSuites(MyEnv.new);
```

```sh
flutter test test/contract
```

Green = the screens will work on your back-end.

## Supabase skeleton

```dart
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    try {
      final r = await _client.auth.signInWithPassword(email: email, password: password);
      final s = r.session!;
      return AuthResult(
        session: Session(
          userId: s.user.id,
          accessToken: s.accessToken,
          refreshToken: s.refreshToken ?? '',
          expiresAt: DateTime.fromMillisecondsSinceEpoch((s.expiresAt ?? 0) * 1000),
        ),
        user: User(id: s.user.id, firstName: '', lastName: '', email: s.user.email ?? email),
      );
    } on AuthException catch (e) {
      throw e.statusCode == '400'
          ? const AuthFailure(reason: AuthFailureReason.invalidCredentials)
          : const ServerFailure();
    }
  }
  // signUp, requestPasswordReset, renew, currentUser, signOut…
}
```
