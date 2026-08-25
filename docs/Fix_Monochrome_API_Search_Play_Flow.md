# Search → Play → Auto-Download → Play — Step-by-Step Process

## The Short Answer

**Yes, you can do this — and your app is already built to do exactly this.**

The flow you described (what you do manually in Lucida or Monochrome: search →
click the song → get the download) is already automated in Hi Hat:

```text
You type a song name in the app
    ↓
App shows results (title, artist, album, quality)
    ↓
You tap Play on a result
    ↓
App downloads the FLAC automatically in the background
    ↓
FLAC is saved to your device (Music/Artist/Album/Song.flac)
    ↓
Your player opens the local file and plays it
    ↓
Next time you tap Play on the same song → plays instantly, no re-download
```

Nothing needs to be redesigned. The only reason it is not working right now is
that **Monochrome changed its API and most of its instances are down**. Your
provider code still speaks the old API contract.

This document explains:

1. How the flow works today in your code
2. Exactly what broke (verified live on 2026-08-25)
3. The step-by-step fix process
4. How to verify each step
5. What to do when instances go down again

---

# Part 1 — How the Flow Works in Your Code Today

## 1.1 Search (already implemented)

```text
Search screen (client/lib/features/search/search_screen.dart)
    ↓
HiHatApi.search()  (client/lib/services/api_client.dart)
    ↓  GET /v1/search?q=...
FastAPI route      (backend/src/hi_hat_backend/main.py)
    ↓
MonochromeProvider.search()  (backend/.../providers/monochrome/provider.py)
    ↓  GET {instance}/search/?s=...
Monochrome API instance
    ↓
Normalized TrackCandidate list → back to the app → results list
```

## 1.2 Tap Play → automatic download → play (already implemented)

In `search_screen.dart`, tapping Play on a result runs:

```text
downloadService.acquire(track)   (client/lib/services/download_service.dart)
    ↓
1. Check local database — already downloaded?
      YES → skip everything, play the local file immediately
      NO  → continue
2. POST /v1/downloads            → backend creates a download job
3. Poll GET /v1/downloads/{id}   → progress updates (QUEUED → RESOLVING →
                                   DOWNLOADING → VERIFYING → READY)
4. GET /v1/downloads/{id}/file   → transfer FLAC to the device
5. Verify SHA-256 of the received file against the job
6. Save to  Music/Artist/Album/Song.flac
7. Save track + quality metadata into the local library database
8. POST /v1/downloads/{id}/complete
    ↓
audioEngine.playLocal(track)     → Player opens, playback starts
```

On the backend side, a download job runs:

```text
DownloadManager (backend/src/hi_hat_backend/downloads.py)
    ↓
MonochromeProvider.resolve_audio(track_id)   → get a playable source
    ↓
MonochromeProvider.acquire(...)              → download the audio
    ↓  (direct file URL, or DASH manifest via ffmpeg)
validation.py                                → check the file is real audio,
                                               read codec / sample rate / bit depth
    ↓
Job becomes READY, file waits in the staging folder for the app to fetch
```

**Every piece of this already exists.** The break is only in step
`resolve_audio` / `search` inside `provider.py`, because the upstream
Monochrome API changed.

---

# Part 2 — What Exactly Broke (Verified Live, 2026-08-25)

## 2.1 Most Monochrome instances are down

Tested from your machine:

| Instance | Search `/search/?s=...` | Status |
|---|---|---|
| `https://api.monochrome.tf` | **503** | down |
| `https://eu-central.monochrome.tf` | **503** | down |
| `https://us-west.monochrome.tf` | **503** | down |
| `https://arran.monochrome.tf` | **530** | down |
| `https://triton.squid.wtf` | DNS fail | down |
| `https://wolf/maus/vogel/katze/hund.qqdl.site` | timeout | unreachable |
| `https://tidal.kinoplus.online` | DNS fail | down |
| **`https://monochrome-api.samidy.com`** | **200 OK** | **works** |

Monochrome's own `INSTANCES.md` warns:

> "this file is currently outdated, as we have switched away from hifi-api"

So this is expected — the project changed its backend and the public
instance list is in flux.

## 2.2 The search response shape changed

Old shape your provider expects (`_find_section(payload, "tracks")`):

```json
{ "data": { "tracks": { "items": [ ... ] } } }
```

New shape actually returned by the working instance:

```json
{
  "version": "2.3",
  "data": {
    "limit": 25,
    "offset": 0,
    "totalNumberOfItems": 246,
    "items": [ { "id": 116125921, "title": "Daylight", "artist": {...}, "album": {...}, "audioQuality": "LOSSLESS", ... } ]
  }
}
```

The track fields your mapper needs (`id`, `title`, `artist`, `album`,
`duration`, `explicit`, `audioQuality`) are all still there — but there is no
`tracks` section anymore, so `_search_items()` raises
`ProviderResponseChanged` on every instance and your search ends with:

```text
PROVIDER_UNAVAILABLE — No compatible Monochrome instance is available
```

**This is the main reason your app finds nothing right now.**

## 2.3 The audio-resolution endpoint was removed

Your provider calls:

```text
GET {instance}/trackManifests/?id=...&quality=...&formats=...&usage=DOWNLOAD
```

On the working instance this now returns **404**. It has been replaced by:

```text
GET {instance}/track/?id={trackId}
```

which returns the manifest **inline as base64** instead of a URL:

```json
{
  "version": "2.3",
  "data": {
    "trackId": 116125921,
    "audioQuality": "HI_RES_LOSSLESS",
    "audioMode": "STEREO",
    "manifestMimeType": "application/dash+xml",
    "manifestHash": "...",
    "manifest": "PD94bWwgdmVyc2lvbj0nMS4wJyBlbmNvZGluZz0nVVRGLTgnPz48TVBE..."
  }
}
```

The base64 decodes to a DASH MPD XML document. Your provider **already knows
how to handle DASH** (`_acquire_dash()` runs ffmpeg with `file` in its
protocol whitelist) and **already knows how to base64-decode manifests** —
the code just expects them behind a URL from `/trackManifests/`, not inline
from `/track/`.

Monochrome's own web app additionally routes stream resolution to a separate
"streaming" instance list (`arran.monochrome.tf`, `triton.squid.wtf`,
`*.qqdl.site`, `hifi.p1nkhamster.xyz`) — all currently unreachable. The
`samidy` instance serves everything from one host, which is simpler for us.

---

# Part 3 — Step-by-Step Fix Process

## Step 1 — Point the backend at the working instance

Edit `backend/.env`:

```text
HI_HAT_MONOCHROME_API_INSTANCES=["https://monochrome-api.samidy.com","https://api.monochrome.tf"]
```

Put the working instance first. Keep the second one as a failover for when it
comes back. Your provider automatically prefers instances with fewer recent
failures, so order is a hint, not a hard rule.

Optional: also update the default list in
`backend/src/hi_hat_backend/config.py` so fresh checkouts work.

## Step 2 — Fix search parsing for the new response shape

File: `backend/src/hi_hat_backend/providers/monochrome/provider.py`

In `_search_items()` (or before calling it), accept the new flat shape:

- If the payload contains `data.items` as a list → use it directly.
- Otherwise fall back to the old `_find_section(payload, "tracks")` logic.

Nothing else in search needs to change — `_map_track()` already reads the
fields the new response provides.

Verify with a unit test in `backend/tests/` using a saved copy of the real
JSON response above (flat `data.items` shape), plus one old-shape fixture so
both contracts pass.

## Step 3 — Fix audio resolution (`/trackManifests/` → `/track/`)

In `resolve_audio()`:

1. Replace the `/trackManifests/` request with:

   ```text
   GET {instance}/track/?id={provider_track_id}
   ```

   (Optionally pass `&quality=HI_RES_LOSSLESS` first, then `LOSSLESS`,
   keeping your existing quality-fallback loop.)

2. Read the response: `payload["data"]` contains
   `audioQuality`, `manifestMimeType`, `manifest`, `manifestHash`.

3. Base64-decode `manifest`:
   - If the decoded text starts with `<MPD` → it is DASH. **Write the decoded
     XML to a temp `.mpd` file** in the staging dir and return
     `ResolvedAudio(track_id, <temp .mpd path>, "dash")`.
     Your existing `_acquire_dash()` already feeds a path/URL to ffmpeg, and
     `file` is already in its protocol whitelist.
   - If the decoded JSON has `urls: [...]` → take the first URL and return
     `ResolvedAudio(track_id, url, "direct")` (your existing direct path).
   - If the manifest contains `<ContentProtection` / `cenc:` → raise
     `AccessRestricted`, same as today (you do not bypass DRM).

4. Run the decoded manifest URL (if any) through `_assert_allowed_media_url()`
   as today. Temp local `.mpd` files skip that check — they are local paths,
   not URLs.

5. Record the real `audioQuality` from the response so the quality label
   shown in the player comes from verified data, not from the request.

Verify with unit tests: a fixture of the new `/track/` JSON → assert a DASH
`ResolvedAudio` comes out, and that the temp MPD file exists and starts with
`<MPD`.

## Step 4 — Restart the backend and test with curl

From `backend/`:

```powershell
.venv\Scripts\uvicorn hi_hat_backend.main:app --host 127.0.0.1 --port 8765
```

Then, in a second terminal (replace `$TOKEN` with your `HI_HAT_API_TOKEN`):

```powershell
# 1. provider health
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8765/v1/provider/status

# 2. search — expect a JSON list of tracks
curl -H "Authorization: Bearer $TOKEN" "http://127.0.0.1:8765/v1/search?q=daylight"

# 3. start a download using a provider_track_id from the search results
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" `
  -d '{"provider":"monochrome","provider_track_id":"116125921","preferred_quality":"best_lossless"}' `
  http://127.0.0.1:8765/v1/downloads

# 4. poll the job until status is READY
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8765/v1/downloads/{job_id}

# 5. fetch the file and check it is a real FLAC (starts with "fLaC")
curl -H "Authorization: Bearer $TOKEN" -o test.flac http://127.0.0.1:8765/v1/downloads/{job_id}/file
```

Do not move on until each step returns sane output.

## Step 5 — Test the real user flow in the app

1. Start the Flutter app (Windows first).
2. Search `Daylight` → results appear with title / artist / quality.
3. Tap **Play** on a result.
4. Watch the progress indicator move through the download phases.
5. Playback starts automatically when the transfer finishes.
6. Check the file exists under the app's
   `Music/Taylor Swift/Lover/Daylight.flac` folder and appears in the
   **Local Library**.
7. Tap Play on the same track again → it must start **instantly** from the
   local copy (no download).
8. Kill the backend and confirm the downloaded track still plays offline.
9. Repeat on Android against the Windows backend over your LAN.

## Step 6 — Clean up failed jobs

Failed or stale download jobs leave files in `backend/tmp/`. Clear them while
testing so old failures do not confuse verification.

---

# Part 4 — When Instances Go Down Again

This will keep happening — these are free community-run servers. The design
already accounts for it; use it:

1. **Check health first, not the app.**

   ```powershell
   curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8765/v1/provider/status
   ```

2. **Refresh your instance list** from Monochrome's live list:

   ```text
   https://raw.githubusercontent.com/monochrome-music/monochrome/main/public/instances.json
   ```

   Add any responding `api` entries to `HI_HAT_MONOCHROME_API_INSTANCES` in
   `backend/.env` and restart the backend. No code change needed.

3. **Test an instance before adding it** — it must answer both:

   ```powershell
   curl "{instance}/search/?s=test"
   curl "{instance}/track/?id=116125921"
   ```

   Some instances serve search but not track resolution (that was the trap
   with `samidy` before this fix — and why both checks matter).

4. **Remember the offline rule:** anything already in your Local Library plays
   with zero dependence on Monochrome, the backend, or the network. An outage
   only blocks *new* searches and downloads.

---

# Definition of Done

- [ ] `GET /v1/provider/status` shows at least one healthy instance
- [ ] `GET /v1/search?q=daylight` returns normalized track results
- [ ] A download job reaches `READY` and delivers a valid FLAC file
- [ ] The real codec / sample rate / bit depth are recorded (no invented labels)
- [ ] In the app: search → tap Play → download happens automatically → playback starts
- [ ] The track appears in Local Library and replays instantly without re-downloading
- [ ] Downloaded tracks play with the backend stopped (fully offline)
- [ ] Provider unit tests cover both the old and new response shapes
- [ ] DRM-protected or unavailable tracks fail with a clean error, never a crash

---

# Why This Keeps Your Original Design Intact

- The Flutter app changes **zero lines** — it only talks to your FastAPI
  contract (`/v1/search`, `/v1/downloads`, ...), which is unchanged.
- The Download Manager, validation, local storage, library, and player are
  untouched.
- All Monochrome churn stays where it belongs: inside
  `providers/monochrome/provider.py`. This is exactly what the provider
  abstraction was for.
