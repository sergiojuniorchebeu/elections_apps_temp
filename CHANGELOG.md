# Changelog

## Unreleased

- PNG icon set (`assets/icons`) used across the app: tab bar, home
  shortcuts, lists, buttons. `AppIcons.x` works wherever an icon is
  expected; `AppIcon` draws them.
- Landing: presentation with the four main features, actions pinned at
  the bottom.
- Sign-in: no demo ids on screen; **any e-mail + `password`** signs in on
  the simulator. "Continue with Apple / Google": `SocialSignIn` service
  (device) + `AuthRepository.signInWithProvider` + `POST /auth/social`;
  simulated consent sheet in demo mode, hidden with no provider plugged.
- Signature: Profile > Ma signature to draw, save, redo or delete it
  (`SignatureRepository`, `/me/signature`, strokes as JSON). Signing a
  petition writes the saved signature on the petition sheet, pen moving
  along the line, while the request runs; first time, the member draws
  it first.
- Tests: contract suites for social sign-in and signature (simulator +
  REST), flows for the universal password, Apple/Google, signature and
  petition signing.

## 0.2.0 — 2026-11-27

- Interface in French (texts, simulated data, error messages, dates and
  numbers in `fr_FR`, French system widgets).
- App named **Votaa**, identifier `sergio.votaa.app` (iOS, Android, macOS,
  Linux, web, Windows).
- Licence: Apache-2.0 (`LICENSE`, `NOTICE`).

## 0.1.0 — 2026-11-27

First version, front-end only, running on the built-in simulator.

- Architecture: repository interfaces per feature, single plug point
  (`lib/backend.dart`), sealed `Failure`, Riverpod 3, go_router.
- Simulator: deterministic data, latency, cursor pagination, server-like
  validation, expiring sessions, idempotency, scenario panel (demo mode).
- Reference REST implementation + OpenAPI contract (`docs/api_contract.yaml`).
- Screens: landing, sign-in, sign-up, password reset, home, Digital ID
  (show code, share, check an ID, biometric protection, personal details),
  activity, profile, notifications, elections, petitions, documents,
  services, search.
- Tests: contract suites (simulator + REST), flows, layouts at 3 sizes and
  200 % text, touch targets, light/dark goldens.
