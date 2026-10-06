---
layout: default
title: 6 · Deployment
nav_order: 15
parent: SDLC — Waterfall Model
---

# 05 — Deployment

## Table of contents

- [Backend (FastAPI)](#backend-fastapi)
- [Mobile client (Flutter)](#mobile-client-flutter)
- [Phone install](#phone-install)
- [Environment matrix](#environment-matrix)
- [Release gate](#release-gate)
- [Release history](#release-history)

## Backend (FastAPI)

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Local dev binds `:8000` (the code and emulator default). The live
supervised backend serves on `:8791` — see
[Environment matrix](#environment-matrix).

The coordinator-triggered `POST …/dispatch-auto` needs the Laya agent
reachable (`LAYA_BASE_URL`, default `http://127.0.0.1:8010`): the live
box runs it as the systemd user unit `laya-api` (`laya-serve`, lazy-load
via `LAYA_PRELOAD=0` — full preload OOM-stalls the box). Laya being
down is safe (dispatch-auto falls back), but role inference degrades to
keyword heuristics.

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

Backend address resolution (in order):

1. In-app server setting (server icon in the app bar, per session).
2. `--dart-define=API_BASE=http://100.89.180.23:8791` baked into the build
   (CI default since v1.1.0 — works on the Tailnet out of the box).
3. Emulator default `http://10.0.2.2:8000` (host loopback, emulator only).

OSM tiles require network; offline map packs are a post-MVP hardening item.

## Phone install

1. Download the versioned APK from [Release history](#release-history)
   (served over the local file server; verify the SHA-256 below after
   download).
2. Open it on the phone — Android asks for a one-time "install unknown apps"
   confirmation, then installs **Commencys** (`com.commencys.app`).
3. Start the backend on the same network (`uvicorn ... --host 0.0.0.0`),
   set the server URL in-app, send a test SOS.
4. SOS needs GPS + network: allow location when prompted, keep the phone
   online (map tiles, API, and live alerts all need connectivity).

## Environment matrix

| Var | Purpose | Default |
|-----|---------|---------|
| `OSRM_BASE_URL` | routed ETA proxy target | unset → labelled stub |
| `LAYA_BASE_URL` | Laya agent for `dispatch-auto` | `http://127.0.0.1:8010` |
| `LAYA_TIMEOUT_S` | Laya call timeout (then fallback) | `15` |
| backend host/port (local dev) | deploy binding | `0.0.0.0:8000` |
| backend host/port (live supervised) | systemd `commencys-backend` binding | `0.0.0.0:8791` |
| `API_BASE` (dart-define, baked) | baked-in client → backend (CI since v1.1.0) | `http://100.89.180.23:8791` |
| `API_BASE` fallback | emulator default in `AppConfig` | `http://10.0.2.2:8000` |
| in-app server setting | runtime client → backend | overrides `API_BASE` |

## Release gate

CI green (`ci.yml`: backend pytest + flutter analyze/test/release build;
`flutter_build.yml`: same flutter pipeline + APK upload) →
manual QA checklist (`04-testing.md`) → versioned APK published below →
tag `vX.Y.Z`.

## Services & ports (live box)

| Service | systemd user unit | Listens |
|---------|-------------------|---------|
| Commencys backend (FastAPI) | `commencys-backend` | `127.0.0.1:8791` → Tailnet `http://100.89.180.23:8791` |
| Laya agent (role/headcount inference) | `laya-api` (`laya-serve`, `LAYA_PRELOAD=0`) | `127.0.0.1:8010` |
| APK asset server | — (local file server) | `100.89.180.23:8765` |

## Release history

| Version | APK | Size | SHA-256 | CI run | Notes |
|---------|-----|------|---------|--------|-------|
| 1.2.0 (`65409f0`, 2026-10-02) | `commencys-65409f0-20261002.apk` | 52.9 MB | `ec02ab93…37892ef7` | [CI #36985531449](https://github.com/JoshRiang/commencys/actions/runs/36985531449) / [Build #36985531411](https://github.com/JoshRiang/commencys/actions/runs/36985531411) | AI triage heuristic-v2 (maintenance change request): advisory-only urgency inference, DBSCAN-lite clustering, review queue, correct/split, audit trail, visible AI UI; 13/13 + 5/5 tests |
| 1.1.0 (`6967487`, 2026-10-02) | `commencys-6967487-20261002.apk` | 52.8 MB | `86b1120a…c0841bed` | [CI #36981431135](https://github.com/JoshRiang/commencys/actions/runs/36981431135) / [Build #36981431212](https://github.com/JoshRiang/commencys/actions/runs/36981431212) | Map-centric liquid-glass shell (maintenance change request): `AppShell` + floating glass tab bar, map-as-home, `LiquidGlass` material, in-app server setting; CI bakes `API_BASE=http://100.89.180.23:8791` |
| 1.0.1 (`a811497`, 2026-10-02) | `commencys-a811497-20261002.apk` | 50.3 MB | `46dd8f35…b357318` | [CI #36966554133](https://github.com/JoshRiang/commencys/actions/runs/36966554133) / [Build #36966554085](https://github.com/JoshRiang/commencys/actions/runs/36966554085) | Apple liquid-glass UI reskin (maintenance change request): theme tokens + glass kit, 5 screens reskinned, backend contract frozen, analyze clean, 7/7 + 5/5 tests |
| 1.0.0 (`8c15973`, 2026-10-02) | `commencys-8c15973-20261002.apk` | 52.5 MB | `8bf33393…db76fa` | [CI #36911073696](https://github.com/JoshRiang/commencys/actions/runs/36911073696) | first Commencys build: `com.commencys.app`, analyze clean, 5/5 tests |

CI artifact SHA-256 (1.2.0): `ec02ab93a4a4282c9b293de1433e63edba51ef7f236d273cc5f2fed137892ef7`.
CI artifact SHA-256 (1.1.0): `86b1120a64b30f8fa8ffe9aa6e7e81081d87a2c94963916490677ddc0841bed2`.
Full SHA-256 (1.0.1): `46dd8f35fde9c78ec8f88241e3e27f0ed6cced85906d88fb5c04881b3573181f`.
Download: `http://<host>:8765/commencys-<sha>-20261002.apk` (local file server).
Full SHA-256 (1.0.0): `8bf33393860b81da1322e30921c8f11503a6b41a7e95905b916fd9c2e4db76fa`.
