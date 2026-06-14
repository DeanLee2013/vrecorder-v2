# Audit Dimensions — vrecorder-v2 (iOS)

Used by the pre-push Codex gate (`scripts/git-hooks/pre-push`) and by periodic
sweeps. **Pattern grafted from vmark** (`claude-audit.yml`): rotate dimensions,
keep each run focused, cover the whole set over time. **Content rewritten for
iOS** — vmark's Tauri/React/Rust dimensions do not apply here.

> Pre-push runs read-only on the changed Swift files and picks the dimensions
> relevant to the diff. A periodic full sweep (manual or cron) can seed off a run
> id to pick 3 dimensions/run so the whole list is covered over a week.

## 1. Swift 6 strict concurrency
Actor isolation correct; no data races; `@MainActor` only where required; `Sendable`
conformances real (no `@unchecked Sendable` hiding a race); no `assumeIsolated`
outside narrow App-init contexts; cross-actor calls go through `await`.

## 2. Audio session lifecycle
All `AVAudioSession` config in one controller; interruptions (call/Siri/alarm) and
route changes (AirPods) pause/resume the pipeline; the session is **deactivated** on
stop (no other apps left ducked); permission-revoked mid-session handled.

## 3. Streaming pipeline semantics
partial→final correctness; partials are **replaceable not append-only**; cancellation
tears down the whole chain (no orphaned recognition tasks / network streams);
bounded buffering / backpressure (drop or coalesce, never grow unbounded).

## 4. Engine abstraction boundaries
ASR / translation / TTS sit behind protocols; concrete providers selected via a
capabilities object, never hard-coded at call sites; UI never calls a concrete
provider directly; capability differences (offline, language pairs, latency) declared.

## 5. SwiftData / persistence
All mutations through a single persistence actor; never pass `@Model` across actor
boundaries (value-type DTOs only); store directory ensured before container creation;
schema/version handled; retention/caps enforced.

## 6. Permission & error taxonomy
Mic vs speech-recognition denial distinguished (not collapsed to one); user-facing
errors distinguish offline / timeout / rate-limited / permission-denied /
provider-error — never mislabel a timeout as "offline".

## 7. Memory & lifecycle
No retain cycles in closures/Combine/`Task`; `[weak self]` where needed; observers /
continuations finished on teardown; long sessions don't leak.

## 8. Secrets & network safety
No API keys in source or logs (keys via Keychain / gitignored config); no key in
transcript/print; TLS endpoints only; request bodies don't log plaintext transcripts
beyond retention policy.

## 9. Concurrency hazards in tests / fixtures
Tests use recorded fixtures (never live mic); no bare `Task.sleep` for sync; no
order-dependent tests; `#if DEBUG` gating for test seams at file scope.

## 10. Rule & convention compliance
Files < ~300 lines; no bare `print()` in production (`Logger` instead); features
local (no cross-feature imports unless shared); no UI invented outside committed
designs (rule 51); doc-sync done when services/schema/notifications change.

## 11. Clean-clone integrity
Every file referenced by the Xcode project is git-tracked; no stray references in
`project.pbxproj` to untracked files (the rule-48 clean-clone-break class); generated
artifacts gitignored.
