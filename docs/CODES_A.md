---
layout: default
title: CODE MAP A - BACKEND AND API
nav_order: 20
parent: Reference
---

# CODE MAP A: BACKEND AND API

This guide maps the backend files to the project responsibilities they reserve. It supplements [implementation status](03-IMPLEMENTATION.md) and the [API contract](API-CONTRACT.md) with file ownership. The route names are present, but operational routes are not implemented.

## Request entry point

`backend/app/main.py` creates the FastAPI application, defines `/health`, declares the REST and WebSocket paths, and serves `web/` as static files from the API root. The report, SOS, task, review, assignment, correction, audit, and ETA route functions call `_not_implemented()` and return HTTP 501. The WebSocket route closes with code 1011. `configure_state_store()` constructs a `SQLiteStateStore` and keeps it in a module variable; routes do not use that variable to read or write reports.

| File | Boundary | Current state |
|---|---|---|
| `backend/app/main.py` | HTTP and WebSocket surface; static dashboard mount | Health response is active. Operational REST paths are 501; alerts socket closes. |
| `backend/app/incident_workflow.py` | Report, offer, decision, review, resolution, and related-report workflow functions | Functions are placeholders that raise `NotImplementedError`. |
| `backend/app/security.py` | Reporter, volunteer, and admin identity and access boundary | Role constants exist; authentication and authorization functions are hollow. |
| `backend/app/storage.py` | `StateStore` protocol, storage error name, SQLite adapter seam | Protocol describes load, atomic change/audit, idempotency, and ping. SQLite methods raise `NotImplementedError`; no file is opened. |
| `backend/app/postgres_store.py` | PostgreSQL adapter for the same storage contract | Holds configuration only; no driver call, SQL, connection, or migration runs. |
| `backend/app/ai_pipeline.py` | Laya text triage, urgency, distance, and related-report grouping | Imports are guarded; functions raise `NotImplementedError`. No checkpoint or clustering run. |
| `backend/app/notification_service.py` | Recipient selection and assignment notification boundary | Placeholder functions; no recipient is selected and no notification is sent. |
| `backend/app/routing_service.py` | Route and ETA boundary | Placeholder; no OSRM request or ETA calculation. |
| `backend/evaluation/evaluate_laya.py` | Future evaluation on reviewed examples | Evaluation functions are placeholders; no dataset or model checkpoint is loaded. |
| `backend/migrations/001_initial_schema.sql` | Intended database schema location | Comments-only outline; it contains no executable migration. |

## Declared API surface

The route declarations in `main.py` currently cover:

- Health: `GET /health`.
- Report access and intake: `GET /api/incidents`, `GET /api/incidents/{ticket_id}`, `POST /api/incidents`, and `POST /api/sos`.
- Volunteer tasks and decisions: `GET /api/volunteer/tasks`, `POST /api/incidents/{ticket_id}/accept`, and `/reject`.
- Admin coordination: `GET /api/review-queue`, `POST /api/incidents/{ticket_id}/offer`, `/correct`, `/split`, and `/resolve`.
- Audit and routing: `GET /api/audit`, `GET /api/eta`, and `WS /ws/alerts`.

Bodies are plain dictionaries. Header parameters such as `Authorization` and `Idempotency-Key` reserve the contract only; credentials, idempotency, validation, and policy are not processed. See [API-CONTRACT.md](API-CONTRACT.md) for intended fields and lifecycle semantics.

## Intended ownership when implementation resumes

Keep `main.py` as the transport boundary. Put workflow rules in `incident_workflow.py`, identity checks in `security.py`, persistence behavior behind `StateStore`, and external effects behind notification and routing modules. Do not put state transitions, vendor calls, or authorization policy into route handlers. The current code does not yet provide a dependency-wired service layer, so this is a target boundary, not a description of active calls.

Preserve these distinctions when filling the seams:

1. A report or SOS receipt requires a durable save; it does not mean a notification was sent.
2. An offer is an admin coordination action; it does not mean the volunteer accepted.
3. Accept and reject are explicit decisions made by the assigned, authenticated volunteer.
4. Rejecting an offer leaves the incident available for later review and another offer.
5. A triage correction or related-report split must not overwrite or delete the reporter's original account.
6. ETA is an estimate for an accepted assignment, not a promise or an SOS prerequisite.

These rules come from [API-CONTRACT.md](API-CONTRACT.md), [DB-SCHEMA.md](DB-SCHEMA.md), and the project chapters. No request schema or domain model class exists; use the established mapping boundary unless the owner revises that constraint.

## Related reading

- [Implementation status](03-IMPLEMENTATION.md)
- [API route and data surface](API-CONTRACT.md)
- [Persistence target](DB-SCHEMA.md)
- [AI and related-report interfaces](AI-STATIONS.md)
- [Guardrails](GUARDRAILS.md)
