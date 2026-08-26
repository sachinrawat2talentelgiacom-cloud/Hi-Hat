# Hi Hat

Hi Hat is a minimal lossless music player for Android and Windows. The Windows app runs as a single Flutter application: search, embedded browser acquisition, validation, the local library, and playback do not require FastAPI or Python at runtime. Playback currently begins after a complete lossless file is downloaded, validated, and saved on the listening device.

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

## Safety boundary

Hi Hat does not bypass authentication, DRM, paywalls, CAPTCHAs, or other access controls. It rejects encrypted manifests and should be used only with files the user is permitted to access and download.
