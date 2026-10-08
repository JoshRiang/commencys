# COMMENCYS AGENT ENTRYPOINT

This is the first document an AI agent should read before changing Commencys. It provides the project boundary, the order for retrieving project context, and links to focused code maps. It is a navigation and handoff document, not evidence that a planned capability is implemented.

- **Repository:** `JoshRiang/commencys`
- **Project name:** Commencys
- **Context snapshot:** 8 October 2026

## Read in this order

1. Read this file and [README.md](README.md) for the product boundary, local setup, dependency groups, and current environment notes.
2. Read [docs/INDEX.md](docs/INDEX.md), then [docs/03-IMPLEMENTATION.md](docs/03-IMPLEMENTATION.md) for the current code state. Use [docs/API-CONTRACT.md](docs/API-CONTRACT.md), [docs/DB-SCHEMA.md](docs/DB-SCHEMA.md), [docs/AI-STATIONS.md](docs/AI-STATIONS.md), and [docs/GUARDRAILS.md](docs/GUARDRAILS.md) for the relevant contract or integration.
3. Open only the code map needed for the task: [CODES_A](docs/CODES_A.md) for API and backend, [CODES_B](docs/CODES_B.md) for client surfaces, [CODES_C](docs/CODES_C.md) for dependencies and optional services, or [CODES_D](docs/CODES_D.md) for cross-file ownership by planned workflow.
4. For intended requirements and design rationale, read [HISTORY_TRACE/RESULT/CHAPTER_1.md](HISTORY_TRACE/RESULT/CHAPTER_1.md), [CHAPTER_2.md](HISTORY_TRACE/RESULT/CHAPTER_2.md), and [CHAPTER_3.md](HISTORY_TRACE/RESULT/CHAPTER_3.md). Consult the source PDFs in `HISTORY_TRACE/PDF/` when exact source wording or diagram context matters.
5. Read the live source files before making a claim or edit. Use the archived analysis under `HISTORY_TRACE/MD/`, `HISTORY_TRACE/DOCUMENTATION/`, and `HISTORY_TRACE/DOCUMENTATION_AND_AI_BUILDING_BLOCKS/` to trace how a requirement was interpreted, not as proof of runtime behavior.

## Project boundary

Commencys is a scaffold for community incident reporting and volunteer coordination. It is **not an emergency service** and must not be used to coordinate live incidents. Its report intake, SOS receipt, authentication, authorization, persistence, triage, matching, notifications, live updates, task decisions, and routing are not implemented end to end.

The roles are **reporter**, **volunteer**, and **admin**. The admin uses the human review and coordination dashboard; “operator” describes that dashboard function and is not a fourth role. Reporters use the compact report/SOS client and widget. Volunteers use a separate task widget to view offers and accept or reject them. The web dashboard belongs to the admin. Flutter is the reporter flow shell, not another admin dashboard.

The intended lifecycle keeps these facts separate: saving a report, sending a notification, a volunteer explicitly accepting or rejecting an offer, and resolving the work. A delivery attempt is not proof that someone read an alert. A model suggestion is not a decision. A related-report candidate must remain reversible. Route and ETA belong after assignment acceptance. These are design constraints; the current source does not execute the lifecycle.

## Current implementation facts

- FastAPI exposes `/health` and declares REST routes. Health reports `status: scaffold` and `ready: false`; operational routes return HTTP 501. `/ws/alerts` closes with code 1011. The API serves the static `web/` dashboard at its root.
- API and Flutter boundaries use plain JSON maps/dictionaries. There are no application data-model classes or request schemas. Do not add model classes unless the project owner changes this constraint.
- The reporter and volunteer Android widgets are static shells. Volunteer gateway and action receiver files reserve the client boundary; the feed and accept/reject actions do not call the backend.
- The admin dashboard is a static shell. Its JavaScript functions are placeholders; it does not load or mutate report data.
- Storage, identity and access checks, workflow transitions, audit, notifications, routing, Laya inference, DBSCAN clustering, and Laya evaluation are placeholders. Declared packages and Compose profiles do not activate those integrations.
- `backend/migrations/001_initial_schema.sql` is a comments-only outline, not an executable migration. No database is opened by the API.
- Tests under `backend/tests/` are deferred acceptance specifications. Their presence is not evidence that the user workflows work.

Treat comments as intent for the next implementation phase. When a comment conflicts with executable code, inspect the code and report the discrepancy instead of assuming the intended behavior already exists.

## Which source answers which question

| Question | Primary source | How to handle conflicts |
|---|---|---|
| What runs now? | Live code, manifests, and configuration, checked against `docs/03-IMPLEMENTATION.md` | Report what the code actually does; do not silently make it match a target chapter. |
| What should the system do? | Chapter documents and source PDFs in `HISTORY_TRACE/` | Treat as requirements and design, not runtime evidence. |
| Why was a boundary chosen? | Active `docs/` plus the relevant analysis in `HISTORY_TRACE/MD/` | Preserve the distinction between a decision, a proposal, and an implemented fact. |
| What did an earlier check establish? | The dated checkpoint that recorded it | Treat it as historical. Prefer a newer, explicit check for the same source state. |

The archive is intended to preserve source material and prior analysis. The chapters, PDFs, and existing checkpoint files were frozen by the project owner. This handoff and the four `CODES_*.md` guides are additive navigation material; do not rewrite archived chapter content unless the owner reopens it.

There is one known verification discrepancy to keep visible: `README.md` records that Docker Engine responded and Compose configuration passed on 8 October 2026, while `HISTORY_TRACE/RESULT/CHECKPOINT_6.md` says the Docker daemon was unavailable during that checkpoint. Use the README as the later local-toolchain note, but verify Docker again before relying on it. The README's **82/100** is readiness to begin a reproducible team build, not product completion or operational readiness. It also says the APK build was not repeated in that pass; `docs/04-TESTING.md` does not claim a current Android build.

## Repository handling rules

- The working tree contains substantial local, uncommitted work. Inspect `git status` before editing and preserve existing changes. Do not reset, clean, stage, commit, or push unless the owner explicitly asks.
- Keep the project name spelled **Commencys** and keep the three account roles distinct.
- Maintain the scaffold-first direction: keep implementation seams small, single-purpose, and documented. Do not fill hollow features merely to make the code appear complete.
- Do not download model weights, create report data, or start optional containers as a side effect of reading or documenting the repository.
- Large SDKs, package caches, model caches, Gradle/Pub caches, and OSRM data belong outside Git. The documented default locations are on `D:`; use the setup instructions in `README.md` and `tools/bootstrap.ps1`.
- Keep the reporter's source text separate from AI suggestions. Do not make AI or clustering a prerequisite for report/SOS receipt. Preserve explicit volunteer decisions and the admin's human review boundary.

## Fast file navigation

- API routes and static dashboard mount: `backend/app/main.py`
- Workflow and authorization contracts: `backend/app/incident_workflow.py`, `backend/app/security.py`
- Storage contracts and adapters: `backend/app/storage.py`, `backend/app/postgres_store.py`, `backend/migrations/001_initial_schema.sql`
- AI and related-report seams: `backend/app/ai_pipeline.py`, `backend/evaluation/evaluate_laya.py`
- Notification and routing seams: `backend/app/notification_service.py`, `backend/app/routing_service.py`
- Flutter reporter shell: `lib/main.dart`, `lib/app_shell.dart`, `lib/screens/`, `lib/services/`
- Native reporter and volunteer widgets: `android/app/src/main/`
- Admin dashboard: `web/index.html`, `web/app.js`, `web/styles.css`
- Dependency and machine setup: `README.md`, `backend/requirements*.txt`, `pubspec.yaml`, `compose.yaml`, `tools/bootstrap.ps1`, `tools/android-sdk-packages.txt`

## Foundation of the project

The three chapter documents are the project baseline for what the team intends to design. Read them in order because later chapters depend on Chapter 1:

### Chapter 1: problem, purpose, and constraints

The revised [Chapter 1](HISTORY_TRACE/RESULT/CHAPTER_1.md) frames Commencys as a community incident reporting and early coordination prototype. Its central concern is a trustworthy, location-aware report flow. A report needs source text, time, location source, and location accuracy. The user should be able to choose a point manually if GPS is unavailable or unsuitable. Saving a report must precede the receipt shown to the reporter.

Chapter 1 sets three user roles and three separate interfaces: a reporter widget for report/SOS entry, a volunteer widget for task offers and explicit accept/reject decisions, and an admin dashboard for human review and coordination. Admin/operator is one role and one dashboard function. It proposes FastAPI, geospatial persistence, asynchronous advisory text triage, candidate report matching, live updates, and route estimates. Each proposed technology still needs a decision and evidence before it can be treated as an operational requirement.

Safety and trust constraints include keeping the original report separate from analysis, human review of uncertain results, reversible related-report links, appropriate protection of identity and precise location, audit history, and clear referral to official emergency services. Commencys is not an emergency dispatch channel and does not replace official services. The chapter also records the planned iterative lifecycle, development environment assumptions, risks, user stories, and official sources.

### Chapter 2: project management

[Chapter 2](HISTORY_TRACE/RESULT/CHAPTER_2.md) turns Chapter 1 into a management approach: scope and acceptance evidence, responsibilities and review, work packages, risk responses, quality measures, and change control. It proposes an order without asserting calendar dates or team capacity. Do not convert early Trello estimates, the suggested five-second receipt target, or proposed effort into approved commitments without agreement and measurements.

The first suggested delivery focus is a verifiable SOS slice: usable location, durable save, truthful receipt, clear failure behavior, and safe retry. Coordination then adds admin review and offer creation, an authenticated volunteer decision from the volunteer widget, distinct notification states, and persistence/audit. Model evaluation and clustering follow the safe intake boundary. Routing belongs after a volunteer accepts a task. The target sequence is in the chapter; actual team assignments and schedules are not evidenced by this repository.

The initial IndoBERT direction was superseded in the revised chapter by the group's proposal to evaluate **Laya Multilingual**. The candidate is not selected by test results. The English Laya checkpoint and the separate multilingual checkpoint must not be conflated; multilingual coverage does not establish Indonesian quality. Evaluation needs reviewed Indonesian reports, a defined label scheme, held-out data, class-wise metrics, critical false-negative review, calibration, version recording, and rollback. DBSCAN is a separate spatial/time candidate-linking proposal, not a text classifier and not a report merge operation.

Chapter 2's Trello summary is intentionally an evidence summary, not a day-by-day schedule. It preserves the gist of the discussion and embeds five source-board screenshots. Names and estimates in the screenshots are historical material; the revised project chapters supersede old interface or model assumptions where they explicitly do so.

### Chapter 3: target UML views

[Chapter 3](HISTORY_TRACE/RESULT/CHAPTER_3.md) models the same roles and lifecycle through exactly three views:

1. **Use case:** goals of reporter, volunteer, and admin, including location selection, review, task decision, and post-acceptance route/ETA.
2. **Interaction overview:** report/SOS validation and save, advisory follow-up, human review, offer, volunteer decision, and resolution, with failures and status distinctions.
3. **Component:** client surfaces, API, persistence, triage/matching, notifications, identity and routing dependencies.

These are target models. The interaction overview is drawn as a Mermaid flowchart approximation of IOD notation; it is not a native UML model. Diagram sources and exports are under `HISTORY_TRACE/RESULT/UML_PICTURE/`. The current scaffold has separate diagrams and claims in `/docs`; never use the chapter diagram to infer that the represented service exists.

### Cross-chapter invariants

- Stored receipt, notification delivery, volunteer acceptance/rejection, and completed handling are separate events and statuses.
- A report is not accepted until saved. AI, DBSCAN, notification, and routing failures must not be used to fabricate a successful receipt.
- Laya returns advisory triage only after evaluation. DBSCAN may suggest reversible related-report links; neither process overwrites or removes original report content.
- Admin reviews and coordinates. The volunteer decides on an offered task through the separate volunteer widget.
- An accepted assignment may enable an ETA request. ETA is an estimate.
- Any claim of performance, privacy enforcement, delivery, model quality, or operational safety requires measured evidence.

## Documentation and evidence map

Use active `docs/` for current source truth and the archive for source material, requirements history, and provenance. The file prefixes and names below are intentional entry points for targeted retrieval.

### Current repository documentation

| Location | What it answers |
|---|---|
| `README.md` | Repo layout, dependency clusters, Windows setup, local run commands, optional Compose profiles, last recorded local toolchain, and verification limits. |
| `docs/INDEX.md`, `docs/README.md` | Documentation navigation and current scaffold summary. |
| `docs/00-PLANNING.md`, `01-ANALYSIS.md` | Scope baseline, goals, user needs, risks, and open planning assumptions. |
| `docs/02-DESIGN.md`, `architecture.mmd`, `architecture.png`, `architecture-target.png` | Current source boundary versus target component design. The target image is not runtime evidence. |
| `docs/03-IMPLEMENTATION.md`, `CODES_A.md` through `CODES_D.md` | Current code status and code ownership map. Use the `CODES_` guide for file-level traversal. |
| `docs/API-CONTRACT.md`, `DB-SCHEMA.md` | Declared routes/payload intent and proposed persistence shape. The SQL page is not an active schema. |
| `docs/AI-STATIONS.md`, `EVALUATION-MONITORING.md` | Laya/DBSCAN integration seams, evaluation prerequisites, and monitoring intent. |
| `docs/DECISIONS.md`, `GUARDRAILS.md` | Agreed interface split, unresolved technical choices, privacy/safety limits, and responsible-use constraints. |
| `docs/04-TESTING.md`, `QUALITY.md` | Static check instructions, deferred acceptance coverage, prior verification claims, and quality evidence needs. |
| `docs/05-DEPLOYMENT.md`, `06-MAINTENANCE.md` | Local startup limits, deployment boundary, and future support/maintenance responsibilities. |
| `docs/SDLC-LIGHTWEIGHT-SCRUM.md`, `lightweight-scrum-flow.png` | Iterative process reference and its process illustration. These do not prove that meetings or assignments occurred. |
| `docs/06-UI-OVERHAUL-SPEC.md` | Interface scope/reference material; defer to Chapter 1 and `docs/02-DESIGN.md` for the agreed role split and to live UI code for what exists. |
| `docs/REFERENCE.md` | Source references used by the active repository documentation. |

### `HISTORY_TRACE/` source and analysis archive

- `HISTORY_TRACE/DOCUMENTATION/AI_ANALYZE.md` explains the AI-powered reference PDF, its architecture sketch, and implications for Commencys. `TRELLO_ANALYZE.md` records the discussion and screenshots' project-management context.
- `HISTORY_TRACE/DOCUMENTATION_AND_AI_BUILDING_BLOCKS/` contains `AI_Powered_Reference.pdf`, its JPEG architecture image, `Reference.png`, `Jawaban_Trello_Reference.txt`, and `Trello_1.png` through `Trello_5.png`. The architecture JPEG is source material; Chapter 2 does not reproduce it as a project diagram.
- `HISTORY_TRACE/MD/ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md` inventories a prior source snapshot. `ABOUT_2_MARKDOWN_CODE_TRUTH_AUDIT.md` records rules for distinguishing docs from runtime evidence. Recheck both against live code because their line references and some details can age.
- `HISTORY_TRACE/MD/BOOK/BOOK_1_PROJECT_MANAGEMENT.md` extracts relevant project-management ideas from the reference book and Chapter 2 source. `BOOK_2_UML_MODELING.md` extracts UML modeling concepts relevant to Chapter 3. These are study notes, not external authorities and not project implementation.
- `HISTORY_TRACE/MD/FROMCHAPTER1/FROMCHAPTER1_1_FOUNDATION.md` records the source Chapter 1 reading and unresolved questions. `FROMCHAPTER1_2_TRACEABILITY.md` maps the Chapter 1 needs to current code status. Use this pair when a change might alter the foundational scope.
- `HISTORY_TRACE/MD/FOR_CHAP2/` contains management-plan and risk/estimate/schedule analyses. It records proposed controls without approved team dates or commitments.
- `HISTORY_TRACE/MD/FORUML/` contains the use-case, interaction-overview, and component-diagram analysis. The component and flow notes include older source snapshots; follow their time-bound notices and check present code.
- `HISTORY_TRACE/MD/RESULT/`, `RESULT_PDF/`, and `UML_PICTURE/` contain generated or intermediary analysis/render assets. Use `HISTORY_TRACE/RESULT/` as the final chapter/checkpoint location unless a specific artifact says otherwise.
- `HISTORY_TRACE/PDF/` contains original `Chapter1.pdf`, `ForChapter2.pdf`, and `Chapter3.pdf`; the local Braude reference-book PDF; and the final Commencys Chapter 1–3 PDFs. The separate AI reference PDF is in `DOCUMENTATION_AND_AI_BUILDING_BLOCKS/`. The 154 MB Braude PDF remains local-only because GitHub's normal file limit is 100 MB; its relevant analysis and citation are preserved in `MD/BOOK/` and the chapters.
- `HISTORY_TRACE/RESULT/` contains `CHAPTER_1.md` to `CHAPTER_3.md`, their DOCX exports, `CHECKPOINT_0.md` to `CHECKPOINT_6.md`, chapter diagram sources and renders, and `UML_PICTURE/` sources and renders.

### Checkpoint chronology

Treat checkpoints as dated records, not as cumulative proof of today's runtime behavior.

| Checkpoint | Historical milestone |
|---|---|
| `CHECKPOINT_0.md` | Initial analysis collection: codebase state, reference book, Chapter 1 foundation, project-management and UML source analyses. |
| `CHECKPOINT_1.md` | Repository-document alignment work and revised Chapter 1 foundation. |
| `CHECKPOINT_2.md` | Chapter 2, AI/Laya and Trello source analysis, and revised diagrams. |
| `CHECKPOINT_3.md` | Chapter 3 and the three UML views. |
| `CHECKPOINT_4.md` | Separate chapter DOCX/PDF exports and formatting/sanitization review. |
| `CHECKPOINT_5.md` | Recursive document-to-code alignment review; establishes `i = 0` at Chapter 1 and the current source as scaffold `j = 0`. |
| `CHECKPOINT_6.md` | Local dependency/toolchain snapshot, cleanup, and freeze record. Some environment claims conflict with later README notes; follow the conflict note below. |

The reference PDFs include older proposals such as a React PWA and IndoBERT. The revised Chapter 1–3 documents establish the later project direction: Android reporter and volunteer widgets, separate admin dashboard, and Laya Multilingual as a candidate to evaluate. Do not erase the old proposals from the archive or mistake them for current decisions.

## Codebase map by area

| Area | Main files and purpose | What is active now |
|---|---|---|
| CI | `.github/workflows/ci.yml`, `flutter_build.yml` | Both define main-branch pipelines. Flutter steps overlap; workflow definitions do not prove a successful current run. |
| Python API | `backend/app/main.py` | Health and static asset mount work. Operational REST routes return 501; WebSocket closes with 1011. |
| Backend policy/workflow | `incident_workflow.py`, `security.py` | Function signatures and comments; no transitions, authentication, role checks, or access enforcement. |
| Backend persistence | `storage.py`, `postgres_store.py`, `migrations/001_initial_schema.sql` | Protocol, placeholder adapters, comments-only migration. No connection or persistence. |
| AI/evaluation | `ai_pipeline.py`, `evaluation/evaluate_laya.py` | Guarded imports and hollow functions; no checkpoint, inference, dataset, clustering, or evaluation. |
| Notifications/routing | `notification_service.py`, `routing_service.py` | Interface seams only; no delivery, OSRM request, or ETA. |
| Backend checks | `backend/tests/`, `conftest.py` | Acceptance specifications are deferred/skipped as recorded by docs; they do not prove product behavior. |
| Flutter app | `lib/main.dart`, `app_shell.dart`, `screens/`, `theme/` | Compact reporter shell; no working end-to-end report flow. |
| Flutter adapters | `lib/services/`, `lib/widgets/location_picker.dart` | API/location/socket/map seams are hollow. The location picker displays a shell and has no selected-point action. |
| Android native | `android/app/src/main/` | Reporter and volunteer widget providers/layouts, action receiver, gateway, and Flutter host are declared; no live report or volunteer action. |
| Admin UI | `web/index.html`, `styles.css`, `app.js` | Static dashboard shell with named placeholders; no API load, mutation, live update, or audit rendering. |
| Optional services | `compose.yaml`, `config/keycloak/` | PostGIS, Mailpit, Keycloak, OSRM profiles are local development boundaries, not wired to the API. |
| Setup/document tools | `tools/`, `requirements-tools.txt`, `tools/android-sdk-packages.txt` | D-drive dependency bootstrap, OSRM data preparation, and historical document/diagram generators. |
| Docs and history | `docs/`, `HISTORY_TRACE/` | Active truth/reference docs versus frozen source and chapter history, as mapped above. |

Use the focused guides for implementation navigation: [backend/API](docs/CODES_A.md), [client surfaces](docs/CODES_B.md), [dependencies/integrations](docs/CODES_C.md), and [cross-file workflow ownership](docs/CODES_D.md).

## Dependencies and local environment

Manifests define four distinct dependency purposes. Do not combine their meaning:

| Purpose | Manifest or config | Key packages/services |
|---|---|---|
| API runtime | `backend/requirements.txt` | FastAPI, Uvicorn, HTTPX, Psycopg, Pydantic Settings, PyJWT. Some dependencies are reserved for future integrations and are unused by current routes. |
| Backend acceptance work | `backend/requirements-dev.txt` | API requirements plus pytest. Current behavioral checks are deferred. |
| AI evaluation | `backend/requirements-ai.txt` | Laya, Hugging Face Hub, scikit-learn. Does not download weights or activate inference/clustering. |
| Flutter/Android | `pubspec.yaml`, Android Gradle files, `tools/android-sdk-packages.txt` | Flutter/Dart, map/location/HTTP/WebSocket/Auth packages, JDK and Android SDK packages. Auth packages do not mean OIDC is implemented. |
| Optional local integrations | `compose.yaml` | PostGIS (`data`), Mailpit and Keycloak (`identity`), OSRM (`routing`). |
| Chapter/document tooling | `requirements-tools.txt` | Pillow, python-docx, ReportLab. Not needed to run the API or client. |

On 8 October 2026 the root README recorded Python 3.11.15, Java 21, Flutter 3.47.6, Dart 3.13.5, Android SDK platforms/build tools 35/36 under `D:\Android\Sdk`, and Python packages under `D:\Commencys-Cache`. It recorded Docker Engine 29.6.2, Compose 5.3.1, and a passing Compose config validation. SDKs and caches are machine state; verify them if the task depends on them. The bootstrap defaults are `D:\Android\Sdk` and `D:\Commencys-Cache`, overridable through `ANDROID_HOME` and `COMMENCYS_CACHE_ROOT`.

Basic Windows setup and API commands are in [README.md](README.md). The intended API shell command from the repo root is:

```powershell
& 'D:\Commencys-Cache\Python\commencys\Scripts\python.exe' -m uvicorn app.main:app --app-dir backend --reload --port 8000
```

The optional Android/mobile setup clusters are `tools/bootstrap.ps1 -Cluster android -AcceptAndroidLicenses` and `tools/bootstrap.ps1 -Cluster mobile`; Python clusters are `api` or `ai`; optional containers use `data`, `identity`, or `routing`. The routing profile needs map data prepared outside Git. Do not pull images, download Laya weights, or prepare large OSM extracts unless the task requires them.

## Verification status and conflicts to carry forward

The recorded `82/100` score in `README.md` measures readiness to start a reproducible team build. It is **not** product completion, feature correctness, security readiness, or emergency-use readiness. Operational claims remain unverified.

- `/health` is a process response with `ready: false`; it is not a database/readiness probe.
- Backend behavioral specifications were recorded as 39 skipped tests; no business assertions ran. Flutter analyze/test attempts were interrupted without output in prior checks.
- README records an earlier APK build but says the latest setup pass did not repeat it. `docs/04-TESTING.md` says the current Android APK/native widget build was not verified. Do not claim a current build without a new run.
- Environment conflict: `README.md` says Docker Engine responded and Compose config passed on 8 October 2026; `CHECKPOINT_6.md` says the Docker daemon was unavailable during its checkpoint. Verify Docker before relying on it; do not rewrite history to make the two statements appear identical.
- Git for Windows may represent docs case-only filename changes strangely because `core.ignorecase` is normally enabled. Inspect both the physical paths and `git status`; do not edit `.git/config` or stage a mass rename just to hide that behavior.
- `HISTORY_TRACE/MD/FORUML/` includes pre-scaffold flow descriptions and source line references from 7 October 2026. Those describe a historical snapshot and can be stale. `ABOUT_1`, `ABOUT_2`, checkpoint5, current `/docs`, and live code help distinguish it from the current scaffold.
- `HISTORY_TRACE/PDF/Braude_SoftwareBook(Reference).pdf` is a large source file (about 154 MB). It exceeds GitHub's standard per-file limit; do not add it to a normal Git commit. Its extracted topic notes and bibliographic citation are in `HISTORY_TRACE/MD/BOOK/` and the chapters. Keep the local source file intact unless the owner decides on Git LFS or another authorized distribution method.

## How the next agent should work

1. Start from this file, choose the relevant active contract, then inspect the exact source file and current Git state.
2. Trace each proposed change back to a Chapter 1–3 requirement and state whether that requirement is foundational, a project-management proposal, or a target UML behavior.
3. Keep a visible separation between current behavior, scaffold/interface, approved decision, and future proposal. If a document disagrees with source, document the discrepancy and prefer source for runtime facts.
4. Preserve small, cohesive module ownership. Keep route handlers at the transport edge, business transitions in workflow services, identity checks in the security boundary, and storage behind its adapter contract.
5. Keep JSON maps as the project payload boundary and do not introduce data-model classes unless the owner changes this direction. Do not use dynamic framework or vendor wiring merely to fill out the codebase.
6. Do not turn comments, route declarations, UI controls, packages, diagrams, test names, or skipped tests into claims of functionality.
7. When runtime truth changes, update the relevant `docs/` page and the related `CODES_*.md`. Preserve chapter PDFs, chapter Markdown, and archived analyses unless the owner explicitly reopens those materials.
8. Verify the changed boundary and clearly report what was not checked. A clean compile or successful container configuration does not establish product behavior.
9. Inspect and preserve existing local work. Do not reset, clean, stage, commit, or push unless the owner explicitly authorizes the concrete action and destination. Use the exact branch and commit message when the owner provides them.
