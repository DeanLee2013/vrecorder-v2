# Feature #6 — Verification harness (XCUITest + DebugBridge)

> Gate-1 plan, revision 4. Status: **PLANNED** (Gate-2 audit reached the rule-47
> 3-round cap; round-3 items folded in here — `listening` URL param, file-scope
> DEBUG gating per rule 50 §7, full plist key templates, decoupling propagated.
> Proceeding to Gate 3; impl audits (Gate 4) catch any residual).
> **Estimated PR size**, per WI (separate PR each): WI-1 ~3 files / ~90 LOC
> (model fixture API + tests); WI-2 ~7 files (UITest target, a11y ids on 4 views,
> launch-mode wiring, smoke test) / ~160 LOC; WI-3 ~5 files (DebugBridge, plist
> restructure, app wiring, parser tests, lifecycle test) / ~200 LOC; WI-4 ~1 file
> + evidence / ~120 LOC. Medium feature, **4 WIs**.

## Revision history
- **r1** — initial plan. Gate-2 audit r1: 2 High + 4 Medium.
- **r2** — fixture API; UI-testing launch mode + InMemory store; Debug/Release
  `INFOPLIST_FILE` mechanism; lifecycle test; feature #2 matrix; 4-WI split.
  Gate-2 audit r2: 2 High + 3 Medium.
- **r3** — active-session fixture (`listening:` param) + observable MicButton a11y
  state so the lifecycle test isn't vacuous; **decoupled feature #2 VERIFIED** (WI-4
  is a harness smoke, not feature #2's Gate-5 — that needs real-Keychain + Release);
  DebugBridge end-to-end UI test; feature #6's own evidence file; `#6b → #7`
  (numeric ID) + correct `.claude/cron-prompts/verify.md` path; removed stale plist
  alternative wording. Gate-2 audit r3: 1 High + 4 Medium.
- **r4** — `listening=true` URL param + parser tests (the bridge couldn't reach the
  active fixture); fixtures in a `#if DEBUG` extension + file-scope-gated `.onOpenURL`
  (rule 50 §7); full plist key templates (copy generated plist as the base);
  feature-#2-VERIFIED decoupling propagated to WI-4 + Docs Sync; `#7`/path
  propagated. **Rule-47 3-round plan-audit cap reached → PLANNED; Gate 4 is the net.**

## Problem
The `.claude/cron-prompts/verify.md` workflow assumes a CU-free verification harness
(XCUITest + a `vrecorder-debug://` DebugBridge + a gesture fallback) that does NOT
exist in the repo. So the verify cron is permanently `blocked`, and shipped work
(feature #2 DONE-not-VERIFIED; bugs awaiting device verification) can't be
machine-verified at all. This builds the scriptable core of that harness so the
verify cron can flip at least the UI/state-driven targets.

## Scope
**In:** an XCUITest target; accessibility identifiers on the key UI; a UI-testing
launch mode (seeded `InMemoryAPIKeyStore`, bootstrap skipped) so tests don't touch
the real Keychain; a DEBUG-only `vrecorder-debug://` DebugBridge that drives
`LiveSessionModel` via a new named fixture API; XCUITests for the live-screen
smoke, the DebugBridge, and feature #2's API-key flow.
**Out:** real-mic / AirPods / interruption verification (inherently human-on-device
— bugs #1/#3/#5/#9 stay `awaiting-device-verification`). The idb/`sim-tap.sh`
gesture fallback + `docs/subsystems/sim-gesture-driver.md` are **split out as
feature #7** (XCUITest's native tap/typeText covers feature #6; idb is not
installed) — the `docs/features.md` #6 row and the reference in
`.claude/cron-prompts/verify.md` are reconciled to point at #7 for the gesture driver.
The demo simulator path is unaffected.

## Model fixture API (audit-r1 #1 — resolves the reset-contract gap)
`LiveSessionModel.pushA/pushB` are `internal` and there is no reset; injecting mid
-session would race the recognizer/demo tasks. Add ONE named, `@MainActor`
operation, unit-tested independently of the bridge:

- `func installFixture(a: [TranscriptLine], b: [TranscriptLine], listening: Bool = false)`
  — calls `stop()` first (tears down any live recognizer/demo work + bumps the
  session generation, so no in-flight task mutates the fixture), atomically
  replaces `partyA` / `partyB`, and when `listening == true` sets the model into a
  deterministic listening state **without a real recognizer** (sets the
  `listening` flag; no audio/STT). This gives the lifecycle test a real active
  session to background-stop (audit-r2 #1). `func resetTranscripts()` — empty state,
  not listening.
- **Observable listening state** (audit-r2 #1): `MicButton` already varies by
  `listening`; add `.accessibilityValue(listening ? "listening" : "idle")` (or an
  a11y id pair) so a UI test can assert the session stopped after backgrounding.
- **File-scope DEBUG gating** (rule 50 §7, audit-r3 #4): these are test seams, so
  they live in a `#if DEBUG` **extension** of `LiveSessionModel` in its own file
  (`LiveSessionModel+Fixtures.swift`) — file-scope gated, not compiled into
  Release. The matching tests are `#if DEBUG` too. Unit tests:
  `installFixtureStopsActiveSessionAndReplaces`, `installFixtureListeningSetsState`,
  `resetClears`.

## App-owns-AppEnvironment + UI-testing launch mode (audit-r1 #2, #4)
`AppEnvironment` constructs a real `KeychainAPIKeyStore` + DEBUG-bootstraps the
dev key; UI tests must NOT touch that (they'd clobber persistent sim credentials
and be order-dependent). And `RootView` owns `env` via `@State` specifically to
fix the scene-phase teardown bug (audit-G4r2 #2). Resolution:
- `AppEnvironment` gets `init(uiTesting: Bool)`: when true (or when
  `ProcessInfo…arguments.contains("-uiTesting")`), use a seeded
  `InMemoryAPIKeyStore` and SKIP `APIKeyBootstrap`. UI tests set the launch arg
  (and per-test seed via another arg, e.g. `-seedKey sk-…` / absent = unconfigured).
- `VRecorderApp` owns `@State private var env = AppEnvironment(uiTesting: …)` and
  injects it (plain `let`) into both `RootView` and the DebugBridge — preserving
  single-`@State` ownership (the teardown fix), just lifted one level.

## Surface area (file-by-file)
- **WI-1 (foundational) — model fixture API**
  - MODIFY `vrecorder/Models/LiveSessionModel.swift`: add `installFixture(a:b:)` +
    `resetTranscripts()` (see "Model fixture API"). NEW
    `vrecorderTests/LiveSessionFixtureTests.swift`.
- **WI-2 (behavioral) — XCUITest target + a11y ids + launch mode + smoke**
  - `project.yml`: NEW `vrecorderUITests` (type `bundle.ui-testing`, dep on
    `vrecorder` → supplies `TEST_TARGET_NAME`); add to the scheme's test action.
  - `AppEnvironment.init(uiTesting:)` + the launch-arg detection above; `VRecorderApp`
    + `RootView` take an injected `env`.
  - MODIFY `LiveScreen.swift`, `MicButton.swift`, `SettingsScreen.swift`,
    `APIKeyEntryView.swift`: namespaced `.accessibilityIdentifier` (`vr.live.mic`,
    `vr.live.gear`, `vr.settings.apiKeyRow`, `vr.apikey.field`, `vr.apikey.save`,
    `vr.apikey.clear`) — invisible metadata, explicitly outside rule 51.
  - NEW `vrecorderUITests/LiveScreenUITests.swift`: launch with `-uiTesting`, assert
    mic + gear exist.
- **WI-3 (behavioral) — DebugBridge + URL scheme + lifecycle test**
  - NEW `vrecorder/Debug/DebugBridge.swift` (`#if DEBUG` file scope):
    `@MainActor func handle(_ url: URL)` parses
    `vrecorder-debug://inject?a=…&b=…&listening=true` → `session.installFixture(a:
    b: listening:)` (the `listening` query item is strictly parsed: `true` →
    listening, else/absent → idle — covered by a parser test, audit-r3 #1);
    `…/reset` → `resetTranscripts()`; malformed → no-op. Synchronous on the main
    actor (no Sendable / detached task).
  - MODIFY `VRecorderApp.swift`: a single `#if DEBUG`-gated `.onOpenURL` modifier
    (file-scope conditional via a small DEBUG-only `View` extension, NOT an inline
    `#if` inside the closure — rule 50 §7, audit-r3 #4) calling
    `DebugBridge(env.session).handle($0)`.
  - **URL-scheme registration (audit-r1 #3):** set `GENERATE_INFOPLIST_FILE: NO`
    and provide explicit `vrecorder/Resources/Info-Debug.plist` (with the
    `CFBundleURLTypes` `vrecorder-debug` entry) and `Info-Release.plist` (without),
    selected via `settings.configs.Debug.INFOPLIST_FILE` /
    `settings.configs.Release.INFOPLIST_FILE`. **Because `GENERATE_INFOPLIST_FILE`
    is off, both plists must define the FULL set of normally-generated core keys**
    (audit-r3 #5): `CFBundleIdentifier`/`Name`/`Executable`/`PackageType`,
    `CFBundleShortVersionString` + `CFBundleVersion` (driven from the build
    settings via `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`), the nested
    `UILaunchScreen` + `UIApplicationSceneManifest` dictionaries, supported
    orientations, and the mic/speech `NS*UsageDescription` strings — not merely the
    `INFOPLIST_KEY_*` translations. **Concrete approach:** WI-3 first runs the
    current generated plist (`GENERATE_INFOPLIST_FILE: YES`) once, copies that
    `.app/Info.plist` as the `Info-Debug.plist`/`Info-Release.plist` starting
    template, then adds/removes the URL scheme. Release verification asserts the app
    installs AND reports the right version (not only URL-scheme absence).
  - NEW `vrecorderTests/DebugBridgeTests.swift` (`#if DEBUG`): URL parsing →
    fixture installed / reset / malformed no-op (drives a model directly, no UI).
  - NEW lifecycle regression: `vrecorderUITests/LifecycleUITests.swift` — inject a
    fixture, background+foreground the app, assert the session stopped (audit-r1 #4)
    — deterministic via the fixture, not a real recognizer.
- **WI-4 (final) — API-key UI smoke (harness demonstration) + feature #6 evidence**
  - NEW `vrecorderUITests/APIKeyEntryUITests.swift`: with `-uiTesting` + seeded
    InMemory store, drive the drivable UI behaviors — open sheet; valid key → 保存
    → 已配置; empty → 保存 disabled; 清除 (confirm) → 未配置; cancel leaves state.
  - **Does NOT flip feature #2 to VERIFIED** (audit-r2 #2): feature #2's acceptance
    needs a real-Keychain round-trip + visible failure handling + a Release pass —
    its own plan reserves these for Gate 5. This WI proves the *harness works*;
    feature #2's full VERIFIED is a **separate verification task** (note added to
    feature #2's row pointing at the harness as the now-available tool).
  - NEW `dev-docs/verification/feature-6-<date>.md` (audit-r2 #4): feature #6's own
    Gate-5 evidence — all UI suites green on the sim + the Debug/Release plist
    built-product assertion. feature #6 → VERIFIED on this.

## Prior art / project precedent / rejected alternatives
- **Precedent:** `LiveSessionModel.pushA/pushB` are already public seams (used by
  the demo simulator) — the DebugBridge reuses them, inventing no new state API.
  `#if DEBUG` file-scope gating is the established pattern (APIKeyBootstrap).
- **Industry:** XCUITest + accessibility identifiers + a debug URL scheme to drive
  deterministic UI state is the standard iOS UI-verification approach.
- **Rejected:** (a) idb/`sim-tap.sh` as the primary driver — XCUITest's native
  tap/typeText covers this feature; idb isn't installed; defer as optional. (b)
  Snapshot/pixel testing — brittle, and rule-51 governs visual design, not tests.
  (c) Driving the real recognizer in UI tests — non-deterministic; the DebugBridge
  injects fixtures instead.

## Work items (4 WIs, one PR each — rule 47, audit-r1 #6)
- **WI-1 (foundational)**: model fixture API + unit tests. No UI, no Release change.
- **WI-2 (behavioral)**: XCUITest target + a11y ids + UI-testing launch mode +
  live-screen smoke. Slice-verify: smoke UI test green on the sim.
- **WI-3 (behavioral)**: DebugBridge + Debug/Release plist restructure + app
  wiring + parser unit tests + background-stop lifecycle UI test. Slice-verify:
  `vrecorder-debug://inject` seeds the asserted transcript; built-product check
  that Debug `.app` Info.plist contains `vrecorder-debug` and Release does NOT.
- **WI-4 (final)**: feature #2 full-acceptance UI test → flips feature #2 to
  VERIFIED (complete matrix recorded). Completes feature #6.

## Test catalogue
- `vrecorderTests/LiveSessionFixtureTests.swift`:
  `installFixtureStopsActiveSessionAndReplaces`, `resetClears`.
- `vrecorderTests/DebugBridgeTests.swift` (`#if DEBUG`): `injectSeedsTranscript`,
  `injectListeningTrueSetsListening`, `injectListeningAbsentIsIdle`, `resetClears`,
  `malformedURLIsNoOp` (drives a model directly).
- `vrecorderUITests/LiveScreenUITests.swift`: `liveScreenShowsMicAndGear`.
- `vrecorderUITests/DebugBridgeUITests.swift` (audit-r2 #3): `openInjectURLRenders
  Transcript` — `XCUIApplication().open(URL("vrecorder-debug://inject?...")!)` then
  assert the seeded transcript text is on screen (validates URL delivery,
  `.onOpenURL`, shared-env identity, and rendering — which the parser unit tests
  can't).
- `vrecorderUITests/LifecycleUITests.swift`: `backgroundStopsActiveSession` —
  inject an `installFixture(..., listening: true)` fixture (via the debug URL),
  assert MicButton a11y value `listening`, background+foreground, assert `idle`.
- `vrecorderUITests/APIKeyEntryUITests.swift`: `enterKeyFlipsRowToConfigured`,
  `emptyInputKeepsSaveDisabled`, `clearKeyFlipsRowToUnconfigured`,
  `cancelLeavesRowUnchanged`.
- **Built-product assertion** (WI-3 verification step, in the PR description):
  `plutil`/`grep` the Debug vs Release `.app/Info.plist` for `vrecorder-debug`.

## Edge cases
- App not built for UI testing → XCUITest target launches its own host (handled by
  the target type).
- DebugBridge active only in DEBUG (Release ignores the URL scheme entirely).
- Malformed `vrecorder-debug://` URL → no-op, no crash.
- Sheet/keyboard timing in XCUITest → use `waitForExistence(timeout:)`, never bare
  sleeps.
- Simulator wedge (seen this session) → run UI tests through `scripts/run-tests.sh`
  (UDID-pinned, watchdog) on a clean sim.
- a11y identifiers must not collide → namespaced (`vr.live.mic`, `vr.settings.apiKeyRow`…).

## Acceptance criteria
1. `vrecorderUITests` target builds and runs via the scheme; smoke test green.
2. A `vrecorder-debug://inject` URL deterministically seeds an on-screen transcript
   (DEBUG); **built-product check**: Debug `.app/Info.plist` contains
   `vrecorder-debug`, Release does NOT.
3. UI tests run under `-uiTesting` with a seeded `InMemoryAPIKeyStore` (bootstrap
   skipped) — they never read/write the real Keychain and are order-independent.
4. The API-key UI smoke drives the drivable behaviors (enter/save/clear/cancel);
   it demonstrates the harness but does NOT flip feature #2 to VERIFIED (that needs
   feature #2's own real-Keychain + Release Gate-5).
5. The background-stop lifecycle still holds after lifting `env` to the App
   (deterministic UI test).
6. All UI tests run on the iPhone 17 Pro simulator through `run-tests.sh`.
7. No production behavior change; DebugBridge + the URL scheme are DEBUG-only.

## Scope reconciliation (audit-r1 #5, audit-r2 #5)
The `docs/features.md` #6 row and `.claude/cron-prompts/verify.md` reference an idb
`sim-tap.sh` gesture driver + `docs/subsystems/sim-gesture-driver.md`. This plan
EXCLUDES them (XCUITest's native tap/typeText covers feature #6; idb isn't
installed). On Gate-1 acceptance: file **feature #7 — idb gesture-driver fallback**
(numeric ID — tracker hooks recognize numbers only, not `#6b`) and edit the #6 row
to scope it to the XCUITest+DebugBridge core, so the tracker matches this plan. The
verify cron can use XCUITest once #6 lands; #7 adds gestures XCUITest can't express.

## Risks + mitigations
- **URL-scheme registration mechanism**: resolved — `GENERATE_INFOPLIST_FILE: NO`
  + explicit `Info-Debug.plist` (with `CFBundleURLTypes`) / `Info-Release.plist`
  (without), selected via `settings.configs.<config>.INFOPLIST_FILE`. Both plists
  carry the existing `INFOPLIST_KEY_*` values as real keys. (A `.xcconfig` or
  partial plist can't express/merge the nested `CFBundleURLTypes` — not used.)
- **App-owns-AppEnvironment refactor** could disturb the scene-phase teardown
  (audit-G4r2 #2 fix). Mitigation: keep `@State` ownership, just lift it one level
  (App → injected into RootView); a UI test asserts background still stops.
- **XCUITest flakiness**: bounded `waitForExistence`, no sleeps; UDID-pinned sim.

## Docs sync + version bump (rules 24 + 40)
- `docs/architecture.md`: note the DebugBridge + UITest target. `README.md`:
  Developer Tools / testing note. `docs/features.md`: row #6 PLANNED → IN PROGRESS
  → DONE → VERIFIED. feature #2 stays DONE here (its full VERIFIED is a separate real-Keychain + Release Gate-5, now unblocked by this harness).
- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.

## Backward compat
Additive + DEBUG-only. No schema, no Release behavior change. The
App-owns-AppEnvironment change is internal wiring.
