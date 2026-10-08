---
layout: default
title: GUARDRAILS AND RESPONSIBLE USE
nav_order: 2
parent: Quality & Governance
---

# GUARDRAILS AND RESPONSIBLE USE

Commencys is a project scaffold for a community reporting concept. It is not an emergency service and must not be used to coordinate live incidents. The source cannot submit a report or send SOS.

## CURRENT SAFEGUARDS AND LIMITS

- Report and SOS routes return HTTP 501.
- The reporter widget action, volunteer task feed, and volunteer accept/reject actions are disabled.
- The browser dashboard does not load or change reports.
- Route payloads are unvalidated JSON dictionaries; no identity, authorization, or privacy protection is active.
- No report data is stored, no notification is delivered, and no classifier or matcher runs.

## REQUIREMENTS BEFORE OPERATIONAL USE

1. **Identity and access:** define reporter, volunteer, and admin roles; operator is the admin dashboard function. Restrict exact coordinates to the people who need them.
2. **Persistence and recovery:** implement durable storage, tested backups, retention, deletion, and service recovery.
3. **Human review:** preserve original reports and require a human decision for uncertain triage or report links.
4. **Truthful status:** distinguish stored receipt, notification delivery, explicit volunteer acceptance or rejection from the widget, and completed handling.
5. **Model controls:** keep candidate Laya output advisory; evaluate Indonesian data, calibration, and critical false negatives.
6. **Notification scope:** select recipients and define delivery evidence before calling an alert delivered.
7. **Emergency boundary:** tell users to contact official emergency services when immediate assistance is needed.

## DATA HANDLING

Define purpose, minimum collection, coordinate access, retention, deletion, and audit ownership before connecting real user reports. The documented target fields include personal and location information; no runtime schema or policy enforcement is active.
