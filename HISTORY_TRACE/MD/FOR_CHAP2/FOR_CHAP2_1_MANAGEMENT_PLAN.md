# FOR_CHAP2_1 — Commencys Project Management Plan Analysis

**Course:** ForChapter2 slides 2–4, 6–22, 34–37.  
**Book:** Braude Chapters 7–9, printed pp. 140–229; [BOOK_1](../BOOK/BOOK_1_PROJECT_MANAGEMENT.md).  
**Purpose:** project-specific management plan structure, not an approved schedule.

## 1. Plan basis

The target role mapping is a reporter widget for reports/SOS, a volunteer widget for task offers and accept/reject actions, and an admin dashboard for human review. “Operator” names the admin's dashboard function. Chapter 1 names lightweight Scrum as the intended approach, and /docs describes the same iterative process. Repository files do not establish that ceremonies occurred. Chapter 2 should distinguish the proposed method from documented team practice.

No approved date, budget, effort, capacity, velocity, or named backend/data owner was found. This plan uses work packages/dependencies, not invented people or durations.

## 2. Scope baseline

### Current scaffold

- Android widget layout and Flutter report-flow shell; the widget action, location access, and submission are disabled.
- Separate static admin/operator dashboard; data loading and review actions are disabled.
- Separate static volunteer widget; task feed and accept/reject actions are disabled.
- FastAPI health and route boundaries; operational routes return HTTP 501.
- Raw JSON dictionaries without application data-model classes or request schemas.
- Laya and DBSCAN imports only; no checkpoint, inference, clustering, database, WebSocket delivery, or routing behavior.

### Target decisions/work

Preserve the widget/dashboard separation; define PostgreSQL/PostGIS and durable audit; approve identity, role, and coordinate policy; define targeted delivery and verified acceptance; evaluate Laya Multilingual and DBSCAN; decide OSRM and deployment/operations; prepare reviewed data, retention, support, and legal review.

Target items must be accepted and decomposed before estimate. They can remain future work for a narrower assignment.

## 3. Work breakdown structure

| WBS | Package | Exit evidence |
|---|---|---|
| 1.0 | Baseline/scope | Current scaffold/target inventory, widget and dashboard responsibilities, glossary, accepted requirements. |
| 1.1 | Requirements | IDs traced to actor goal, source, implementation and verification. |
| 1.2 | UML/architecture | Separate as-is/target components, use cases, IOD branches and scenarios. |
| 2.0 | Intake validation | GPS/manual selection, request/receipt/error/status checked in agreed environment. |
| 2.1 | Access/data decision | Role matrix, lifecycle, storage, backup/recovery and audit requirements accepted. |
| 2.2 | Response workflow | Recipient scope, delivery evidence, identity and acceptance transition defined. |
| 2.3 | Triage/matcher evaluation | Reviewed data, metrics, thresholds, fallback/rollback agreed. |
| 2.4 | ETA/operations | Route source/freshness, security/load/recovery evidence. |
| 3.0 | Readiness review | Go/no-go against approved scope; residual risks recorded. |

For coursework limited to management/UML, WBS 2.x remains future, not a commitment.

## 4. Responsibility template

Roles must be assigned by the team. This does not imply named ownership.

| Deliverable | Accountable role | Responsible role | Consulted | Backup |
|---|---|---|---|---|
| Scope/priority/process | Project coordinator | Requirements owner | Team/instructor | To assign |
| Client/device checks | Client owner | Mobile implementer | Requirements/test | To assign |
| API/data/access | Backend/data owner | Backend implementer | Security/product | To assign |
| Triage/matcher evaluation | Triage/data owner | Evaluator | Coordinator/backend | To assign |
| UML/architecture consistency | Architecture/docs owner | Model author | Client/backend | To assign |
| Quality/release evidence | Verification/release owner | Test/release executor | All owners | To assign |

## 5. Coordination/change control

For an iterative method, choose a small backlog slice with acceptance criteria, implement, inspect evidence, and reprioritize. Review records decisions, defects, risk changes, scope and next owners. Retrospective improvement becomes an action; a method label alone is not proof.

Changes to requirement/UML/API/architecture record change ID, reason/source, affected components, status/test impact, decision owner and date. Update baseline after review to reduce drift.

## 6. Chapter 2 controls mapped to project

| Topic | Commencys use | Evidence |
|---|---|---|
| Cost/scope/quality/date, slides 6–9 | Preserve truth/safety conditions before optional target work. | Approved priorities and estimate assumptions. |
| Roadmap, slides 10–11 | Baseline problem/target, risk, roles, schedule/review. | Versioned scope and decision log. |
| Meeting design, slides 13–14 | Agenda, owner, actions, blockers and evidence. | Meeting/action records. |
| Team structure, slides 16–22 | Assign roles/backups, not code areas only. | Named RACI after confirmation. |
| Risk, slides 24–29 | Revisit triggers, response, retirement evidence. | Dated risk register. |
| Schedule, slides 35–37 | Sequence dependencies, date after capacity. | Schedule and variance log. |
| Quality, book Ch. 9 | Distinguish test definition, execution and field measure. | Test reports and metric definition. |

## 7. Process basis and evidence

Chapter 1 states lightweight Scrum as the intended approach. The documentation now follows an iterative structure, but the repository does not prove that planning, review, or retrospective sessions occurred. Chapter 2 should describe the intended process and report completed activities only when records support them.

## 8. Inputs needed before dates/budget

Deadline/deliverables; team availability and roles; confirmed scope and interface split; acceptance/deployment environment; estimate unit/history; risk scales; external service/data ownership.

## 9. Sources

ForChapter2 slides 2–4, 6–22, 34–37; Braude Ch. 7–9; [planning](../../../docs/00-PLANNING.md), [quality metrics](../../../docs/EVALUATION-MONITORING.md), [ABOUT_1](../ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md).
