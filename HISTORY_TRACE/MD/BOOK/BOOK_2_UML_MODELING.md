# BOOK_2 — Reference Book and Chapter 3: UML Modeling Synthesis

**Project use:** Commencys use case, Interaction Overview, and component diagrams.  
**Reference:** PDF/Braude_SoftwareBook(Reference).pdf, Chapters 11, 15, 16, 18.  
**Course source:** PDF/Chapter3.pdf, 12 pages.

## 1. Fit between source book and assignment

Use Case asks who has a goal and what falls inside the system boundary. Interaction Overview Diagram (IOD) explains how interactions and decisions compose a scenario. Component diagram shows software parts and dependencies.

The book supports these views through requirements/use cases (Ch. 11), model integration (Ch. 15), UML interaction/activity concepts (Ch. 16), and architecture boundaries (Ch. 18). Chapter 3 gives direct definitions of Component and IOD. Do not attribute a complete IOD recipe to book Chapter 16 unless the scanned text supports it.

Citations below use printed folio; scanned PDF physical page offset is about 15 pages. Verify before verbatim citation.

## 2. Reference-book sections

| Book section | Printed pages | Relevance |
|---|---:|---|
| Ch. 11, high-level requirements | 245–277 | Actor goals, identifying use cases, scope/requirements communication. |
| Ch. 15, software design, §15.2 | 350–360 | Keep use case, class, data-flow and state models coherent. |
| Ch. 16, UML | 361–382 | Complementary views; sequence/activity/state concepts for interaction detail. |
| Ch. 18, software architecture | 438–475 | Decomposition, component boundaries/dependencies, alternatives. |

## 3. Chapter 3 points applied

| PDF page | Course idea | Commencys modeling consequence |
|---:|---|---|
| 3 | UML models include static and dynamic views. | Cross-check views; none is a complete spec. |
| 4 | Component diagrams decompose software and show dependencies. | Show active boundaries; label target replacement separately. |
| 8 | Use case diagrams show actors, goals, relationships. | Draw human goals, not buttons or endpoints. |
| 9 | Interaction diagrams show participants exchanging messages. | Sequence detail may supplement IOD. |
| 10 | IOD uses activity-like control flow and interaction nodes. | Show decisions and marked interaction-use nodes. |
| 11 | Sequence/timing diagrams refine order/time. | IOD is overview; sequence view can detail message contract. |

## 4. Project modeling rules

1. Keep as-is and target separate.
2. Use actor goals: “submit SOS” is a use case; tapping is UI detail; POST /api/sos is interface detail.
3. Keep target lifecycle terms distinct: receipt, notification delivery, explicit task acceptance, and completion are separate states. They are requirements, not current runtime transitions.
4. Show actual scaffold boundaries separately: Android widget resources, Flutter shell, static operator dashboard, and FastAPI declarations are present; no report workflow, model execution, or persistence is active.
5. Do not place auth, DB, routing, broker or verified responders in as-is component view.
6. Each IOD node needs referenced scenario, precondition, outcome and alternate.
7. Diagram does not prove scale, security, availability or quality.
8. Distinguish category, reporter severity, AI category, urgency, status, actor role.

## 5. Traceability

| Need | Book support | Chapter 3 | Project evidence |
|---|---|---|---|
| Actors/goals | Ch. 11 §11.5/11.9; Ch. 15 §15.2.1 | Use Case p.8 | Chapter 1 roles; no current role enforcement. |
| Composed flow | Ch. 16 sequence/activity | Interaction p.9; IOD p.10; sequence/timing p.11 | Target SOS and review paths; the current scaffold does not execute them. |
| Decomposition | Ch. 18; Ch. 15 | Component p.4 | Widget, Flutter report flow, operator dashboard, FastAPI, and proposed service boundaries. |
| Cross-view coherence | Ch. 15 model integration | UML p.3 | Shared lifecycle and data glossary. |
| Target system | Ch. 18 alternatives | Apply component definition | Separate Chapter 1 target view. |

## 6. Limits and source map

These are analysis/design artifacts, not executable behavior or UML certification. Use case is requirements; as-is components are source-oriented; IOD is behavioral; target is proposed.

Sources: book Ch. 11, 15, 16, 18; Chapter3.pdf pp.3–11; Chapter1.pdf pp.3–9; backend/app, lib/, web/.


## 7. More precise source coverage and attribution

- Braude Ch. 11 §11.5 covers main functions/use cases; §11.9 discusses diagrams for high-level requirements. Use for the goal-oriented use-case rationale.
- Ch. 15 §15.2.1 links the use-case model with design models. Use it to justify consistency checks, not as a direct source for current Commencys interfaces.
- Ch. 16 covers UML; its relevant view-specific sections include §16.5 sequence and §16.7 activity, with class/state material nearby. These support interaction detail and complementary views.
- Ch. 18 §18.2 covers architecture and component-oriented decomposition/independent components. Use it as architecture background.
- Chapter3.pdf p.4 is the direct course source for component diagrams; p.8 for use cases; p.10 for Interaction Overview. The assignment handout has the direct definition where the book chapter does not.
- Use page numbers printed in the book. The reference PDF is scanned; its physical page index is about fifteen pages later. Do not cite a physical PDF index as the printed folio.

## 8. Diagram review checklist

Before final submission, verify each diagram against the text:
1. Each actor is a human/system role with a goal; target roles are not presented as current accounts.
2. Use-case links mean participation; include/extend semantics have a real mandatory/optional relationship.
3. IOD branch conditions are testable and match the source behavior.
4. Component dependencies follow runtime data/control direction.
5. Planned components carry a visible target label.
6. Terms for status, severity, urgency and category match request/model definitions.
7. Every diagram is rendered and visually checked in the chosen editor.
