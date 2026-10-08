---
layout: default
title: PERSISTENCE TARGET
nav_order: 2
parent: Reference
---

# PERSISTENCE TARGET

## CURRENT SCAFFOLD

The application has no incident data-model classes or request schemas. API and Flutter service boundaries use plain JSON dictionaries. A StateStore interface, inactive SQLite placeholder, and hollow PostgreSQL adapter preserve future seams; no database is opened, no schema is created, and reports do not survive a request. `backend/migrations/001_initial_schema.sql` is a comments-only outline, not an executable migration.

## PROPOSED POSTGRESQL/POSTGIS SCHEMA

The following is a design sketch only. Names, migrations, authorization, and operational behavior must be reviewed before use.

~~~sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE incidents (
  id              TEXT PRIMARY KEY,
  title           TEXT NOT NULL,
  description     TEXT NOT NULL DEFAULT '',
  category        TEXT NOT NULL,
  severity        TEXT NOT NULL,
  geom            GEOGRAPHY(Point, 4326) NOT NULL,
  accuracy_m      DOUBLE PRECISION,
  location_source TEXT NOT NULL,
  reporter_ref    TEXT,
  urgency         CHAR(2) NOT NULL,
  urgency_source  TEXT NOT NULL,
  status          TEXT NOT NULL,
  accepted_by     TEXT,
  resolved_at     TIMESTAMPTZ,
  ai_category     TEXT,
  ai_confidence   DOUBLE PRECISION,
  ai_suggested_urgency TEXT,
  ai_urgency_conf DOUBLE PRECISION,
  needs_review    BOOLEAN NOT NULL DEFAULT FALSE,
  cluster_id      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX incidents_geom_gist ON incidents USING GIST (geom);
CREATE INDEX incidents_time ON incidents (created_at);
CREATE INDEX incidents_status_urgency ON incidents (status, urgency);

CREATE TABLE audit_log (
  seq           BIGSERIAL PRIMARY KEY,
  incident_id   TEXT NOT NULL REFERENCES incidents(id),
  actor         TEXT NOT NULL,
  action        TEXT NOT NULL,
  model_version TEXT,
  detail        JSONB NOT NULL DEFAULT '{}',
  at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Keep each recipient's offer and decision separate from delivery attempts.
CREATE TABLE assignment_offers (
  id              TEXT PRIMARY KEY,
  incident_id     TEXT NOT NULL REFERENCES incidents(id),
  volunteer_ref   TEXT NOT NULL,
  offered_by      TEXT NOT NULL,
  status          TEXT NOT NULL,
  offered_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at    TIMESTAMPTZ,
  response_note   TEXT
);

CREATE TABLE notification_deliveries (
  id              TEXT PRIMARY KEY,
  offer_id        TEXT NOT NULL REFERENCES assignment_offers(id),
  channel         TEXT NOT NULL,
  status          TEXT NOT NULL,
  attempted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  delivered_at    TIMESTAMPTZ
);
~~~

## DESIGN REQUIREMENTS

- Store and return coordinates only under an approved access policy.
- Keep original report fields separate from triage suggestions and admin corrections.
- Keep volunteer task offers and decisions separate from notification delivery status.
- An offer belongs to a specific incident and intended volunteer; acceptance or rejection records that volunteer's authenticated decision.
- A delivery record states only the outcome known by the delivery channel; it never stands in for reading or accepting the offer.
- Store every transition and audit event consistently.
- Use append-only audit permissions where the chosen service supports them.
- Define reversible cluster membership and its history.
- Add versioned migrations, backup, restoration, retention, and deletion procedures.
- Do not treat an uncalibrated triage score as a probability.

This schema is a target artifact, not an active application schema. See [target design](02-DESIGN.md).
