---
layout: default
title: API Contract
nav_order: 1
parent: Reference
---

# API Contract (FastAPI — client-agnostic)

Base URL: emulator `http://10.0.2.2:8000`, device-on-LAN `http://<host>:8000`,
live supervised backend `http://100.89.180.23:8791` (Tailnet, `:8791`),
public demo `https://vector-server.tail53166f.ts.net/commencys`
(funnel → `:8791`; reads open, write ops `POST/PUT/PATCH/DELETE` require
`X-Demo-Key` header — the CI-built demo APK sends it automatically from
its baked `DEMO_KEY`).
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

## `POST /api/volunteers` → 201

Register (or update) a volunteer: `name*`, `phone`, `roles*`
(`medical|fire|rescue|security|driver|coordinator` — 422 on invalid),
`skills`, `latitude*`, `longitude*` (coordinates required; the Flutter
client falls back to Jakarta `-6.2, 106.8` when it has no fix). Dedupes
roles, returns the stored volunteer incl. generated `id`. Writes audit
action `volunteer_register`.

## `GET /api/volunteers?role=&category=` → 200

List volunteers; optional `?role=` filter (`category` is an alias).

## `POST /api/incidents/{id}/dispatch-auto` → 200

Laya AI dispatch (see `ai-stations.md` station 6): infers
`required_roles` + `headcount` (Laya agent on `:8010`, ID→EN
pre-translated report, confidence gate `< 0.5` → heuristic fallback —
never 5xxes), matches registered volunteers by role overlap
(nearest-first by haversine, capped at `headcount`), stores
`required_roles` + `invited[]` + `dispatch_source` (`laya|fallback`) on
the ticket, writes audit action `dispatch_auto`, broadcasts WS
`incident.dispatch_auto`. Manual `POST …/dispatch` override is
untouched. 404 for unknown id.

## `GET /api/review-queue` → 200

Coordinator triage inbox: tickets with `needs_review: true` (AI confidence
< 0.65 or a pending urgency escalation). Same ticket shape as
`GET /api/incidents`.

## `POST /api/incidents/{id}/correct` → 200

Coordinator correction. Body: `{"ai_category"?: string, "urgency"?: "P1"-"P4"}`.
Raw `title`/`description` are immutable — only metadata changes; an urgency
change stamps `urgency_source: "coordinator_corrected"` and clears
`needs_review`. Returns the updated ticket; 404 for unknown id, 422 for bad
urgency.

## `POST /api/incidents/{id}/split` → 200

Reversible clustering: clears this ticket's `cluster_id` (false-merge undo).
Returns the updated ticket; 404 for unknown id.

## `GET /api/audit?incident_id=<id>` → 200

Immutable audit trail (spec station 9): `[{ts, action, incident_id,
model_version, detail}]`. Actions: `create`, `ai_classify`, `cluster`,
`dispatch`, `dispatch_auto`, `volunteer_register`, `correct`, `split`;
`model_version` is `heuristic-v2`.
Without `incident_id` returns the full log.

## `GET /api/eta?from_lat&from_lng&to_lat&to_lng` → 200

```json
{"source": "stub|osrm", "distance_m": 1234.5, "eta_s": 148}
```

Production proxies self-hosted OSRM `/route/v1`; `source` tells the client
whether the ETA is routed or a labelled fallback estimate.

## `WS /ws/alerts`

Behind the `/commencys` funnel prefix the public demo URL is
`wss://vector-server.tail53166f.ts.net/commencys/ws/alerts`
(`AppConfig.wsUrlFor` preserves the base path; local dev stays
`ws://<host>:<port>/ws/alerts`).

Server frames (JSON): `hello`, `incident.sos`, `incident.created`,
`incident.ai_updated`, `incident.dispatched`, `incident.dispatch_auto`. Frame shape:

```json
{"type": "incident.dispatched", "id": "abc123", "title": "SOS",
 "category": "sos", "urgency": "P1", "status": "dispatched",
 "latitude": -6.36, "longitude": 106.82, "created_at": "…"}
```

Client sends heartbeat text; must implement auto-reconnect with exponential
backoff + REST re-sync (`GET /api/incidents`) on flaky networks (spec §3).
Note: the server emits a `hello` frame on every connect — clients must filter
non-`incident.*` frames before treating a message as an alert.

## `GET /health` → 200 `{"status": "ok", "service": "commencys-mvp"}`

## Ticket object (canonical)

`id, title, description, category, latitude, longitude, accuracy_m,
reporter_name, urgency (P1–P4), urgency_source, status
(reported|acknowledged|broadcast|dispatched|resolved), ai_category,
ai_confidence, ai_suggested_urgency, ai_urgency_conf, needs_review,
cluster_id, required_roles, invited, dispatch_source, reason, created_at`.
Raw report fields are immutable after creation; only metadata + status change.
