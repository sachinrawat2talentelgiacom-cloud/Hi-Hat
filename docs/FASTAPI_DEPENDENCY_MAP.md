# FastAPI dependency map

Audited: 2026-08-26

| Capability | Current Windows implementation | FastAPI runtime dependency |
|---|---|---:|
| Search | Dart provider HTTPS plus Drift local results | No |
| Play | `media_kit` opens local FLAC paths | No |
| Library | Drift / SQLite in the Flutter process | No |
| Download | Embedded WebView2 download callback | No |
| Validation and metadata | Dart FLAC reader and local import service | No |
| Settings | Flutter preferences | No |
| Provider status | Errors from the actual provider path | No |

No active client code references a backend base URL, localhost API, health
polling, or backend reconnect flow. `scripts/start-backend.ps1`, `backend/`, and
`acquisition_helper/` are legacy/reference assets and are not invoked by the
normal launcher.

The phrase `Flutter tool backend` in generated Windows CMake is Flutter build
terminology and is unrelated to the former FastAPI service.
