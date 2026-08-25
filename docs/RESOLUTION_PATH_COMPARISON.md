# Resolution path comparison

| Stage | Official Monochrome | Local Monochrome | Hi Hat FastAPI |
|---|---|---|---|
| Search | Native TIDAL query with HiFi fallback | Same source code | Public `/search/` works via samidy |
| Track ID | TIDAL ID | TIDAL ID | TIDAL/Monochrome ID |
| Audio resolver | Unified Playback, then ISRC Deezer | Source supports this on localhost; interactive result not executed here | Optional authorized Unified strategy, then public instances |
| Public instance | Dev mode/fallback, not primary current path | Optional paid endpoint | Existing fallback strategy |
| Download intent | Explicit `intent=download` | Same source path | Explicit `intent=download` for authorized resolver |
| Formats | Direct, DASH, HLS; protected Amazon variants | Same code | Unprotected direct, DASH, HLS only |
| Known-track result | User reports successful official download | Not verified: Docker absent and interactive browser/Turnstile test unavailable | Search succeeds; public acquisition is denied/unavailable |
| Authorization dependency | Default Unified token uses browser Turnstile JWT | README permits localhost, but requires interactive verification | No browser credentials or challenge bypass; user-authorized token only |

Root-cause statement: the official site succeeds because it uses the current Unified Playback/download resolution path (with browser authorization) and provider fallback. The backend failed because it used the older public `/track/` path. The supported part implemented in Hi Hat is a normalized, optional resolver contract for a service/token the user is authorized to use; the browser challenge and protected resources are excluded.
