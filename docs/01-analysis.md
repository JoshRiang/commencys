# 01 — Analysis (Analisis)

## User story

> *Emergency-unit response is too slow in incidents where the early golden
> minutes matter most. As a community member witnessing an emergency, I want
> to send one SOS with my location in minimal interaction, see transparent
> proof of what happens next, and get nearby help moving — without wondering
> whether "received by system" means "help is coming".*

## Acceptance criteria (spec §1 — normative)

1. **Minimal-interaction SOS:** reporter sends SOS with automatic GPS; if GPS
   is imprecise, the reporter can adjust a manual pin on the interactive map.
2. **Sub-5-second ack:** the FastAPI backend confirms the ticket is received
   **and stored** in strictly < 5 s (`X-Process-Time-Ms`, `X-SOS-Budget-S`
   headers; test `test_sos_ack_under_budget`).
3. **Transparent status:** the app visually separates *Report Acknowledged*
   (system stored it) → *Broadcast* (volunteers notified) → *Volunteer
   Dispatched* (someone accepted). Acknowledged must never look like
   dispatched.
4. **AI never blocks SOS:** IndoBERT + DBSCAN run asynchronously; their
   failure or latency must not prevent ticket storage or the initial
   broadcast.

## Functional requirements

- FR-1 One-tap SOS with lat/lng, accuracy radius, short description, optional photo.
- FR-2 Manual pin adjustment on the map when GPS is imprecise.
- FR-3 Incident report form (title, description, category, severity, reporter).
- FR-4 Live incident map (OSM pins coloured by urgency).
- FR-5 Geospatial alert feed (REST + WebSocket live frames).
- FR-6 Coordinator triage: confirm/correct AI label, split false-merged clusters.
- FR-7 Volunteer dispatch accept → status `dispatched` + ETA via OSRM.
- FR-8 Immutable audit log of every ticket transition and AI inference.

## Non-functional requirements

- NFR-1 SOS persist+ack p95 < 5 s end-to-end (criterion 2).
- NFR-2 WS delivery success rate ≥ 99% to connected clients; REST fallback.
- NFR-3 IndoBERT F1 tracked per class; **false-negative rate on P1/P2
  minimised first** (spec §8).
- NFR-4 DBSCAN false-merge ratio tracked; 100% of merges reversible.
- NFR-5 ETA calibration error tracked vs actual travel time.
- NFR-6 Precision GPS access-scoped (coordinator + assigned volunteer only).
- NFR-7 Every AI output auditable: raw report immutable, AI writes metadata only.

## Gap map — spec → repo (before this update)

| Spec requirement | Repo state (before) | Closed by |
|------------------|--------------------|-----------|
| SOS < 5 s persist+ack (FastAPI) | No backend at all; Flutter called a non-existent server | `backend/app/main.py` + timing tests |
| Async IndoBERT + DBSCAN, non-blocking | Absent | `backend/app/ai_pipeline.py` (stubbed heuristics behind the real interface + threshold) |
| acknowledged ≠ dispatched | Single `reported` status, "Help is on the way" message overstated dispatch | `Status` lifecycle, Flutter status-timeline UI, dispatch endpoint |
| 9-station AI mapping doc | README only | `docs/ai-stations.md` |
| 3 tech decisions + trade-offs | Absent | `docs/decisions.md` |
| API contract | 4-line sketch | `docs/api-contract.md` |
| PostGIS DB schema | Absent | `docs/db-schema.md` |
| Eval/monitoring plan | Absent | `docs/evaluation-monitoring.md` |
| Guardrails (privacy, review, audit, 112/119) | One disclaimer-less SOS screen | `docs/guardrails.md` + in-app disclaimer + SOPs in `06-maintenance.md` |
| Manual pin fallback | GPS-only SOS | Documented + client TODO surfaced in `03-implementation.md` (map screen is the pin host) |

## Client note (spec §7 vs repo)

The spec text names a React PWA; this repo implements the client as a
**Flutter app** (installable, offline-tolerant, OSM map, WS-capable), which
fulfils the same architectural role: reporter/volunteer front-end talking to
the FastAPI backend over the documented contract. No spec behaviour is lost
in the substitution — the contract (`api-contract.md`) is client-agnostic.
