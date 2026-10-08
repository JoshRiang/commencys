# CHECKPOINT_0 — Analysis Baseline Completed

**Catatan status, 8 Oktober 2026:** checkpoint ini adalah rekaman tahap analisis awal pada 7 Oktober. Untuk keadaan dokumen dan kode terbaru, gunakan [CHECKPOINT_5](CHECKPOINT_5.md); isi historis di bawah tidak menyatakan status codebase saat ini.

**Date:** 2026-10-07  
**Stage:** analysis artifacts only  
**Source snapshot:** branch main at 65409f0; working tree is dirty.  
**Boundary:** no /docs sanitation, final Chapter 1/2 thesis, or application-code change was made.

## 1. Artifacts created or replaced

| Folder | Files | Coverage |
|---|---|---|
| MD/ABOUT | ABOUT_1_CODEBASE_CURRENT_STATE.md; ABOUT_2_MARKDOWN_CODE_TRUTH_AUDIT.md | Architecture, progress, dependencies, code/doc truth, defect register. |
| MD/BOOK | BOOK_1_PROJECT_MANAGEMENT.md; BOOK_2_UML_MODELING.md | Relevant reference-book sections tied to course Chapter 2/3 and project. |
| MD/FROMCHAPTER1 | FROMCHAPTER1_1_FOUNDATION.md; FROMCHAPTER1_2_TRACEABILITY.md | Ten-page Chapter 1 close reading and requirement-to-code/docs matrix. |
| MD/FOR_CHAP2 | FOR_CHAP2_1_MANAGEMENT_PLAN.md; FOR_CHAP2_2_RISK_ESTIMATE_SCHEDULE.md | Project plan, WBS/roles, risk register, estimation and dependency schedule. |
| MD/FORUML | FORUML_1_USE_CASES.md; FORUML_2_INTERACTION_OVERVIEW.md; FORUML_3_COMPONENT_DIAGRAMS.md | Target/as-is use cases, two current-flow IODs, as-is/target component diagrams. |
| MD/RESULT | CHECKPOINT_0.md | Inventory, key findings, evidence limits and stage boundary. |

Selected count: 2 ABOUT, 2 BOOK, 2 FROMCHAPTER1, 2 FOR_CHAP2, 3 FORUML. The UML views are separate to preserve goal, behavior and architecture distinctions.

## 2. Principal findings

1. Current code is a Flutter/FastAPI prototype with static browser console, process-local storage/audit/socket state, keyword triage, reversible custom matching and straight-line ETA.
2. Chapter 1 target names React/PWA, PostgreSQL/PostGIS, IndoBERT, DBSCAN, OSRM, role/privacy controls and Docker. These are not active integrations in the reviewed working tree.
3. Manual map selection exists in report and SOS source. docs/00-planning.md and docs/01-analysis.md incorrectly say it is missing; docs/03-implementation.md contradicts itself.
4. acknowledged means stored in this process; broadcast means at least one socket send succeeded; dispatched records an unverified name; resolved has no route.
5. Persistence/audit are in memory. Socket delivery is global within this process, not nearby/role-targeted.
6. Chapter 1 Lightweight Scrum conflicts with Waterfall structure in /docs; actual team method is unverified.
7. CI/test definitions and test sources exist, but tests were not executed and no test pass is claimed.
8. Competitor, response improvement, hardware, legal, deployment, and model-quality claims need separate evidence.

## 3. Source mapping

- Code/dependencies: [ABOUT_1](../MD/ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md)
- Markdown truth defects: [ABOUT_2](../MD/ABOUT/ABOUT_2_MARKDOWN_CODE_TRUTH_AUDIT.md)
- Reference book: [BOOK_1](../MD/BOOK/BOOK_1_PROJECT_MANAGEMENT.md), [BOOK_2](../MD/BOOK/BOOK_2_UML_MODELING.md)
- Chapter 1: [foundation](../MD/FROMCHAPTER1/FROMCHAPTER1_1_FOUNDATION.md), [traceability](../MD/FROMCHAPTER1/FROMCHAPTER1_2_TRACEABILITY.md)
- Project management: [plan](../MD/FOR_CHAP2/FOR_CHAP2_1_MANAGEMENT_PLAN.md), [risk/schedule](../MD/FOR_CHAP2/FOR_CHAP2_2_RISK_ESTIMATE_SCHEDULE.md)
- UML: [use cases](../MD/FORUML/FORUML_1_USE_CASES.md), [IOD](../MD/FORUML/FORUML_2_INTERACTION_OVERVIEW.md), [components](../MD/FORUML/FORUML_3_COMPONENT_DIAGRAMS.md)

Code line citations are relative to the inspected working tree and may move. Book citations use printed page numbers; Chapter PDF citations use PDF page/slide numbers.

## 4. Validation and limitations

- Files are written as UTF-8 without BOM.
- Source analysis includes uncommitted files and changes.
- Tests were not run. PlantUML snippets were not rendered/validated by a diagram engine.
- No external, competitor or legal claims were researched independently.
- No source, PDF, or /docs file was changed by this analysis batch.
- Line citations may move as code changes.

## 5. Handoff

This checkpoint closes the requested analysis stage. Findings identify stale docs and open decisions for a later sanitation/write-up stage. A subsequent stage can use this evidence to align /docs with the chosen baseline, then prepare Indonesian Chapter 1 and Chapter 2. Those later deliverables are not part of Checkpoint 0.
- Static scan confirmed every local relative Markdown link target resolves.
- All 12 analysis/checkpoint files were inspected for expected titles and artifact placement.
