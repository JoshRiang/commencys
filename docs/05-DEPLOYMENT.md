---
layout: default
title: 6. LOCAL STARTUP AND DEPLOYMENT LIMITS
nav_order: 15
parent: SDLC and Verification Flow
---

# 05 · LOCAL STARTUP AND DEPLOYMENT LIMITS

The current source is a non-operational scaffold. Do not expose it publicly or use it for real emergency coordination. Report routes return HTTP 501, the dashboard does not load tickets, and no database is configured.

## START THE API SHELL ON WINDOWS

From the repository root:

~~~powershell
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --reload --port 8000
~~~

The root page serves the static operator dashboard. The health route reports scaffold status and readiness false. Starting Uvicorn does not enable report intake or coordination.

## INSPECT THE FLUTTER SHELL

With Flutter 3.x installed:

~~~powershell
flutter pub get
flutter analyze --no-pub
flutter run
~~~

The Android widget is declared but its action is disabled. The application does not request location or send reports in this phase. Building an Android package requires an Android SDK and license acceptance.

## BEFORE A FUNCTIONAL PILOT

1. Confirm client, API, data, and operating scope with the team.
2. Implement storage, backup, restoration, and migration ownership.
3. Add authentication, role checks, and exact-coordinate access rules.
4. Define recipients, acceptance semantics, and reconnect recovery.
5. Evaluate triage and related-report analysis on reviewed data.
6. Integrate and measure routing only after an assignment is accepted.
7. Verify the full flow on devices and in an approved operational setting.

Earlier builds and test results describe older source states. They do not apply to this scaffold.
