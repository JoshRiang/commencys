---
layout: default
title: 4. IMPLEMENTATION
nav_order: 13
parent: SDLC and Verification Flow
---

# 03 · IMPLEMENTATION STATUS

The repository is in a scaffold phase. Component boundaries and contracts remain visible for team planning; operational workflows are deliberately hollow.

| Component | Present source | Runtime status |
|---|---|---|
| FastAPI | Health and REST/WebSocket route declarations | Health reports scaffold; operational API routes return HTTP 501 |
| API payloads | Plain JSON dictionaries on report, SOS, admin-offer, volunteer-feed, accept/reject, correction, and responder routes | No application request schema or field validation; operational routes return HTTP 501 |
| Storage | StateStore contract, inactive SQLite adapter, and hollow PostgreSQL adapter | No file, connection, schema, or persistence is created; migration outline is comments only |
| Identity and workflow | Role constants, authorization boundary, and workflow functions | Hollow; no identity is verified and no state transition runs |
| Triage and matching | Function signatures for urgency, candidate classification, distance, and grouping | Each service raises NotImplementedError |
| Notification and routing | Recipient/delivery and accepted-assignment ETA boundaries | Hollow; no message or route request is sent |
| Laya evaluation | Evaluation module for reviewed Indonesian examples | Hollow; no dataset or checkpoint is loaded |
| Flutter report-flow shell | Compact screen outlines and service boundaries using raw JSON maps | Intended to host the reporter widget's report/SOS flow; location, API, and WebSocket behavior are absent |
| Android widgets | Reporter and volunteer providers, layouts, metadata, action receiver, and host activity | Static shells only; report action and volunteer accept/reject buttons are disabled |
| Admin operator dashboard | HTML/CSS layout and named interaction functions | No data is fetched or mutated; controls are disabled |

## PROJECT DECISIONS REPRESENTED AS INTERFACES

Project documents keep location source, reporter-selected severity, urgency, status, and triage metadata as separate concepts. The application has no data-model classes. Laya and scikit-learn are declared runtime dependencies and imported at their service seams, but no checkpoint is loaded and no inference or clustering runs. Related-report analysis remains a proposal for reversible candidate links. Reporter and volunteer use role-specific Android widgets; admin uses the operator dashboard. Persistence, identity and role enforcement, delivery targeting, and routed ETA remain open design work.

## CODE MAP

- backend/app/main.py: route declarations and scaffold health response
- backend/app/storage.py: state-store interface and inactive adapter placeholder
- backend/app/security.py and backend/app/incident_workflow.py: hollow identity and workflow boundaries
- backend/app/postgres_store.py and backend/migrations/001_initial_schema.sql: target persistence seam and comments-only schema outline
- backend/app/ai_pipeline.py: triage and related-report interfaces
- backend/app/notification_service.py, backend/app/routing_service.py: hollow integration boundaries
- backend/evaluation/evaluate_laya.py: Laya evaluation outline; no data or checkpoint is loaded
- lib/services: API payload maps, location, configuration, and socket seams
- lib/screens and lib/widgets: compact consumer UI outlines and location picker
- android/app/src/main: reporter and volunteer widget declarations
- web: static operator dashboard outline
- backend/tests and test: deferred workflow and client-configuration checks; no domain data-model tests remain

## DEPENDENCIES

Python requirements include FastAPI, Uvicorn, HTTP client support, pytest, Psycopg 3, Laya, and scikit-learn. Psycopg is reserved for the hollow PostgreSQL adapter and is not imported at runtime. The AI module imports Laya and DBSCAN when loaded; model loading and analysis are not implemented. Flutter packages retain selected map, geolocation, HTTP, WebSocket, and formatting integration points. Their presence in a package manifest does not mean the corresponding behavior is active.

No Laya checkpoint, active SQLite or PostgreSQL adapter, PostGIS extension, OSRM client, authentication provider, or delivery broker is configured. Psycopg 3 is declared for the future PostgreSQL adapter, but no code imports it or opens a connection. The comments-only migration cannot be run against a database.

## COMPLETION BOUNDARY

This phase establishes the structure and comments needed for shared implementation planning. It does not establish that a report can be submitted, persisted, delivered, reviewed, or resolved. Do not use the source for live incident coordination.
