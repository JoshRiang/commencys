# FOR_CHAP2_2 — Risk Register, Estimation Method, and Dependency Schedule

**Course:** ForChapter2 slides 24–29 and 34–37.  
**Book:** Braude Ch. 7 risk, Ch. 8 estimation/scheduling, Ch. 9 quality; printed pp. 140–229.  
**Rule:** no unsupported scores, effort, names, budget, or dates are invented.

## 1. Initial risk register

Owners are roles to assign. Retirement evidence closes a risk; task completion alone does not.

| ID | Risk/trigger | Consequence | Response and retirement evidence | Owner role |
|---|---|---|---|---|
| R1 | Exact coordinates become available without an approved access policy when report routes are enabled. | Disclosure/trust loss. | Approve access matrix; implement authorization/minimization; verify allowed/denied tests before using real reports. | Backend/security |
| R2 | A future persistent store is used without restart, backup, or multi-worker checks. | Tickets/audit may disappear or diverge. | Select a durable store, migrations, backup/restore/restart tests; document topology before pilot. | Backend/data |
| R3 | A future notification send is mistaken for nearby receipt or task acceptance. | False expectation; no accountable response. | Define recipient/ACK; implement delivery evidence; test no-recipient/offline cases. | Product/backend |
| R4 | A supplied responder name is treated as verified identity when assignment actions are implemented. | An unauthenticated person may appear to accept or resolve a task. | Add authentication and role checks; define accept/reject and resolution transitions; verify allowed and denied actions. | Product/identity |
| R5 | GPS denied/unavailable/inaccurate/stale. | Wrong incident point. | Test permissions/services/timeouts/manual point on target devices; show source/accuracy. | Mobile/verification |
| R6 | Rules miss urgent/informal/negated report. | Critical ticket weakly triaged. | Keep review/fail-safe; reviewed data and class/P1-P2 error analysis before model claims. | Triage/quality |
| R7 | Matcher links false pair or misses repeat. | Confusing operations/repeat work. | Label pairs, measure false links/misses, keep reversible links, approve thresholds. | Backend/quality |
| R8 | Straight-line ETA read as route arrival. | Misleading expectation. | Label/hide stub; define route source/freshness, compare observed travel. | Product/backend |
| R9 | Target scope exceeds capacity. | Incomplete integration/quality. | Prioritize, slice criteria, estimate ranges, defer unapproved scope. | Coordinator |
| R10 | Intended Scrum approach may be mistaken for completed ceremonies. | Progress narrative may overstate practice. | Record planning, review, and retrospective evidence; retain the distinction between intended process and completed work. | Project team |
| R11 | A map-tile provider is enabled without terms, rate, or offline-use review. | Map may be unavailable or used outside provider conditions. | Confirm terms/usage; test failure; define fallback/provider owner before enabling map requests. | Client/operations |
| R12 | CI/test files assumed passed. | Defects or false readiness. | Run checks; record command, tree identity, logs/result. | Verification/release |

Current evidence boundary: these are risks to retire before the related workflows are enabled, not claims that the scaffold currently exposes coordinates, stores tickets, sends WebSocket events, or calculates ETA. See [current codebase state](../ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md) and [safety guardrails](../../../docs/GUARDRAILS.md).

## 2. Lecture prioritization formula

Slide 27 gives:

**Priority = (11 − Likelihood) × (11 − Impact) × RetirementCost**

Scales 1–10; lower result first per slide. Define scales, preserve rationale, and check that ranking reflects intent. Probability and team retirement effort cannot be derived from source, so no score is assigned here.

## 3. Estimation method

1. Decompose into vertical slice with observable exit criteria.
2. List provider/data/policy/review/deployment unknowns.
3. Estimate range/confidence; record estimator/date.
4. Independently cross-check large/high-uncertainty work.
5. Record actual effort/blocked time after work.
6. Re-estimate remaining scope; preserve original baseline/variance.
7. Do not use commit/file/line counts as labor estimates.

| Estimate field | Required entry |
|---|---|
| Work item/acceptance ID | Traceable identifier |
| Included/excluded scope | Boundaries |
| Range | Team-agreed unit and low/likely/high |
| Confidence | Defined scale/rationale |
| Dependencies | Data/provider/policy/other work |
| Owner/backup | Team-confirmed |
| Estimate date/baseline | Versioned |
| Actual/variance | Filled after work |

No numerical estimate can be responsibly filled from source inspection.

## 4. Dependency schedule without dates

| Order | Milestone | Exit evidence | Dependency |
|---:|---|---|---|
| M0 | Product/process baseline | Platform, target/as-is, scope, actors and method recorded. | Team/instructor. |
| M1 | Intake/status proof | GPS/manual, receipt, error and status checked in agreed environment. | Prototype/devices. |
| M2 | Access/data design | Role matrix, coordinate policy, persistence, audit, backup/recovery accepted. | Security/product. |
| M3 | Verified response | Recipient criteria, delivery ACK, authenticated accept/reject specified. | Identity/delivery design. |
| M4 | Triage/matcher evaluation | Reviewed data, metrics, threshold, fallback/rollback decision. | Dataset/evaluator. |
| M5 | Routing/operations | Route limits, security/load/recovery evidence. | Provider, durable store, ops owner. |
| M6 | Readiness decision | Go/no-go against scope; residual risks recorded. | Selected milestone evidence. |

For a coursework scope limited to management/UML, M2–M6 may be future work, not commitments. Dates require deadline/capacity.

## 5. Schedule and quality controls

- Begin risk work immediately; do not defer privacy/data/security.
- Schedule integration, review, device and failure-path work, not only coding.
- Separate planned, implemented, tested, deployed.
- Define metric numerator/denominator, environment, sample, method, time window, owner.
- Unit test, suite pass, device observation, load test and production measure are separate evidence.
- Five-second budget is not an SLA without deployment/measurement definitions.

## 6. Sources

ForChapter2 slides 24–29, 34–37; Braude Ch. 7–9; [planning](../../../docs/00-PLANNING.md), [evaluation](../../../docs/EVALUATION-MONITORING.md), [backend](../../../backend/app/main.py).
