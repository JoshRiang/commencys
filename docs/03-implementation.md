---
layout: default
title: 4 · Implementation
nav_order: 13
parent: SDLC — Waterfall Model
---

# 03 — Implementation

## What was built (this update)

| Piece | Location | Spec coverage |
|-------|----------|---------------|
| FastAPI skeleton: SOS/incidents/dispatch/ETA/WS/health | `backend/app/main.py` | Criteria 2 + 4, station 7 |
| Pydantic schemas: taxonomy, P1–P4, lifecycle | `backend/app/models.py` | Station 4, criterion 3 |
| Async AI workers: classify + cluster stubs with 0.65 threshold | `backend/app/ai_pipeline.py` | Station 4, criterion 4 |
| Backend tests incl. sub-5 s SOS guard | `backend/tests/test_api.py` | `evaluation-monitoring.md` |
| Status-timeline UI + disclaimer on SOS screen | `lib/screens/sos_screen.dart`, `lib/widgets/status_timeline.dart` | Criterion 3, guardrail 8 |
| Reconnecting WS client | `lib/services/websocket_service.dart` | Decision D3 |
| Accuracy-aware SOS payload | `lib/services/api_client.dart`, `lib/services/location_service.dart` | Criterion 1 |
| Spec-aligned categories | `lib/screens/report_screen.dart` | Station 4 taxonomy |

## Client — Apple liquid-glass reskin (maintenance change request `a811497`, released as v1.0.1)

UI-only reskin on top of the frozen API contract — no endpoint or schema
changed. Greeting header + SOS hero on home, fail-safe P1 pill + ticket card
on SOS, chip pickers on report, severity pins + bottom sheet on map, glass
alert cards + LIVE/SYNCING pill on alerts, stepper timeline. Theme tokens in
`lib/theme/app_theme.dart`, shared kit in `lib/widgets/glass.dart`.
CI green: backend `pytest` + Flutter analyze/test/release APK on the same
commit (run `36966554133` / `36966554085`).

## Client — map-centric liquid-glass shell (maintenance change request `6967487`, released as v1.1.0)

Map is home now: full-bleed live map + glass top bar
(search/status/server) + draggable glass bottom sheet + floating SOS +
recenter. Navigation moved into `lib/app_shell.dart` (`AppShell`) with a
floating glass tab bar (`lib/widgets/floating_tab_bar.dart`:
Home / Report / Map / Alerts / SOS), map as the center default tab.

- New `LiquidGlass` material (`lib/widgets/glass.dart`: blur 24–30,
  specular highlight, 22–28 radius); the old `GlassCard` is kept as an
  alias so existing screens keep compiling.
- SOS hero re-wrapped in a glass surround, report reworked as a stepped
  glass form, alerts reworked as a glass timeline.
- In-app server setting (`lib/widgets/server_dialog.dart`, app-bar icon)
  overrides the baked endpoint per session.
- Backend APIs unchanged. CI bakes
  `--dart-define=API_BASE=https://vector-server.tail53166f.ts.net/commencys`
  `--dart-define=DEMO_KEY=${{ secrets.DEMO_KEY }}` so the APK works
  off-Tailnet out of the box against the public funnel (reads open, writes
  gated by `X-Demo-Key`, sent automatically from the baked key); emulator
  fallback stays `http://10.0.2.2:8000`.

## Backend + client — AI triage heuristic-v2 (maintenance change request `65409f0`, released as v1.2.0)

Real (heuristic) AI on the async path — SOS hot path still persist-first,
still no model on it:

- `infer_urgency` (`backend/app/ai_pipeline.py`): advisory-only urgency
  escalation — SOS keeps its P1 fail-safe, AI **never downgrades**;
  low confidence (< 0.65) flags `needs_review` instead of auto-applying.
- `cluster()`: DBSCAN-lite with 150 m + 30 min + same-category gate, plus
  cluster backfill for late arrivals; reversible via split.
- New endpoints (see `api-contract.md`): `GET /api/review-queue`,
  `POST /api/incidents/{id}/correct`, `POST /api/incidents/{id}/split`,
  `GET /api/audit` — `model_version` is `heuristic-v2`.
- 6 new pytest guards (13/13 total): no-downgrade, advisory-only
  escalation, review-queue listing, cluster + split clearing,
  correct-metadata-only, audit trail.
- Visible AI UI (`lib/widgets/ai_badges.dart` → `AiTriageBadges`: AI label
  pill, suggested-urgency pill, needs-review pill, cluster chip): SOS
  ticket badges, report AI-preview hint, alerts needs-review filter row +
  coordinator correction sheet, map-sheet badges + cluster filter.
- `ApiClient`: `fetchReviewQueue` / `correctTicket` / `splitCluster` /
  `fetchAudit`.

## Backend — Laya AI dispatch + volunteer registry (change `4a94fb6`)

Role-based targeted invites, coordinator-triggered, never on the SOS path:

- `POST /api/volunteers` + `GET /api/volunteers?role=` (`backend/app/main.py`):
  volunteer registry with server-canonical role ids
  (`medical|fire|rescue|security|driver|coordinator`, 422 on invalid),
  required home coordinates; writes `volunteer_register` audit rows.
- `POST /api/incidents/{id}/dispatch-auto`
  (`backend/app/laya_dispatch.py` → `dispatch_incident`): asks the Laya
  agent (`:8010`, `POST /v1/systemone`, 4 questions — category choice,
  severity score, role-bundle choice, headcount score), expands the bundle
  (`ROLE_BUNDLES`, e.g. `fire_team` → `fire` + `rescue`), matches
  volunteers by role overlap nearest-first (haversine, capped at
  `headcount`), stores `required_roles` + `invited[]` +
  `dispatch_source` on the ticket, writes `dispatch_auto` audit +
  `incident.dispatch_auto` WS frame. Manual `dispatch` override untouched.
- Never-blocks rule: **any** Laya failure → keyword-heuristic fallback on
  the original text with `source: "fallback"` — no 5xx from Laya.
- 7 new pytest guards (20/20 at that point): register + role validation,
  list + role filter, dispatch-auto matching (mocked Laya), 404,
  Laya-down fallback, heuristic keyword mapping.

## Backend — Laya ID→EN pre-translator + confidence gate (change `a91d104`)

Laya's English model misclassifies raw Indonesian at low confidence
(fire report → `accident` @ 0.30), so the report is pre-translated with
an offline glossary first (`pretranslate_id_en`, ~50 emergency terms in
`_ID_EN_GLOSS`, longest-phrase-first, word-boundary aware so `api`
never fires inside `tetapi`; English passes through untouched; reasons
tagged `Laya+pretranslated:`). The heuristic fallback keeps running on
the **original** Indonesian text. A confidence gate discards Laya labels
below **0.5** in favour of fallback (`laya_conf=X` in the reason).
5 new tests (24/24 total): gloss, word boundaries, EN passthrough,
low-confidence fallback, pretranslated-payload capture.

## Client — role onboarding + targeted-invite UX (change `084cb07`)

- First-launch gate (`lib/main.dart` `_LaunchGate`): no stored profile →
  `RolePickerScreen` (`lib/screens/role_picker_screen.dart`: 6 roles,
  multi-select tiles, display name + free-text skills, onboarding/editor
  modes) instead of the map shell. Save order is local-first
  (`shared_preferences` via `VolunteerStore`) → background
  `POST /api/volunteers` with device GPS (Jakarta fallback when no fix);
  server id cached via `markSynced`.
- Alerts as targeted-invite inbox (`lib/widgets/invite_cards.dart`,
  `lib/models/incident.dart` `requiredRoles`/`inviteReason`/`matchedRoles`
  + `lib/models/volunteer.dart` canonical role ids): SPECIAL INVITE
  banner with live count (tap = filter), INVITED badge + red glow,
  WHY block (`Needs: … — matches your … role` + server reason), invites
  sorted first, dimmed normal cards, invite-style snackbar on live WS
  frames.
- 7 new Flutter tests (`test/invite_test.dart`): parsing, broadcast
  defaults, case-insensitive matching, round-trip, role ids, payload
  shape, `matchedRoles` helper.

## Client changes (detail, MVP baseline)

- `sos_screen.dart`: after `sendSos`, shows the returned ticket id / urgency /
  status via `StatusTimeline` (acknowledged → broadcast → dispatched →
  resolved) instead of the overstated "Help is on the way"; adds the
  non-112/119 disclaimer; sends `accuracy_m` from the position fix.
- `websocket_service.dart`: auto-reconnect with exponential backoff
  (spec §3 trade-off) + `statuses` stream parsing `incident.*` frames into
  the lifecycle steps the timeline renders.
- `api_client.dart`: `sendSos`/`createIncident` send `accuracy_m` and parse
  the canonical ticket (`urgency`, `status`, `needs_review`, `cluster_id`).
- `location_service.dart`: exposes `accuracy()` (GPS fix accuracy in metres)
  for the payload's accuracy radius.
- `report_screen.dart`: categories aligned to the spec taxonomy
  (`medical/accident/fire/security/facility/other`).
- `incident.dart`: extended with `urgency, urgencySource, accuracyM,
  aiCategory, aiConfidence, needsReview, clusterId` (+ `broadcast` status),
  then with targeted-invite metadata (`requiredRoles`, `inviteReason`,
  `matchedRoles` / `isSpecialInviteFor`, lenient `required_roles` parsing).
- `api_client.dart`: `registerVolunteer` (`POST /api/volunteers`,
  coordinates always sent) alongside `dispatch`.

## Backend notes

- In-memory `_store` mirrors `docs/db-schema.md` field-for-field; the
  PostGIS swap is a store replacement, not a redesign.
- `/api/eta` returns `source: "stub"` (haversine @ 30 km/h) until
  `OSRM_BASE_URL` is set — clients must render it as an estimate.
- `requirements.txt` pins `fastapi/uvicorn/pydantic/httpx/pytest`.

## Known TODOs (tracked, not silent)

- Manual pin adjustment UI on the map (criterion 1 fallback) — contract
  field `accuracy_m` already supported. **OPEN, not shipped:** `location_service.dart`
  fails fast (returns null on no fix) and `sos_screen.dart` blocks with
  "Location permission denied. Enable GPS." — no manual-pin fallback exists today
  (map shows only display markers, not draggable).
- JWT + RBAC gateway (station 6, `api-contract.md`).
- Real IndoBERT checkpoint + PostGIS + OSRM wiring (M2/M3 in `00-planning.md`).
