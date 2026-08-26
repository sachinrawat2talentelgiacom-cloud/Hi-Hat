# Project component status

Audited: 2026-08-26

| Component | Status | Evidence |
|---|---|---|
| Flutter Search UI | PASS | Widget test; spinner now has bounded controller completion |
| Search state controller | PASS | 10-second timeout, three attempts, generation guard |
| Native channel | FAIL | No MethodChannel or named-pipe server exists |
| SearchService | PASS | Dart service is implemented; live upstreams currently fail |
| WebView2 runtime | PASS | Runtime 151.0.4129.107 installed; app process launches |
| Provider page | NOT TESTED | Requires visible interactive browser session |
| Provider DOM parser | NOT TESTED | Acquisition uses only track page Download selector |
| Result normalizer | PASS | Unit/build coverage and direct Dart implementation |
| Track matcher | NOT TESTED | UI is user-selected; automated exact matcher is absent |
| AcquisitionManager | PASS | Dart route/state implementation exists |
| ResolutionStrategyManager | FAIL | No multi-strategy manager exists in current runtime |
| DownloadService | NOT TESTED | Live WebView download callback requires interactive run |
| FLAC validator | PASS | Parser tests and public-domain full-pipeline test |
| Metadata service | PASS | Embedded tags and measured audio properties verified |
| SQLite | PASS | Write/read/reopen persistence test passes |
| Artwork service | NOT TESTED | Remote/embedded artwork storage is not implemented |
| Player service | PASS | media_kit load, controls, and natural-end test pass |
| Playback state controller | PASS | Position/duration/playing streams are wired |
| Offline local playback | PASS | Fixture playback uses only a finalized local file |
