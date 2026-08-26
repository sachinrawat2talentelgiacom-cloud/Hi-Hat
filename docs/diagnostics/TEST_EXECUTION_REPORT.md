# Test execution report

- Date/time: 2026-08-26 12:18 Asia/Calcutta
- Git commit: `2cc23fcaa85a9aabfc76af0b784fe15fd31a5bf0` plus uncommitted migration work
- Flutter: 3.47.1 stable
- Dart: 3.13.1
- Windows: 10.0.26200.0
- WebView2 Runtime: 151.0.4129.107
- Build: Windows x64 debug
- Live test query: `closer`
- Deterministic test track: `Gapless FLAC #1` by `Me`
- Expected album: `Exaile Test Files`
- Expected duration: 10 seconds

| Stage | Status | Evidence | Error |
|---|---|---|---|
| App startup | PASS | Debug process remained alive after 5 seconds | |
| Native services | FAIL | Named-pipe PING timed out | Server not implemented |
| WebView2 init | NOT TESTED | Cannot observe without diagnostic bridge | |
| Provider page load | NOT TESTED | Requires interactive acquisition | |
| Provider ready | DEGRADED | Primary returned data in 1.59 s on rerun; fallback returned 503 | External provider state |
| Search start | PASS | Controller instrumentation and watchdog tests | |
| Search request sent | PASS | Direct endpoint probes executed | |
| Search results received | PASS | Primary endpoint returned a live payload on rerun | Fallback HTTP 503 |
| Search parse | PASS | Current Dart parser accepts the primary response in application tests/build | |
| Track match | PASS | Exact public-domain fixture tags matched | |
| Play trigger | NOT TESTED | Live test bridge is absent | |
| Local check | PASS | SQLite lookup code and persistence test | |
| Acquisition start | NOT TESTED | Interactive browser run required | |
| Resolve source | NOT TESTED | No runtime strategy manager | |
| Download start/progress/completion | NOT TESTED | Interactive WebView callback required | |
| FLAC validation | PASS | Actual fixture parsed and ffprobed | |
| Duration validation | PASS | 10.0 seconds measured and matched | |
| Metadata extraction | PASS | Title, artist, album and audio properties matched | |
| Artwork | NOT TESTED | Fixture contains no required artwork | |
| DB write | PASS | Row written, read, database reopened, row read again | |
| Player load | PASS | media_kit opened finalized local FLAC | |
| Playback start/progress/end | PASS | Natural 10-second playback emitted completion | |
| Offline replay | PASS | Local file playback has no provider dependency | |

## Conclusion

The local FLAC pipeline passes. The complete live project flow does not pass.
The first diagnostic failure is the absent in-process named-pipe server. Live
remote search is independently blocked by the current configured endpoints.
