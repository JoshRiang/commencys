---
layout: default
title: DB schema
nav_order: 23
---

# DB Schema — PostgreSQL/PostGIS (production target)

The MVP skeleton (`backend/app/main.py`) keeps an in-memory dict with the
**same field shape** as this DDL, so migration is a store swap, not a redesign.

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE incidents (
  id            TEXT PRIMARY KEY,          -- server-generated ticket id
  title         TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',
  category      TEXT NOT NULL DEFAULT 'other',  -- reporter-chosen taxonomy
  geom          GEOGRAPHY(Point, 4326) NOT NULL, -- GPS (+accuracy_m context)
  accuracy_m    DOUBLE PRECISION,
  reporter_ref  TEXT NOT NULL DEFAULT 'anonymous', -- FK users(id) in prod
  urgency       CHAR(2) NOT NULL DEFAULT 'P3'
                CHECK (urgency IN ('P1','P2','P3','P4')),
  urgency_source TEXT NOT NULL DEFAULT 'reporter_default',
  status        TEXT NOT NULL DEFAULT 'acknowledged'
                CHECK (status IN ('reported','acknowledged','broadcast',
                                 'dispatched','resolved')),
  -- AI metadata (nullable, coordinator-correctable; raw fields immutable):
  ai_category   TEXT,
  ai_confidence DOUBLE PRECISION,
  needs_review  BOOLEAN NOT NULL DEFAULT FALSE,
  cluster_id    TEXT,                        -- reversible DBSCAN linkage
  dispatched_to TEXT,
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

CREATE TABLE audit_log (                   -- immutable (REVOKE UPDATE/DELETE)
  seq         BIGSERIAL PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(id),
  actor       TEXT NOT NULL,               -- user id or 'system:ai-pipeline'
  action      TEXT NOT NULL,               -- create/ack/broadcast/dispatch/
                                           -- ai_classify/cluster/correct/split
  detail      JSONB NOT NULL DEFAULT '{}',
  at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
REVOKE UPDATE, DELETE ON audit_log FROM PUBLIC;
```

Design notes (spec stations 1, 8, 9): raw report columns are write-once;
every AI write and every coordinator correction appends an `audit_log` row;
precision coordinates live in `geom` with row-level access policy
(coordinator + assigned volunteer); retention policy in `guardrails.md`.
