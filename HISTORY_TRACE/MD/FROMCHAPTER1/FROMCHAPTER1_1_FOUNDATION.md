# FROMCHAPTER1_1 — Chapter 1 Foundation: Close Reading and Interpretation

**Source:** PDF/Chapter1.pdf, 10 pages, Indonesian.  
**Role:** foundational requirements/design source.  
**Status rule:** this note interprets a target; it does not claim every described feature exists.

**Document boundary:** this is a historical analysis of the source PDF and the pre-scaffold code snapshot. The current foundational chapter is [RESULT/CHAPTER_1.md](../../RESULT/CHAPTER_1.md); it records the later role mapping for reporter and volunteer widgets plus the separate admin dashboard. See [ABOUT_1](../ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md) for current code status.

## 1. Central problem model

Chapter 1 presents Commencys as community incident reporting and response coordination. The stated problem is the interval between incident and useful awareness: reports may be delayed or fragmented, locations uncertain, and repeats difficult to coordinate. The product aims to improve information flow while complementing official channels.

A traceable end-to-end model derived from the chapter:

1. Witness submits actionable report with location.
2. Service validates and records it.
3. Relevant parties receive useful information.
4. Coordinator reviews uncertain information.
5. Responder accepts an assignment and progress is reflected.
6. Reports and decisions remain explainable and safely handled.

The repository implements portions, not the whole chain. Stored receipt, WebSocket send, and verified response must remain distinct.

## 2. Page-by-page analysis

| PDF page | Content | Foundation to retain | Precision/ambiguity |
|---:|---|---|---|
| 1 | Project/chapter identity. | Provenance. | No implementation evidence. |
| 2 | Background/problem framing. | Define the social problem before choosing technology. | Incident/delay facts need independent sources. |
| 3 | Objectives/intended outcomes. | Connect goals to measures later. | Does not prove response-time improvement or outcomes. |
| 4 | Scope, limits, method introduction. | State included/excluded scope; official integration not assumed. | Geography may be study context, not server policy. |
| 5 | Lightweight Scrum/iteration framing. | Backlog and incremental work are stated foundation. | The documentation structure is aligned in Checkpoint 1; neither layout nor code proves that the team held ceremonies. |
| 6 | Architecture/hardware/deployment assumptions. | Original PDF diagram shows React 18 PWA/Leaflet, FastAPI, PostgreSQL/PostGIS, IndoBERT, DBSCAN, WebSockets, OSRM, Docker. | Image visually checked. These were source proposals; the current Chapter 1 sets a widget/dashboard split and updates the model proposal. Hardware adequacy remains unverified. |
| 7 | Competitor/context comparison and risks. | Preserve comparison criteria and risks. | Competitor claims need dated external sources. |
| 8 | Privacy/load/model/GPS/scope mitigations; user-story setup. | Risks need owner and evidence. | Proposed mitigation is not implemented control or proof of legal compliance. |
| 9 | Actors/user stories. | Citizen reporter, volunteer, coordinator, administrator; goals inform UML. | Current system has no identity/role enforcement. |
| 10 | References. | Verify sources before thesis use. | Validate publication details and support for each factual claim. |

Page 6 was visually reviewed because it controls target/as-is interpretation; its technologies are not active in current runtime.

## 3. Foundational requirement groups

These normalize Chapter 1; they are not newly approved requirements.

### FND-01 — Safe intake and truthful receipt

Citizen submits actionable report/SOS with description/category/location. Service validates and acknowledges only what it stored. Backend/network failure must not appear successful. Receipt is not broadcast or response.

### FND-02 — Useful location

Use current GPS or intentional selected point. Accuracy/source and stale/default map position must be distinct. If study is geographically limited, specify UI boundary vs server validation vs evaluation context.

### FND-03 — Triage and uncertainty

Category/urgency support prioritization; uncertain or untyped cases go to human review; original report stays distinct from derived/corrected metadata. Chapter 1 names IndoBERT; the group's later proposal is Laya Multilingual. Evaluate the selected model on reviewed local data with held-out measures and error analysis before making performance claims.

### FND-04 — Coordination and response

Relevant responders receive reports; assignment/acceptance/resolution are attributable. Do not claim nearby delivery without targeting and receipt evidence. Official-service integration stays out of scope unless approved.

### FND-05 — Privacy, audit and trust

Precise coordinates/reporter identity need access, retention, deletion and disclosure policy. Trust/audit need actor provenance, durability, write controls and recovery. Legal compliance needs review and implemented controls.

### FND-06 — Delivery and quality evidence

Latency, delivery, classifier, matcher and usability claims need denominator, environment and method. Load claims need concurrency/duration/failure definitions. Hardware claims need bill of materials and measured resource profile.

## 4. Foundation-to-current-scaffold comparison

| Chapter 1 element | Current repository relationship |
|---|---|
| Report/SOS | API route declarations remain, but intake returns HTTP 501; no report is accepted or stored. |
| Map/location | Flutter screens and location-picker shell remain; device location and submission are inactive. |
| AI category/urgency | Laya package is imported as a service seam; no checkpoint is loaded and no inference runs. |
| Related reports | DBSCAN is imported; no features are prepared and no clustering or report link is produced. |
| Realtime delivery | WebSocket endpoint closes with an unimplemented response; no alert is delivered. |
| Assignment | Accept, reject, and resolution route declarations return HTTP 501. |
| Data/audit | StateStore protocol and inactive SQLite placeholder remain; no connection, report, or durable audit is created. |
| Client surfaces | Android widget, Flutter consumer shell, and separate static operator dashboard are present; actions do not submit or load incident data. |
| OSRM | No routing client or ETA calculation is active. |
| Administrator/access | No account, role authorization, settings management, or coordinate policy is active. |

## 5. Questions the PDF leaves open

1. How should the widget hand off to the Flutter report flow, and which dashboard implementation details fit the operator tasks?
2. Operational response: stored receipt, event send, explicit acceptance or rejection, and resolution are separate stages; which roles should authorize each action?
3. Is Depok enforced or only research context?
4. Which roles can see precise location/reporter identity; what retention/deletion?
5. Which triage thresholds and review rules apply when confidence is low or the model is unavailable?
6. What defines a duplicate and who can undo a link?
7. What data support classification, ETA, latency or improvement claims?
8. What process was actually followed and what records prove it?

Chapter 1 gives direction but not all acceptance conditions. Later prose should state decisions or mark open items, not invent certainty.

## 6. Evidence notes

PDF has 10 pages; page references above are PDF pages. The page 6 architecture image was visually checked. Competitor claims, legal interpretation, hardware and emergency outcomes were not independently verified. See [ABOUT_1](../ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md) and [FROMCHAPTER1_2](FROMCHAPTER1_2_TRACEABILITY.md).

**Time boundary:** the foundation-to-current-scaffold table describes the local source reviewed on 8 October 2026. The page-by-page reading above remains an analysis of the original PDF proposal; current implementation facts are summarized in [ABOUT_1](../ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md).
