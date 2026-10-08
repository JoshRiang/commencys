---
layout: default
title: 2. REQUIREMENTS ANALYSIS
nav_order: 11
parent: SDLC and Verification Flow
---

# 01 · REQUIREMENTS ANALYSIS

## USER GOAL

A community member should be able to submit a report with a useful location, receive a truthful system receipt, and see separately whether a responder accepts the task. A receipt must never be presented as proof that help is on the way.

The following are project requirements. None of the workflow requirements is active in the current scaffold.

## ACCEPTANCE NEEDS

| Need | Required behavior | Current source status |
|---|---|---|
| Located report and SOS | Accept GPS coordinates or an intentionally selected map point, retaining source and accuracy | Request fields exist; device location and map selection are stubs |
| Truthful receipt | Acknowledge only after the report has been stored | Route declaration exists; request returns HTTP 501 |
| Separate response stages | Distinguish receipt, notification delivery, explicit acceptance, and completion | Vocabulary is design-only; no runtime enum or transition logic exists |
| Advisory triage | Present category and urgency suggestions for human review | Candidate interfaces exist; no model or rules run |
| Reversible related-report review | Link possible duplicates without deleting source reports | Interface only; no matcher or review operation runs |
| Admin review | Read, correct, and audit report metadata from the operator dashboard | Dashboard and routes are shells; no mutations run |
| Volunteer task action | View relevant offers and explicitly accept or reject from the volunteer widget | Widget structure and API boundary are scaffolds; no task feed or action runs |
| Persistent history | Preserve reports and decisions with accountable access | Data contract only; no storage adapter is active |

## FUNCTIONAL REQUIREMENTS

- FR-1: SOS contains coordinates, source, optional accuracy, and a short summary.
- FR-2: A reporter can choose a location manually if a usable GPS point is unavailable.
- FR-3: A standard report contains a description, category, reporter-selected severity, and location.
- FR-4: Consumer screens can show a map and incident list from server data.
- FR-5: Connected clients can receive relevant status updates and resynchronize after reconnect.
- FR-6: An admin using the operator dashboard can review uncertain suggestions and preserve original report text when correcting metadata.
- FR-7: An assigned volunteer can view task offers and explicitly accept or decline from the volunteer widget. A decline leaves the report open for another response.
- FR-8: Authorized people can inspect a durable history of decisions.
- FR-9: Routing information is provided only for an accepted assignment and is labeled as an estimate.

## QUALITY AND SAFETY REQUIREMENTS

Performance targets, delivery reliability, model quality, and matching accuracy require an agreed measurement method. There is no current production data or deployed metric.

Exact location access must be scoped by an approved role policy. Model output must remain advisory until evaluated on reviewed Indonesian data. The SOS response must not depend on model completion. None of these protections is enforced by the current scaffold.

## TECHNICAL BOUNDARY

The current source has Android widget shells for reporter and volunteer tasks, a Flutter report-flow shell, an HTML/CSS admin dashboard, FastAPI routes, and service interfaces. The admin uses the dashboard; the volunteer uses the task widget. API payloads remain plain JSON dictionaries; application request and incident model classes are absent. The widget actions and operational services are not active. Laya Multilingual is the group's candidate for evaluation. The `ai_pipeline` module imports its package, but creates no router, loads no checkpoint, and runs no inference.

See [design](02-DESIGN.md), [API surface](API-CONTRACT.md), and [verification](04-TESTING.md).
