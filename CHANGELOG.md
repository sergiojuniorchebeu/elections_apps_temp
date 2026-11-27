# Changelog

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
