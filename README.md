# Hi Hat

Hi Hat is a minimal lossless music player for Android and Windows. The Windows app runs as a single Flutter application: search, embedded browser acquisition, validation, the local library, playback, and optional DeepL lyrics translation do not require FastAPI or Python at runtime. Playback currently begins after a complete lossless file is downloaded, validated, and saved on the listening device.

## One-click Windows launch

Double-click `Start Hi Hat.cmd` in File Explorer. The launcher prepares Flutter dependencies and opens the Windows app. It does not start a backend console, Python process, or separate browser helper.

## Architecture

- `client/` - Flutter application and local Drift library.
- `backend/` - legacy/reference FastAPI implementation retained during migration; not used by the Windows runtime.
- `acquisition_helper/` - legacy/reference browser helper; not used by the Windows runtime.
- `docs/ARCHITECTURE.md` - boundaries, request flow, and failure behavior.
- `PRODUCT.md` - durable product requirements.

The Flutter application currently performs provider search directly and uses an embedded WebView2 surface for the provider's normal download flow. Provider browser state remains inside WebView2 and is not exported to application data.

## Backend setup

Requires Python 3.12+ and FFmpeg on `PATH`.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e ".[dev]"
Copy-Item .env.example .env
```

Replace the development token in `.env`, then start the service from the repository root:

```powershell
.\scripts\start-backend.ps1
```

Use `-Lan` only on a trusted network and allow the selected port through the host firewall. Configure the same backend URL and bearer token in the app's Settings screen.

## Flutter setup

The client is pinned to the Puro environment in `client/.puro.json`. Flutter 3.47.1 and Dart 3.13.1 were used for this build.

```powershell
cd client
puro flutter pub get
puro flutter run -d windows
# or
puro flutter build apk --debug
```

On Windows, Flutter plugins require Developer Mode (Settings > System > Advanced > For developers). Android builds require an Android SDK and a JDK; Android Studio's bundled JBR is suitable when `JAVA_HOME` and `PATH` are configured.

## Verification

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest -p no:cacheprovider -q
.\.venv\Scripts\python.exe -m ruff check --no-cache .

cd ..\client
puro flutter analyze
puro flutter test
```

## Download builds from GitHub

Every push starts the **Build APK and Windows app** workflow. Open the repository's **Actions** tab, select the newest successful run, and download either `Hi-Hat-Android-…` or `Hi-Hat-Windows-…` from its **Artifacts** section. GitHub keeps these test builds for 30 days. The Android artifact contains an installable APK; the Windows artifact contains the complete application folder, so keep its DLLs and `data` folder beside `hi_hat.exe`.

## Catalog and lyrics configuration

Hi Hat uses the configured Monochrome-compatible provider endpoints for song and album metadata. Optional direct TIDAL catalog access is compiled in only when application credentials are supplied at build time; no secret is stored in the repository:

```powershell
puro flutter build windows --release --dart-define=TIDAL_CLIENT_ID=<id> --dart-define=TIDAL_CLIENT_SECRET=<secret>
puro flutter build apk --release --dart-define=TIDAL_CLIENT_ID=<id> --dart-define=TIDAL_CLIENT_SECRET=<secret>
```

Without these values, search automatically uses the credential-free configured provider endpoints. Lyrics are fetched from [LRCLIB](https://lrclib.net/), attributed in the player, and successful responses are cached on-device. LRCLIB requires no API key. Lyrics translation uses DeepL in every packaged Android and Windows release through the repository Actions secret named `DEEPL_API_KEY`; release jobs now fail instead of publishing an installer when that shared configuration is absent. Local Windows runs use `HI_HAT_DEEPL_API_KEY` in the ignored `backend/.env` file, and the installer builder embeds that same value with `--dart-define`. The legacy Python backend does not need to run. DeepL advises against distributing credentials in client applications; use a server-side proxy before public distribution. Queue, volume, mute restoration, shuffle/repeat settings, related autoplay, and custom playlists use a versioned local preferences schema (`playback_state_v2` and `custom_playlists_v2`); the playlist loader imports the earlier `custom_playlists_v1` key when present.

## Safety boundary

Hi Hat does not bypass authentication, DRM, paywalls, CAPTCHAs, or other access controls. It rejects encrypted manifests and should be used only with files the user is permitted to access and download.
