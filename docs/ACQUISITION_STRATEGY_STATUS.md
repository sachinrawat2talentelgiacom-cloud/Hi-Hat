# Acquisition strategy status

Updated: 2026-08-25

| Strategy | Configured | Tested | Search | Full FLAC | Automatic | Status / next action |
|---|---:|---:|---:|---:|---:|---|
| Flutter local library | Yes | Automated metadata tests | Yes | Yes | Yes after import | Existing local-first playback retained. |
| Manual FLAC import | Yes | Parser tests | N/A | Yes | One-time selection | Existing picker, hash deduplication, metadata, database, and local playback retained. |
| Personal library folders | Optional | Backend integration test | Yes | Yes | Yes | Configure `HI_HAT_PERSONAL_LIBRARY_ROOTS` with user-controlled folders. |
| Authorized Unified resolver | No | Contract tests | Via Monochrome | When authorized | Yes | Requires a legitimate endpoint/token supplied by the user. |
| Public Monochrome instances | Yes | Live | Yes | No for known track | Yes when capable | Samidy denies `/track`; second instance is unavailable. Fallback only. |
| Monochrome localhost | Reference cloned | Source audit only | Pending interactive test | Pending | Unknown | Node is available, but browser authorization behavior needs a normal interactive localhost test. |
| Self-hosted HiFi | No | No | No | No | Potentially | Requires user-owned provider credentials and permission. |
| Download inbox watcher | No | No | N/A | N/A | After user download | Still to implement; manual import remains the current fallback. |
| Browser handoff | No | No | N/A | User-dependent | No | May open the normal site later; must never extract browser authorization state. |

## Local FLAC proof

Fixture: `backend/tests/assets/player_test.flac`, sourced from the public-domain Exaile test corpus.

- Container/codec: FLAC
- Duration: 10 seconds
- Bit depth: 16-bit
- Sample rate: 44.1 kHz
- Channels: mono
- Validation: passed using Mutagen; `ffprobe` is optional and currently absent on this machine
- Personal-library resolution/copy/full-duration validation: passed
- Flutter tests: passed
- Audible end-to-end Windows playback: not claimed; it requires an interactive run of the Windows client

Automatic online acquisition is not complete until an authorized resolver is configured. Automatic acquisition from user-controlled personal-library folders is implemented.
