---
layout: default
title: Reference
nav_order: 30
has_children: true
---

# Reference

Stable technical references that support the Waterfall phases but change
only through the change-control process
([SDLC](sdlc-waterfall.md#change-control)).

| Doc | What it is | Used by phase |
|-----|------------|---------------|
| [API contract](api-contract.md) | REST + WebSocket reference, frozen | Design → Implementation → Verification |
| [DB schema](db-schema.md) | PostgreSQL/PostGIS DDL, production target | Design → Deployment |
| [AI stations](ai-stations.md) | 9-station AI architecture mapping | Design → Maintenance |
| [Decisions](decisions.md) | Key technical decisions + trade-offs | Design |
