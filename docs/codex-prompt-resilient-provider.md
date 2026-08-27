# Codex Task — Restore search/discovery by making provider instances resilient

## Objective

The home page's discovery feed and normal search are both showing "source did not respond." This is NOT a UI bug and NOT a logic bug — it is a **provider outage**. The client's hardcoded Monochrome instance list is entirely dead right now. Restore the app by adding a resilient, health-aware instance layer so that (a) the app can use any working public instance and (b) a single dead instance never blanks search/discovery again. Do not just swap URLs — build the mechanism, wire it in, and prove it with tests.

## Already-diagnosed (do not re-diagnose, use as ground truth)

Live probe results (2026-08-27):

| Instance | Result |
|---|---|
| `https://monochrome-api.samidy.com/search/?s=circles` | HTTP 502 — `{"error":"All upstream API instances failed.","attempts":[...401, 401, timeout]}` |
| `https://lol.samidy.workers.dev/search/?s=circles` | HTTP 503 — "This service has been suspended by its owner." |
| `https://api.monochrome.tf/search/?s=circles` | HTTP 401 — unauthorized |

## Architecture facts (read first)

- The **Flutter client does not call the FastAPI backend.** It calls Monochrome directly. The only code path that matters for search/discovery is `client/lib/services/provider_search_service.dart`.
- `ProviderSearchService.instances` is a hardcoded `const` list. It already has a failover loop and a per-instance 45-second cooldown, but:
  - There is no periodic health check to learn which instances are live before a user-visible failure.
  - The cooldown is only set after a failed request, so on cold start the app always tries the first (dead) instance and only falls back after a timeout.
  - The list is compile-time constant; a working instance cannot be added without rebuilding.
- `DiscoveryService` (new) calls `ProviderSearchService.search` for many seed queries via `Future.wait`. When every query fails, it correctly throws and the UI shows "Discovery source did not respond." No change to that error handling is required; the fix is the source underneath.

## Requirements

### 1. Instance discovery + health probing
- Add a health-check capability to `ProviderSearchService` (or a new `ProviderInstanceRegistry` it owns):
  - Probe each configured instance with `GET {instance}/search/?s=test` (or a cheaper `GET {instance}/health` if you can confirm one exists — do not guess; use `/search/?s=test` as the reliable probe).
  - Treat HTTP 200 + JSON as healthy; 401/403/404/5xx/timeout/network-error as unhealthy.
  - Run an initial probe on first use and a lightweight periodic re-probe (e.g. every 60s) so recovered instances are promoted back.
  - Order search attempts by health: healthy instances first, then unprobed, then known-bad. Never fully remove a bad instance — keep it retryable.

### 2. Configurable instance list
- Move the instance list out of a compile-time `const` into a runtime-loadable list:
  - Default seed = the current list (all three), so behavior is unchanged if no override exists.
  - Allow overriding/adding instances via a local config file read at startup (e.g. `client/assets/provider_instances.json` or a file under application support). Read it, merge with defaults, de-dupe, and use it.
  - This means a working instance can be added later without a code change. Document the file format in a short comment or README note.

### 3. Fast, honest user feedback
- Keep the existing graceful error states. Do NOT change the "did not respond" copy.
- Add a small "source status" signal that reflects live health (healthy = chartreuse; degraded = amber; down = muted) in the `_SignalMark` widget. Derive it from the registry's current health, not from a per-request failure. This is a minor UI addition and must stay in the existing design language.

### 4. Tests (these must pass before you stop)
- Add/update unit tests under `client/test/` that mock `Dio` (or the service's HTTP boundary) and verify:
  - Healthy instances are ordered first.
  - A dead first instance does not prevent a healthy second instance from succeeding.
  - A recovered instance is promoted after a re-probe.
  - Config override instances merge with defaults and de-dupe.
  - `search()` returns results when at least one instance is healthy, and throws only when all are down.
- Add a lightweight integration-style probe script or test that, when run against the real network, reports each configured instance's status. It must be safe to run offline (report unknown, do not fail the suite because the internet is down).

### 5. Resolve-until-green loop
- Run `cd client && flutter analyze` — must be clean.
- Run `cd client && flutter test` — all tests must pass.
- Run the probe script/command against the live instances and paste the output in your final report.
- If no public instance is currently reachable, that is an external condition: the deliverable is the **resilient mechanism + tests + probe tooling**, not a magical working endpoint. Clearly state in the final report which instances are live and which are down, and explain exactly how to add a live instance via the config file.

## Constraints

- No new dependencies unless strictly necessary. Prefer `dio` (already present) for probing.
- Do not touch the FastAPI backend; it is out of scope for this path.
- Do not add fake/mock "popular" data. The source must remain real Monochrome search results.
- Follow existing Riverpod and service patterns. No unrelated refactors.

## Final report format

When done, report:
1. What you changed and why (files + summary).
2. Live probe output table (instance → HTTP status / reachable).
3. Test results (`flutter analyze`, `flutter test`).
4. If a live instance exists, confirm search + discovery now return tracks in a manual run. If none exists, say so plainly and give the exact config-file steps to add one.
