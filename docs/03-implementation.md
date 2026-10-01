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

## Client changes (detail)

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
  aiCategory, aiConfidence, needsReview, clusterId` (+ `broadcast` status).

## Backend notes

- In-memory `_store` mirrors `docs/db-schema.md` field-for-field; the
  PostGIS swap is a store replacement, not a redesign.
- `/api/eta` returns `source: "stub"` (haversine @ 30 km/h) until
  `OSRM_BASE_URL` is set — clients must render it as an estimate.
- `requirements.txt` pins `fastapi/uvicorn/pydantic/httpx/pytest`.

## Known TODOs (tracked, not silent)

- Manual pin adjustment UI on the map (criterion 1 fallback) — host is
  `map_screen.dart`; contract field `accuracy_m` already supported.
- JWT + RBAC gateway (station 6, `api-contract.md`).
- Real IndoBERT checkpoint + PostGIS + OSRM wiring (M2/M3 in `00-planning.md`).
