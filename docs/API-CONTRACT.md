---
layout: default
title: API SURFACE
nav_order: 1
parent: Reference
---

# API ROUTE AND DATA SURFACE

This page records route shapes and request fields kept in the scaffold. It is not a promise that those operations work.

## RUNTIME STATUS

The FastAPI process exposes a health route and serves the static dashboard. The health response reports status scaffold and ready false. Operational REST routes return HTTP 501. The WebSocket route closes with code 1011. The API does not store or deliver report data.

Routes accept JSON objects as plain dictionaries. There are no application request schemas, field-bound checks, or domain model classes. Invalid or incomplete fields are not checked before a placeholder returns HTTP 501.

The volunteer task feed and decision routes declare an `Authorization` header as an integration seam. The scaffold does not parse the header, resolve a role, or authorize incident access. The hollow functions in `backend/app/security.py` describe the intended boundary only.

## ROUTE INVENTORY

| Method and path | Intended boundary | Current result |
|---|---|---|
| GET /health | Process liveness | Returns scaffold status; readiness is false |
| GET /api/incidents | List reports | HTTP 501 |
| GET /api/incidents/{ticket_id} | Read one report | HTTP 501 |
| GET /api/volunteer/tasks | List offers visible to the authenticated volunteer | HTTP 501 |
| POST /api/incidents | Submit standard report | HTTP 501 |
| POST /api/sos | Submit urgent report | HTTP 501 |
| POST /api/incidents/{ticket_id}/offer | Admin creates an offer for an eligible volunteer | HTTP 501 |
| GET /api/review-queue | Read review queue | HTTP 501 |
| POST /api/incidents/{ticket_id}/accept | Record explicit acceptance | HTTP 501 |
| POST /api/incidents/{ticket_id}/reject | Record explicit rejection | HTTP 501 |
| POST /api/incidents/{ticket_id}/resolve | Record completion | HTTP 501 |
| POST /api/incidents/{ticket_id}/correct | Correct triage metadata | HTTP 501 |
| POST /api/incidents/{ticket_id}/split | Remove a related-report link | HTTP 501 |
| GET /api/audit | Read report history | HTTP 501 |
| GET /api/eta | Request a route estimate | HTTP 501 |
| WS /ws/alerts | Receive live event frames | Closes with code 1011 |

The Idempotency-Key request header remains part of the SOS client boundary. It is not processed by the scaffold.

## INTENDED PAYLOAD FIELDS

SOS fields: latitude, longitude, location_source, optional accuracy_m, optional description, and optional reporter_name.

Standard report fields: title, description, category, latitude, longitude, location_source, accuracy_m, severity, and reporter_name.

Correction fields: optional ai_category, urgency, and reason. At least one of ai_category or urgency is required. An admin offer may contain an optional note; an approved recipient-selection policy chooses which volunteer receives it. Accept and reject requests have no actor-name body; the server must derive the volunteer from authenticated credentials. Resolution may contain an optional note and must also derive its authorized actor from credentials.

These fields describe the intended contract only. Coordinate ranges, finite numeric values, string limits, enumerated values, and cross-field rules are not validated by the scaffold.

## SHARED INCIDENT FIELDS

The project documents and target database sketch refer to incident fields including id, title, description, category, latitude, longitude, location_source, accuracy_m, reporter reference, severity, urgency, urgency source, status, triage suggestions, review state, related-report links, accepted volunteer reference, resolution time, and creation time. Assignment offers and notification-delivery records are separate target persistence concerns. The application does not define a shared runtime record for them.

The intended lifecycle terms are acknowledged, broadcast, accepted, and resolved. Their transitions and meanings remain design requirements; no transition executes in the current source.

## TARGET BEHAVIOR

When implementation resumes, preserve these rules:

- stored receipt is not notification delivery
- a successful send is not proof that a person read an alert
- the admin may create a targeted task offer; this remains distinct from notification delivery
- acceptance or rejection requires an explicit action by the assigned, authenticated volunteer; the volunteer widget is the intended client
- rejection leaves the report open for another response
- the admin reviews reports and coordinates offers through the dashboard; “operator” describes this dashboard function and is not a separate account role
- completion follows accepted work under an authorized actor, with the responsible role still to be agreed
- triage metadata does not replace the original report
- ETA is an estimate and is available only after acceptance

See [design](02-DESIGN.md), [target persistence sketch](DB-SCHEMA.md), and [guardrails](GUARDRAILS.md).
