---
layout: default
title: Testing
nav_order: 14
---

# 04 — Testing

## Layers

| Layer | Suite | Command |
|-------|-------|---------|
| Backend contract + SOS budget | `backend/tests/test_api.py` (7 tests: health, SOS < 5 s ack + P1 default, create, list, dispatch transition, WS hello, ETA labelled) | `cd backend && pytest -q` |
| Flutter model | `test/incident_test.dart` (JSON round-trip incl. new fields) | `flutter test` |
| Static analysis | `flutter analyze` (lints) | `flutter analyze` |
| CI (all, both platforms) | `.github/workflows/ci.yml`: backend job (pip + pytest) + flutter job (pub get → analyze → test → release APK) | GitHub Actions on `main` |

## Criterion → test traceability

- C2 (SOS < 5 s): `test_sos_ack_under_budget` asserts wall-clock 201 +
  `acknowledged` strictly under `SOS_BUDGET_S`.
- C4 (AI non-blocking): `_enrich` runs only as `BackgroundTask`; test client
  completes SOS without any model loaded; failure path logs and skips.
- C3 (status transparency): `test_dispatch_transitions_status` asserts the
  `acknowledged → dispatched` transition; `StatusTimeline` widget renders the
  intermediate `broadcast` step distinctly.
- C1 (GPS + manual pin): `accuracy_m` round-trips through SOS payload;
  manual-pin UI is a tracked TODO with the contract field ready.

## Manual QA checklist (pre-release)

- [ ] SOS on poor GPS → accuracy shown; pin-adjust path reviewed.
- [ ] Airplane-mode mid-SOS → error state, no false "sent".
- [ ] WS kill → reconnect + REST re-sync, no duplicate tickets.
- [ ] Coordinator corrects AI label → audit row written, WS update received.
- [ ] Disclaimer visible on SOS screen (bukan pengganti 112/119).
