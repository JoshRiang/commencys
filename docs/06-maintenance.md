# 06 — Maintenance + SOPs

## SOP-1 · Coordinator triage (daily during pilot)

1. Open review queue (`needs_review=true`, low-confidence AI).
2. Confirm/correct category + urgency; split false-merged clusters.
3. Every correction writes an audit row (actor, before/after, model version).
4. Weekly: review all P1/P2 false negatives (predicted ≤ P3 on a true P1/P2)
   — findings go to annotation + retraining.

## SOP-2 · Model lifecycle (per release / quarterly)

1. Evaluate IndoBERT on the held-out set; block release on F1 regression.
2. Recalibrate confidence threshold if review-queue precision drifts.
3. Recalibrate DBSCAN eps/time-window from false-merge sampling.
4. Recalibrate OSRM speed profiles from ETA-error distribution.

## SOP-3 · Incident: SOS path degradation

1. If p95 ack latency > 4 s (alert), freeze AI-worker concurrency first —
   AI must never borrow the hot path's resources.
2. If WS delivery < 99%, verify REST fallback serves `GET /api/incidents`;
   clients re-sync on reconnect.
3. Post-mortem template: timeline, golden-minutes impact, FN check, fix + test.

## SOP-4 · Data retention & access

Precision GPS and photos under coordinator/assigned-volunteer scoping only;
exports require coordinator approval + audit entry; retention per campus
policy; deletion requests purge raw + metadata + audit-reference consistently.

## Roadmap hooks (deferred stations)

- Station 2 (embeddings): historical-incident grouping experiment after M4.
- Station 5 (RAG): SOP-retrieval panel on coordinator dashboard, cited answers.
- Station 3/6 (LLM): advisory summaries / read-only drafts only, never
  autonomous action or SOS-path coupling.
