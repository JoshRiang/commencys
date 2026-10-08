---
layout: default
title: AI AND RELATED-REPORT INTERFACES
nav_order: 3
parent: Reference
---

# AI AND RELATED-REPORT INTERFACES

The repository currently contains no executable classifier, matcher, embedding store, language model call, or autonomous action. The Python functions in ai_pipeline.py are documented placeholders.

The project documents identify Laya Multilingual as the team's candidate for Indonesian text triage. This proposal replaced the earlier IndoBERT direction in the chapter narrative. The `laya` package is declared in `backend/requirements.txt` and imported when `ai_pipeline.py` is loaded. The scaffold does not instantiate a router, download a checkpoint, or run inference.

## DATA AND EVALUATION PREREQUISITES

Before selecting a model, the team needs reviewed Indonesian reports, an agreed category and urgency scheme, versioned training and held-out splits, per-class precision and recall, macro F1, P1/P2 false-negative review, output calibration, and a rollback plan. Reports from the same event should not be split across train and test sets.

Model output must remain advisory and outside the SOS receipt path. An admin using the operator dashboard should be able to review a suggestion while preserving the original report. The evaluation module is a hollow seam and does not load a dataset or checkpoint.

## RELATED-REPORT ANALYSIS

DBSCAN is a target proposal for finding possible relationships from spatial and temporal data. `scikit-learn` is declared and its `DBSCAN` class is imported when `ai_pipeline.py` is loaded. The scaffold performs no distance calculation, query, clustering, or link operation. A later implementation must preserve source reports and make mistaken relationships reversible.

## OPERATIONS AND SAFETY

The project has no production model metric, delivery metric, trained artifact, model registry, or monitoring dashboard. A compile or passing schema check does not establish classifier quality or operational safety.

See [evaluation requirements](EVALUATION-MONITORING.md), [guardrails](GUARDRAILS.md), and [API surface](API-CONTRACT.md).
