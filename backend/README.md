# Commencys backend (FastAPI skeleton — MVP)

Implements the spec's SOS hot path: persist + acknowledge in **< 5 s**,
IndoBERT/DBSCAN as non-blocking background enrichment, transparent ticket
statuses (`acknowledged` → `broadcast` → `dispatched` → `resolved`), and a
WebSocket fan-out at `/ws/alerts`.

## Run

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
# Android emulator -> host: http://10.0.2.2:8000
```

PostGIS swap: the in-memory `_store` in `app/main.py` keeps the same
ticket dict shape as `docs/db-schema.md`, so replacing it with SQLAlchemy +
`asyncpg` is a drop-in. OSRM: set `OSRM_BASE_URL` (self-hosted
`osrm-backend`) to switch `/api/eta` from the labelled stub to routed ETAs.

## Test

```bash
pytest -q
```
