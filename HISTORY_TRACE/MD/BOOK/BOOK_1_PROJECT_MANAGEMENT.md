# BOOK_1 — Reference Book and Chapter 2: Project Management Synthesis

**Project application:** Commencys management chapter.  
**Primary source:** PDF/Braude_SoftwareBook(Reference).pdf, Chapters 7–9.  
**Course source:** PDF/ForChapter2.pdf, 39 slides/pages.  
**Pagination:** citations use printed book numbers; scanned PDF physical pages are approximately 15 pages later.

## 1. Relevance and limits

The book treats management as software engineering work: organize the team, estimate/plan, manage risks, measure quality. The slides distill project variables, organization, recurring risk work, and dependency scheduling. This applies because Commencys spans client/backend work while Chapter 1 proposes unbuilt services.

The book provides methods, not Commencys facts. It cannot establish staffing, process, budget, or delivery date; those require team records.

## 2. Reference-book sections

| Section | Printed pages | Topic | Project application |
|---|---:|---|---|
| Ch. 7, organization/tools/risk | 140–167 | Team structures, tools, risks, meetings, student teams. | Assign owners; distinguish tools from ownership; manage data/security/delivery risks. |
| Organization | about 140–150 | Match structure to goals and communication needs. | Peer structure may fit small team; actual lead/owners need confirmation. |
| Tools | about 155–157 | Environment/build-buy affect time and cost. | Flutter/Python dependencies are present; the widget action, dashboard calls, map requests, database, model inference, and routing are not active. |
| §7.6 Risk management | about 159–162 | Identify, plan retirement, prioritize, revisit. | Track trigger, owner, response, evidence, review date. |
| Student team/meetings | about 163–165 | Role assignment and useful meeting discipline. | Assign artifact owner and backup with team agreement. |
| Ch. 8, estimate/schedule/SPMP | 168–212 | Uncertainty, dependencies, plan structure. | Sequence work then estimate from decomposition/capacity. |
| SPMP/responsibility | about 185–195 | Organization, process, schedule, quality/configuration/support. | Connect scope/backlog, UML, risk and quality evidence. |
| Schedule example | about 209–210 | Milestones and dependencies. | Intake/privacy precede pilot readiness; ML/routing depend on data/services. |
| Ch. 9, quality/metrics | 213–229 | Contextual measures and disciplined measurement. | Separate local assertions from deployed latency/delivery/model/usability. |

The PDF is scanned and OCR quality varies. Verify printed folio/subsection before quoting; this note paraphrases.

## 3. Chapter 2 concepts applied

### Variables and trade-offs (slides 6–9)

Slides identify cost, scope/capability, quality and date as connected constraints. Repository contains no approved budget, effort estimate, delivery date, velocity or quality baseline. State unknowns and trade-off policy; do not invent dates.

Retain safety/truthfulness conditions (status semantics, coordinate access, recoverability) as acceptance constraints; prioritize optional scope; estimate after ownership, dependencies, acceptance evidence and capacity are known.

### Planning and meetings (slides 10–14)

Agree on as-is/target baseline before estimating. PostGIS implies model, migration, backup, tests, deployment and operations, not a small isolated coding item. Proposed review agenda: evidence since last review; blockers/decisions; risk changes; next slice/owner/acceptance; action log with team-agreed due points. This proposal does not claim meetings already happen.

### Organization (slides 16–22)

Planning lists contributor focus but leaves backend/data ownership open ([planning](../../../docs/00-PLANNING.md#L13)). Do not infer ownership from authorship. Define roles then assign people/backups: project coordinator, requirements/docs, client, backend/data/security, verification/release. One person may hold multiple roles; decision rights and backup should remain explicit.

### Risk retirement (slides 24–29; book §7.6)

Loop: identify event/consequence; define retirement evidence; use consistent scale; assign owner/review; mitigate or gather evidence; close only when evidence is recorded.

Slide 27 gives priority = (11 − Likelihood) × (11 − Impact) × RetirementCost on 1–10 scales and says lowest first. The direction may be counterintuitive; preserve source convention, define scales/rationale, verify ordering intent. No scores are assigned here.

### Schedule (slides 35–37)

Use milestone/dependency planning, a requirements baseline, iteration, risk work from project start, and buffer/unallocated time. Commencys order without dates: confirm scope/process and the widget/dashboard split → validate intake/location/status → decide access/persistence → design verified response → evaluate triage/matching → verify operations. Dates need deadline and capacity.

## 4. Evidence-to-plan map

| Topic | Evidence | Implication |
|---|---|---|
| Scope | Chapter 1 target exceeds the current commented Flutter/FastAPI scaffold. | Mark target/as-is before estimating; treat the widget and operator dashboard as separate surfaces. |
| Roles | Focus areas listed; backend/data ownership open. | Confirm owner and backup. |
| Tools | Flutter, FastAPI, CI, and Jekyll configuration exist; no live map-tile request or target database/model/routing integration is active. | Separate installed tools from service integrations; confirm external provider assumptions before use. |
| Risk | Qualitative list without scored retirement evidence. | Add trigger, response, owner, review, closure. |
| Estimate | No capacity/history baseline. | Use ranges after decomposition/team input. |
| Schedule | Milestones proposed without dates. | Keep dependency order; date after agreement. |
| Quality | Tests specified, metrics proposed, no production measure. | Report execution separately from target. |
| Process | Chapter 1 names lightweight Scrum; the docs structure now reflects an iterative approach. | Distinguish intended method from ceremonies evidenced by team records. |

## 5. Suggested SPMP chapter outline

Purpose/stakeholders/scope; team and backups; actual process/cadence with evidence; work breakdown/acceptance; estimate assumptions/ranges/confidence/capacity/dates; dependency schedule; risk register; verification/quality; configuration/change control; deployment/support/open decisions.

This is a proposal, not an approved plan.

## 6. Citation map

Book Ch. 7, printed pp. 140–167; Ch. 8, pp. 168–212; Ch. 9, pp. 213–229. ForChapter2 slides 6–11, 13–22, 24–29, 35–37; slides 3–4 for SPMP. Project evidence: [planning](../../../docs/00-PLANNING.md), [metrics](../../../docs/EVALUATION-MONITORING.md), [backend](../../../backend/app/main.py).


## 7. More precise book-to-project extraction

- Ch. 7 begins with project objectives/organization (printed p.140); organization forms and coordination are developed in the following pages. Use this to justify explicit role/backup assignment rather than assigning tasks informally.
- The book discusses team-size/communication overhead (around printed p.145). Commencys should report actual team size and availability from team records; this repository inspection cannot supply them.
- Tool/build-buy discussion (printed pp.155–157) supports documenting active Flutter/Python/CI/map services separately from proposed DB, model and route provider decisions.
- Risk discussion begins around printed p.159; the priority treatment appears around pp.159–160. The lecture's numeric formula is a separate course-slide method and must be cited to slide 27.
- Student-team role guidance appears around printed p.163; meeting guidance around pp.164–165. These support a responsibility/agenda template, not the claim that the team already uses one.
- Chapter 8 plan contents are around printed p.188; responsibility guidance around p.191; schedule example around pp.209–210. Keep these printed book pages distinct from scanned-PDF index.
- Chapter 9, printed pp.213–229, supports measurement discipline. Pair a metric with an operational definition and a collection method; never interpret a configured target as a measured result.

## 8. Application test: does the management plan address actual project risk?

| Book/lecture concern | Concrete Commencys example | Required management output |
|---|---|---|
| Organization | No named backend/data owner in planning Markdown. | Named owner and backup confirmed by team. |
| Tool choice | No map-tile request is active; OSRM remains a target. | Provider assumptions and route decision before enabling either integration. |
| Risk | Location routes and role checks are not operational in the scaffold. | Approve an access policy and collect verification evidence before connecting real data. |
| Estimation | Target spans database, auth, ML, spatial matching, routing, UI. | Dependency decomposition and range estimates. |
| Schedule | CI has backend/mobile builds; there is no evidence of integrated release baseline. | Integration/review milestone and recorded result. |
| Quality | Workflow checks are deferred and no field metrics are measured. | Test report and separately defined field metrics. |
