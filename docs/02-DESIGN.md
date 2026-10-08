---
layout: default
title: 3. DESIGN AND ROADMAP
nav_order: 12
parent: SDLC and Verification Flow
---

# CURRENT SCAFFOLD AND TARGET DESIGN

This page distinguishes the source structure from the design described by the project chapters. The current source is a scaffold. It does not operate report workflows.

## CURRENT CODE BOUNDARY

The Android home-screen widgets provide two compact role-specific entry points: a reporter widget for reports/SOS and a volunteer widget for task offers and explicit accept/reject actions. Both are inert scaffolds. A small Flutter report-flow shell remains the reporter widget's intended host. The admin uses the separate operator dashboard, which does not load data. FastAPI declares the route surface and serves the static dashboard. Route bodies use plain JSON dictionaries with no application schema validation; storage, access control, triage, matching, location, notification, and routing services are placeholders.

![Current scaffold component boundary](architecture.png)

See the [Mermaid source](architecture.mmd) for this component map.

## TARGET ARCHITECTURE FROM THE PROJECT DOCUMENTS

Chapter 1 describes location-aware reporting, human review, related-report analysis, notifications, persistence, and route estimates. Chapter 3 models actor goals, composed interactions, and component dependencies. Those diagrams are targets for analysis and design; they are not runtime evidence.

The chapters identify these target concerns:

- consumer report and SOS with GPS or deliberate manual location
- a separate operator dashboard used by the admin for human review and coordination
- a volunteer widget for viewing offers and accepting or rejecting a task
- FastAPI service contracts
- persistent incident and audit data with spatial query support
- advisory text triage, with Laya Multilingual proposed for evaluation
- reversible related-report links, with DBSCAN proposed
- notifications whose delivery and acceptance states are distinct
- OSRM route estimates after assignment acceptance
- access, retention, recovery, and operating responsibilities

The agreed role mapping is reporter to report/SOS widget, volunteer to task widget, and admin to the operator dashboard. “Operator” names the admin's dashboard function, not a fourth account role. Service choices such as persistence, identity, delivery, model evaluation, and routing remain open in the chapter documents. Do not add an unapproved technology to the runtime merely because it appears in a target diagram.

## LIFECYCLE CONTRACT TO PRESERVE

The project documents retain the planned terms acknowledged, broadcast, accepted, and resolved. Their intended meanings are distinct: stored receipt, notification send, explicit responder acceptance, and completed handling. The source contains no runtime data-model class or status enum and performs none of those transitions.

The intended system must keep original reporter text separate from triage metadata. Laya and DBSCAN outputs are suggestions or candidate links, not automatic changes to source reports. Model and route processing should not block an SOS receipt.

## DESIGN DECISIONS STILL NEEDED

The report-widget, volunteer-widget, and admin-dashboard roles are settled at the design level. Agree the widget-to-report handoff, volunteer session handoff and task feedback, dashboard implementation, persistence service, identity and role policy, delivery recipients, data retention, model evaluation, matching definition, route provider, and operating owner before implementation estimates are treated as commitments.
