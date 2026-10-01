# 05 — Deployment (Penyebaran)

## Backend (FastAPI)

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Production: run behind a reverse proxy with TLS; set `OSRM_BASE_URL` to the
self-hosted `osrm-backend`; replace `_store` with PostgreSQL/PostGIS per
`db-schema.md`; terminate WS at the proxy with sticky/timeout config for
long-lived `/ws/alerts` connections; export latency + delivery metrics to the
dashboards in `evaluation-monitoring.md`.

## Mobile client (Flutter)

```bash
flutter pub get && flutter analyze && flutter test
flutter build apk --release   # CI also produces app-release.apk artifact
```

Point `ApiClient.baseUrl` at the deployed backend (LAN IP for devices;
emulator keeps `http://10.0.2.2:8000`). OSM tiles require network; offline
map packs are a post-MVP hardening item.

## Environment matrix

| Var | Purpose | Default |
|-----|---------|---------|
| `OSRM_BASE_URL` | routed ETA proxy target | unset → labelled stub |
| backend host/port | deploy binding | `0.0.0.0:8000` |
| `ApiClient.baseUrl` | client → backend | `http://10.0.2.2:8000` |

## Release gate

CI green (`ci.yml`: backend pytest + flutter analyze/test/release build) →
manual QA checklist (`04-testing.md`) → tag `vX.Y.Z` → attach release APK.
