# 00 — Planning (Perencanaan)

**Project:** Commencys — Platform Respons Darurat Dini Berbasis Komunitas
**Course:** RPL DTE UI, Gasal 2026/2027 · **Repo:** `JoshRiang/emergency-community-response-911`

| Name | NIM | Role |
|------|-----|------|
| Reinathan Ezkhiel Kurniawan | 2406397675 | Mobile / SOS flow |
| Alwahib Raffi Raihan | 2406397630 | Map & geolocation |
| Joshua Ricardo Riangkamang | 2406361946 | Backend client & alerts |

## Problem statement

Emergency-unit response is too slow in incidents where the first *golden
minutes* decide outcomes. Commencys shortens time-to-awareness by letting any
community member emit a one-tap SOS (GPS + optional manual pin) that reaches
nearby volunteers and a coordinator in **strictly under 5 seconds** — while
remaining explicitly a *community early-response aid*, **not** a replacement
for official services (112 / SPGDT 119).

## MVP scope (in) vs deferred (out)

| In (MVP) | Out (post-MVP) |
|----------|----------------|
| One-tap SOS + GPS, manual pin fallback | Embeddings / vector store (station 2) |
| FastAPI persist + ack < 5 s | Generative-LLM summaries (station 3, advisory-only later) |
| IndoBERT urgency/type classification, async, human-review threshold | RAG over campus SOP corpus (station 5) |
| PostGIS + DBSCAN dedup, async, reversible merges | Autonomous LLM actions (station 6 — permanently read-only/draft-only if ever added) |
| WebSocket live status + OSRM ETA | SOP full-text retrieval UI |
| Acknowledged-vs-dispatched transparency | |
| Immutable audit log, RBAC, GPS-privacy scoping | |

Deferral rationale is recorded per station in `ai-stations.md`: physical
proximity + recency matching (PostGIS/DBSCAN) beats semantic search for the
emergency hot path, and generative/agentic AI is banned from the critical
path by guardrail (see `guardrails.md`).

## Milestones

1. **M1 — Hot path:** SOS → persist → ack < 5 s → WS broadcast (this repo:
   `backend/app/main.py` + Flutter SOS screen).
2. **M2 — AI enrichment:** IndoBERT fine-tune + DBSCAN async workers,
   confidence-threshold review queue, coordinator correction UI.
3. **M3 — Production backing:** PostGIS migration (`db-schema.md`), JWT+RBAC,
   self-hosted OSRM, immutable audit sink.
4. **M4 — Evaluation:** metric dashboards + targets in
   `evaluation-monitoring.md`; FN-priority review cadence.

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| AI latency blocks SOS | AI runs only as background tasks; hot path has no model dependency (acceptance criterion 4) |
| Low-confidence misclassification downgrades a critical report | Fail-safe defaults (SOS = P1 until triage); below-threshold → human review, never auto-downgrade |
| DBSCAN false merge hides a distinct incident | Merges reversible by coordinator; merges logged in audit trail |
| WS drops on flaky mobile networks | Reconnect + REST fallback (`GET /api/incidents`); status always re-fetchable |
| GPS imprecision / denial | Manual pin on interactive map (criterion 1); accuracy radius stored with report |
| Privacy leak of victim coordinates | Precision GPS visible only to authorised coordinator + assigned volunteer (`guardrails.md`) |
