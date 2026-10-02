---
layout: default
title: Decisions
nav_order: 21
---

# Key Technical Decisions + Trade-offs

## D1 — IndoBERT for report classification

- **Decision:** fine-tuned IndoBERT assigns incident type + P1–P4 urgency.
- **Rationale:** pre-trained transformer optimised for Indonesian; captures
  semantics of informal citizen text (slang, abbreviations) fast enough for
  near-real-time triage.
- **Trade-offs:** needs a sufficient local labelled dataset + periodic
  re-evaluation (language drift); low-confidence predictions require a
  coordinator review queue (threshold 0.65, `ai_pipeline.py`); inference
  runs async so it can never stall SOS (criterion 4). FN on P1/P2 is the
  metric that matters most (`evaluation-monitoring.md`).
- **Alternatives rejected:** keyword rules (brittle on informal text);
  generative LLM classifier (non-deterministic, slower, harder to calibrate
  a threshold on).

## D2 — PostgreSQL/PostGIS + DBSCAN for report matching

- **Decision:** spatio-temporal index + DBSCAN dedupes duplicate reports of
  the same incident.
- **Rationale:** proximity + recency matching needs no vector-DB cost or
  complexity at MVP scale; PostGIS `GIST` + `ST_DWithin` pre-filter keeps
  the clustering window small and fast.
- **Trade-offs:** accuracy is sensitive to spatial epsilon and the time
  window; wrong merges must be splittable by the coordinator
  (`cluster_id` is nullable metadata, never destructive); parameters need
  calibration from field data (false-merge ratio tracked).
- **Alternatives rejected:** vector/embeddings dedup (station 2 — deferred;
  semantic similarity is the wrong primary key for "same physical event").

## D3 — WebSocket for live status + OSRM for route/ETA

- **Decision:** WebSocket gateway for bidirectional low-latency ticket/location
  updates; self-hosted OSRM for route + volunteer ETA.
- **Rationale:** WS gives server-push status transitions without polling;
  OSRM on OSM road data gives accurate, cost-free routing vs paid APIs.
- **Trade-offs:** WS needs concurrency management + auto-reconnect with REST
  fallback on flaky mobile networks (client implements reconnect;
  `GET /api/incidents` is the fallback); ETA stays an *estimate* bound to
  OSM data freshness — the UI labels stub/unrouted ETAs as estimates, never
  promises.
- **Alternatives rejected:** pure polling (latency + battery cost); hosted
  routing API (cost, data sovereignty, offline-campus limitation).
