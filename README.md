# COMMENCYS

Commencys is a software engineering scaffold for community incident reporting and volunteer coordination. The repository defines the intended boundaries for a reporter widget, a separate volunteer task widget, an admin review dashboard, and a FastAPI service.

For AI handoff and document traversal, start with [AGENT.md](AGENT.md). It points to the current implementation notes, the frozen project chapters, and the focused code maps.

**This checkout is not an emergency response service.** Report delivery, SOS receipt, location access, assignment decisions, authentication, persistence, AI triage, clustering, live updates, and routing are not active end-to-end. The operational API routes remain scaffold responses, and the UI controls do not submit or change real records.

## SYSTEM BOUNDARY

- **Reporter:** Android widget and Flutter client shell for report and SOS entry.
- **Volunteer:** separate Android widget for viewing and accepting or rejecting offers. Its feed and decision actions are not connected to a backend.
- **Admin:** web dashboard for human review and coordination. It does not load or mutate project data.
- **API:** FastAPI route and service boundaries. Request payloads use plain JSON mappings; there are no application data-model classes.
- **Supporting integrations:** PostGIS, Keycloak and Mailpit, Laya Multilingual, DBSCAN, and OSRM have dependency or configuration seams. Their presence does not mean they are active in a user workflow.

The report receipt, admin review, volunteer offer, volunteer decision, and post-acceptance route are separate lifecycle steps. AI suggestions and related-report candidates are advisory and require the planned human review. Laya weights are not downloaded, its Indonesian performance is not evaluated, and DBSCAN does not cluster project reports.

## REPOSITORY LAYOUT

| Path | Purpose |
| --- | --- |
| `backend/` | FastAPI scaffold, service contracts, deferred acceptance specifications, and SQL migration outline |
| `lib/` | Flutter client shell, screens, configuration, and service interfaces |
| `android/` | Android host and reporter and volunteer home-screen widget declarations |
| `web/` | Admin dashboard shell and disabled service actions |
| `docs/` | Current scaffold notes, target constraints, dependencies, and verification limits |
| `config/keycloak/` | Local development realm import for the optional identity profile |
| `tools/` | Dependency bootstrap, OSRM data preparation, and historical document builders |
| `HISTORY_TRACE/DOCUMENTATION/` | Analysis notes for the project AI reference and Trello source material |
| `HISTORY_TRACE/DOCUMENTATION_AND_AI_BUILDING_BLOCKS/` | Reference PDF, diagram image, Trello screenshots, and source discussion text |
| `HISTORY_TRACE/MD/` | Project, reference book, Chapter 1, Chapter 2, and UML analysis notes |
| `HISTORY_TRACE/PDF/` | Source PDFs and generated Chapter 1 to Chapter 3 PDFs |
| `HISTORY_TRACE/RESULT/` | Chapter Markdown and DOCX files, checkpoints, and diagram sources and outputs |

The archived chapter documents describe the project requirements and intended design. They are kept separate from the active code documentation so that a chapter is not presented as evidence that a code path is implemented.

## DEPENDENCY GROUPS

The manifests separate the small core scaffold from optional services and document tools.

| Group | Manifest or configuration | Main dependencies | When needed |
| --- | --- | --- | --- |
| API runtime | `backend/requirements.txt` | FastAPI, Uvicorn, HTTPX, Psycopg, Pydantic Settings, PyJWT | Running the API scaffold |
| API development | `backend/requirements-dev.txt` | API runtime plus pytest | Local test development |
| AI evaluation | `backend/requirements-ai.txt` | API runtime plus Laya, Hugging Face Hub, scikit-learn | Preparing the separate Laya and DBSCAN evaluation environment; does not fetch model weights |
| Flutter client | `pubspec.yaml` | Flutter SDK, `flutter_map`, `latlong2`, `geolocator`, HTTP, WebSocket, AppAuth, and secure storage packages | Resolving and building the client shell |
| Android build | `tools/android-sdk-packages.txt` and Gradle wrapper | Android command-line tools, platform tools, Android platforms 35 and 36, build tools 35 and 36, NDK, CMake, Java | Building the Android host and native widgets |
| Local service profiles | `compose.yaml` | PostGIS, Mailpit, Keycloak, and OSRM container images | Optional integration development only |
| Chapter and diagram tools | `requirements-tools.txt` | Pillow, python-docx, ReportLab | Rebuilding the archived images, DOCX, or PDF artifacts |

The Android SDK, Pub cache, Gradle cache, Python environment, model cache, and OSRM data are configured to live on `D:` by default. The bootstrap script uses `D:\Android\Sdk` and `D:\Commencys-Cache`; set `ANDROID_HOME` or `COMMENCYS_CACHE_ROOT` to override those locations.

## WINDOWS SETUP

Install Git, Python 3.11, Flutter 3.47.6 with its bundled Dart 3.13.5 SDK, a Java 17 or newer JDK, and Docker Desktop if you need the optional containers. Keep Docker Desktop's disk image on `D:` before pulling large images. The repository does not install these system tools automatically.

From PowerShell at the repository root, prepare the Android SDK and Flutter packages:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tools\bootstrap.ps1 -Cluster android -AcceptAndroidLicenses
.\tools\bootstrap.ps1 -Cluster mobile
```

The Android cluster installs the SDK packages listed in `tools/android-sdk-packages.txt` and writes the machine-local `android/local.properties` file. The mobile cluster puts Pub and Gradle caches on `D:` and runs `flutter pub get`.

Create the Python environment and install the API development dependencies:

```powershell
.\tools\bootstrap.ps1 -Cluster api
$python = 'D:\Commencys-Cache\Python\commencys\Scripts\python.exe'
```

For the optional AI evaluation packages, use the same Python environment:

```powershell
.\tools\bootstrap.ps1 -Cluster ai
```

To rebuild the archived chapter documents or diagrams, install the separate document tools:

```powershell
& $python -m pip install -r requirements-tools.txt
```

The cluster installer sets pip, Hugging Face, Torch, Pub, Gradle, and temporary-file caches under `D:\Commencys-Cache` or `D:\Android\Sdk`. It does not download Laya weights. The optional OSRM preparation script downloads a large Java region extract and stores the generated routing graph outside Git.

## RUN THE LOCAL SCAFFOLD

Start the API shell:

```powershell
& $python -m uvicorn app.main:app --app-dir backend --reload --port 8000
```

The API health endpoint reports scaffold status. Operational report, SOS, review, assignment, and route actions are not implemented and may return HTTP 501. The admin dashboard shell is served from the API root; its controls do not load or change report data.

To start the Flutter client on an available emulator or device:

```powershell
flutter devices
flutter run -d <device-id>
```

The Android reporter and volunteer widgets are native home-screen widgets. Their visible structure is present, but report submission, task loading, and accept or reject actions are not connected to working services.

## OPTIONAL DOCKER PROFILES

Validate the Compose file without pulling images or starting containers:

```powershell
docker compose config --quiet
```

Start only the service group needed for local integration work:

```powershell
docker compose --profile data up -d
docker compose --profile identity up -d
```

The `data` profile starts PostGIS. The `identity` profile starts Mailpit and Keycloak with local development settings. These services are not connected end-to-end to the current API scaffold. Do not expose the development credentials outside the local machine.

The `routing` profile requires the prepared Java road graph first:

```powershell
$env:OSRM_DATA_DIR = 'D:\Commencys-Cache\OSRM\java'
.\tools\prepare-osrm.ps1
docker compose --profile routing up -d
```

Stop services started from this Compose project with `docker compose down`. The named database volumes are retained unless explicitly removed.

## LOCAL TOOLCHAIN CHECK

On 8 October 2026, Docker Desktop Engine 29.6.2 and Compose 5.3.1 responded to local checks, and `docker compose config --quiet` passed. Python 3.11.15, Java 21, Flutter 3.47.6, and Dart 3.13.5 were detected. Android SDK command-line tools 22.0, ADB 37.0.1, platforms 35 and 36, and build tools 35 and 36 are present under `D:\Android\Sdk`. The SDK manager works by full path but is not on the current shell `PATH`.

The Python environment under `D:\Commencys-Cache` contains FastAPI 0.142.4, Uvicorn 0.54.0, Psycopg 3.3.6, PyJWT 2.15.1, Laya 0.4.0, Hugging Face Hub 1.33.0, scikit-learn 1.9.1, PyTorch 2.14.1, Transformers 5.19.0, and pytest 8.4.2. `pip check` reports no broken requirements. A previous local checkpoint records a successful debug APK build; this pass verified the Flutter and Android tools but did not repeat the build. The current scaffold therefore has **82/100 readiness to begin a reproducible team build**. The score reflects the validated toolchain and dependency setup, with points reserved for a fresh build and mobile dependency resolution in this pass. It is not a product-completion or operational-readiness score.

## VERIFICATION LIMITS

The repository intentionally contains scaffolding. Automated test files are deferred acceptance specifications; their presence does not show that user workflows work. No current claim is made for SOS delivery, authentication, durable persistence, AI quality, clustering, notifications, live updates, routing, performance, or emergency response readiness.

See [implementation status](docs/03-IMPLEMENTATION.md), [API surface](docs/API-CONTRACT.md), [target design](docs/02-DESIGN.md), and [verification plan](docs/04-TESTING.md).
