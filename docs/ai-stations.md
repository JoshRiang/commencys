---
layout: default
title: AI Stations Mapping
nav_order: 3
parent: Reference
---

# AI Stations Mapping (9-station AI architecture)

Design reference: "Designing an AI-Powered Feature" (Sep 2026).
Each station: function → project realisation → repo pointer.

## 1. Data & ETL Pipelines — collecting and tidying reports

SOS intake carries timestamp, GPS + accuracy radius, short description,
optional photo. FastAPI validates schema and persists to PostgreSQL/PostGIS.
Raw report fields are **immutable**; IndoBERT labels and DBSCAN cluster ids
land in nullable metadata columns so every inference is auditable and
coordinator-correctable.
→ `backend/app/models.py`, `docs/db-schema.md`

## 2. Embeddings & Vector Stores — finding similar-meaning text

**Deferred past MVP (explicit).** Emergency matching is proximity + recency,
which spatio-temporal PostGIS + DBSCAN already cover without a vector DB's
cost. Embeddings may return for post-MVP features: campus-SOP retrieval or
historical-incident grouping.
→ rationale in `docs/00-planning.md`, future hook in `docs/06-maintenance.md`

## 3. LLM APIs & Prompt Engineering — generating/summarising text

**Not an MVP component.** Classification is discriminative (IndoBERT), not
generative. Future multi-report narrative summaries are allowed only as
*advisory* modules — an LLM must never delay an SOS, issue standalone medical
guidance, or execute handling decisions without officer verification.
→ guardrail in `docs/guardrails.md`

## 4. Fine-Tuning & Custom Models — IndoBERT for Indonesian triage

Fine-tuned IndoBERT classifies incident type + urgency over informal
Indonesian (slang, abbreviations, campus/regional terms), trained on
human-annotated, human-verified data. A **confidence threshold** (0.65)
routes low-confidence tickets to coordinator review. Taxonomy + P1–P4 matrix
are standardised so annotation and inference stay consistent.
→ `backend/app/ai_pipeline.py` (`CONFIDENCE_THRESHOLD`, `classify()`),
`docs/evaluation-monitoring.md`

Implemented as `heuristic-v2` (keyword stand-in behind the IndoBERT
interface — same thresholds, same metadata contract):
* Urgency inference (`infer_urgency()`): P1 signals (pingsan / tidak sadar /
  jantung / sesak / terjebak / berdarah / kebakaran besar / ledakan) and P2
  signals (luka parah / kebakaran / asap tebal / bocor gas / begal /
  keracunan) suggest a **higher** urgency only. The original `urgency` field
  is never mutated by AI; the suggestion lands in `ai_suggested_urgency` +
  `ai_urgency_conf` with `urgency_source='ai_triage_pending_review'`.
  SOS tickets stay P1 fail-safe unconditionally.
* Low confidence (< 0.65) **or** a pending escalation sets
  `needs_review=true`, surfaced in `GET /api/review-queue` and the Alerts
  "Needs review (N)" row.

## 5. RAG — retrieving documents before answering

**Not on the SOS/notification critical path.** Post-MVP: RAG on the
coordinator dashboard over campus SOPs, internal/external emergency contacts,
and official safety guides. Every RAG answer must cite its source document
and never override coordinator judgement.
→ roadmap in `docs/06-maintenance.md`

## 6. Tool/Function Calling & Agents — AI triggering actions

**Laya AI dispatch (`POST /api/incidents/{id}/dispatch-auto`,
`backend/app/laya_dispatch.py`).** The coordinator (or an automation)
triggers dispatch-auto on a ticket; the Laya agent (default
`http://127.0.0.1:8010`, `POST /v1/systemone`, overridable via
`LAYA_BASE_URL` / `LAYA_TIMEOUT_S`) infers category (choice), severity
(score 1–5), role bundle (choice) and headcount (score 1–5) over the
incident report, and the backend matches registered volunteers by role
overlap, nearest-first (haversine), capped at `headcount`.

Guardrails that keep this advisory, never autonomous on the hot path:

* The ticket report is pre-translated ID→EN with an offline glossary
  (~50 emergency terms, e.g. `kebakaran` → `fire`; Laya's English model
  misclassifies raw Indonesian at low confidence) — the heuristic
  fallback still runs on the **original** Indonesian text.
* A **confidence gate** (`< 0.5`) discards Laya's labels in favour of the
  keyword-heuristic fallback; **any** Laya failure (timeout 15 s,
  connection error, malformed answer) falls back with
  `source: "fallback"` — dispatch-auto never 5xxes because of Laya.
* The manual `POST …/dispatch` override is untouched; dispatch results
  (`required_roles`, `invited[]`, `dispatch_source`) are stored as ticket
  metadata, audit-logged (`dispatch_auto`) and WS-broadcast
  (`incident.dispatch_auto`) for coordinator visibility.
* SOS intake itself never touches Laya; JWT + RBAC remain the production
  gateway TODO.
→ `backend/app/laya_dispatch.py` (`VALID_ROLES`, `ROLE_BUNDLES`,
`pretranslate_id_en`, `heuristic_dispatch`, `dispatch_incident`),
`docs/api-contract.md` (auth), `docs/guardrails.md`

## 7. Application Integration — wiring everything

Reporter flow (Flutter app — spec's PWA role) → FastAPI validation →
PostgreSQL/PostGIS → async IndoBERT + DBSCAN → WebSocket gateway fan-out →
OSRM shortest-route + ETA. UI strictly separates "Laporan Diterima Sistem"
(acknowledged) from a volunteer accepting the ticket (dispatched).
→ `docs/02-design.md` (diagram), `backend/app/main.py`, `lib/`

Implemented: classification + clustering run as FastAPI BackgroundTasks
(`_enrich`), `incident.ai_updated` fans out on WS, clustering backfills new
cluster ids onto neighbours, coordinator endpoints (`correct` / `split`)
and the Flutter AI surfaces (`AiTriageBadges`, review-queue filter, AI
preview on the report form) close the loop.

## 8. Evaluation & Monitoring — measuring quality continuously

Tracked: SOS end-to-end latency (< 5 s), WS delivery rate, IndoBERT
accuracy/F1, DBSCAN false-merge ratio, OSRM ETA calibration vs actual travel
time. **FN priority:** high-risk reports must never be missed or silently
downgraded.
→ `docs/evaluation-monitoring.md`

Implemented in MVP: pytest guards (`backend/tests/test_api.py`, 24 tests) —
SOS ack < 5 s, SOS never downgraded by AI, AI escalation advisory-only,
review-queue contents, cluster + split reversibility, correction keeps raw
immutable, audit lifecycle (`create` → `ai_classify` → `cluster`/`dispatch`/
`dispatch_auto`/`correct`/`split`, all stamped `model_version='heuristic-v2'`),
volunteer registry + role filter, dispatch-auto matching (mocked Laya),
Laya-down → heuristic fallback, low-confidence → fallback, ID→EN
pre-translator coverage.

## 9. Responsible AI & Guardrails — protecting users

Precision GPS visible only to authorised coordinators + assigned verified
volunteers. Transparent status, coordinator review/correction of every AI
output, immutable audit log. The platform is a community early-response aid —
**not** a substitute for 112 / SPGDT 119.
→ `docs/guardrails.md`, `docs/db-schema.md` (audit table)
