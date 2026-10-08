---
layout: default
title: COMMENCYS PROJECT DOCUMENTATION
permalink: /
nav_order: 1
---

# COMMENCYS PROJECT DOCUMENTATION

The repository is currently a phase-one scaffold. It preserves the component and data boundaries needed for the project, while operational behavior is intentionally absent. The project chapters describe the intended system and must not be read as evidence that the code already provides it.

Commencys is an academic community reporting concept, not an emergency service and not a replacement for official emergency channels.

| Area | Current repository state |
|---|---|
| Reporter surface | Compact Android report/SOS widget with a Flutter report-flow shell; action, submission, and location access are disabled |
| Volunteer surface | Separate compact widget for task offers and accept/reject actions; feed and actions are disabled |
| Admin dashboard | Separate static review layout; data, network, and mutation actions are inactive |
| Backend | FastAPI health route and API route declarations; operational routes return HTTP 501 |
| Data | Plain JSON dictionaries; no application data-model classes or persistent repository |
| AI and related reports | Laya and scikit-learn dependencies with import seams; no checkpoint, inference, or clustering execution |
| Verification | Existing behavioral checks are deferred; compilation and static analysis are the current checks |

## PROJECT REFERENCES

| Topic | Document |
|---|---|
| Scope, risks, and priorities | [Planning](00-PLANNING.md) |
| User goals and acceptance needs | [Requirements analysis](01-ANALYSIS.md) |
| Scaffold and target architecture | [Design](02-DESIGN.md) |
| Implemented source boundaries | [Implementation status](03-IMPLEMENTATION.md) |
| Build and deferred test status | [Verification](04-TESTING.md) |
| Local startup limits | [Deployment](05-DEPLOYMENT.md) |
| Future operational duties | [Maintenance](06-MAINTENANCE.md) |

## TECHNICAL REFERENCES

- [API route and payload surface](API-CONTRACT.md)
- [Persistence target](DB-SCHEMA.md)
- [AI and matching seams](AI-STATIONS.md)
- [Open technical decisions](DECISIONS.md)
- [Evaluation requirements](EVALUATION-MONITORING.md)
- [Safety and privacy constraints](GUARDRAILS.md)

See [architecture.mmd](architecture.mmd) for the current scaffold boundary. The target component diagram in the chapter documents remains a separate proposal.
