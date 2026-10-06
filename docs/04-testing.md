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
| Backend contract + SOS budget + AI guards + dispatch | `backend/tests/test_api.py` (24 tests: health, SOS < 5 s ack + P1 default, create, list, dispatch transition, WS hello, ETA labelled, + 6 AI guards: no-downgrade, advisory-only escalation, review-queue listing, cluster + split, correct-metadata-only, audit trail, + volunteer register/list/role-filter, dispatch-auto matching, 404, Laya-down fallback, heuristic keyword mapping, pre-translator gloss/word-boundaries/EN-passthrough, low-confidence fallback, pretranslated-payload capture) | `cd backend && pytest -q` |
| Flutter model + invites | `test/incident_test.dart` (5 tests: WS URL mapping, base-URL normalisation, JSON round-trip, canonical ticket incl. urgency + AI metadata, lifecycle order) + `test/invite_test.dart` (7 tests: targeted-invite parsing, broadcast defaults, case-insensitive matching, invite round-trip, canonical role ids, registration payload, `matchedRoles` helper) | `flutter test` |
| Static analysis | `flutter analyze` (lints) — clean through AI triage `65409f0` | `flutter analyze` |
| CI (all, both platforms) | `.github/workflows/ci.yml`: backend job (pip + pytest) + flutter job (pub get → analyze → test → release APK) | GitHub Actions on `main` |

## Latest verification (AI triage `65409f0`, 2026-10-02; dispatch work
`4a94fb6`/`084cb07`/`a91d104` after — counts verified locally `2026-10-06`)

| Check | Result | Evidence |
|-------|--------|----------|
| Backend `pytest` | ✅ 24/24 pass | local `pytest -q`, 2026-10-06 (13 contract+AI guards at `65409f0`, +11 volunteer/dispatch/Laya guards since; CI run `36985531449` for the 13) |
| `flutter analyze` | ✅ clean | CI run `36985531411` (plus `7e3e1e7`/`cd581b2` const-map fixes after) |
| `flutter test` | ✅ 5/5 + 7/7 pass | `test/incident_test.dart` (5) + `test/invite_test.dart` (7); CI run `36985531411` for the 5 |
| Release APK | ✅ built | `app-release.apk` artifact, run `36985531411` |
| Live backend | ✅ serving | `GET /health → {"status":"ok","service":"commencys-mvp"}` |
| Laya API | ✅ serving | systemd `laya-api` on `127.0.0.1:8010` (`/health`, `/v1/systemone`) |

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
- AI safety (advisory-only): `test_sos_never_downgraded_by_ai` (SOS keeps
  P1 fail-safe) + `test_ai_escalation_is_advisory_only` (escalation never
  auto-applies without review).
- AI reversibility: `test_cluster_and_split_clear_cluster` (false-merge
  undo) + `test_correct_updates_metadata_not_raw` (raw report immutable).
- AI accountability: `test_audit_trail_records_lifecycle`
  (`create/ai_classify/cluster/dispatch/correct/split`, `heuristic-v2`)
  + `test_review_queue_lists_low_conf_ticket` (low-confidence triage inbox).
- Targeted dispatch: `test_volunteer_register_and_validation` (role
  whitelist 422) + `test_volunteer_list_and_role_filter`
  + `test_dispatch_auto_matching_picks_right_role` (mocked Laya:
  role-overlap + nearest-first) + `test_dispatch_auto_404_unknown_ticket`
  + `test_laya_down_fallback` + `test_laya_low_confidence_falls_back`
  (both → `source: "fallback"`) + `test_heuristic_dispatch_maps_keywords`
  + pre-translator: `test_pretranslate_id_en_glosses_fire_report` /
  `_word_boundaries` / `_english_passthrough`
  + `test_laya_sends_pretranslated_report`.
- Flutter invites: `test/invite_test.dart` — `required_roles` + `reason`
  parse, broadcast defaults, case-insensitive intersection, invite
  round-trip, canonical role ids, registration payload shape,
  `matchedRoles` helper.

## Manual QA checklist (pre-release)

- [ ] SOS on poor GPS → accuracy shown; pin-adjust path reviewed.
- [ ] Airplane-mode mid-SOS → error state, no false "sent".
- [ ] WS kill → reconnect + REST re-sync, no duplicate tickets.
- [ ] Coordinator corrects AI label → audit row written, WS update received.
- [ ] Disclaimer visible on SOS screen (bukan pengganti 112/119).
