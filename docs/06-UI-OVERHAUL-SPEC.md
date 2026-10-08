---
layout: default
title: FRONTEND SURFACE CONTRACT
nav_order: 17
parent: SDLC and Verification Flow
---

# FRONTEND SURFACE CONTRACT

**Reviewed:** 8 October 2026. This page describes the intended reporter and volunteer widgets and the separate admin dashboard, then records the current scaffold state.

## ROLE-SPECIFIC SURFACES

| Surface | User and purpose | Current scaffold |
|---|---|---|
| Reporter Android widget | Compact entry into an urgent report flow | Static layout and provider declaration; the action is disabled |
| Volunteer Android widget | Review a task offer and explicitly accept or reject it | Static layout and provider declaration; the task feed and both actions are disabled |
| Admin operator dashboard | Human review of reports and coordination state | Static queue and detail layout; data and action controls are inactive |
| Flutter application | Consumer map, ordinary report, and SOS outlines | Navigation and disabled screen shells; no location or API workflow |

The widgets are not websites or miniature dashboards. The reporter widget opens the report flow; the volunteer widget is limited to assigned task actions. The admin operates the separate dashboard. “Operator” describes that dashboard function, not a separate product role. The current source preserves these boundaries without providing operational behavior.

## WIDGET DESIGN REQUIREMENTS

Keep each widget compact. The reporter widget should provide a clear report/SOS entry; the volunteer widget should show only an eligible task summary and explicit accept/reject controls. Do not show a global incident count or claim that help is coming. The volunteer task-feed and authenticated decision routes are declared but return HTTP 501; no recipient filter is active.

The visual direction follows the [Apple Widgets UI Kit reference](https://www.uistore.design/items/apple-widgets-ui-kit-for-figma/) and Apple's [widget design guidance](https://developer.apple.com/design/human-interface-guidelines/widgets). Android uses its native AppWidgetProvider and RemoteViews entry points; the current callback is a scaffold.

## ADMIN DASHBOARD DESIGN REQUIREMENTS

Use a task-focused queue and detail layout that can adapt to narrow screens. The future dashboard is intended to support:

- loading and refreshing reports, with live updates after delivery rules exist
- searching and filtering the review queue
- inspecting report text, status, urgency, location source, accuracy, and coordinates
- reviewing triage suggestions and audit history
- correcting metadata while preserving the original report
- separating a mistaken related-report link
- preparing and monitoring assignment offers without impersonating the volunteer's decision
- reviewing whether an offer was accepted, rejected, or remains unanswered
- recording triage corrections and audit context

The [Figma dashboard collection](https://www.figma.com/community/ui-kits/dashboards?resource_type=files&editor_type=figma) is a broad reference set, not a single design specification. Keep the layout limited to actions with approved service contracts. The current page does not perform these actions.

## OPERATIONAL BOUNDARY

The dashboard is served as static content by FastAPI. Its JavaScript functions are placeholders, and API routes return HTTP 501. The reporter and volunteer widget actions are disabled. No login, permission check, role enforcement, recipient targeting, location access, report persistence, or volunteer identity is active.

## VERIFICATION BOUNDARY

Static source checks can confirm the dashboard script parses. They do not verify visual behavior or user workflows. Browser interaction, device behavior, and Android widget execution remain deferred until implementation resumes.
