---
layout: default
title: EVALUATION AND MONITORING REQUIREMENTS
nav_order: 1
parent: Quality & Governance
---

# EVALUATION AND MONITORING REQUIREMENTS

The repository has no deployed service metrics or active report workflow. The values below are questions to resolve during implementation, not measured results.

| Measure | Required definition | Current evidence |
|---|---|---|
| SOS acknowledgement | Start/end points, device/network conditions, percentile, and sample count | Route is a placeholder; no timing measurement |
| Alert delivery | Eligible recipients, successful send, read receipt, and acceptance | No delivery or recipient service |
| Classifier quality | Per-class precision/recall, macro F1, calibration, and P1/P2 false negatives | No model or labeled dataset |
| Related-report quality | False-link rate, review method, and ability to reverse links | No matcher |
| ETA error | Route provider, comparison method, and observed travel time | No routing service |
| Privacy | Access tests for exact coordinates, identity, retention, and deletion | No authorization or policy enforcement |

## MODEL EVALUATION BEFORE SELECTION

1. Prepare and review Indonesian incident data.
2. Keep reports from one event in the same dataset split.
3. Compare Laya Multilingual with any approved baseline.
4. Review critical false negatives and calibrate outputs on held-out data.
5. Keep suggestions advisory and record the model version and review decision.

## OPERATIONS NEEDED BEFORE A PILOT

Implement persistent ticket and audit storage, authentication, coordinate access controls, recipient targeting, reconnect resynchronization, backup and recovery, and a named owner for each measure. Compile success and UI screenshots are not operational evidence.