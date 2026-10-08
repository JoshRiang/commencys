---
layout: default
title: CODE MAP D - WORKFLOW FILE OWNERSHIP
nav_order: 23
parent: Reference
---

# CODE MAP D: WORKFLOW FILE OWNERSHIP

Use this map to locate the files a future implementation is likely to touch. It is a change-navigation aid, not a claim that the flows below already work. Each row links a project responsibility to its existing seams and the current gap.

## Cross-file responsibility map

| Responsibility | Existing files to inspect | Current gap |
|---|---|---|
| Reporter submits a located report | `lib/screens/report_screen.dart`, `lib/widgets/location_picker.dart`, `lib/services/location_service.dart`, `lib/services/api_client.dart`, `backend/app/main.py`, `backend/app/incident_workflow.py`, `backend/app/storage.py` | UI, location, request, validation, persistence, and receipt are not connected. |
| Reporter submits SOS | `lib/screens/sos_screen.dart`, `lib/services/api_client.dart`, `backend/app/main.py`, `backend/app/incident_workflow.py`, `backend/app/storage.py`, `backend/app/security.py` | SOS route is 501. Idempotency is declared but unused; no receipt or durable save occurs. |
| Admin reviews a report | `web/app.js`, `web/index.html`, `backend/app/main.py`, `backend/app/security.py`, `backend/app/incident_workflow.py`, `backend/app/storage.py` | Dashboard state is empty and interactions are placeholders; review queue and authorization are inactive. |
| Admin offers a task | `web/app.js`, `backend/app/main.py`, `backend/app/incident_workflow.py`, `backend/app/security.py`, `backend/app/notification_service.py`, `backend/app/storage.py` | No offer is saved, recipient selected, or notification sent. |
| Volunteer sees and decides an offer | `CommencysVolunteerWidgetProvider.kt`, `CommencysVolunteerWidgetActionReceiver.kt`, `VolunteerTaskGateway.kt`, `backend/app/main.py`, `backend/app/security.py`, `backend/app/incident_workflow.py`, `backend/app/storage.py` | Widget feed and decision receiver are disconnected; API routes are 501. |
| Admin corrects triage or separates a candidate link | `web/app.js`, `backend/app/main.py`, `backend/app/ai_pipeline.py`, `backend/app/incident_workflow.py`, `backend/app/storage.py`, `backend/migrations/001_initial_schema.sql` | No model output, review action, persisted audit, or reversible relationship is implemented. |
| Accepted volunteer views an ETA | `lib/services/api_client.dart`, `lib/screens/map_screen.dart`, `backend/app/main.py`, `backend/app/routing_service.py`, Compose routing profile | No acceptance-aware route handoff, OSRM call, or ETA calculation exists. |
| Add persistence and audit | `backend/app/storage.py`, `backend/app/postgres_store.py`, `backend/migrations/001_initial_schema.sql`, Compose `data` profile | Adapter and migration are hollow; the API does not use a store. |
| Add authentication and role access | `backend/app/security.py`, `config/keycloak/commencys-realm.json`, `pubspec.yaml`, Flutter auth-related services | No token verification, session flow, or resource authorization is active. |

The more precise route payload list is in [API-CONTRACT.md](API-CONTRACT.md). The target persistence shape is in [DB-SCHEMA.md](DB-SCHEMA.md). Keep code edits within the owning seams and update the contract documentation when a user-visible behavior or payload changes.

## Build and check automation

| File | Configured work | Reading the result |
|---|---|---|
| `.github/workflows/ci.yml` | On pushes and pull requests to `main`, installs Python and Flutter dependencies, compiles Python, runs pytest, analyzes/tests Flutter, and builds a release APK artifact. | Workflow configuration is not evidence that a run passed. Backend behavior checks are deferred in the current test files; the mobile job still requests a full build. |
| `.github/workflows/flutter_build.yml` | Runs Flutter dependency resolution, analysis, Flutter tests, and a release APK build on the same `main` events. | This overlaps the Flutter job in `ci.yml`; preserve both unless the owner asks to consolidate them. |
| `backend/conftest.py` | Adds `backend/` to Python's import path for tests. | It does not create database fixtures or activate the placeholder services. |
| `backend/tests/` | Holds former and planned API, storage, concurrency, dashboard, and vertical-slice acceptance specifications. | The active docs record those behavioral assertions as skipped/deferred; a green pytest process alone does not mean the workflows were exercised. |

The project's dated local checks are summarized in [README.md](../README.md) and [04-TESTING.md](04-TESTING.md). The README records that the latest toolchain pass did not repeat the APK build. Do not report an Android build as verified for the current source solely because a workflow contains a build step or an older checkpoint records an APK.

## Shared invariants across files

- Use the names reporter, volunteer, and admin for account roles. “Operator” refers to the admin's dashboard function.
- Keep API and client payloads as plain maps/dictionaries. The project owner asked to omit data-model classes.
- Preserve the reporter's original text, location source, and selected severity separately from AI suggestions and admin corrections.
- Report receipt, notification delivery, offer creation, volunteer acceptance/rejection, and resolution are distinct events.
- Accept/reject decisions must be explicit and attributable to the assigned volunteer's verified session. A client-supplied name or widget action ID is not proof of identity.
- Laya and DBSCAN outputs are advisory. They must not alter source reports, suppress SOS intake, or trigger assignment automatically.
- Candidate links must be reviewable and reversible. Reports are not merged or discarded by clustering.
- Routing and ETA follow an accepted assignment. An ETA is an estimate.
- Handle and document failure states before showing success. A comment, package, interface, or static control is not runtime evidence.

## Suggested trace for a code change

1. Identify the requirement in the relevant Chapter 1 to Chapter 3 document and note whether it is a target or an accepted project decision.
2. Read the matching active contract in `docs/` and the relevant `CODES_*.md` map.
3. Inspect the live source and current `git status`; preserve unrelated local edits.
4. Change the smallest owning boundary, keeping the API as the authority for identity and state.
5. Update the active code documentation when runtime truth changes. Do not edit frozen chapter PDFs or archive analysis unless the owner explicitly reopens them.
6. Verify only the affected build or behavior and state what was not verified. The broader deferred acceptance work is catalogued in [04-TESTING.md](04-TESTING.md).
