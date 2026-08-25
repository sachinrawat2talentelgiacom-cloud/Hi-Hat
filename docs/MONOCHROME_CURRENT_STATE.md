# Monochrome current state

Captured: 2026-08-25 (Asia/Calcutta)

- App/backend commit: repository has no `HEAD`; the working project is entirely untracked, so no checkpoint commit was created.
- Python: 3.12.10.
- FastAPI: 0.141.1.
- Flutter: installed project artifacts exist, but `flutter` is not available on the current shell `PATH`.
- Configured public instances: `https://monochrome-api.samidy.com`, then `https://api.monochrome.tf`.
- Known track: Closer — The Chainsmokers, TIDAL/Monochrome ID `63232677`, search label `LOSSLESS`.
- Backend resolution request: `GET {instance}/track/?id=63232677`.
- Live public-instance observations:
  - samidy search: HTTP 200 JSON, about 1497 ms; track: HTTP 403 JSON, about 355 ms.
  - api.monochrome.tf search: HTTP 503 HTML, about 558 ms; track: HTTP 503 HTML, about 333 ms.
- Normalized final error before this audit: `PROVIDER_ACCESS_DENIED`.
- Baseline before this audit: Ruff passed; 8 backend tests passed; search passed; acquisition failed.

No credentials, signed URLs, manifests, or media URLs are recorded here.
