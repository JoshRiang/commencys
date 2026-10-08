# ABOUT_1: Current Codebase State

**Reviewed:** 8 October 2026. This note describes the uncommitted local working tree. No commit or push was made.

## Summary

Commencys is a commented phase-one scaffold. The reporter has a compact Android report/SOS widget and Flutter report-flow shell. The volunteer has a separate task widget with disabled accept/reject controls. The admin uses the separate static operator dashboard. These surfaces do not submit reports, load assignments, or change incident data. FastAPI retains the route boundaries, returns HTTP 501 for operational routes, and reports readiness as false. “Operator” is the admin dashboard function, not an additional account role.

Chapter 1 is the project baseline; Chapters 2 and 3 follow its management and UML scope. These chapters define intended behavior, not implementation evidence. The code and repository documentation preserve the widget/dashboard split while leaving operational behavior as scaffold.

## Components and dependencies

| Component | Current source state | Dependencies or boundary |
|---|---|---|
| Reporter UI | Compact Android report/SOS widget and Flutter report-flow shell | Widget action, location access, and report submission remain disabled |
| Volunteer UI | Compact Android task widget with accept/reject controls | Task-feed and decision route seams exist; controls remain disabled and no identity is verified |
| Admin UI | Static HTML/CSS operator dashboard with disabled controls and interaction stubs | No data fetch, API mutation, or JavaScript package manifest |
| FastAPI | Health response, route declarations, and dashboard static mount | FastAPI, Uvicorn, HTTPX, and pytest in [requirements.txt](../../../backend/requirements.txt) |
| Payloads | Plain JSON dictionaries in FastAPI and `Map<String, dynamic>` in the Flutter client | No application request schema, domain data class, parser, or serializer |
| Triage and clustering | Hollow functions with dependency imports at their service boundaries | `laya` and `scikit-learn` are declared; no router, checkpoint, inference, or clustering call runs |
| Persistence | StateStore protocol and inactive SQLite adapter placeholder | No database file, connection, schema creation, or durable report storage |

## Declared dependencies

| Manifest | Declared packages or tools | Current use in the scaffold |
|---|---|---|
| `backend/requirements.txt` | FastAPI, Uvicorn, HTTPX, pytest, Psycopg 3, `laya`, scikit-learn | FastAPI serves route boundaries; pytest collects deferred acceptance cases; Psycopg is declared but not imported; `laya` and `sklearn.cluster.DBSCAN` are import-only seams. No checkpoint or database connection is configured. |
| `requirements-tools.txt` | Pillow plus `backend/requirements.txt` | Pillow supports local diagram generation; it is not part of application runtime. |
| `pubspec.yaml` | Flutter SDK, `cupertino_icons`, `flutter_map`, `latlong2`, `geolocator`, `web_socket_channel`, `http`, `intl`; `flutter_test` and `flutter_lints` for development | Packages reserve boundaries for mapping, location, REST, and live status. Screens and services do not perform those operations yet. |
| `web/` | Browser HTML, CSS, and JavaScript; no package manifest | Static operator dashboard, served by FastAPI. It loads no reports and performs no mutations. |
| `android/` | Flutter Android host and Android App Widget APIs | Reporter and volunteer widget providers/resources are declared; the volunteer action receiver is a hollow boundary and neither action path is active. |

The team selected the Laya Python package as the import boundary for the Hugging Face Laya family. The candidate checkpoint is `convaiinnovations/laya-multilingual`; `import laya` does not call `laya.load`, download weights, or run inference. Laya requires Python 3.10 or newer. The multilingual model remains a candidate for Indonesian report evaluation; DBSCAN remains a candidate for reversible related-report links.

The current local `.venv` has `laya` 0.4.0 and `scikit-learn` 1.9.1 installed from `backend/requirements.txt`. Their imports work. The installation includes the libraries needed by Laya, including PyTorch and Hugging Face Hub, but no model checkpoint or report dataset was downloaded.

## Source map

- `backend/app/main.py`: health response, raw dictionary payload boundaries, HTTP 501 placeholders, and static dashboard mount
- `backend/app/storage.py`: StateStore interface and inactive SQLite placeholder
- `backend/app/postgres_store.py`, `backend/migrations/001_initial_schema.sql`: hollow target adapter and comments-only SQL outline
- `backend/app/security.py`, `backend/app/incident_workflow.py`: role and state-transition boundaries that raise `NotImplementedError`
- `backend/app/notification_service.py`, `backend/app/routing_service.py`, `backend/evaluation/evaluate_laya.py`: hollow delivery, route, and model evaluation seams
- `backend/app/ai_pipeline.py`: Laya and DBSCAN import seams; analysis functions raise `NotImplementedError`
- `lib/main.dart` and `lib/app_shell.dart`: consumer application entry and compact route shell
- `lib/screens`: map, report, alert, and SOS outlines
- `lib/services`: JSON-map API boundary, location, configuration, and socket seams
- `lib/widgets/location_picker.dart`: manual-location selection placeholder
- `android/app/src/main`: reporter and volunteer widget declarations, action receiver, and activity host
- `web`: static operator dashboard and JavaScript placeholders

The former backend Pydantic classes and Flutter `Incident` class have been removed. The unused detail, generic surface, and server-setting widgets were also removed to keep the UI small.

## Alignment and boundaries

Chapter 1 establishes located reporting, a truthful receipt, human review, privacy, and iterative development. Chapter 2 describes project management and proposed evaluation of Laya and DBSCAN. Chapter 3 supplies target use-case, interaction overview, and component models. Current code preserves route and component seams without executing those workflows.

`README.md` and `/docs` describe the code state. `RESULT/CHAPTER_1.md` through `CHAPTER_3.md` remain standalone chapter documents and were not rewritten from repository state.

## Verification status

The latest local static pass compiled Python sources, checked `web/app.js`, parsed ten Android XML files, and confirmed the migration outline contains no executable SQL. DOCX structure contains the expected embedded figures and landscape sections; Times New Roman and bold/italic runs are present. PDF extraction found no replacement characters or em dashes. Visual DOCX rendering is unavailable because Word and LibreOffice are not installed. Earlier checks imported FastAPI, Laya, and DBSCAN and found no broken Python requirements. `pytest -q backend/tests` previously collected 39 tests, all marked skipped; no behavioral assertion ran. Repeated `flutter analyze --no-pub` and `flutter test` attempts produced no output and were interrupted, so Dart analysis and Flutter tests remain unverified. Static checks cannot establish SOS intake, persistence, model quality, clustering quality, privacy enforcement, delivery, or emergency readiness.
