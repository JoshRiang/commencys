---
layout: default
title: CODE MAP C - DEPENDENCIES AND INTEGRATION SEAMS
nav_order: 22
parent: Reference
---

# CODE MAP C: DEPENDENCIES AND INTEGRATION SEAMS

This page distinguishes installed or declared packages from services that the application actually uses. The local setup instructions and version snapshot are in [README.md](../README.md); this page focuses on where each integration enters the code and what remains inactive.

## Dependency and service clusters

| Cluster | Files | Present purpose | Runtime status |
|---|---|---|---|
| FastAPI service | `backend/requirements.txt`, `backend/app/main.py` | API process and HTTP/WebSocket route surface | Health and static dashboard serve; product routes remain 501. |
| Backend development | `backend/requirements-dev.txt`, `backend/tests/` | Pytest and later acceptance checks | Tests are deferred specifications, not passing behavior evidence. |
| Laya and DBSCAN | `backend/requirements-ai.txt`, `backend/app/ai_pipeline.py`, `backend/evaluation/evaluate_laya.py` | Candidate text triage and spatial/temporal related-report analysis | Laya and `sklearn.cluster.DBSCAN` imports are guarded. No checkpoint is loaded, no model inference runs, and no report clustering executes. |
| Flutter reporter client | `pubspec.yaml`, `lib/` | Map, location, REST, WebSocket, OIDC, secure storage seams | Packages are declared, but the corresponding report, auth, location, and live-update flows are not active. |
| Android build | `tools/android-sdk-packages.txt`, Gradle files under `android/` | Flutter host and native home-screen widgets | Local SDK setup is documented; package declarations do not make widget actions operational. |
| PostgreSQL/PostGIS | `compose.yaml` profile `data`, `backend/app/postgres_store.py`, `backend/migrations/` | Target durable and spatial storage | Compose service is optional and not connected to the API. Adapter is hollow; migration has comments only. |
| Email identity development | `compose.yaml` profile `identity`, `config/keycloak/commencys-realm.json` | Local Keycloak and Mailpit environment | Development services only. The API does not validate tokens or use the realm. |
| OSRM routing | `compose.yaml` profile `routing`, `tools/prepare-osrm.ps1`, `backend/app/routing_service.py` | Local route engine and planned ETA | Requires prepared regional map data. No graph, API client, or ETA workflow is active. |
| Document generation | `requirements-tools.txt`, `tools/build_chapter_docx.py`, `tools/build_chapter_pdf.py` | Rebuild archived chapter and diagram artifacts | Separate document tooling; unrelated to the API runtime. |

## Python package groups

- `backend/requirements.txt` declares FastAPI, Uvicorn, HTTPX, Psycopg, Pydantic Settings, and PyJWT. Psycopg and PyJWT are reserved integration dependencies; their presence does not create database or identity behavior.
- `backend/requirements-dev.txt` extends runtime requirements with pytest.
- `backend/requirements-ai.txt` extends the runtime set with Laya, Hugging Face Hub, and scikit-learn. Importing `laya` or `DBSCAN` is not model loading, weight download, inference, fitting, or evaluation.
- `requirements-tools.txt` is for document/image generation and should not be confused with application dependencies.

## Optional Compose profiles

`compose.yaml` separates the optional local services:

- `data`: PostGIS on loopback port 5432 with a named volume.
- `identity`: Mailpit on loopback ports 1025/8025 and Keycloak on 8080, using the local realm import.
- `routing`: OSRM on loopback port 5000, mounting prepared Java map data read-only.

These profiles can be checked with `docker compose config --quiet`. Pulling images or starting services consumes disk and is not part of documentation traversal. The bootstrap script validates profile configuration by default; it pulls or starts only when the corresponding explicit switch is passed. Never reuse the development credentials outside the local machine.

## Machine paths and setup

`tools/bootstrap.ps1` groups setup into `android`, `mobile`, `api`, `ai`, `data`, `identity`, and `routing` clusters. The documented defaults place the Android SDK under `D:\Android\Sdk` and package/build/model caches under `D:\Commencys-Cache`. The script accepts `ANDROID_HOME` and `COMMENCYS_CACHE_ROOT` overrides. Use the commands in the root [README](../README.md), which also records the 8 October 2026 local toolchain snapshot.

Do not commit machine-specific `android/local.properties`, SDKs, caches, model weights, OSRM extracts, database volumes, or local secrets. Do not download Laya weights just to make an import succeed; model evaluation and artifact handling are separate project decisions.

## Integration activation checklist

Before describing any seam as connected, verify its actual call path:

1. **Database:** API dependency wiring, active schema migrations, PostGIS connection, persistence and audit transactions, and recovery procedure.
2. **Identity:** approved Keycloak client and role mapping, token verification in `security.py`, Flutter login/session boundary, and per-resource access checks.
3. **Laya:** approved checkpoint, reviewed Indonesian evaluation data, reproducible metrics and critical-error review, advisory output, and rollback plan.
4. **DBSCAN:** accepted spatial/time criteria, tested distance units and edge cases, reversible candidate links, and human review.
5. **Notification:** recipient policy, delivery evidence, retry behavior, and clear separation from acceptance.
6. **OSRM:** prepared data, service client, accepted-assignment check, failure handling, and ETA wording as an estimate.

The detailed contracts and unresolved choices are in [DB-SCHEMA.md](DB-SCHEMA.md), [AI-STATIONS.md](AI-STATIONS.md), [DECISIONS.md](DECISIONS.md), and [GUARDRAILS.md](GUARDRAILS.md).
