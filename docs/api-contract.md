# API Contract (FastAPI — client-agnostic)

Base URL: emulator `http://10.0.2.2:8000`, device-on-LAN `http://<host>:8000`.
Auth (production): `Authorization: Bearer <JWT>`; RBAC roles
`reporter / volunteer / coordinator` (spec station 6). MVP skeleton leaves
auth as a gateway TODO — endpoints are deterministic and permission-checked
once the gateway lands.

## `POST /api/sos` → 201 (criterion 2)

One-tap SOS. Persists + acknowledges in strictly < 5 s; AI runs afterwards.

Request:

```json
{
  "latitude": -6.36, "longitude": 106.82,
  "accuracy_m": 12.5,
  "description": "Kebakaran di lantai 2 (opsional)",
  "photo_url": "https://… (opsional)",
  "reporter_name": "Anonim"
}
```

Response headers: `X-Process-Time-Ms`, `X-SOS-Budget-S: 5.0`.
Response body = ticket with `status: "acknowledged"`, `urgency: "P1"`,
`urgency_source: "sos_default_pending_triage"`.

## `POST /api/incidents` → 201

Full report: `title*`, `description`, `category*`
(`medical|accident|fire|security|facility|other`), `latitude*`,
`longitude*`, `accuracy_m`, `reporter_name`. Response: stored ticket,
`status: "acknowledged"`.

## `GET /api/incidents` → 200

List tickets (newest last in MVP; PostGIS build adds spatio-temporal query
params — radius, `since`, urgency filter).

## `POST /api/incidents/{id}/dispatch?volunteer=<id>` → 200

`acknowledged|broadcast → dispatched`. Records `dispatched_to`, emits
`incident.dispatched` on WS.

## `GET /api/eta?from_lat&from_lng&to_lat&to_lng` → 200

```json
{"source": "stub|osrm", "distance_m": 1234.5, "eta_s": 148}
```

Production proxies self-hosted OSRM `/route/v1`; `source` tells the client
whether the ETA is routed or a labelled fallback estimate.

## `WS /ws/alerts`

Server frames (JSON): `hello`, `incident.sos`, `incident.created`,
`incident.ai_updated`, `incident.dispatched`. Frame shape:

```json
{"type": "incident.dispatched", "id": "abc123", "title": "SOS",
 "category": "sos", "urgency": "P1", "status": "dispatched",
 "latitude": -6.36, "longitude": 106.82, "created_at": "…"}
```

Client sends heartbeat text; must implement auto-reconnect with exponential
backoff + REST re-sync (`GET /api/incidents`) on flaky networks (spec §3).

## `GET /health` → 200 `{"status": "ok", "service": "commencys-mvp"}`

## Ticket object (canonical)

`id, title, description, category, latitude, longitude, accuracy_m,
reporter_name, urgency (P1–P4), urgency_source, status
(reported|acknowledged|broadcast|dispatched|resolved), ai_category,
ai_confidence, needs_review, cluster_id, created_at`.
Raw report fields are immutable after creation; only metadata + status change.
