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

## 5. RAG — retrieving documents before answering

**Not on the SOS/notification critical path.** Post-MVP: RAG on the
coordinator dashboard over campus SOPs, internal/external emergency contacts,
and official safety guides. Every RAG answer must cite its source document
and never override coordinator judgement.
→ roadmap in `docs/06-maintenance.md`

## 6. Tool/Function Calling & Agents — AI triggering actions

**No autonomous LLM actions in the MVP.** SOS intake, dispatch approval, and
status updates execute deterministically via FastAPI endpoints with JWT + RBAC.
Any future assistant is strictly **read-only + draft reports**, with no direct
mutation authority.
→ `docs/api-contract.md` (auth), `docs/guardrails.md`

## 7. Application Integration — wiring everything

Reporter flow (Flutter app — spec's PWA role) → FastAPI validation →
PostgreSQL/PostGIS → async IndoBERT + DBSCAN → WebSocket gateway fan-out →
OSRM shortest-route + ETA. UI strictly separates "Laporan Diterima Sistem"
(acknowledged) from a volunteer accepting the ticket (dispatched).
→ `docs/02-design.md` (diagram), `backend/app/main.py`, `lib/`

## 8. Evaluation & Monitoring — measuring quality continuously

Tracked: SOS end-to-end latency (< 5 s), WS delivery rate, IndoBERT
accuracy/F1, DBSCAN false-merge ratio, OSRM ETA calibration vs actual travel
time. **FN priority:** high-risk reports must never be missed or silently
downgraded.
→ `docs/evaluation-monitoring.md`

## 9. Responsible AI & Guardrails — protecting users

Precision GPS visible only to authorised coordinators + assigned verified
volunteers. Transparent status, coordinator review/correction of every AI
output, immutable audit log. The platform is a community early-response aid —
**not** a substitute for 112 / SPGDT 119.
→ `docs/guardrails.md`, `docs/db-schema.md` (audit table)
