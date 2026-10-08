---
layout: default
title: 7. MAINTENANCE AND OPERATIONS PLAN
nav_order: 16
parent: SDLC and Verification Flow
---

# 06 · MAINTENANCE AND OPERATIONS PLAN

There is no active operational service in this repository. The steps below describe requirements for a later implementation and pilot.

## REVIEW AND TRIAGE

1. Show the original report beside any model suggestion.
2. Keep model output advisory until it has been evaluated on reviewed Indonesian data.
3. Preserve SOS priority unless an authorized human changes it under an agreed policy.
4. Keep source reports independent when possible duplicates are linked.
5. Record reviewer identity, reason, before-and-after metadata, and model version.

## MODEL LIFECYCLE

1. Version reviewed data and model artifacts.
2. Measure per-class precision and recall, macro F1, and P1/P2 false negatives on held-out data.
3. Review critical misses before release and define a rollback condition.
4. Keep inference outside the SOS receipt path.
5. Do not use admin corrections as training labels until they pass data review.

Laya Multilingual is a candidate proposed by the team. The repository has no model artifact or evaluation result.

## SERVICE OPERATIONS REQUIRED BEFORE A PILOT

- assign an API and data owner with backup
- define identity, access, retention, and deletion rules
- provide durable storage, tested backup, and recovery
- define delivery recipients, volunteer widget refresh, and reconnect resynchronization
- track service and model measures with a named owner
- record an operational timeline and affected reports during incidents

## MAINTENANCE ORDER

Build the report and receipt path first, then review and audit, then triage and related-report analysis, then targeted delivery and route estimates. Keep each feature disabled until its acceptance conditions and failure behavior are verified.
