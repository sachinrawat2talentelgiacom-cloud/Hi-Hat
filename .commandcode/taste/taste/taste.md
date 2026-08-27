# Taste
- Wants deliverables as step-by-step process documents written in Markdown (.md) files, not just chat answers. Confidence: 0.9
- Reports app issues/current state by sharing screenshots (pastes Windows file paths to image files) rather than long textual descriptions. Confidence: 0.7
- Maintains multiple Markdown spec/design docs for his own projects (e.g. spec, refined spec, project details, migration notes) before/while building software. Confidence: 0.9
- Works on Windows; user files under C:\Users\my and code under D:\Code. Confidence: 0.85
- Main project "Hi Hat" (D:\Code\Hi Hat): a lossless FLAC music player with a Python FastAPI backend (backend/) and a Flutter/Dart client (client/), integrating third-party music provider APIs (Monochrome/Lucida). Confidence: 0.85
- Wants home/front pages populated with content by default rather than an empty state; wants personalization via selecting favorite artists (then serving similar-type songs), with the selection persisted locally and auto-loaded on every launch so the user never sees an empty screen, and content shown as large visual cards (cover art plus title and artist). Confidence: 0.85
- Wants solution prompts to include tests and an iterative "resolve until solved" loop (keep fixing and re-running until it passes), not a single-shot fix. Confidence: 0.8
- Prefers the agent to implement solutions directly ("do it yourself") rather than only drafting a prompt for another model/CLI to execute. Confidence: 0.75
- Works alongside multiple AI models/CLI agents on the same codebase and wants edits to avoid conflicts with them (don't clobber concurrent work; check existing symbols/callers before touching files). Confidence: 0.7
