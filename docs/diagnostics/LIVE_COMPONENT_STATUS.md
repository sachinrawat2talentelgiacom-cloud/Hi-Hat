# Live component status

| Component | Status | Evidence |
|---|---|---|
| Diagnostic named-pipe server | PASS | PING returned `diagnosticsReady=true` |
| Flutter diagnostic bridge | PASS | Live commands reached Riverpod state |
| Search UI/controller | PASS | 25 live results within deadline |
| ProviderSearchService primary | PASS | Successful primary returned immediately |
| Exact matcher/selection | PASS | Track ID `63232677` selected explicitly |
| TrackPlaybackCoordinator | PASS | Shared route reached local lookup and acquisition |
| BrowserAcquisitionScreen | PASS | Real route opened |
| Download action detection | PASS | State advanced to `STARTING_DOWNLOAD` |
| Download callback | FAIL | No callback within 20 seconds |
| Completed-file scanner | BLOCKED | No download path/file |
| LocalImportService onward | NOT_TESTED | Blocked upstream in live run |
