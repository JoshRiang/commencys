---
layout: default
title: 1. PLANNING (CHARTER)
nav_order: 10
parent: SDLC and Verification Flow
---

# 00 · PLANNING

**Project:** Commencys, community incident reporting and coordination concept
**Repository:** JoshRiang/commencys

| Contributor | Recorded focus |
|---|---|
| Reinathan Ezkhiel Kurniawan | Mobile and SOS flow |
| Alwahib Raffi Raihan | Map and geolocation |
| Joshua Ricardo Riangkamang | Backend client and alerts |

The repository does not record a named owner for the FastAPI service, data operations, security, or model evaluation. The team should assign owners and backups before scheduling those work items.

## PROBLEM AND INTENDED OUTCOME

Commencys is intended to help a community submit a location-aware report and review coordination status. A system receipt, notification, responder acceptance, and completed handling are different outcomes. The project is not an emergency dispatch service and does not replace 112 or SPGDT 119.

## SCOPE BASELINE

The source currently contains structural shells, not an operational prototype.

| Capability | Current scaffold |
|---|---|
| Reporter and volunteer Android widgets | Reporter layout reserves report/SOS handoff; volunteer layout reserves task feed and accept/reject controls. All actions are disabled |
| Admin operator dashboard | Separate static page for human review; network and action controls are disabled |
| FastAPI | Health route plus API declarations; operational routes return HTTP 501 |
| Request and incident data | Raw JSON dictionaries at the API and client boundaries; no application data-model classes or request schemas |
| Triage and related reports | Hollow function signatures; Laya and scikit-learn dependencies are declared but no analysis runs |
| Persistence and audit | Store interface only; no SQLite file or other database is opened |
| PostgreSQL/PostGIS, access control, targeted delivery, OSRM | Target decisions, not current code |

Dates, cost, capacity, velocity, and delivery estimates are not recorded. They must come from team agreement and evidence, not from the repository.

## PROPOSED MILESTONES

1. Confirm scope, the reporter/volunteer/admin role mapping, widget and dashboard boundaries, status meanings, and service seams.
2. Implement and verify located report and SOS intake with truthful receipt behavior.
3. Add storage, audit, access policy, admin review and offer approval, and authenticated volunteer decisions from the task widget.
4. Evaluate advisory triage and related-report analysis on reviewed data.
5. Add notification targeting and route estimates only after ownership and acceptance conditions are defined.
6. Verify device behavior, failure handling, privacy controls, and operational readiness.

The order is a dependency proposal; it is not a dated schedule or an approved commitment.

## MAIN RISKS

| Risk | Priority | Planning response |
|---|---|---|
| SOS is mistaken for a working emergency channel | High | Keep actions disabled and label scaffold status until intake and receipt are verified |
| Exact coordinates become visible without access policy | High | Decide roles, coordinate scope, retention, and deletion before connecting real data |
| Laya misclassifies informal Indonesian reports | High | Review an appropriate dataset, evaluate critical false negatives, and keep output advisory |
| A related-report link is incorrect | Medium to high | Define evidence, preserve source reports, and provide a reversible review action |
| Team work depends on unassigned service owners | High | Name an owner and backup before estimates or dates are approved |
| A component target is mistaken for an active dependency | Medium | Mark proposals separately from runtime packages and implementation evidence |

Risk scores and calendar dates require team estimates and project context.
