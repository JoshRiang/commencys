# ABOUT_2: Markdown-to-Code Truth Audit

**Current baseline:** local scaffold reviewed 8 October 2026. The working tree is uncommitted.

## Truth rules

- A route or interface declaration proves only that a boundary exists.
- A dependency and import do not prove that a model or algorithm runs.
- A chapter or diagram describes intended behavior, not runtime behavior.
- A skipped test is a deferred acceptance specification, not a passing result.
- A JSON payload type is not field validation or a shared application data model.

## Current source-to-document comparison

| Area | Current source evidence | Truthful status |
|---|---|---|
| Reporter surface | Android report/SOS widget and Flutter report-flow shell | Visual structure only; widget action, location access, and report submission are disabled |
| Volunteer surface | Android task widget, task-feed route, and decision routes | Feed and accept/reject route boundaries are present; static controls remain disabled and no role check or action runs |
| Admin dashboard | HTML/CSS shell and JavaScript placeholders | No report loading, filtering, connection, or mutation; operator is a dashboard function for admin |
| FastAPI | Health and operational route declarations in `backend/app/main.py` | Health reports not ready; operational routes return HTTP 501 |
| Payload boundaries | `dict[str, Any]` in API routes and `Map<String, dynamic>` in Flutter | Raw JSON objects only; no request schemas or domain record classes |
| Laya | `laya` requirement and import inside triage seam | No Router instance, checkpoint download, inference, or evaluation |
| DBSCAN | `scikit-learn` requirement and import inside cluster seam | No feature preparation, clustering call, or report-link update |
| Persistence | StateStore protocol, inactive SQLite and PostgreSQL adapters, comments-only SQL outline | No database connection, stored report, or durable audit; Psycopg is declared but unused |
| WebSocket | Client and server boundaries | No active connection or alert delivery |
| Tests | Backend suite contains deferred acceptance specifications; Flutter tests are deferred | `pytest -q backend/tests` collected 39 tests and skipped all 39; no behavior assertions executed. Flutter analysis and tests produced no output and were interrupted |
| Project chapters | `RESULT/CHAPTER_1.md` through `CHAPTER_3.md` and their PDFs | Independent project documents and target models |

## Documentation updates

The root README, backend README, and current-state pages under `docs` now say that report payloads are plain JSON dictionaries and that the application contains no data-model classes. The API documentation no longer claims field-level validation. AI documentation now distinguishes declared package dependencies from model and algorithm execution. The current architecture diagram and Mermaid source now show the raw payload boundary and import-only service seams without title or footer strips. The database page remains a target design artifact; it does not describe an active application model or database.

The `FORUML`, `FROMCHAPTER1`, `BOOK`, and prior checkpoint notes retain dated analyses of earlier code snapshots. Their historical implementation claims are not current runtime status. Chapter 1 sets the project baseline, and Chapters 2 and 3 are aligned to its widget/dashboard split. The new checkpoint records the recursive document audit and its boundaries.

## Current completion boundary

The UI was reduced by removing unused Flutter detail, generic surface, and server-setting widgets and simplifying the theme. Reporter and volunteer widgets are separate from the admin operator dashboard. API, identity, workflow, storage, notification, routing, and AI evaluation implementations remain hollow. No model weights were downloaded, and no commit or push was made.

The latest local static pass compiled Python sources, checked `web/app.js`, parsed ten Android XML files, and confirmed the SQL migration outline contains no executable statements. DOCX structure contains the expected images, page orientations, Times New Roman styling, and bold/italic runs; PDF text extraction found no replacement characters or em dashes. Visual DOCX rendering is unavailable because Word and LibreOffice are not installed. Earlier direct Laya and DBSCAN imports passed and `pip check` reported no broken requirements. `pytest -q backend/tests` collected 39 tests, but every test was skipped by the suite-level deferral marker; no behavioral assertions ran. Flutter analysis and test attempts produced no output and were interrupted. No device checks, production checks, or model evaluation are claimed.

## Remaining project work

1. Refine the widget-to-report handoff and select dashboard implementation details within the chapter-defined interface split.
2. Define and validate payload fields and acceptance rules before implementing report intake.
3. Add durable storage, access policy, audit, and recovery.
4. Add human review and explicit responder transitions.
5. Evaluate Laya Multilingual and DBSCAN with reviewed project data before selecting operational thresholds.
6. Define targeted notification, recovery, and route boundaries before use.
7. Verify the complete flow on devices and in an approved environment.
