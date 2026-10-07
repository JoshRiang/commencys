---
layout: default
title: DB Schema
nav_order: 2
parent: Reference
---

# DB Schema — PostgreSQL/PostGIS (production target)

The MVP skeleton (`backend/app/main.py`) keeps in-memory dicts with the
**same field shape** as this DDL, so migration is a store swap, not a redesign.
Field source of truth: `backend/app/models.py`
(`Incident` incl. `reporter_name`, `ai_suggested_urgency`, `ai_urgency_conf`;
**no** `photo_url` on `Incident` — that lives only on the `SosIn` request body)
plus dispatch columns written by `main.py:292-294`
(`required_roles`, `dispatch_source`, `invited`; manual dispatch writes
`dispatched_to`).

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE incidents (
  id            TEXT PRIMARY KEY,          -- server-generated ticket id
  title         TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',
  category      TEXT NOT NULL DEFAULT 'other',  -- reporter taxonomy, or 'sos'
                                            -- for one-tap SOS tickets
  geom          GEOGRAPHY(Point, 4326) NOT NULL, -- GPS (+accuracy_m context)
  accuracy_m    DOUBLE PRECISION,
  reporter_name TEXT NOT NULL DEFAULT 'Anonymous',
  urgency       CHAR(2) NOT NULL DEFAULT 'P3'
                CHECK (urgency IN ('P1','P2','P3','P4')),
  urgency_source TEXT NOT NULL DEFAULT 'reporter_default',
  status        TEXT NOT NULL DEFAULT 'acknowledged'
                CHECK (status IN ('reported','acknowledged','broadcast',
                                 'dispatched','resolved')),
  -- AI metadata (nullable, coordinator-correctable; raw fields immutable):
  ai_category   TEXT,
  ai_confidence DOUBLE PRECISION,
  ai_suggested_urgency CHAR(2),             -- advisory only, never auto-applied
  ai_urgency_conf      DOUBLE PRECISION,
  needs_review  BOOLEAN NOT NULL DEFAULT FALSE,
  cluster_id    TEXT,                        -- reversible DBSCAN linkage
  -- Dispatch (Laya dispatch-auto writes the first three — main.py:292-294;
  -- manual POST .../dispatch writes dispatched_to):
  required_roles TEXT[] NOT NULL DEFAULT '{}',
  invited        TEXT[] NOT NULL DEFAULT '{}',  -- invited volunteer ids
  dispatch_source TEXT,                      -- 'laya' | 'fallback'
  dispatched_to TEXT,                        -- volunteer id/name (manual accept)
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX incidents_geom_gist ON incidents USING GIST (geom);
CREATE INDEX incidents_time ON incidents (created_at);
CREATE INDEX incidents_status_urgency ON incidents (status, urgency);

-- Spatio-temporal dedup pre-filter (DBSCAN window feeds off this):
-- SELECT * FROM incidents
--  WHERE ST_DWithin(geom, ST_MakePoint($lng,$lat)::geography, 150)
--    AND created_at > now() - interval '30 minutes'
--    AND status <> 'resolved';

CREATE TABLE volunteers (                  -- POST /api/volunteers registry
  id          TEXT PRIMARY KEY,            -- server-generated volunteer id
  name        TEXT NOT NULL,
  phone       TEXT,
  roles       TEXT[] NOT NULL DEFAULT '{}', -- must be VALID_ROLES (laya_dispatch)
  skills      TEXT[] NOT NULL DEFAULT '{}',
  home_geom   GEOGRAPHY(Point, 4326) NOT NULL, -- home coords (nearest-first match)
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_log (                   -- immutable (REVOKE UPDATE/DELETE)
  seq         BIGSERIAL PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(id),
  actor       TEXT NOT NULL,               -- user id or 'system:ai-pipeline'
  action      TEXT NOT NULL,               -- create/ai_classify/cluster/
                                           -- dispatch/dispatch_auto/
                                           -- volunteer_register/correct/split
  detail      JSONB NOT NULL DEFAULT '{}',
  at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
REVOKE UPDATE, DELETE ON audit_log FROM PUBLIC;
```

Audit actions observed in code (`main.py` `_audit(...)` calls +
`test_audit_trail_records_lifecycle`): `create`, `ai_classify`, `cluster`,
`dispatch`, `dispatch_auto`, `volunteer_register`, `correct`, `split`.
There are **no** `ack` or `broadcast` audit actions — ack/broadcast are WS
frame types (`incident.created` / fan-out), not audit rows.

Design notes (spec stations 1, 8, 9): raw report columns are write-once;
every AI write and every coordinator correction appends an `audit_log` row;
precision coordinates live in `geom` with row-level access policy
(coordinator + assigned volunteer); retention policy in `guardrails.md`.
