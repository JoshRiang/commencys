---
layout: default
title: CODE MAP B - CLIENT SURFACES
nav_order: 21
parent: Reference
---

# CODE MAP B: CLIENT SURFACES

Commencys has three role-specific surfaces: the reporter flow and widget, the volunteer task widget, and the admin review dashboard. They are separate client responsibilities. Their visible layout or declared service method does not show that a workflow is connected.

## Reporter: Flutter shell and Android widget

| Path | Responsibility | Current state |
|---|---|---|
| `lib/main.dart`, `lib/app_shell.dart` | App startup and compact screen shell | Navigation and screen structure only. |
| `lib/screens/report_screen.dart`, `sos_screen.dart`, `map_screen.dart`, `alerts_screen.dart` | Report, SOS, location/map, and alert screens | UI scaffold; report, location, and alert flows are not operational. |
| `lib/services/api_client.dart` | HTTP boundary for report listing, report details, report/SOS submission, and ETA | Methods declare payload intent and throw `UnimplementedError`; no request is sent. |
| `lib/services/location_service.dart` | Device location and permission boundary | Service seam only; location behavior is not connected to a report submission. |
| `lib/services/websocket_service.dart` | Live update boundary | No active subscription or recovery flow. |
| `lib/services/app_config.dart` | API base URL and WebSocket URL construction boundary | Configuration seam; no persisted or validated service connection. |
| `android/app/src/main/kotlin/com/commencys/app/CommencysWidgetProvider.kt` and `android/app/src/main/res/layout/commencys_home_widget.xml` | Native reporter home-screen widget | Static widget structure; it does not submit a report or SOS. |

The Flutter shell supports the reporter's report flow. It is not a second admin dashboard. Keep manual location choice distinct from GPS-derived location and keep the report text as the reporter provided it.

## Volunteer: separate native task widget

| Path | Responsibility | Current state |
|---|---|---|
| `CommencysVolunteerWidgetProvider.kt` and `commencys_volunteer_widget.xml` | Render task offer information and accept/reject controls | Static shell; no task feed is loaded. |
| `CommencysVolunteerWidgetActionReceiver.kt` | Receive explicit widget button actions | Comments reserve the flow; the receiver performs no network call or state change. |
| `VolunteerTaskGateway.kt` | Fetch tasks and submit accept/reject requests | Interface only; there is no implementation or session provider. |
| `commencys_volunteer_widget_info.xml`, drawable resources, `MainActivity.kt` | Android widget metadata, visuals, and Flutter host | Platform declarations; they do not connect the task widget to the API. |

The volunteer decision must come from the authenticated volunteer targeted by the offer. Do not trust a volunteer name or identity supplied in a widget `Intent`. The server response must confirm a decision before the widget presents success. Those are required implementation behaviors, not active behavior in this scaffold.

## Admin: web dashboard

| Path | Responsibility | Current state |
|---|---|---|
| `web/index.html` | Dashboard structure and controls | Static shell. |
| `web/styles.css` | Compact admin layout and status styles | Presentation only. |
| `web/app.js` | Queue, details, review, correction, offer, audit, and socket interaction boundaries | State starts empty; placeholder functions throw errors. There is no API fetch or mutation. |

`backend/app/main.py` serves this dashboard from the API root. The admin dashboard owns human review and coordination; volunteer accept/reject belongs to the volunteer widget. Keep admin as the account role and “operator” as the dashboard function.

## Client change boundary

For a reporter change, trace `lib/screens/` through `lib/services/api_client.dart` to the matching API route. For a volunteer decision, trace the Android provider, action receiver, gateway, and server accept/reject route; do not route the decision through the admin dashboard. For admin review, trace `web/app.js` to review, offer, correction, split, audit, and resolution routes. The server remains the source of truth for identity, permissions, and status.

Before a client workflow can be called functional, verify the full request and response path, error handling, authentication handoff, disabled/offline states, and device behavior. Existing deferred checks are listed in [04-TESTING.md](04-TESTING.md). The present files are scaffolds; no end-to-end client flow has been established.

## Related reading

- [Current scaffold design](02-DESIGN.md)
- [Implementation status](03-IMPLEMENTATION.md)
- [API route and data surface](API-CONTRACT.md)
- [Responsible use and guardrails](GUARDRAILS.md)
