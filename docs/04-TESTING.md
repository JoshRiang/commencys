---
layout: default
title: 5. VERIFICATION AND DEFERRED CHECKS
nav_order: 14
parent: SDLC and Verification Flow
---

# 04 · VERIFICATION AND DEFERRED CHECKS

Behavioral checks from the former prototype are retained as acceptance specifications and marked skipped. Their expectations describe later implementation work; they are not results for the current scaffold.

## STATIC CHECKS

From the repository root on Windows:

~~~powershell
.\.venv\Scripts\python.exe -m compileall -q backend\app backend\tests
node --check web\app.js
flutter analyze --no-pub
~~~

Flutter HTTP and server-configuration checks are marked deferred until those services are implemented. Incident data-model checks were removed with the model classes. Android APK compilation requires the Android SDK.

## DEFERRED BACKEND ACCEPTANCE CHECKS

- API request validation and report/SOS receipt
- persistence, retry identity, and audit records
- explicit accept, reject, correction, split, and resolve transitions
- asynchronous triage and related-report analysis
- concurrency behavior
- same-origin dashboard data and WebSocket delivery
- complete report-to-review vertical slices

These checks remain under backend/tests. They are intentionally skipped because their supporting services are placeholders.

## DEFERRED CLIENT CHECKS

- HTTP request mapping and idempotency headers
- persistent server configuration
- GPS permission and manual map selection on devices
- widget routing into the SOS flow
- volunteer task-feed refresh and accept/reject actions from the widget
- admin dashboard loading, correction, coordination status, and audit actions
- disconnect and recovery behavior

On 8 October 2026, the latest local static pass compiled Python sources, checked `web/app.js`, parsed ten Android XML files, and confirmed the SQL migration outline has no executable statements. DOCX package inspection found the expected image counts and landscape sections, Times New Roman styles, and bold/italic runs. Text extraction from all three PDFs found no replacement characters or em dashes. Visual DOCX rendering is unavailable because Word and LibreOffice are not installed. Earlier direct FastAPI, Laya, and DBSCAN imports succeeded and `pip check` found no broken requirements. `pytest -q backend/tests` previously collected 39 tests and skipped all 39 under the suite-level deferral marker, so no behavioral assertions ran. Repeated `flutter analyze --no-pub` and `flutter test` attempts produced no output and were interrupted; current Dart analysis and Flutter tests are unverified. Android APK and native widget builds have not been verified. Static checks do not verify user workflows, privacy enforcement, delivery, model quality, performance, or emergency response readiness.
