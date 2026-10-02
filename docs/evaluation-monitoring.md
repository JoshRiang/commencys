---
layout: default
title: Evaluation & Monitoring
nav_order: 1
parent: Quality & Governance
---

# Evaluation & Monitoring Plan (spec station 8)

## Metrics, targets, instruments

| Metric | Target | Instrument |
|--------|--------|------------|
| SOS persist+ack latency (end-to-end) | **strictly < 5 s**, p95 | `X-Process-Time-Ms` header + server log; CI test `test_sos_ack_under_budget`; prod histogram alert at p95 > 4 s |
| WS delivery success to connected clients | ≥ 99% | gateway ack counters; client REST re-sync covers the remainder |
| IndoBERT accuracy / macro-F1 per class | tracked per release, no silent regression | held-out Indonesian test set (informal/slang/campus terms); CI gate on F1 delta |
| **False-negative rate on P1/P2** | **minimised first; review every FN** | triage audit: any P1/P2 predicted ≤ P3 is an incident-review item (spec: high-risk never missed/downgraded) |
| DBSCAN false-merge ratio | tracked; 100% of merges reversible | coordinator split-rate; sampled geo-review |
| OSRM ETA calibration | tracked vs actual travel time | `|eta − actual| / actual` distribution per area; recalibrate speed profiles quarterly |

## Operating rules

1. **Fail-safe defaults:** SOS enters as P1 (`sos_default_pending_triage`);
   low-confidence AI output (`< 0.65`) routes to human review, never
   auto-downgrades urgency.
2. **AI is advisory on the hot path:** classify/cluster run as background
   tasks; their outage pages the AI owner, not the SOS path (criterion 4).
3. **FN review cadence:** weekly triage of all P1/P2 FNs + a sample of
   `needs_review` tickets; findings feed annotation + retraining.
4. **Dashboards:** latency histogram, WS delivery, F1-per-class, FN list,
   false-merge rate, ETA error — one page per metric group, owner assigned
   (see `06-maintenance.md` SOPs).
