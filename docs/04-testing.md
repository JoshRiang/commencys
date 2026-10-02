---
layout: default
title: 5 · Verification & Testing
nav_order: 14
parent: SDLC — Waterfall Model
---

# 04 — Verification & Testing

## Layers

| Layer | Suite | Command |
|-------|-------|---------|
| Backend contract + SOS budget | `backend/tests/test_api.py` (7 tests: health, SOS < 5 s ack + P1 default, create, list, dispatch transition, WS hello, ETA labelled) | `cd backend && pytest -q` |
| Flutter model | `test/incident_test.dart` (5 tests: WS URL mapping, base-URL normalisation, JSON round-trip, canonical ticket incl. urgency + AI metadata, lifecycle order) | `flutter test` |
| Static analysis | `flutter analyze` (lints) — clean on UI reskin `a811497` | `flutter analyze` |
| CI (all, both platforms) | `.github/workflows/ci.yml`: backend job (pip + pytest) + flutter job (pub get → analyze → test → release APK) | GitHub Actions on `main` |

## Latest verification (UI reskin `a811497`, 2026-10-02)

| Check | Result | Evidence |
|-------|--------|----------|
| Backend `pytest` | ✅ 7/7 pass | CI run `36966554133` (backend job 13 s) |
| `flutter analyze` | ✅ clean | CI run `36966554085` |
| `flutter test` | ✅ 5/5 pass | CI run `36966554085` |
| Release APK | ✅ built | `app-release.apk` artifact, run `36966554085` |
| Live backend | ✅ serving | `GET /health → {"status":"ok","service":"commencys-mvp"}`, service `commencys-backend` active |

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
