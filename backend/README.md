# Commencys backend scaffold

FastAPI preserves report, SOS, admin assignment-offer, volunteer task-feed, review, volunteer decision, audit, and ETA route boundaries. This phase intentionally contains no ticket workflow, background analysis, WebSocket delivery, database access, authentication, or routing provider. Every operational route returns HTTP 501.

The health route reports that the process is a scaffold and not ready. Routes accept unvalidated JSON objects; there are no application request or incident model classes. Laya and scikit-learn are declared dependencies and imported only at the triage and clustering seams. No checkpoint is loaded and neither analysis runs. PostgreSQL/PostGIS and OSRM are not configured runtime services. Hollow seams reserve access control, workflow orchestration, notification, PostgreSQL persistence, routing, and Laya evaluation. The SQL migration file contains comments only and cannot create tables.

## Run locally

From the repository root on Windows:

~~~powershell
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --reload --port 8000
~~~

Open the local root URL to inspect the static operator dashboard. Its queue and action controls are disabled. Do not use this API for real incident coordination.

## Source map

- app/main.py defines the route and health boundaries.
- Route bodies remain plain JSON dictionaries; project field vocabulary is documented separately.
- app/ai_pipeline.py defines advisory triage and related-report interfaces.
- app/security.py and app/incident_workflow.py reserve actor checks and workflow boundaries; they raise `NotImplementedError`.
- app/storage.py defines the state-store contract and an inactive SQLite placeholder; app/postgres_store.py is a hollow target adapter.
- app/notification_service.py and app/routing_service.py preserve future service boundaries without sending or requesting data.
- evaluation/evaluate_laya.py records the Indonesian evaluation seam; it does not load a dataset or checkpoint.
- migrations/001_initial_schema.sql is a comments-only schema outline.
- tests/ retains behavior checks as skipped acceptance specifications.

## Verification

Python compilation can be checked with:

~~~powershell
.\.venv\Scripts\python.exe -m compileall -q backend\app backend\tests
~~~

Behavioral suites are intentionally skipped while their underlying services are hollow. A skip is not evidence that a feature works. Installing Laya does not download its model checkpoint; the checkpoint is not loaded by this scaffold.
