---
layout: default
title: TECHNICAL DECISION REGISTER
nav_order: 4
parent: Reference
---

# TECHNICAL DECISION REGISTER

This scaffold records the interface decision and the technical choices that still need evidence or team approval.

## CLIENT SURFACES

The agreed role mapping is a reporter widget for reports/SOS, a volunteer widget for viewing and accepting or rejecting offers, and a separate operator dashboard for the admin. “Operator” is the dashboard function used by the admin, not an additional role. The Flutter shell hosts the reporter's report flow; it is not a second dashboard. The widgets and dashboard remain static scaffolds with disabled actions.

## ADVISORY TRIAGE

The group proposes evaluating Laya Multilingual instead of the earlier IndoBERT proposal. The Laya package is declared and imported when `ai_pipeline.py` loads, but no checkpoint is loaded and no dataset, inference call, or model evaluation is present. Select a model only after reviewing representative data, critical false negatives, calibration, latency, and rollback conditions.

## RELATED REPORTS

DBSCAN is a proposed analysis approach; its scikit-learn dependency and class import are present in `ai_pipeline.py`. No distance function, clustering call, or matcher is active. Define what counts as a related report and how an incorrect link is reviewed and reversed before implementation.

## PERSISTENCE AND ACCESS

No storage backend, authentication, role check, coordinate policy, or audit persistence is active. A commented SQL migration outline and a hollow PostgreSQL adapter now reserve the target seam; neither can create schema or connect to a database. Psycopg 3 is declared for the future adapter but is not imported at runtime. PostgreSQL/PostGIS remains the target described by the project materials. Decide service ownership, backup, recovery, retention, and access before adding real report data.

## NOTIFICATIONS AND ROUTING

The source keeps REST and WebSocket boundaries, including a volunteer task-feed route. No alert is delivered, and no recipient scope is implemented. OSRM is a proposal and is not called. Define receipt, send, read, volunteer acceptance/rejection, and completion separately before presenting route estimates.
