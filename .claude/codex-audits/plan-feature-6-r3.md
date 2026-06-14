Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019ec6e6-6264-79c2-b961-3650f9bfc51e
--------
user
INDEPENDENT plan auditor, vrecorder-v2 (Swift 6 / SwiftUI / XCUITest, iOS 26). REVISION 3 of the feature-#6 plan (verification harness), addressing your round-2 findings: (1) active-session fixture (installFixture listening: param sets the model's listening flag without a real recognizer) + observable MicButton accessibilityValue so the lifecycle test asserts a real stop; (2) DECOUPLED — feature #6 no longer claims to flip feature #2 to VERIFIED (WI-4 is a harness smoke; feature #2's real-Keychain+Release Gate-5 stays separate); (3) added a DebugBridge end-to-end UI test (open the URL, assert rendered transcript); (4) added feature-6's own evidence file; (5) #6b renamed to numeric #7, verify.md path corrected; removed stale plist wording. Verify each is resolved and surface any NEW Critical/High/Medium. End with exactly 'VERDICT: BLOCK' if any Critical/High/Medium remains, else 'VERDICT: PASS'.

PLAN r3:
# Feature #6 — Verification harness (XCUITest + DebugBridge)

> Gate-1 plan, revision 3. Status: PLANNED after Gate-2 audit passes.
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
  alternative wording.

## Problem
The `cron-prompts/verify.md` workflow assumes a CU-free verification harness
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
feature #6b** (XCUITest's native tap/typeText covers feature #6; idb is not
installed) — the `docs/features.md` #6 row and the reference in
`cron-prompts/verify.md` are reconciled to point at #6b for the gesture driver.
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
- These are normal model methods (DEBUG callers only, but compile in all configs —
  no `#if DEBUG` on the model API, only on the bridge that calls them). Unit tests:
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
    `@MainActor func handle(_ url: URL)` parses `vrecorder-debug://inject?a=…&b=…`
    → `session.installFixture(...)`; `…/reset` → `resetTranscripts()`; malformed →
    no-op. Synchronous on the main actor (no Sendable / detached task).
  - MODIFY `VRecorderApp.swift`: `.onOpenURL { #if DEBUG; DebugBridge(env.session).handle($0); #endif }`.
  - **URL-scheme registration (audit-r1 #3):** set `GENERATE_INFOPLIST_FILE: NO`
    and provide explicit `vrecorder/Resources/Info-Debug.plist` (with the
    `CFBundleURLTypes` `vrecorder-debug` entry) and `Info-Release.plist` (without),
    selected via `settings.configs.Debug.INFOPLIST_FILE` /
    `settings.configs.Release.INFOPLIST_FILE`. Both plists carry the existing
    `INFOPLIST_KEY_*` values (mic/speech usage, orientation, etc.) as real keys.
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
  `resetClears`, `malformedURLIsNoOp` (drives a model directly).
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
  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.

## Backward compat
Additive + DEBUG-only. No schema, no Release behavior change. The
App-owns-AppEnvironment change is internal wiring.
codex
I’ll audit revision 3 against the five claimed fixes and check the repository rules and current implementation for contradictions. I’ll start with `git status`, `docs/architecture.md`, the feature workflow/TDD rules, and the files this plan proposes to change.
exec
/bin/zsh -lc "git status -sb && printf '\\n-- files --\\n' && rg --files | sed -n '1,240p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
## feat/6-verification-harness
?? dev-docs/plans/20260615-feature-6-verification-harness.md

-- files --
CLAUDE.md
vrecorderTests/LiveSessionModelTests.swift
vrecorderTests/PipelineFlowTests.swift
vrecorderTests/OpenAITranslationEngineTests.swift
vrecorderTests/APIKeyEntryModelTests.swift
vrecorderTests/RecognitionEventCoalescerTests.swift
vrecorderTests/AudioSessionControllerTests.swift
vrecorderTests/AudioTapBridgeTests.swift
vrecorderTests/KeychainAPIKeyStoreTests.swift
vrecorderTests/PCMRolloverTests.swift
vrecorderTests/OpenAIStatusMappingTests.swift
AGENTS.md
scripts/run-codex.sh
scripts/run-tests.sh
scripts/git-hooks/pre-push
scripts/git-hooks/install.sh
README.md
dev-docs/audit/DIMENSIONS-ios.md
dev-docs/verification/bug-5-20260615.md
dev-docs/verification/bug-3-20260614.md
dev-docs/verification/bug-1-20260614.md
dev-docs/verification/SCHEMA.md
dev-docs/verification/bug-2-20260615.md
dev-docs/verification/feature-2-20260614.md
dev-docs/decisions/ADR-001-mvp-scaffold-audit-bypass.md
dev-docs/decisions/README.md
dev-docs/plans/20260615-feature-6-verification-harness.md
dev-docs/plans/20260614-feature-2-api-key-entry.md
dev-docs/无人值守开发-启动教程-vrecorder-v2.html
dev-docs/designs/api-key-entry/api-key-entry.html
dev-docs/designs/api-key-entry/README.md
dev-docs/无人值守开发-goal与cron辨析.html
dev-docs/冷启动手册-小白版-从初始化到无人值守.html
docs/features.md
docs/tasks.md
docs/bugs.md
docs/architecture.md
project.yml
config/README.md
vrecorder/Views/LiveScreen.swift
vrecorder/Views/APIKeyEntryView.swift
vrecorder/Views/Components/MicButton.swift
vrecorder/Views/Components/LiveBadge.swift
vrecorder/Views/Components/WaterSurface.swift
vrecorder/Views/Components/TranscriptLineView.swift
vrecorder/Views/SettingsScreen.swift
vrecorder/Engines/AppleSpeechRecognizer.swift
vrecorder/Engines/StreamingEvents.swift
vrecorder/Engines/RecognitionEventCoalescer.swift
vrecorder/Engines/OpenAITranslationEngine.swift
vrecorder/Engines/EngineProtocols.swift
vrecorder/Audio/AudioSessionController.swift
vrecorder/Audio/PCMRollover.swift
vrecorder/Audio/AudioTapBridge.swift
vrecorder/Models/LiveSessionModel.swift
vrecorder/Models/TranscriptLine.swift
vrecorder/Resources/Assets.xcassets/Contents.json
vrecorder/Resources/Assets.xcassets/AccentColor.colorset/Contents.json
vrecorder/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
vrecorder/Security/APIKeyBootstrap.swift
vrecorder/Security/APIKeyStore.swift
vrecorder/Security/APIKeyEntryModel.swift
vrecorder/App/AppEnvironment.swift
vrecorder/App/VRecorderApp.swift
vrecorder/App/RootView.swift
vrecorder/App/Log.swift
vrecorder/DesignSystem/Palette.swift
vrecorder/DesignSystem/Typography.swift
design/mvp.html
design/tokens/motion.css
design/tokens/effects.css
design/tokens/colors.css
design/tokens/spacing.css
design/tokens/typography.css
design/components/water-surface.jsx
design/components/live-badge.jsx
design/components/transcript-line.jsx
design/components/switch.jsx
design/components/icon-button.jsx
design/components/mic-button.jsx
design/README.md
design/settings-screen.jsx
design/live-screen.jsx
design/_ds_bundle.js
design/styles.css
vrecorder.xcodeproj/xcshareddata/xcschemes/vrecorder.xcscheme
vrecorder.xcodeproj/project.pbxproj

codex
The working tree contains only the untracked plan artifact, so I can assess it without conflating implementation changes. I’m now checking the plan text against the binding workflow, tracker wording, app lifecycle ownership, URL handling, and test-runner capabilities.
exec
/bin/zsh -lc "sed -n '1,280p' docs/features.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
# Feature Tracker

Track features to be implemented here. Must be planned before implementation.

## Rules

> **Binding for this file.** The rules, statuses, and plan template below govern every change made to `docs/features.md`. AGENTS.md treats them as the authoritative feature-tracker workflow.

- **Bugs vs features**: If something was implemented but doesn't work correctly, it is a **bug** — track it in `docs/bugs.md`. If something was never implemented, it is a **feature** — track it here. Never mix them.
- **Partial implementations**: If something is partially implemented, the broken part is a bug in `docs/bugs.md`; the missing capability is a feature here. Link them.
- **Cross-links**: When a bug fix resolves a feature, update the feature status to `DONE` with note `Resolved by bug #N`. When a feature depends on a bug fix, use `TODO` status with note `Blocked by bug #N`.
- **Plan before implementation**: Every feature must be planned before any code is written. Status must reach `PLANNED` before moving to `IN PROGRESS`. A plan requires the fields listed in the "Plan Template" section below.
- **Exception — resolved by bug fix**: If a bug fix incidentally delivers a feature, the feature may be set to `DONE` with `Resolved by bug #N` without a full plan.

## How to use

1. Add features as you identify them (fill in Summary and Area at minimum)
2. Plan the feature (fill in required plan fields) → set status to `PLANNED`
3. Tell the agent: "implement feature #N" to start implementation
4. Agent updates Status when done

- **GitHub Issue closure** (post-merge finalizer — see `AGENTS.md` for full policy):
  - If the feature has a `GH: #N` in Notes, close the GitHub Issue only after:
    1. All acceptance criteria met and status is VERIFIED in this file.
    2. Implementation is merged to `main`.
    3. Closure comment posted with commit SHA and acceptance result.
  - Partial delivery: keep GitHub Issue open; use checklist or split follow-ups.
  - PRs use `Refs #N`, not `Fixes #N` (prevents premature auto-close).

## Statuses

- `TODO` — not started
- `PLANNED` — plan complete (problem, scope, edge cases, tests, acceptance criteria), ready to implement
- `IN PROGRESS` — being worked on
- `DONE` — implemented; correctness not yet verified end-to-end
- `VERIFIED` — covered by an automated end-to-end test or an explicit on-device manual verification log
- `DEFERRED` — postponed to a later milestone
- `WONT DO` — out of scope or rejected

## Plan Template

Before setting a feature to `PLANNED`, fill in these fields in a sub-section under the feature table (e.g., `### Feature #1 — Plan`):

- **Problem**: What user need does this address?
- **Scope**: What is included and excluded?
- **Edge cases**: Empty input, nil, boundary values, concurrent access, audio-session interruptions, network failures, language-pair specifics.
- **Test plan**: What tests will verify the feature?
- **Acceptance criteria**: How do we know it's done?

## Features

| #   | Summary | Area | Priority | Status | Notes |
| --- | ------- | ---- | -------- | ------ | ----- |
| 1   | MVP 同传管线骨架（同传屏/设置屏 + 本地STT + OpenAI翻译 + Keychain key） | pipeline/ui | High | DONE | Scaffold, retro-registered outside gates 1-2 (course demo). Mirror: no. Pipeline-translate leg verified against live OpenAI; on-device STT needs device verify (Gate 5 deferred). Pre-push Codex audit (prepush-25e2320) found 6H+2M; fixes #3-8 + #1 applied (see Notes). |
| 2   | Release 内 API 密钥录入页（Keychain 编辑器） | ui/settings | Medium | DONE | Shipped in v0.2.0 (PR #2, merge `1d3644d`). 4 plan-audit + 2 impl-audit rounds. Design bundle `dev-docs/designs/api-key-entry/` (owner-authorized). 31 tests. NOT yet VERIFIED — interactive tap flow needs a manual device pass (evidence `feature-2-20260614.md`, result: partial). Mirror: no. |
| 3   | 打断后自动暂停/恢复（来电/Siri/AirPods 后续传） | audio/pipeline | Low | TODO | From audit-3 #5 (Medium, non-blocking): 当前打断即 stop()，需重新点麦克风。理想是 paused 态保留观察、interruption-ended `shouldResume` 时自动恢复。演示影响小。Mirror: no. |
| 4   | 专用 VAD/分段阶段（无间隙轮转，连续传译鲁棒分句） | audio/pipeline | Medium | TODO | From bug-#1 audits: PCMRollover mitigates the common rotation gap but a long gap during sustained speech can still truncate. Robust fix = a dedicated VAD/segmentation stage that rotates recognition with no gap; ALSO owns the demand-aware bounded streaming pump (bug #2 residual: output stream + finals array not yet backpressured). Needs Gate-1 plan. Mirror: no. |
| 5   | 仅转写模式（不翻译，只上屏转写） | settings/pipeline | Low | TODO | Settings toggle exists (designed) but is a no-op; wire into LiveSessionModel to bypass translation. Disable the toggle until implemented. GH: #10. Mirror: no. |
| 6   | 验证 harness（XCUITest + DebugBridge + sim-gesture 驱动） | tooling/test | High | TODO | cron verify.md 假设的 harness（XCUITest target / vrecorder-debug:// DebugBridge / scripts/sim-tap.sh / sim-gesture-driver 文档）都不存在，导致 verify cron 全 blocked。建之以解锁 UI/可脚本化验证；音频真机验证仍需人工。GH issue filed. Mirror: no. |

### Feature #1 — Notes (retro)

Built as the initial environment/scaffold, not through the formal 6-gate flow
(no Gate-1 plan / Gate-2 plan audit — code preceded planning here, recorded
honestly). What exists:

- **Design-faithful UI**: LiveScreen (ink/violet split, water surface, mic
  button), SettingsScreen (light grouped list). From `design/`.
- **Engine abstraction**: `SpeechRecognizing` / `TranslationEngine` protocols;
  `AppleSpeechRecognizer` (on-device) + `OpenAITranslationEngine` (cloud).
- **Pipeline**: mic → 中文 partial/final → per-final OpenAI translate → English
  panel; demo simulator fallback (no network).
- **Secrets**: Keychain store, DEBUG-seeded from `config/openai-key.txt`.

Verification done: 11 unit tests green; live OpenAI translation confirmed
(`重庆火锅…` → English). **Outstanding (future gate 5)**: on-device mic STT
end-to-end on a real device; settings persistence + TTS (Stage 3) tracked as
new features that WILL go through gates 1-6.

**Audit fixes (pre-push Codex `prepush-25e2320`, 6 High + 2 Medium):**
- #1 continuous interpretation — recognizer now rotates recognition segments on
  each final instead of stopping; one session handles many utterances.
- #3 session-generation token invalidates stale async paths on stop/restart.
- #4 translation tasks owned, cancelled on stop, committed in source order.
- #5 `AudioSessionController` exposes interruption/route events; session stops on
  interruption-began / route loss (resume requires an explicit re-tap).
- #6 teardown always deactivates `AVAudioSession` (no leftover ducking).
- #7 recognition errors finish the stream with a mapped `PipelineError`.
- #8 mic vs speech-recognition denial are distinct errors + messages.
- #2 → split out as **feature #2** (Release key-entry UI, BLOCKED: needs-design).
  The Settings row now reflects real Keychain state instead of hardcoding "已配置".

**Audit rounds 2–4** (artifacts `prepush-1f8798f / 6211616 / f62e8fa`): a further
~15 findings fixed — sequential bounded translation queue, error finishes the
stream exactly once, protocol-typed engines (deterministic pipeline tests),
partial-id in-place transition, AudioTapBridge thread-safe VAD with
duration-based silence + atomic request handoff, on-device recognition enforced,
Release key resource excluded from the bundle, scenePhase background stop,
distinct recognition error. **Residual:** Release key-entry UI (feature #2,
design-blocked, rule 51) keeps the gate from PASS, so the scaffold ships via
documented `--no-verify` bypass — see **ADR-001**. Mediums (route
`.newDeviceAvailable`, bounded partial ingress) + feature #3 tracked, non-blocking.

exec
/bin/zsh -lc "sed -n '1,260p' docs/architecture.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
# vrecorder-v2 Architecture

> Fact source. AGENTS.md requires every agent to read this before changing code.
> Update it in the SAME PR whenever layers, services, schema, or notifications change
> (rule 24). Stale-but-passing doc text is worse than none.

## System diagram

```
LiveScreen / SettingsScreen (SwiftUI)
   │
   ▼
LiveSessionModel (@MainActor @Observable)   ← composition root: AppEnvironment
   │            │
   │            ├── SpeechRecognizing  → AppleSpeechRecognizer (SFSpeechRecognizer + AVAudioEngine)
   │            ├── TranslationEngine  → OpenAITranslationEngine (Chat Completions)
   │            └── AudioSessionController (single AVAudioSession owner)
   │
   ▼
TranscriptLine[]  (partial → final → history, max 3/panel)

API key: KeychainAPIKeyStore (DEBUG seed from bundled config/openai.key)
```

Pipeline (MVP): mic → on-device 中文 STT (partial/final) → per-final OpenAI
translate 中文→English → push English final to the counterpart panel. When no
engines are injected, LiveSessionModel runs a built-in demo simulator (no
network) for course demos / offline fallback.

## Layers

| Layer | May import | Notes |
|-------|-----------|-------|
| Views (SwiftUI) | ViewModels, DesignSystem | no business logic |
| ViewModels | services, engines (protocols) | `@MainActor @Observable` |
| Services / pipeline actors | other services, AVFoundation, Speech | actor-isolated |
| Persistence | SwiftData | single actor owns all mutations |

## Services

| Name | Purpose |
|------|---------|
| `AppEnvironment` | Composition root — builds the session model with concrete engines + Keychain store |
| `LiveSessionModel` | `@MainActor @Observable` session state machine; runs the STT→translate→display pipeline (or demo simulator) |
| `AppleSpeechRecognizer` | On-device `SpeechRecognizing` (SFSpeechRecognizer + AVAudioEngine), emits partial/final |
| `OpenAITranslationEngine` | `TranslationEngine` over OpenAI Chat Completions; pure request/parse helpers are unit-tested |
| `AudioSessionController` | Single owner of `AVAudioSession` config + interruption handling |
| `KeychainAPIKeyStore` | `APIKeyStoring` over the Keychain (atomic update→add via injectable `KeychainOps`); DEBUG-seeded from bundled `config/openai-key.txt` |
| `APIKeyEntryModel` | `@MainActor @Observable` view-model for the Settings → API-key sheet; format-agnostic validation + masking, atomic save/clear over `APIKeyStoring` |

## Key design patterns

- **Engine-behind-protocol**: `SpeechRecognizing` / `TranslationEngine` so providers
  (Apple on-device, OpenAI cloud) are swappable and mockable; capabilities are
  declared, not hard-coded at call sites.
- **Replaceable partials**: a `.partial` line is replaced in place; `.final` freezes
  it; older lines demote to `.history` (max 3 per panel).
- **Single audio-session owner**: only `AudioSessionController` touches `AVAudioSession`.
- **VAD segment rotation with rollover**: `AudioTapBridge` does RMS silence
  detection and `endAudio()`s to segment utterances; audio captured during the
  request-rotation gap is held in a bounded `PCMRollover` and replayed into the
  next request so the next utterance's start isn't dropped (bug #3 fix).
- **Demo fallback**: `LiveSessionModel` with no injected engines runs a scripted
  partial→final sequence — zero network, for course demos.

## Data layer
_(SwiftData schema version + entities — fill in at M4)_

## Notification bus
_(name | payload | direction — add rows as cross-component events appear)_


exec
/bin/zsh -lc "sed -n '1,300p' .claude/rules/47-feature-workflow.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
# 47 — Feature Implementation Workflow

Binding sequence for every feature implementation. Six gates, never skip one.

> **Plan → Independent plan audit → TDD implementation → Implementation audit loop → Device/integration verification → Merge**

This is a **gate model**, not a chronological task list. Each gate has an explicit acceptance bar; you do not enter the next gate until the current gate's bar is met. Multiple iterations within a gate are normal.

## Gate 1 — Plan

Write `dev-docs/plans/YYYYMMDD-feature-N-<slug>.md` covering, at minimum:

- **Problem** — what user need this addresses (mirror or refine the row's `Problem` field).
- **Surface area** — file-by-file with concrete signatures (which protocols, types, methods get added or modified). Includes a "files OUT of scope" subsection.
- **Prior art / project precedent / rejected alternatives** — what existing patterns we're building on, what we considered and rejected, and why. **Research is part of the plan**, not a separate step.
- **Work-item sequencing** — small, testable units (typically 1-15 WIs). Each WI is one PR's worth of work. Estimated PR size per WI.
- **Test catalogue** — concrete test files, what each covers, including the audit-driven additions (corruption, partial failure, idempotency edge cases).
- **Risks + mitigations** — known unknowns and how we'll handle them.
- **Backward compat** — what happens to existing data / older clients / older backups when this ships.

The features.md "Plan Template" fields (Problem, Scope, Edge Cases, Test plan, Acceptance criteria) live in the row; the implementation-detail plan in `dev-docs/plans/` expands on them with file paths, signatures, and sequencing.

**Acceptance bar**: plan exists at the documented path; status moves to `PLANNED` only when this gate passes.

## Gate 2 — Independent Plan Audit

Send the plan to an independent AI auditor (not the same agent/model/context as the plan author). cc-suite (driving Codex via `codex exec`) is the current default; Gemini, OpenCode, or any equivalent satisfies the gate. The invariant is **independence**, not the brand.

Audit prompt must explicitly request:

- **Model assumption verification** — do the SwiftData fields, enum cases, function signatures, file paths I named actually exist? (This catches the largest class of pre-implementation bugs.)
- **Risks + missing edge cases** — what failure modes the plan misses.
- **Protocol signature critique** — are new interfaces well-shaped, or do they leak implementation concerns?
- **Concurrency hazards** — actor isolation, Sendable, race conditions in mutable state.
- **Cohesion check** — is the WI split right, or are some WIs too big or too small?

**Acceptance bar**:

- Zero open Critical/High/Medium findings.
- Low findings either fixed in the plan or explicitly accepted with rationale (in the plan's "Known limitations" or "Audit fixes applied" section).
- **Maximum 3 audit rounds**. If unresolved findings remain after round 3, stop and escalate to the user — accept, defer, or redesign.

Track audit rounds in the plan's revision history. The author rewrites the plan to address findings; the auditor re-reviews. Same loop until clean.

**Why this gate exists**: Codex audits routinely catch 5-10 real bugs per round on non-trivial plans (compile-breaking model assumptions, missing preconditions, protocol shape mistakes). Skipping the audit shifts that cost into wasted implementation work.

## Gate 3 — TDD Implementation

Per work item:

1. **RED** — write a failing test that captures the WI's behavior. See `.claude/rules/10-tdd.md` for pattern catalogue.
2. **GREEN** — write minimal implementation to make the test pass.
3. **REFACTOR** — clean up without changing behavior. Tests stay green.
4. **PR** — small, focused PR per WI. Apply per-PR rules: docs sync (`24-doc-sync.md`), version bump (`40-version-bump.md`).

Status: feature → `IN PROGRESS` when WI-1's PR opens.

**Acceptance bar per WI**: tests pass under `xcodebuild test -only-testing:vrecorderTests`; new code follows codebase conventions (`.claude/rules/50-codebase-conventions.md`).

## Gate 4 — Implementation Audit Loop

After implementation but before merge: independent audit of the changed files (read-only sandbox). This is what `/fix-issue` already runs.

Audit prompt focuses on:

- Correctness against the plan
- Edge cases in the diff (boundary conditions, nil, Unicode/CJK, concurrent access)
- Security (JS injection in evaluateJavaScript, WKWebView bridge safety, etc.)
- Duplicate / dead code introduced
- VRecorder compliance (Swift 6 concurrency, @MainActor correctness, file size <300 lines)
- Bridge safety (FoliateJSEscaper for JS interpolation, message parser edge cases)

**Acceptance bar**:

- Zero open Critical/High/Medium findings.
- Low findings fixed or explicitly accepted with rationale in the PR body.
- **Maximum 3 audit-fix rounds**. After round 3, escalate.

Same author/auditor separation as Gate 2.

## Gate 5 — Device / Integration Verification

For each PR before it merges:

- **Foundational WIs** (DTOs, protocols, utilities, pure types — no user-observable behavior): unit + integration tests + audit are sufficient. No device verification required.
- **Behavioral WIs** (anything that changes app behavior, persistence, networking, backup format, reader rendering, or UI flow): **slice verification** — exercise the slice end-to-end against the real environment available at this point. Run on iPhone 17 Pro Simulator with `vrecorder-debug://` harness; for backup/network features, against a real WebDAV server (or local Docker WebDAV equivalent); for reader features, with a fixture book.
- **Final WI** (the one that completes the feature): full end-to-end acceptance pass — every acceptance criterion exercised. This is what flips the feature row from `DONE` to `VERIFIED`.

Record slice verification in the PR description (what was run, what was observed). Record final acceptance verification in a structured evidence file at `dev-docs/verification/feature-<id>-<YYYYMMDD>.md` per the schema in `dev-docs/verification/SCHEMA.md`. The PreToolUse hook `.claude/hooks/check_terminal_status_evidence.sh` blocks any tracker edit that flips a row to `VERIFIED` (features) or `FIXED` (bugs) without a matching evidence file.

**Acceptance bar per PR**: every behavioral slice in the PR has been verified end-to-end at the level appropriate to its WI tier. Final WI requires full acceptance pass + evidence file.

**"Tooling unavailable" is NOT an acceptable deferral reason** unless a specific tool is named and confirmed missing (e.g., `xcrun simctl` returns "command not found", a real device is required and none is connected, the rclone WebDAV server is down). "I'll do it next session" is not a tool-unavailability claim — it's a discipline lapse. The Stop hook (`.claude/hooks/check_unfinished_verification.sh`) surfaces unverified `DONE` rows at session end so the gap doesn't quietly carry over.

## Gate 6 — Merge

PR may merge when ALL of the following hold:

- Tests pass (the merge gate from `AGENTS.md`).
- Implementation audit loop is clean (Gate 4).
- Device / integration verification is complete for the PR's tier (Gate 5).
- Docs sync completed if triggered (`.claude/rules/24-doc-sync.md`).
- Version bump committed as the last commit before opening the PR (`.claude/rules/40-version-bump.md`).
- For PRs that reference an open bug/feature: the referenced row has reached its terminal status (`FIXED` for bugs, `DONE` for features) — the existing fix-or-implement merge gate.

After merge:

- Feature status moves to `DONE` only after **all** WIs are merged AND every acceptance criterion is implemented.
- `VERIFIED` is a separate post-implementation status, set after Gate 5's final-WI acceptance pass lands and is recorded in the row. Requires a `dev-docs/verification/feature-<id>-<YYYYMMDD>.md` evidence file (PreToolUse hook enforces).
- GH issue closes per close-gate rule (closure comment cites the verification: commit SHA + what was tested + what was observed).

## Gate progress is recorded in the GH issue (binding)

The GH issue mirror is not just a creation-time pointer — it is the **running record** of the feature's path through the six gates. Once the issue exists (created at the Gate 2 → `PLANNED` flip), every gate transition posts a short, append-only comment so the issue reads as a verifiable timeline of the workflow. A reviewer who only sees GitHub can then audit gate compliance without cloning the repo.

Post one comment at each of these transitions:

| Transition | Comment records |
| --- | --- |
| Gate 2 passes (issue just created) | plan path + audit verdict (Codex threadId + rounds, or `manual-fallback`) + the WI list with foundational/behavioral tiers |
| Each WI's PR merges (Gate 6) | WI number + tier, PR number, version bumped to, merge-commit SHA, Gate 4 audit verdict, Gate 5a slice result |
| Final WI merges → row `DONE` | "shipped in vX.Y.Z (commit `<sha>`), awaiting verification" — this is the existing close-gate comment |
| Gate 5b acceptance pass → row `VERIFIED` | evidence-file path + `result:` + a one-line acceptance-criteria summary — this is the existing closure comment, posted just before `gh issue close` |

Rules for these comments:

- **Append-only, short, factual.** Paths, SHAs, verdicts, version numbers — not prose. One comment per transition; do not edit prior comments.
- **The markdown artifacts stay the source of truth.** The `dev-docs/plans/` plan, the `.claude/codex-audits/` logs, `docs/features.md`, and the `dev-docs/verification/` evidence file are authoritative. The issue comments are a timeline that *points at* them; never copy a plan's full contents into the issue.
- **A skipped comment is a gate-process lapse, not a hard-blocked one.** No hook enforces these (they are post-action `gh issue comment` calls), so the discipline is the gate. If a transition happened without its comment, back-fill it before the next transition.

The two bottom rows already exist in the close-gate / finalizer flow; this rule adds the Gate-2 and per-WI-merge rows so the *middle* of the workflow is visible on GitHub, not just its endpoints.

## Audit count by feature size

To keep the audit cost honest:

| Size   | WIs     | Plan audits             | PR audits                                                                               |
| ------ | ------- | ----------------------- | --------------------------------------------------------------------------------------- |
| Small  | 1 PR    | 1                       | 1                                                                                       |
| Medium | 2-4 WIs | 1                       | 1 per WI                                                                                |
| Large  | 5+ WIs  | 1+ rounds (until clean) | 1 per WI; mechanical low-risk WIs that share the same surface MAY batch under one audit |

If a feature is genuinely 10+ WIs, consider whether the plan should split into multiple features.

## Author / auditor separation (invariant)

The agent that writes the plan must NOT be the same agent that audits it. Today this happens by accident (cc-suite runs Codex as a separate `codex exec` process from the implementing Claude Code session). The rule preserves this invariant explicitly so a future single-agent setup doesn't degenerate into self-marking.

If a future setup runs everything through one agent, the audit step requires invoking a different model/context boundary explicitly (e.g., a fresh subagent with read-only sandbox + explicit "audit, don't implement" framing).

## Manual fallback when AI auditor unavailable

When Codex / Gemini / equivalent is unavailable (network, quota, outage), do the audit manually AND record evidence in the plan or PR. Required `Manual Audit Evidence` section:

- **Files read** (paths)
- **Symbols / signatures verified** (which fields/types/enums you confirmed exist)
- **Edge cases checked** (the list)
- **Risks accepted** (with rationale)
- **Tests added or intentionally deferred**

Manual fallback is allowed only when the independent audit tool is genuinely unavailable, not just inconvenient. The audit step is non-negotiable; manual fallback is an evidence-bearing alternative, not a way to skip.

## What this rule does NOT change

- TDD discipline (`10-tdd.md`) is unchanged.
- Per-PR Codex audit in `/fix-issue` skill is exactly Gate 4 — reference, don't duplicate.
- Merge gate (fix-or-implement) and close gate (verified, not just merged) are unchanged — this rule names where they fit in the workflow.
- Bug fix workflow (`docs/bugs.md` `## Rules`) is unchanged — bugs follow Understand → RED → GREEN → REFACTOR → Verify → Track. Bugs do NOT require a separate plan + plan audit (they're reactive); they do require the implementation audit loop and verification gates.

## Worked example

Feature #46 (WebDAV materializing restore, 11 WIs, High priority):

- **Gate 1 (Plan)**: `dev-docs/plans/20260503-feature-46-materializing-restore.md` — drafted v1.
- **Gate 2 (Plan audit)**: 2 Codex rounds. Round 1 found compile-breaking model assumptions (`Book.originalFilename` doesn't exist), missing `ImportSource.restore`, MOBI handling gap, idempotency hole in `BookImporter`, MOVE 501 silent fallback. Round 2 found `Book.fileExtension` also doesn't exist, weak `BackupBlobStore` signature, weak error shape. Plan v2 incorporates all findings.
- **Gate 3 (TDD impl)**: 11 WIs sequenced (WI-0a model migration, WI-0b enum case, WI-1 BlobPath, etc.). Each ships its own PR.
- **Gate 4 (Impl audit)**: per-PR via `/fix-issue` audit loop.
- **Gate 5 (Verification)**: WI-0a, WI-0b, WI-1, WI-2 = foundational, no device verify. WI-7 (provider integration) = slice verify against Docker WebDAV. WI-10 (UI) = device verify on simulator. Final WI = full acceptance pass (backup → wipe → restore with positions/annotations).
- **Gate 6 (Merge + close)**: each WI's PR merges through its own gate. Final WI moves feature row to `DONE`. After Gate 5 final acceptance pass: row → `VERIFIED`, GH #144 closes with citation.


exec
/bin/zsh -lc "sed -n '1,260p' .claude/rules/10-tdd.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
# 10 - TDD Workflow


> NOTE: Code examples below are inherited from the vreader reference project — apply the same TDD patterns to vrecorder domain types (SessionRecord, pipeline actors, engines).
Test-Driven Development for vrecorder. Tests live in `vrecorderTests/`. Run via `xcodebuild test`. Coverage thresholds are not currently gated structurally; discipline is the gate.

**vrecorder uses Swift Testing as the primary framework** (`import Testing`, `@Test`, `#expect`). XCTest is used only for tests that need `XCTestExpectation` (notification / async-callback timing) or `XCUnwrap`-style helpers — minority of tests, ~5% of the suite. New tests should default to Swift Testing unless they specifically need XCTest's expectation/notification machinery.

## Core Discipline: RED → GREEN → REFACTOR

1. **RED** — Write a failing test that describes the expected behavior.
2. **GREEN** — Write the minimum code to make the test pass.
3. **REFACTOR** — Clean up without changing behavior. Tests must still pass.

Never skip RED. If you write code first, you don't know your test actually catches regressions.

## When Tests Are Required

| Category          | Required?      | Examples                                                                  |
| ----------------- | -------------- | ------------------------------------------------------------------------- |
| Services / actors | **ALWAYS**     | `PersistenceActor`, `BookImporter`, `TXTService`, encoding detectors      |
| Pure utilities    | **ALWAYS**     | `DocumentFingerprint`, `Locator`, parsers, formatters                     |
| ViewModels        | **ALWAYS**     | State transitions, async flows, error paths                               |
| Bug fixes         | **ALWAYS**     | Regression test that fails on the pre-fix commit                          |
| Edge cases        | **ALWAYS**     | Empty input, nil, boundary values, Unicode/CJK, RTL, race conditions      |
| SwiftUI views     | Case-by-case   | Test behavior (callbacks, observable state), not pixel rendering          |
| Reader bridges    | Case-by-case   | Test message parsing, JS escaping, locator math — not WebView interaction |
| Pure data models  | If non-trivial | `BookRecord`, `HighlightRecord` — test invariants, not getters            |

## Pattern Catalog

The patterns below show XCTest first because vrecorder's actor/ViewModel/notification tests rely on `XCTestCase`-specific helpers (`XCTestExpectation`, `XCUnwrap`, async `setUp`, isolation pinning). For straightforward tests, prefer Swift Testing.

### 0. Swift Testing (default for new tests)

```swift
import Testing
@testable import vrecorder

@Suite("DocumentFingerprint")
struct DocumentFingerprintSuite {
    @Test func canonicalKeyRoundTrips() {
        let fp = DocumentFingerprint(contentSHA256: "abc...", fileByteCount: 1024, format: .epub)
        let parsed = DocumentFingerprint(canonicalKey: fp.canonicalKey)
        #expect(parsed == fp)
    }

    @Test(arguments: [
        ("hello world", 11),
        ("",            0),
        ("héllo",       6),  // 5 chars but 6 UTF-8 bytes
    ])
    func byteCountMatchesUTF8(_ input: String, _ expected: Int) {
        #expect(input.utf8.count == expected)
    }
}
```

**Use Swift Testing for:** pure functions, value types, parameterized tests, anything that doesn't need XCTest's async-callback machinery.

**Use XCTest (patterns 1-5 below) for:** actor tests with async setUp, MainActor-isolated ViewModels, notification observers needing `XCTestExpectation`, anywhere you need `XCUnwrap` over `#require`.

### 1. Actor / Service Tests

```swift
import XCTest
@testable import vrecorder

final class PersistenceActorTests: XCTestCase {
    private var container: ModelContainer!
    private var actor: PersistenceActor!

    override func setUp() async throws {
        let schema = Schema(SchemaV4.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        actor = PersistenceActor(modelContainer: container)
    }

    func test_insertBook_dedupesByFingerprintKey() async throws {
        let record = makeBookRecord(sha: String(repeating: "a", count: 64))
        let first = try await actor.insertBook(record)
        let second = try await actor.insertBook(record)
        XCTAssertEqual(first.fingerprintKey, second.fingerprintKey)
    }
}
```

**Key patterns:**

- In-memory `ModelContainer` for SwiftData isolation.
- `setUp() async throws` to construct dependencies.
- Test public actor methods directly — actors serialize, no manual locking.

### 2. ViewModel Tests

```swift
@MainActor
final class LibraryViewModelTests: XCTestCase {
    func test_deleteBook_removesFromBooksArray() async {
        let persistence = MockPersistence()
        let viewModel = LibraryViewModel(persistence: persistence, importer: ..., preferenceStore: ...)
        await viewModel.loadBooks()
        await viewModel.deleteBook(fingerprintKey: "key-1")
        XCTAssertFalse(viewModel.books.contains { $0.fingerprintKey == "key-1" })
    }
}
```

**Key patterns:**

- `@MainActor` on the test class for ViewModels marked `@MainActor`.
- Inject mocks via protocol parameters (`LibraryPersisting`, `BookImporting`).
- Assert on observable state, not internal helpers.

### 3. Pure-Function Tests

```swift
final class DocumentFingerprintTests: XCTestCase {
    func test_canonicalKey_roundTrips() {
        let fp = DocumentFingerprint(contentSHA256: "abc...", fileByteCount: 1024, format: .epub)
        let parsed = DocumentFingerprint(canonicalKey: fp.canonicalKey)
        XCTAssertEqual(parsed, fp)
    }
}
```

**Key patterns:**

- Pure functions = no setUp, no mocks.
- Use `XCTAssertEqual(_:_:_)` for `Equatable` types.
- Cover all branches in one test class via `func test_` methods.

### 4. Async / Concurrency Tests

```swift
@MainActor
func test_bridge_concurrentCalls_doNotInterleave() async {
    let bridge = MyBridge(...)
    async let a = bridge.handle(...)
    async let b = bridge.handle(...)
    _ = await (a, b)
    // assert ordering invariants on the recorded calls
}
```

**Key patterns:**

- `async let` for concurrent calls; `await (a, b, ...)` to join.
- For deterministic timing, use a clock probe pattern (see `DebugBridgeTests.SlowDebugBridgeContext`).
- Avoid `Task.sleep` for synchronization; use `XCTestExpectation` + `fulfillment(of:timeout:)`.

### 5. Notification / Bridge Tests

```swift
func test_handler_postsExpectedNotification() async {
    let exp = expectation(description: "notification posted")
    nonisolated(unsafe) var receivedKey: String?
    let token = NotificationCenter.default.addObserver(
        forName: .myNotification, object: nil, queue: .main
    ) { notification in
        receivedKey = notification.userInfo?["key"] as? String
        exp.fulfill()
    }
    defer { NotificationCenter.default.removeObserver(token) }

    handler.fire(key: "test-key")
    await fulfillment(of: [exp], timeout: 2.0)
    XCTAssertEqual(receivedKey, "test-key")
}
```

**Key patterns:**

- `XCTestExpectation` + `fulfillment(of:timeout:)` — never bare `sleep`.
- Always `removeObserver` in `defer`.
- `nonisolated(unsafe)` to capture into a notification closure that runs on a different queue.

## Anti-Patterns — What NOT to Do

| Anti-pattern                       | Why it's wrong                                 | Do this instead                                              |
| ---------------------------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| Write code first, tests after      | You can't verify your test catches regressions | RED first — always                                           |
| `func test_loadsWithoutCrashing()` | Tests nothing meaningful                       | Test specific observable behavior                            |
| Testing `private` implementation   | Breaks on refactor                             | Test public API only                                         |
| Mocking everything                 | Tests prove nothing                            | Mock boundaries (network, filesystem), not internal logic    |
| Skipping edge cases                | Bugs live at boundaries                        | Empty input, nil, max values, concurrent access, Unicode/CJK |
| Bare `Task.sleep(...)` for sync    | Flaky in CI                                    | `XCTestExpectation` with timeout                             |
| `XCTAssertNotNil(x); x!.foo()`     | Crashes on failure                             | `let x = try XCTUnwrap(opt); x.foo()`                        |
| Tests that depend on order         | Flaky                                          | Reset state in `setUp`; never share state across tests       |

## Test Commands

```bash
# Build then run unit tests only (skip UI tests during dev)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
    -project vrecorder.xcodeproj -scheme vrecorder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:vrecorderTests

# Single test class (faster iteration)
... -only-testing:vrecorderTests/MyClassTests

# Single test method
... -only-testing:vrecorderTests/MyClassTests/test_specificThing
```

The TDD Guardian config at `.claude/tdd-guardian/config.json` invokes the same `xcodebuild test` flow.

## File Placement

- Tests go next to the production code, mirroring the source tree:
  `vrecorder/Services/Foo/Bar.swift` → `vrecorderTests/Services/Foo/BarTests.swift`
- Larger test suites use a `__tests__` or feature subdirectory.
- Shared test helpers go in `vrecorderTests/Helpers/` (e.g., `CollectionTestHelper`).

## Exceptions to Mandatory TDD

These categories don't require tests:

- CSS/asset-only changes (don't apply to vrecorder, but listed for completeness)
- Documentation, config, comments
- Type-only changes with no runtime effect
- Pure file moves / renames

If unsure, write the test.

exec
/bin/zsh -lc "sed -n '1,240p' .claude/rules/24-doc-sync.md && sed -n '1,220p' .claude/rules/40-version-bump.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
# 24 - Architecture & README Sync

`docs/architecture.md` and `README.md` are checked-in claims about the codebase.
Every PR that changes the code must check whether those claims still hold and
update them in the same PR if not. Drift is a real problem here — the
architecture doc currently still says "SwiftData SchemaV3" even though the
schema migrated to V4 long ago, because nobody owned the line at the time.

## When to update `docs/architecture.md`

Update in the same PR whenever the code change touches any of:

| Trigger                                                 | What to update                                                    |
| ------------------------------------------------------- | ----------------------------------------------------------------- |
| New `@Model` entity or schema version                   | Data Layer section + the schema name in the system diagram        |
| New `Service` (singleton / actor / namespace)           | Services Layer table                                              |
| New `Coordinator` / `ViewModel` shared by ≥2 features   | Coordinator Layer table or Layers section                         |
| New SwiftUI `Environment` key threaded through views    | Note in Layers section + reference in App Layer if injected there |
| New `Notification.Name` on the cross-component bus      | Notification Bus table (name, payload, direction)                 |
| New `HighlightRenderer` adapter or other protocol impl  | Highlight System table or relevant pattern table                  |
| New top-level directory under `vrecorder/` or `Services/` | File Organization tree                                            |
| New design pattern shared across features               | Key Design Patterns section                                       |
| Performance optimization with cross-cutting impact      | Performance Optimizations table                                   |
| Existing stated fact becomes wrong                      | Fix it. Stale-but-passing doc text is worse than no doc text      |

You don't need to update for: pure bug fixes, edits inside a single existing
file, refactors that don't change the layer/file boundaries, test-only changes,
or new code paths that conform to an already-documented pattern.

## When to update `README.md`

Update in the same PR whenever:

| Trigger                                                    | What to update                                                  |
| ---------------------------------------------------------- | --------------------------------------------------------------- |
| User-visible feature lands or is removed                   | Features section (the right sub-bullet)                         |
| Tech stack change (rendering engine, persistence, etc.)    | Tech Stack table                                                |
| New requirement (Xcode version, iOS target, external dep)  | Requirements section                                            |
| Setup or run instructions change                           | Getting Started block                                           |
| New top-level directory worth highlighting                 | File Organization tree (it's a tree, not the full layout)       |
| Major design decision flips                                | Key Design Decisions bullets                                    |
| Feature or bug counts change meaningfully (≥5 new entries) | Status line at the bottom (`docs/features.md` / `docs/bugs.md`) |
| New developer tool / harness                               | Developer Tools section                                         |

You don't need to update for: minor bug fixes, internal refactors invisible to
the user, doc-only changes elsewhere, or unit test churn.

## Pre-PR self-check

As the last step before opening a PR, run a quick mental audit:

1. **Diff scan.** What did this PR add/remove that's mentioned in either doc?
2. **Claim scan.** For files I touched, do the doc's claims about them still hold?
3. **Cross-reference.** If I added a service/notification/pattern, did I also
   add it to the right table?

If a doc update is needed, it goes in the same PR as a separate commit
(`docs: update architecture.md for <change>` or similar), not as a follow-up.
The version bump tail commit (per `40-version-bump.md`) lands after the doc
update commit.

## Anti-patterns

- **"I'll update the doc later."** Later doesn't happen. The doc rots and the
  next agent inherits stale claims.
- **Updating the doc as the only commit in a separate PR.** Splits the change
  from its evidence; reviewers can't see what triggered the update.
- **Adding a service to the Services Layer table without describing its
  purpose.** A bare row is no better than missing — the table's value is the
  one-line "what does this do" column.
- **Bumping the feature count in README without updating ****`docs/features.md`****.**
  README's Status line cites the trackers; the trackers are authoritative.

## Not covered by this rule

This rule covers `docs/architecture.md` and `README.md` only. The live
trackers (`docs/bugs.md`, `docs/features.md`, `docs/tasks.md`) carry their
own workflow rules at the top of each file — those are binding for those
files and govern bug/feature/task lifecycle, not architecture/README claim
sync. AGENTS.md is the rule pointer.

## Rationale

`docs/architecture.md` is the first thing AGENTS.md tells every agent to read.
If it lies, every downstream decision starts from a wrong premise. README.md
is the first thing humans read on the GitHub page, and stale feature lists
make the project look abandoned even when active. The cost of a one-line edit
in the same PR is far below the cost of either kind of drift.
# 40 - Version Bump Procedure

vrecorder's version lives in `project.yml` (xcodegen) under `targets: vrecorder: settings: base:`. xcodegen regenerates `vrecorder.xcodeproj/project.pbxproj` from it; pbxproj is checked in but should not be hand-edited for a bump.

## When to bump

**Every PR must include a version bump.** The version line is owned by the PR
that ships the change, not by a separate release commit, so:

- **Bump before opening the PR** — bumping after the PR is open and rebasing
  conflicts with reviews.
- **Bump as the last step on the branch** — after the feature commits are in,
  not interleaved with them. A clean tail commit `chore: bump version to X.Y.Z`
  is easier to revert than a bump folded into a feature commit.
- **Choose increment by impact:**
  - `patch` — bug fix, docs, chores, refactors with no externally-visible change.
  - `minor` — new user-visible feature or capability.
  - `major` — breaking change to data, schema, or public contract.
- `CURRENT_PROJECT_VERSION` always increments by ≥1 — App Store Connect rejects
  uploads with a non-monotonic build number.

The post-merge tag (`git tag v{version}` on the merge commit) is cut by the
finalizer once the PR lands on `main`.

## Files to Update

| File          | Field                                                       |
| ------------- | ----------------------------------------------------------- |
| `project.yml` | `MARKETING_VERSION` (visible version, e.g. `0.1.0`)         |
| `project.yml` | `CURRENT_PROJECT_VERSION` (build number, monotonic integer) |

After editing `project.yml`, regenerate the Xcode project and commit BOTH:

```bash
# 1. Edit project.yml — change MARKETING_VERSION (and bump CURRENT_PROJECT_VERSION)
# 2. Regenerate
xcodegen generate

# 3. Confirm the regen actually changed pbxproj
git diff vrecorder.xcodeproj/project.pbxproj | grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION"
```

## Bump Procedure

1. \*\*Edit \*\***`project.yml`** — change `MARKETING_VERSION` to the new version. Bump `CURRENT_PROJECT_VERSION` too (always increasing — App Store requires a higher build number than any previously-uploaded build).

2. **Regenerate the Xcode project**:

   ```bash
   xcodegen generate
   ```

3. **Verify both files updated**:

   ```bash
   grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" project.yml
   grep -E "MARKETING_VERSION =|CURRENT_PROJECT_VERSION =" vrecorder.xcodeproj/project.pbxproj
   ```

4. **Build to confirm**:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
       -project vrecorder.xcodeproj -scheme vrecorder \
       -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   ```

5. **Commit** (single commit, both files together):

   ```bash
   git add project.yml vrecorder.xcodeproj/project.pbxproj
   git commit -m "chore: bump version to {version}"
   ```

6. **Tag and push** (only after commit lands on main):

   ```bash
   git tag v{version}
   git push origin main --tags
   ```

## Common Mistakes

- Editing `pbxproj` directly without updating `project.yml` — next `xcodegen` overwrites your change.
- Forgetting `CURRENT_PROJECT_VERSION` — App Store Connect rejects uploads with the same build number as a previous build.
- Tagging before the commit lands on `main` — orphan tag.

## Verification

After a bump, the App's About / TestFlight build number both should reflect the new `MARKETING_VERSION`. The build number from `CURRENT_PROJECT_VERSION` is shown in TestFlight's release lists.

exec
/bin/zsh -lc "sed -n '1,300p' .claude/cron-prompts/verify.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
First, log the fire: run `mkdir -p .claude/cron-logs && echo "$(date -Iseconds) verify FIRED" >> .claude/cron-logs/verify.log`. Then perform the task below. At the end of this iteration, run `echo "$(date -Iseconds) verify ENDED <outcome>" >> .claude/cron-logs/verify.log` where <outcome> is one of: work_done | no_work_in_scope | blocked | error.

Run the `/verify` skill with no explicit target. It auto-picks per its Pick order — the `awaiting-device-verification` GH-issue backlog first (Mode A, bug close-gate verification), then `DONE` features needing Gate-5 (Mode B, feature verification). The skill owns the whole verification workflow: both modes, the CU-free method (XCUITest + DebugBridge, with `scripts/sim-tap.sh` (idb) as the gesture fallback for taps/swipes the first two can't express — see `docs/subsystems/sim-gesture-driver.md`), the UDID-pinned simulator, the close gate, the scope guardrail, and the known harness gaps.

Map the skill's result to the ENDED outcome: `work_done` if it verified and closed or flipped at least one target; `no_work_in_scope` if nothing needed (or could be) verified this iteration; `blocked` if a required tool/harness was genuinely unavailable; `error` on failure.

Verification scope only — if the skill discovers a bug it FILES it (GH issue + `docs/bugs.md` row) but never fixes it; fixes are the bugfix cron's job.

exec
/bin/zsh -lc "sed -n '1,260p' vrecorder/App/AppEnvironment.swift" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
//  AppEnvironment.swift
//  Purpose: Composition root. Builds the live-session model with real engines
//  (on-device STT + OpenAI translation, Keychain-backed key) and seeds the key
//  from a bundled config/openai-key.txt on first DEBUG launch. This is the only
//  place concrete providers are chosen; everything downstream sees protocols.

import SwiftUI

@MainActor
final class AppEnvironment {
    let keyStore: APIKeyStoring
    let session: LiveSessionModel

    init() {
        let store = KeychainAPIKeyStore()
        APIKeyBootstrap.seedIfNeeded(store: store)
        self.keyStore = store

        let translator = OpenAITranslationEngine(keyProvider: { store.key(for: APIProvider.openAI) })
        self.session = LiveSessionModel(
            recognizer: AppleSpeechRecognizer(),
            translator: translator,
            audio: AudioSessionController()
        )
    }
}

exec
/bin/zsh -lc "sed -n '1,340p' vrecorder/Models/LiveSessionModel.swift" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
exec
/bin/zsh -lc "sed -n '1,260p' vrecorder/App/VRecorderApp.swift && sed -n '1,320p' vrecorder/App/RootView.swift" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
//  VRecorderApp.swift
//  Purpose: App entry point. Launches straight into the live-interpretation
//  screen (no onboarding for the MVP). design/README.md.

import SwiftUI

@main
struct VRecorderApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
//  RootView.swift
//  Purpose: Top-level navigation. Live IS the home screen; the gear pushes
//  Settings and the chevron returns (session state is retained). design/README.md.

import SwiftUI

struct RootView: View {
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase
    // @State so SwiftUI keeps ONE environment for this view's identity — a plain
    // stored property is rebuilt on each RootView init, which let scene-phase
    // teardown stop() a different session than the screen holds (audit-G4r2 #2).
    @State private var env = AppEnvironment()

    var body: some View {
        ZStack {
            // Color scheme is per-surface (audit-G4 #5): the live stage is dark,
            // Settings + its key-entry sheet are light — forcing dark globally gave
            // the light sheet low-contrast system chrome.
            LiveScreen(session: env.session, onSettings: { showSettings = true })
                .preferredColorScheme(.dark)

            if showSettings {
                SettingsScreen(onBack: { showSettings = false }, store: env.keyStore)
                    .preferredColorScheme(.light)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.42), value: showSettings)
        .onChange(of: scenePhase) { _, phase in
            // Don't leave the mic + audio session live in the background
            // (audit-4 #6) — tear down explicitly instead of relying on the OS.
            if phase == .background { env.session.stop() }
        }
    }
}

 succeeded in 0ms:
//  LiveSessionModel.swift
//  Purpose: Observable session state for the live-interpretation screen. Runs the
//  STT→translate→display pipeline (or a no-network demo simulator).
//  Correctness guards: a session-generation token invalidates stale async paths
//  on stop/restart (#3); translations run through ONE bounded sequential queue so
//  tasks don't accumulate and results commit in source order (#4, audit-2 High);
//  audio interruptions stop the session (#5); teardown always deactivates the
//  audio session (#6). Engines are referenced via protocols so they're mockable.
//  rules/50 §2-4.

import SwiftUI

@MainActor
@Observable
final class LiveSessionModel {
    private(set) var listening = false
    private(set) var partyA: [TranscriptLine]   // you (中文)
    private(set) var partyB: [TranscriptLine]   // counterpart (English)
    private(set) var errorMessage: String?

    private let maxLines = 3
    private let recognizer: (any SpeechRecognizing)?
    private let translator: (any TranslationEngine)?
    private let audio: AudioSessionController?

    /// Bumped on every start/stop; stale async work compares against it and bails.
    private var generation = 0
    private var sttTask: Task<Void, Never>?
    private var translationConsumer: Task<Void, Never>?
    private var finalsContinuation: AsyncStream<String>.Continuation?
    private var demoTask: Task<Void, Never>?

    private let sourceLocale = Locale(identifier: "zh-CN")
    private let targetLocale = Locale(identifier: "en-US")

    init(recognizer: (any SpeechRecognizing)? = nil,
         translator: (any TranslationEngine)? = nil,
         audio: AudioSessionController? = nil) {
        self.recognizer = recognizer
        self.translator = translator
        self.audio = audio
        partyA = [TranscriptLine(status: .history, text: "中国有很多美食。")]
        partyB = [TranscriptLine(status: .history, text: "There is a lot of delicious food in China.")]
    }

    private var hasPipeline: Bool { recognizer != nil && translator != nil }
    var showPrompt: Bool { listening && partyA.allSatisfy { $0.status == .history } }

    func toggle() { listening ? stop() : start() }
    func clearError() { errorMessage = nil }

    /// Authoritative teardown. Bumps generation so any in-flight async path bails,
    /// cancels owned tasks, closes the translation queue, releases the audio
    /// session. Safe to call repeatedly.
    func stop() {
        generation += 1
        listening = false
        recognizer?.stop()
        sttTask?.cancel(); sttTask = nil
        finalsContinuation?.finish(); finalsContinuation = nil
        translationConsumer?.cancel(); translationConsumer = nil
        demoTask?.cancel(); demoTask = nil
        audio?.deactivate()
    }

    // MARK: - Event ingestion

    /// Push a line into a panel. If the active (trailing) line is a partial, the
    /// incoming line continues that same segment — reuse its id so SwiftUI
    /// animates partial→final in place rather than as a remove/insert (audit Low).
    private func push(into lines: inout [TranscriptLine], _ line: TranscriptLine) {
        var incoming = line
        var kept = lines
        if let last = kept.last, last.status == .partial {
            incoming = TranscriptLine(id: last.id, status: line.status, text: line.text)
            kept.removeLast()
        }
        kept = kept.map { l -> TranscriptLine in
            var l = l; if l.status == .final { l.status = .history }; return l
        }
        if kept.count > maxLines - 1 { kept.removeFirst(kept.count - (maxLines - 1)) }
        kept.append(incoming)
        lines = kept
    }

    func pushA(_ line: TranscriptLine) { push(into: &partyA, line) }
    func pushB(_ line: TranscriptLine) { push(into: &partyB, line) }

    // MARK: - Real pipeline

    private func start() {
        errorMessage = nil
        guard hasPipeline, let recognizer else { startDemo(); return }
        generation += 1
        let gen = generation
        listening = true
        startTranslationQueue(gen: gen)
        audio?.onEvent = { [weak self] event in
            switch event {
            case .interruptionBegan, .routeLost, .routeChanged: self?.stop()
            case .interruptionEnded: break        // require an explicit re-tap to resume
            }
        }
        sttTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await recognizer.requestAuthorization()
                guard gen == self.generation, !Task.isCancelled else { return }
                try self.audio?.activate()
                guard gen == self.generation, !Task.isCancelled else { self.audio?.deactivate(); return }
                let stream = try recognizer.start(locale: self.sourceLocale)
                for try await event in stream {
                    guard gen == self.generation else { break }
                    self.handle(event)
                }
            } catch {
                self.fail(error, gen: gen)
            }
            if gen == self.generation { self.stop() }
        }
    }

    private func handle(_ event: TranscriptEvent) {
        switch event {
        case .partial(let t):
            pushA(.init(status: .partial, text: t))
        case .final(let t):
            pushA(.init(status: .final, text: t))
            finalsContinuation?.yield(t)          // enqueue for ordered translation
        }
    }

    /// One consumer translates finals sequentially (bounded — no task pile-up)
    /// and commits in source order.
    private func startTranslationQueue(gen: Int) {
        guard let translator else { return }
        // Bounded buffer: if translation falls behind speech, drop the oldest
        // pending finals deterministically rather than growing unboundedly
        // (audit-3 #3). A live interpreter values latest speech over backlog.
        let (stream, cont) = AsyncStream<String>.makeStream(bufferingPolicy: .bufferingNewest(8))
        finalsContinuation = cont
        translationConsumer = Task { [weak self] in
            for await chinese in stream {
                guard let self, gen == self.generation, !Task.isCancelled else { continue }
                do {
                    let english = try await translator.translate(chinese, from: self.sourceLocale, to: self.targetLocale)
                    guard gen == self.generation, !Task.isCancelled else { continue }
                    if !english.isEmpty { self.pushB(.init(status: .final, text: english)) }
                } catch {
                    guard gen == self.generation else { continue }
                    self.fail(error, gen: gen)
                }
            }
        }
    }

    private func fail(_ error: Error, gen: Int) {
        guard gen == generation else { return }
        errorMessage = Self.message(for: error)
        stop()
    }

    static func message(for error: Error) -> String {
        switch error {
        case PipelineError.offline:                return "网络不可用，请检查连接"
        case PipelineError.timeout:                return "翻译超时，请重试"
        case PipelineError.rateLimited:            return "请求过于频繁，请稍后再试"
        case PipelineError.micPermissionDenied:    return "需要麦克风权限，请在设置中开启"
        case PipelineError.speechPermissionDenied: return "需要语音识别权限，请在设置中开启"
        case PipelineError.missingAPIKey:          return "未配置 API 密钥"
        case PipelineError.invalidAPIKey:          return "API 密钥无效或已失效，请在设置中更新"
        case PipelineError.recognizerUnavailable:  return "当前语言的语音识别不可用"
        case PipelineError.recognitionFailed:      return "语音识别失败，请重试"
        case PipelineError.providerError(let m):   return "翻译服务错误：\(m)"
        default:                                   return "发生未知错误"
        }
    }

    // MARK: - Demo simulator (no network — course-demo fallback)

    private func startDemo() {
        generation += 1
        let gen = generation
        listening = true
        let steps: [(UInt64, Bool, TranscriptLine)] = [
            (500,  true,  .init(status: .partial, text: "重庆火锅很辣，但是…")),
            (500,  false, .init(status: .partial, text: "Chongqing hot pot is spicy, but…")),
            (1000, true,  .init(status: .final,   text: "重庆火锅很辣，但是很好吃！")),
            (600,  false, .init(status: .final,   text: "Chongqing hot pot is spicy, but delicious!")),
        ]
        demoTask = Task { [weak self] in
            for (ms, isA, line) in steps {
                do { try await Task.sleep(nanoseconds: ms * 1_000_000) }
                catch { return }                              // cancelled → stop mutating
                guard let self, gen == self.generation, !Task.isCancelled else { return }
                isA ? self.pushA(line) : self.pushB(line)
            }
            if let self, gen == self.generation { self.listening = false }
        }
    }
}

exec
/bin/zsh -lc "sed -n '1,320p' project.yml" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
exec
/bin/zsh -lc "sed -n '1,340p' scripts/run-tests.sh && sed -n '1,260p' dev-docs/verification/SCHEMA.md && sed -n '1,360p' dev-docs/plans/20260615-feature-6-verification-harness.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
exec
/bin/zsh -lc "sed -n '1,300p' vrecorder/Views/LiveScreen.swift && sed -n '1,260p' vrecorder/Views/Components/MicButton.swift && sed -n '1,340p' vrecorder/Views/SettingsScreen.swift && sed -n '1,340p' vrecorder/Views/APIKeyEntryView.swift" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
name: vrecorder
options:
  bundleIdPrefix: com.vrecorder
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true

settings:
  base:
    SWIFT_VERSION: "6.0"
    SWIFT_STRICT_CONCURRENCY: complete
    GENERATE_INFOPLIST_FILE: "YES"
    MARKETING_VERSION: "0.2.5"
    CURRENT_PROJECT_VERSION: "7"
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic

targets:
  vrecorder:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: vrecorder
      - path: config/openai-key.txt
        optional: true
        buildPhase: resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app
        MARKETING_VERSION: "0.2.5"
        CURRENT_PROJECT_VERSION: "7"
        GENERATE_INFOPLIST_FILE: "YES"
        INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: "YES"
        INFOPLIST_KEY_NSMicrophoneUsageDescription: "VRecorder 需要使用麦克风进行实时同声传译。"
        INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: "VRecorder 使用语音识别将你的发言实时转写为文字。"
        INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait"
        INFOPLIST_KEY_UIStatusBarStyle: UIStatusBarStyleLightContent
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1"
      configs:
        # Never ship the dev key resource in a distributable (Release) bundle —
        # it stays a DEBUG-only convenience (audit-3 #4). APIKeyBootstrap also
        # #if DEBUG-gates the read; this removes the file from the bundle too.
        Release:
          EXCLUDED_SOURCE_FILE_NAMES: "openai-key.txt"

  vrecorderTests:
    type: bundle.unit-test
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: vrecorderTests
    dependencies:
      - target: vrecorder
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app.tests

schemes:
  vrecorder:
    build:
      targets:
        vrecorder: all
        vrecorderTests: [test]
    test:
      targets:
        - vrecorderTests

 succeeded in 0ms:
#!/usr/bin/env bash
# scripts/run-tests.sh — bounded, watchdogged unit-test gate.
#
# Why (.claude/rules/52-test-sim-isolation.md): `xcodebuild test` can wedge at
# 0% CPU and ghost for hours (sim contention, or a wedged SWBBuildService build
# daemon after a kill -9). This wrapper turns an indefinite hang into a bounded,
# self-terminating run:
#   1. pins the destination by UDID (prefers iPhone 17 Pro, else booted, else any)
#   2. enforces a hard wall-clock timeout (default 900s) on the EXACT pid (rule 49)
#   3. on timeout kills the process tree AND clears the wedged build daemon
#      `SWBBuildService` (rule 52 Cause B) — a bare kill is a half-cleanup that
#      poisons the next run
#   4. prints ONE unambiguous final line:
#      RUN-TESTS RESULT: SUCCEEDED|FAILED|TIMEOUT|NO_BOOTED_SIM
#
# Usage:
#   scripts/run-tests.sh                          # default suite (vrecorderTests)
#   scripts/run-tests.sh vrecorderTests/FooTests  # one targeted suite (fast per-WI gate)
#   TIMEOUT_SECS=2400 scripts/run-tests.sh vrecorderTests   # full-suite periodic sweep
#   TEST_UDID=<udid> scripts/run-tests.sh         # specific simulator (true parallelism)
#
# NEVER pipe this through tail/grep/head (rule 52 #5): `tail -N` on a pipe buffers
# away the streaming markers AND the single RESULT line. Let stdout go straight to
# a file or the task-output; read the file after the RESULT line lands.
set -uo pipefail

PROJECT="vrecorder.xcodeproj"
SCHEME="vrecorder"
SUITE="${1:-vrecorderTests}"
TIMEOUT="${TIMEOUT_SECS:-900}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$(dirname "$0")/.." || { echo "RUN-TESTS RESULT: FAILED (cannot cd to project root)"; exit 1; }

# Resolve a simulator UDID. Pin by UDID to avoid name/OS-matching surprises.
# Order: explicit TEST_UDID > iPhone 17 Pro (project convention) > booted sim > any iPhone.
udid="${TEST_UDID:-}"
[ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone 17 Pro (' | grep -oE '[0-9A-F-]{36}' | head -1)"
[ -z "$udid" ] && udid="$(xcrun simctl list devices booted    2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1)"
[ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone' | grep -oE '[0-9A-F-]{36}' | head -1)"
if [ -z "$udid" ]; then
  echo "RUN-TESTS RESULT: NO_BOOTED_SIM (no usable iOS Simulator found — install a runtime)"
  exit 1
fi

# Clear a stale app instance that wedges the test-host launch with a "Busy
# (Application failed preflight checks)" error (recurring sim-state flake). No-op
# if the sim is shut down or the app isn't installed.
xcrun simctl terminate "$udid" com.vrecorder.app >/dev/null 2>&1 || true

echo "RUN-TESTS START: suite=$SUITE udid=$udid timeout=${TIMEOUT}s"

STATUS="$(mktemp)"; TIMED_OUT="$(mktemp -u)"
run() {
  xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" \
    -destination "id=$udid" \
    -only-testing:"$SUITE" 2>&1
  echo "$?" >"$STATUS"
}
run & RUN_PID=$!

# Watchdog on the EXACT pid; cancelled the instant the test finishes (never re-arms — rule 49).
( sleep "$TIMEOUT"
  if kill -0 "$RUN_PID" 2>/dev/null; then
    : >"$TIMED_OUT"
    pkill -TERM -P "$RUN_PID" 2>/dev/null; kill -TERM "$RUN_PID" 2>/dev/null
    sleep 3
    pkill -KILL -P "$RUN_PID" 2>/dev/null; kill -KILL "$RUN_PID" 2>/dev/null
    pkill -9 -x SWBBuildService 2>/dev/null   # rule 52 Cause B: clear the wedged daemon
  fi ) & WD=$!

wait "$RUN_PID" 2>/dev/null
kill "$WD" 2>/dev/null; wait "$WD" 2>/dev/null

RC="$(cat "$STATUS" 2>/dev/null || echo 1)"; rm -f "$STATUS"
echo
if [ -e "$TIMED_OUT" ]; then
  rm -f "$TIMED_OUT"
  echo "RUN-TESTS RESULT: TIMEOUT (${TIMEOUT}s) — killed process tree + SWBBuildService"
  exit 124
elif [ "$RC" = "0" ]; then
  echo "RUN-TESTS RESULT: SUCCEEDED"
  exit 0
else
  echo "RUN-TESTS RESULT: FAILED (xcodebuild rc=$RC)"
  exit 1
fi
# Verification Evidence Schema

Every flip of a tracker row to `VERIFIED` (features) or `FIXED` (bugs) requires a
matching evidence file here. The PreToolUse hook `check_terminal_status_evidence.sh`
blocks the flip if the file is missing. Verified ≠ merged.

- **Feature evidence**: `feature-<id>-<YYYYMMDD>.md`
- **Bug evidence**: `bug-<id>-<YYYYMMDD>.md`
- Same id verified more than once → distinguish by date; the hook reads the latest.

## Required frontmatter

```yaml
---
kind: feature | bug
id: 7
status_target: VERIFIED | FIXED
commit_sha: <40-hex of HEAD at verification time>
app_version: <MARKETING_VERSION (build CURRENT_PROJECT_VERSION)>
date: 2026-06-14
verifier: claude
device_or_simulator: "iPhone Air (device)" | "iPhone 17 Pro Simulator"
os_version: "iOS 26.x"
build_configuration: Debug | Release
backend: "real OpenAI gpt-realtime-translate" | "recorded-session replay" | "n/a"
result: pass | partial | fail
---
```

## Required sections

- `## Acceptance criteria` — table: each planned criterion → observed behavior → pass/fail
- `## Commands run` — the real shell/simctl/xcodebuild commands, reproducible
- `## Observations` — surprises, near-regressions, what's fragile next time
- `## Artifacts` — screenshot / log / .xcresult paths

## `result` semantics (decides whether the row may flip)

- `pass` — every criterion exercised end-to-end → may flip to VERIFIED/FIXED
- `partial` — some passed + explicit deferral → **must NOT** flip; stays DONE/awaiting
- `fail` — a regression → back to IN PROGRESS / REOPENED
# Feature #6 — Verification harness (XCUITest + DebugBridge)

> Gate-1 plan, revision 3. Status: PLANNED after Gate-2 audit passes.
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
  alternative wording.

## Problem
The `cron-prompts/verify.md` workflow assumes a CU-free verification harness
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
feature #6b** (XCUITest's native tap/typeText covers feature #6; idb is not
installed) — the `docs/features.md` #6 row and the reference in
`cron-prompts/verify.md` are reconciled to point at #6b for the gesture driver.
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
- These are normal model methods (DEBUG callers only, but compile in all configs —
  no `#if DEBUG` on the model API, only on the bridge that calls them). Unit tests:
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
    `@MainActor func handle(_ url: URL)` parses `vrecorder-debug://inject?a=…&b=…`
    → `session.installFixture(...)`; `…/reset` → `resetTranscripts()`; malformed →
    no-op. Synchronous on the main actor (no Sendable / detached task).
  - MODIFY `VRecorderApp.swift`: `.onOpenURL { #if DEBUG; DebugBridge(env.session).handle($0); #endif }`.
  - **URL-scheme registration (audit-r1 #3):** set `GENERATE_INFOPLIST_FILE: NO`
    and provide explicit `vrecorder/Resources/Info-Debug.plist` (with the
    `CFBundleURLTypes` `vrecorder-debug` entry) and `Info-Release.plist` (without),
    selected via `settings.configs.Debug.INFOPLIST_FILE` /
    `settings.configs.Release.INFOPLIST_FILE`. Both plists carry the existing
    `INFOPLIST_KEY_*` values (mic/speech usage, orientation, etc.) as real keys.
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
  `resetClears`, `malformedURLIsNoOp` (drives a model directly).
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
  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.

## Backward compat
Additive + DEBUG-only. No schema, no Release behavior change. The
App-owns-AppEnvironment change is internal wiring.

 succeeded in 0ms:
//  LiveScreen.swift
//  Purpose: Main screen — full-screen two-party split (ink top / violet bottom).
//  Mirrors design/live-screen.jsx. Stage-1 build is driven by LiveSessionModel's
//  demo simulator; the real pipeline plugs into the same model in Stage 2.

import SwiftUI

struct LiveScreen: View {
    @State private var session: LiveSessionModel
    let onSettings: () -> Void

    init(session: LiveSessionModel, onSettings: @escaping () -> Void) {
        _session = State(initialValue: session)
        self.onSettings = onSettings
    }

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                partyB
                partyA
            }
        }
        .background(VR.partyBSurface)
        .ignoresSafeArea()
        .alert("同传出错", isPresented: Binding(
            get: { session.errorMessage != nil },
            set: { if !$0 { session.clearError() } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(session.errorMessage ?? "")
        }
    }

    // MARK: Counterpart (ink, English)

    private var partyB: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("ENGLISH")
                    .font(.system(size: VR.FontSize.caption))
                    .tracking(VR.capsTracking)
                    .foregroundStyle(VR.partyBTextDim)
                ForEach(session.partyB) { TranscriptLineView(line: $0, party: .b) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            topBar
                .padding(.horizontal, 12)
                .padding(.top, 54)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var topBar: some View {
        HStack {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(VR.partyBTextDim)
                    .frame(width: 40, height: 40)
            }
            Spacer()
            LiveBadge().opacity(session.listening ? 1 : 0)
            Spacer()
            Button {} label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 20))
                    .foregroundStyle(VR.partyBTextDim)
                    .frame(width: 40, height: 40)
            }
        }
    }

    // MARK: You (violet "water", 中文)

    private var partyA: some View {
        ZStack(alignment: .top) {
            VR.partyASurface
            WaterSurface(listening: session.listening)
                .offset(y: -44)
                .frame(maxHeight: .infinity, alignment: .top)

            VStack(alignment: .leading, spacing: 8) {
                Text("中文 · 普通话")
                    .font(.system(size: VR.FontSize.caption))
                    .tracking(VR.capsTracking)
                    .foregroundStyle(VR.partyATextDim)
                if session.showPrompt {
                    Text("请开始说话吧")
                        .font(.system(size: VR.FontSize.partial))
                        .foregroundStyle(VR.partyATextDim)
                }
                ForEach(session.partyA) { TranscriptLineView(line: $0, party: .a) }

                Spacer()
                VStack(spacing: 10) {
                    MicButton(listening: session.listening) { session.toggle() }
                    Text("为保证同传效果，请靠近麦克风说话")
                        .font(.system(size: VR.FontSize.caption))
                        .foregroundStyle(VR.partyATextDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
//  MicButton.swift
//  Purpose: 64pt circular mic control. Idle = violet; listening = aqua with
//  glow + breathing pulse. design/README.md › LiveScreen. No spring overshoot.

import SwiftUI

struct MicButton: View {
    let listening: Bool
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(listening ? VR.aqua500 : VR.violet500)
                Image(systemName: "mic.fill")
                    .font(.system(size: 64 * 0.36, weight: .regular))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)
            .scaleEffect(listening && pulse ? 1.08 : 1.0)
            .shadow(color: listening ? VR.aqua500.opacity(0.30) : .black.opacity(0.25),
                    radius: listening ? 14 : 8, y: listening ? 0 : 4)
            .overlay(
                Circle().stroke(VR.aqua500.opacity(listening ? 0.16 : 0), lineWidth: 6)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        .onChange(of: listening) { _, on in pulse = on }
    }
}
//  SettingsScreen.swift
//  Purpose: Light-scope grouped settings list. Mirrors design/settings-screen.jsx.
//  Stage-1 build keeps choices in local @State; Stage 2 backs them with
//  UserDefaults + Keychain (API key). No real persistence yet.

import SwiftUI

struct SettingsScreen: View {
    let onBack: () -> Void
    private let store: any APIKeyStoring

    /// Reflects real Keychain state — refreshed when the key-entry sheet closes
    /// (single refresh path, audit-2 #3/#6). Never hardcode "已配置".
    @State private var keyConfigured: Bool
    @State private var showKeySheet = false

    // Only the OpenAI engine is wired today; don't offer a selection the app
    // can't honor (audit-4 #1). Re-add "Claude" when ClaudeTranslationEngine exists.
    @State private var engine = "OpenAI"
    @State private var stream = true
    @State private var autoSpeak = true
    @State private var speed = "1.0×"
    @State private var subSize = "标准"
    @State private var transcribeOnly = false

    /// Real marketing version from the bundle (audit-G4 Low: was hardcoded 1.0.0).
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    init(onBack: @escaping () -> Void, store: any APIKeyStoring) {
        self.onBack = onBack
        self.store = store
        _keyConfigured = State(initialValue: store.key(for: APIProvider.openAI) != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 24) {
                    group("翻译引擎") {
                        cycleRow("翻译服务", $engine, ["OpenAI"])
                        tapRow("API 密钥", value: keyConfigured ? "已配置" : "未配置") {
                            showKeySheet = true
                        }
                        toggleRow("流式翻译", $stream, last: true)
                    }
                    group("语音播报") {
                        toggleRow("自动播报译文", $autoSpeak)
                        cycleRow("语速", $speed, ["0.8×", "1.0×", "1.2×"], last: true)
                    }
                    group("同声传译") {
                        cycleRow("字幕字号", $subSize, ["标准", "大", "特大"])
                        toggleRow("仅转写模式", $transcribeOnly, last: true)
                    }
                    group("通用") {
                        navRow("历史记录", value: "保留 30 天")
                        destructiveRow("清空翻译记录")
                        navRow("关于", value: "版本 \(Self.appVersion)", last: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .padding(.bottom, 40)
            }
        }
        .background(VR.surfaceApp)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showKeySheet, onDismiss: {
            keyConfigured = store.key(for: APIProvider.openAI) != nil
        }) {
            APIKeyEntryView(store: store, onClose: { showKeySheet = false })
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(VR.accentLight)
            }
            Text("设置")
                .font(.system(size: VR.FontSize.title1, weight: .bold))
                .foregroundStyle(VR.textPrimaryLight)
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
        .padding(.bottom, 10)
    }

    // MARK: Rows

    @ViewBuilder
    private func group<C: View>(_ caption: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(.system(size: VR.FontSize.caption))
                .tracking(VR.capsTracking)
                .foregroundStyle(VR.textFaint)
                .padding(.horizontal, 16)
            VStack(spacing: 0) { content() }
                .background(VR.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
    }

    private func rowChrome<T: View>(_ last: Bool, @ViewBuilder _ content: () -> T) -> some View {
        VStack(spacing: 0) {
            content().frame(minHeight: 50).padding(.horizontal, 16)
            if !last { Divider().background(VR.hairlineLight).padding(.leading, 16) }
        }
    }

    private func navRow(_ label: String, value: String, last: Bool = false) -> some View {
        rowChrome(last) {
            HStack {
                Text(label).foregroundStyle(VR.textPrimaryLight)
                Spacer()
                Text(value).foregroundStyle(VR.textFaint)
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
            }.font(.system(size: VR.FontSize.body))
        }
    }

    private func tapRow(_ label: String, value: String, last: Bool = false, _ action: @escaping () -> Void) -> some View {
        rowChrome(last) {
            Button(action: action) {
                HStack {
                    Text(label).foregroundStyle(VR.textPrimaryLight)
                    Spacer()
                    Text(value).foregroundStyle(VR.textFaint)
                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
                }.font(.system(size: VR.FontSize.body)).contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }

    private func cycleRow(_ label: String, _ sel: Binding<String>, _ options: [String], last: Bool = false) -> some View {
        rowChrome(last) {
            Button {
                let i = options.firstIndex(of: sel.wrappedValue) ?? 0
                sel.wrappedValue = options[(i + 1) % options.count]
            } label: {
                HStack {
                    Text(label).foregroundStyle(VR.textPrimaryLight)
                    Spacer()
                    Text(sel.wrappedValue).foregroundStyle(VR.textFaint)
                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
                }.font(.system(size: VR.FontSize.body))
            }.buttonStyle(.plain)
        }
    }

    private func toggleRow(_ label: String, _ on: Binding<Bool>, last: Bool = false) -> some View {
        rowChrome(last) {
            Toggle(isOn: on) {
                Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.textPrimaryLight)
            }.tint(VR.violet500)
        }
    }

    private func destructiveRow(_ label: String) -> some View {
        rowChrome(false) {
            Button {} label: {
                Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.red500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(.plain)
        }
    }
}
//  APIKeyEntryView.swift
//  Purpose: Light-scope sheet to enter / clear the OpenAI API key (feature #2).
//  Built from VR design tokens per dev-docs/designs/api-key-entry/. Owns exactly
//  one APIKeyEntryModel via @State (constructed from the injected store). The
//  model is the single source of truth; the view never touches the store directly.

import SwiftUI

struct APIKeyEntryView: View {
    @State private var model: APIKeyEntryModel
    @State private var confirmClear = false
    let onClose: () -> Void

    init(store: any APIKeyStoring, onClose: @escaping () -> Void) {
        _model = State(initialValue: APIKeyEntryModel(store: store))
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OPENAI")
                        .font(.system(size: VR.FontSize.caption)).tracking(VR.capsTracking)
                        .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
                    keyCard
                    if let err = model.errorMessage {
                        Text(err).font(.system(size: VR.FontSize.caption))
                            .foregroundStyle(VR.red500).padding(.horizontal, 16)
                    } else if let masked = model.maskedExisting {
                        Text("当前：\(masked)").font(.system(size: VR.FontSize.caption))
                            .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
                    }
                    if model.hasExistingKey { clearCard }
                    notice
                }
                .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 40)
            }
        }
        .background(VR.surfaceApp)
        .alert("清除密钥？", isPresented: $confirmClear) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) { _ = model.clear() }
        } message: { Text("清除后需重新输入才能继续同传。") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button("取消", action: onClose).foregroundStyle(VR.textFaint)
                Spacer()
                Button("保存") { if model.save() { onClose() } }
                    .font(.system(size: VR.FontSize.body, weight: .semibold))
                    .foregroundStyle(model.canSave ? VR.accentLight : VR.textFaint)
                    .disabled(!model.canSave)
            }
            .font(.system(size: VR.FontSize.body))
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
            Text("API 密钥")
                .font(.system(size: VR.FontSize.title1, weight: .bold))
                .foregroundStyle(VR.textPrimaryLight)
                .padding(.horizontal, 20).padding(.bottom, 18)
        }
    }

    private var keyCard: some View {
        HStack(spacing: 12) {
            Text("密钥").foregroundStyle(VR.textFaint)
            SecureField("sk-…", text: $model.draft)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .foregroundStyle(VR.textPrimaryLight)
        }
        .font(.system(size: VR.FontSize.body))
        .frame(minHeight: 50).padding(.horizontal, 16)
        .background(VR.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var clearCard: some View {
        Button { confirmClear = true } label: {
            Text("清除密钥").foregroundStyle(VR.red500)
                .font(.system(size: VR.FontSize.body))
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .background(VR.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.top, 16)
    }

    private var notice: some View {
        Text("你的密钥保存在本机钥匙串（Keychain）。同传时会以 Bearer 凭证经 TLS 发送给你选择的服务商（OpenAI），不会发给其它第三方。设备被攻破时密钥仍可能泄露。")
            .font(.system(size: VR.FontSize.caption))
            .foregroundStyle(VR.textFaint)
            .padding(.horizontal, 16).padding(.top, 28)
    }
}

codex
Three claimed corrections are present in the detailed sections, but the plan still contains stale text that reverses two of them. I also found a new contract gap: the lifecycle test requires `listening=true` through the URL, while the specified DebugBridge URL/parser exposes only `a` and `b`; as written, that test cannot create the active fixture it claims to verify.
exec
/bin/zsh -lc "nl -ba dev-docs/plans/20260615-feature-6-verification-harness.md | sed -n '1,360p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	# Feature #6 — Verification harness (XCUITest + DebugBridge)
     2	
     3	> Gate-1 plan, revision 3. Status: PLANNED after Gate-2 audit passes.
     4	> **Estimated PR size**, per WI (separate PR each): WI-1 ~3 files / ~90 LOC
     5	> (model fixture API + tests); WI-2 ~7 files (UITest target, a11y ids on 4 views,
     6	> launch-mode wiring, smoke test) / ~160 LOC; WI-3 ~5 files (DebugBridge, plist
     7	> restructure, app wiring, parser tests, lifecycle test) / ~200 LOC; WI-4 ~1 file
     8	> + evidence / ~120 LOC. Medium feature, **4 WIs**.
     9	
    10	## Revision history
    11	- **r1** — initial plan. Gate-2 audit r1: 2 High + 4 Medium.
    12	- **r2** — fixture API; UI-testing launch mode + InMemory store; Debug/Release
    13	  `INFOPLIST_FILE` mechanism; lifecycle test; feature #2 matrix; 4-WI split.
    14	  Gate-2 audit r2: 2 High + 3 Medium.
    15	- **r3** — active-session fixture (`listening:` param) + observable MicButton a11y
    16	  state so the lifecycle test isn't vacuous; **decoupled feature #2 VERIFIED** (WI-4
    17	  is a harness smoke, not feature #2's Gate-5 — that needs real-Keychain + Release);
    18	  DebugBridge end-to-end UI test; feature #6's own evidence file; `#6b → #7`
    19	  (numeric ID) + correct `.claude/cron-prompts/verify.md` path; removed stale plist
    20	  alternative wording.
    21	
    22	## Problem
    23	The `cron-prompts/verify.md` workflow assumes a CU-free verification harness
    24	(XCUITest + a `vrecorder-debug://` DebugBridge + a gesture fallback) that does NOT
    25	exist in the repo. So the verify cron is permanently `blocked`, and shipped work
    26	(feature #2 DONE-not-VERIFIED; bugs awaiting device verification) can't be
    27	machine-verified at all. This builds the scriptable core of that harness so the
    28	verify cron can flip at least the UI/state-driven targets.
    29	
    30	## Scope
    31	**In:** an XCUITest target; accessibility identifiers on the key UI; a UI-testing
    32	launch mode (seeded `InMemoryAPIKeyStore`, bootstrap skipped) so tests don't touch
    33	the real Keychain; a DEBUG-only `vrecorder-debug://` DebugBridge that drives
    34	`LiveSessionModel` via a new named fixture API; XCUITests for the live-screen
    35	smoke, the DebugBridge, and feature #2's API-key flow.
    36	**Out:** real-mic / AirPods / interruption verification (inherently human-on-device
    37	— bugs #1/#3/#5/#9 stay `awaiting-device-verification`). The idb/`sim-tap.sh`
    38	gesture fallback + `docs/subsystems/sim-gesture-driver.md` are **split out as
    39	feature #6b** (XCUITest's native tap/typeText covers feature #6; idb is not
    40	installed) — the `docs/features.md` #6 row and the reference in
    41	`cron-prompts/verify.md` are reconciled to point at #6b for the gesture driver.
    42	The demo simulator path is unaffected.
    43	
    44	## Model fixture API (audit-r1 #1 — resolves the reset-contract gap)
    45	`LiveSessionModel.pushA/pushB` are `internal` and there is no reset; injecting mid
    46	-session would race the recognizer/demo tasks. Add ONE named, `@MainActor`
    47	operation, unit-tested independently of the bridge:
    48	
    49	- `func installFixture(a: [TranscriptLine], b: [TranscriptLine], listening: Bool = false)`
    50	  — calls `stop()` first (tears down any live recognizer/demo work + bumps the
    51	  session generation, so no in-flight task mutates the fixture), atomically
    52	  replaces `partyA` / `partyB`, and when `listening == true` sets the model into a
    53	  deterministic listening state **without a real recognizer** (sets the
    54	  `listening` flag; no audio/STT). This gives the lifecycle test a real active
    55	  session to background-stop (audit-r2 #1). `func resetTranscripts()` — empty state,
    56	  not listening.
    57	- **Observable listening state** (audit-r2 #1): `MicButton` already varies by
    58	  `listening`; add `.accessibilityValue(listening ? "listening" : "idle")` (or an
    59	  a11y id pair) so a UI test can assert the session stopped after backgrounding.
    60	- These are normal model methods (DEBUG callers only, but compile in all configs —
    61	  no `#if DEBUG` on the model API, only on the bridge that calls them). Unit tests:
    62	  `installFixtureStopsActiveSessionAndReplaces`, `installFixtureListeningSetsState`,
    63	  `resetClears`.
    64	
    65	## App-owns-AppEnvironment + UI-testing launch mode (audit-r1 #2, #4)
    66	`AppEnvironment` constructs a real `KeychainAPIKeyStore` + DEBUG-bootstraps the
    67	dev key; UI tests must NOT touch that (they'd clobber persistent sim credentials
    68	and be order-dependent). And `RootView` owns `env` via `@State` specifically to
    69	fix the scene-phase teardown bug (audit-G4r2 #2). Resolution:
    70	- `AppEnvironment` gets `init(uiTesting: Bool)`: when true (or when
    71	  `ProcessInfo…arguments.contains("-uiTesting")`), use a seeded
    72	  `InMemoryAPIKeyStore` and SKIP `APIKeyBootstrap`. UI tests set the launch arg
    73	  (and per-test seed via another arg, e.g. `-seedKey sk-…` / absent = unconfigured).
    74	- `VRecorderApp` owns `@State private var env = AppEnvironment(uiTesting: …)` and
    75	  injects it (plain `let`) into both `RootView` and the DebugBridge — preserving
    76	  single-`@State` ownership (the teardown fix), just lifted one level.
    77	
    78	## Surface area (file-by-file)
    79	- **WI-1 (foundational) — model fixture API**
    80	  - MODIFY `vrecorder/Models/LiveSessionModel.swift`: add `installFixture(a:b:)` +
    81	    `resetTranscripts()` (see "Model fixture API"). NEW
    82	    `vrecorderTests/LiveSessionFixtureTests.swift`.
    83	- **WI-2 (behavioral) — XCUITest target + a11y ids + launch mode + smoke**
    84	  - `project.yml`: NEW `vrecorderUITests` (type `bundle.ui-testing`, dep on
    85	    `vrecorder` → supplies `TEST_TARGET_NAME`); add to the scheme's test action.
    86	  - `AppEnvironment.init(uiTesting:)` + the launch-arg detection above; `VRecorderApp`
    87	    + `RootView` take an injected `env`.
    88	  - MODIFY `LiveScreen.swift`, `MicButton.swift`, `SettingsScreen.swift`,
    89	    `APIKeyEntryView.swift`: namespaced `.accessibilityIdentifier` (`vr.live.mic`,
    90	    `vr.live.gear`, `vr.settings.apiKeyRow`, `vr.apikey.field`, `vr.apikey.save`,
    91	    `vr.apikey.clear`) — invisible metadata, explicitly outside rule 51.
    92	  - NEW `vrecorderUITests/LiveScreenUITests.swift`: launch with `-uiTesting`, assert
    93	    mic + gear exist.
    94	- **WI-3 (behavioral) — DebugBridge + URL scheme + lifecycle test**
    95	  - NEW `vrecorder/Debug/DebugBridge.swift` (`#if DEBUG` file scope):
    96	    `@MainActor func handle(_ url: URL)` parses `vrecorder-debug://inject?a=…&b=…`
    97	    → `session.installFixture(...)`; `…/reset` → `resetTranscripts()`; malformed →
    98	    no-op. Synchronous on the main actor (no Sendable / detached task).
    99	  - MODIFY `VRecorderApp.swift`: `.onOpenURL { #if DEBUG; DebugBridge(env.session).handle($0); #endif }`.
   100	  - **URL-scheme registration (audit-r1 #3):** set `GENERATE_INFOPLIST_FILE: NO`
   101	    and provide explicit `vrecorder/Resources/Info-Debug.plist` (with the
   102	    `CFBundleURLTypes` `vrecorder-debug` entry) and `Info-Release.plist` (without),
   103	    selected via `settings.configs.Debug.INFOPLIST_FILE` /
   104	    `settings.configs.Release.INFOPLIST_FILE`. Both plists carry the existing
   105	    `INFOPLIST_KEY_*` values (mic/speech usage, orientation, etc.) as real keys.
   106	  - NEW `vrecorderTests/DebugBridgeTests.swift` (`#if DEBUG`): URL parsing →
   107	    fixture installed / reset / malformed no-op (drives a model directly, no UI).
   108	  - NEW lifecycle regression: `vrecorderUITests/LifecycleUITests.swift` — inject a
   109	    fixture, background+foreground the app, assert the session stopped (audit-r1 #4)
   110	    — deterministic via the fixture, not a real recognizer.
   111	- **WI-4 (final) — API-key UI smoke (harness demonstration) + feature #6 evidence**
   112	  - NEW `vrecorderUITests/APIKeyEntryUITests.swift`: with `-uiTesting` + seeded
   113	    InMemory store, drive the drivable UI behaviors — open sheet; valid key → 保存
   114	    → 已配置; empty → 保存 disabled; 清除 (confirm) → 未配置; cancel leaves state.
   115	  - **Does NOT flip feature #2 to VERIFIED** (audit-r2 #2): feature #2's acceptance
   116	    needs a real-Keychain round-trip + visible failure handling + a Release pass —
   117	    its own plan reserves these for Gate 5. This WI proves the *harness works*;
   118	    feature #2's full VERIFIED is a **separate verification task** (note added to
   119	    feature #2's row pointing at the harness as the now-available tool).
   120	  - NEW `dev-docs/verification/feature-6-<date>.md` (audit-r2 #4): feature #6's own
   121	    Gate-5 evidence — all UI suites green on the sim + the Debug/Release plist
   122	    built-product assertion. feature #6 → VERIFIED on this.
   123	
   124	## Prior art / project precedent / rejected alternatives
   125	- **Precedent:** `LiveSessionModel.pushA/pushB` are already public seams (used by
   126	  the demo simulator) — the DebugBridge reuses them, inventing no new state API.
   127	  `#if DEBUG` file-scope gating is the established pattern (APIKeyBootstrap).
   128	- **Industry:** XCUITest + accessibility identifiers + a debug URL scheme to drive
   129	  deterministic UI state is the standard iOS UI-verification approach.
   130	- **Rejected:** (a) idb/`sim-tap.sh` as the primary driver — XCUITest's native
   131	  tap/typeText covers this feature; idb isn't installed; defer as optional. (b)
   132	  Snapshot/pixel testing — brittle, and rule-51 governs visual design, not tests.
   133	  (c) Driving the real recognizer in UI tests — non-deterministic; the DebugBridge
   134	  injects fixtures instead.
   135	
   136	## Work items (4 WIs, one PR each — rule 47, audit-r1 #6)
   137	- **WI-1 (foundational)**: model fixture API + unit tests. No UI, no Release change.
   138	- **WI-2 (behavioral)**: XCUITest target + a11y ids + UI-testing launch mode +
   139	  live-screen smoke. Slice-verify: smoke UI test green on the sim.
   140	- **WI-3 (behavioral)**: DebugBridge + Debug/Release plist restructure + app
   141	  wiring + parser unit tests + background-stop lifecycle UI test. Slice-verify:
   142	  `vrecorder-debug://inject` seeds the asserted transcript; built-product check
   143	  that Debug `.app` Info.plist contains `vrecorder-debug` and Release does NOT.
   144	- **WI-4 (final)**: feature #2 full-acceptance UI test → flips feature #2 to
   145	  VERIFIED (complete matrix recorded). Completes feature #6.
   146	
   147	## Test catalogue
   148	- `vrecorderTests/LiveSessionFixtureTests.swift`:
   149	  `installFixtureStopsActiveSessionAndReplaces`, `resetClears`.
   150	- `vrecorderTests/DebugBridgeTests.swift` (`#if DEBUG`): `injectSeedsTranscript`,
   151	  `resetClears`, `malformedURLIsNoOp` (drives a model directly).
   152	- `vrecorderUITests/LiveScreenUITests.swift`: `liveScreenShowsMicAndGear`.
   153	- `vrecorderUITests/DebugBridgeUITests.swift` (audit-r2 #3): `openInjectURLRenders
   154	  Transcript` — `XCUIApplication().open(URL("vrecorder-debug://inject?...")!)` then
   155	  assert the seeded transcript text is on screen (validates URL delivery,
   156	  `.onOpenURL`, shared-env identity, and rendering — which the parser unit tests
   157	  can't).
   158	- `vrecorderUITests/LifecycleUITests.swift`: `backgroundStopsActiveSession` —
   159	  inject an `installFixture(..., listening: true)` fixture (via the debug URL),
   160	  assert MicButton a11y value `listening`, background+foreground, assert `idle`.
   161	- `vrecorderUITests/APIKeyEntryUITests.swift`: `enterKeyFlipsRowToConfigured`,
   162	  `emptyInputKeepsSaveDisabled`, `clearKeyFlipsRowToUnconfigured`,
   163	  `cancelLeavesRowUnchanged`.
   164	- **Built-product assertion** (WI-3 verification step, in the PR description):
   165	  `plutil`/`grep` the Debug vs Release `.app/Info.plist` for `vrecorder-debug`.
   166	
   167	## Edge cases
   168	- App not built for UI testing → XCUITest target launches its own host (handled by
   169	  the target type).
   170	- DebugBridge active only in DEBUG (Release ignores the URL scheme entirely).
   171	- Malformed `vrecorder-debug://` URL → no-op, no crash.
   172	- Sheet/keyboard timing in XCUITest → use `waitForExistence(timeout:)`, never bare
   173	  sleeps.
   174	- Simulator wedge (seen this session) → run UI tests through `scripts/run-tests.sh`
   175	  (UDID-pinned, watchdog) on a clean sim.
   176	- a11y identifiers must not collide → namespaced (`vr.live.mic`, `vr.settings.apiKeyRow`…).
   177	
   178	## Acceptance criteria
   179	1. `vrecorderUITests` target builds and runs via the scheme; smoke test green.
   180	2. A `vrecorder-debug://inject` URL deterministically seeds an on-screen transcript
   181	   (DEBUG); **built-product check**: Debug `.app/Info.plist` contains
   182	   `vrecorder-debug`, Release does NOT.
   183	3. UI tests run under `-uiTesting` with a seeded `InMemoryAPIKeyStore` (bootstrap
   184	   skipped) — they never read/write the real Keychain and are order-independent.
   185	4. The API-key UI smoke drives the drivable behaviors (enter/save/clear/cancel);
   186	   it demonstrates the harness but does NOT flip feature #2 to VERIFIED (that needs
   187	   feature #2's own real-Keychain + Release Gate-5).
   188	5. The background-stop lifecycle still holds after lifting `env` to the App
   189	   (deterministic UI test).
   190	6. All UI tests run on the iPhone 17 Pro simulator through `run-tests.sh`.
   191	7. No production behavior change; DebugBridge + the URL scheme are DEBUG-only.
   192	
   193	## Scope reconciliation (audit-r1 #5, audit-r2 #5)
   194	The `docs/features.md` #6 row and `.claude/cron-prompts/verify.md` reference an idb
   195	`sim-tap.sh` gesture driver + `docs/subsystems/sim-gesture-driver.md`. This plan
   196	EXCLUDES them (XCUITest's native tap/typeText covers feature #6; idb isn't
   197	installed). On Gate-1 acceptance: file **feature #7 — idb gesture-driver fallback**
   198	(numeric ID — tracker hooks recognize numbers only, not `#6b`) and edit the #6 row
   199	to scope it to the XCUITest+DebugBridge core, so the tracker matches this plan. The
   200	verify cron can use XCUITest once #6 lands; #7 adds gestures XCUITest can't express.
   201	
   202	## Risks + mitigations
   203	- **URL-scheme registration mechanism**: resolved — `GENERATE_INFOPLIST_FILE: NO`
   204	  + explicit `Info-Debug.plist` (with `CFBundleURLTypes`) / `Info-Release.plist`
   205	  (without), selected via `settings.configs.<config>.INFOPLIST_FILE`. Both plists
   206	  carry the existing `INFOPLIST_KEY_*` values as real keys. (A `.xcconfig` or
   207	  partial plist can't express/merge the nested `CFBundleURLTypes` — not used.)
   208	- **App-owns-AppEnvironment refactor** could disturb the scene-phase teardown
   209	  (audit-G4r2 #2 fix). Mitigation: keep `@State` ownership, just lift it one level
   210	  (App → injected into RootView); a UI test asserts background still stops.
   211	- **XCUITest flakiness**: bounded `waitForExistence`, no sleeps; UDID-pinned sim.
   212	
   213	## Docs sync + version bump (rules 24 + 40)
   214	- `docs/architecture.md`: note the DebugBridge + UITest target. `README.md`:
   215	  Developer Tools / testing note. `docs/features.md`: row #6 PLANNED → IN PROGRESS
   216	  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
   217	- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.
   218	
   219	## Backward compat
   220	Additive + DEBUG-only. No schema, no Release behavior change. The
   221	App-owns-AppEnvironment change is internal wiring.

exec
/bin/zsh -lc "nl -ba project.yml | sed -n '1,300p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	name: vrecorder
     2	options:
     3	  bundleIdPrefix: com.vrecorder
     4	  deploymentTarget:
     5	    iOS: "17.0"
     6	  createIntermediateGroups: true
     7	
     8	settings:
     9	  base:
    10	    SWIFT_VERSION: "6.0"
    11	    SWIFT_STRICT_CONCURRENCY: complete
    12	    GENERATE_INFOPLIST_FILE: "YES"
    13	    MARKETING_VERSION: "0.2.5"
    14	    CURRENT_PROJECT_VERSION: "7"
    15	    DEVELOPMENT_TEAM: ""
    16	    CODE_SIGN_STYLE: Automatic
    17	
    18	targets:
    19	  vrecorder:
    20	    type: application
    21	    platform: iOS
    22	    deploymentTarget: "17.0"
    23	    sources:
    24	      - path: vrecorder
    25	      - path: config/openai-key.txt
    26	        optional: true
    27	        buildPhase: resources
    28	    settings:
    29	      base:
    30	        PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app
    31	        MARKETING_VERSION: "0.2.5"
    32	        CURRENT_PROJECT_VERSION: "7"
    33	        GENERATE_INFOPLIST_FILE: "YES"
    34	        INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
    35	        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: "YES"
    36	        INFOPLIST_KEY_NSMicrophoneUsageDescription: "VRecorder 需要使用麦克风进行实时同声传译。"
    37	        INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: "VRecorder 使用语音识别将你的发言实时转写为文字。"
    38	        INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait"
    39	        INFOPLIST_KEY_UIStatusBarStyle: UIStatusBarStyleLightContent
    40	        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
    41	        TARGETED_DEVICE_FAMILY: "1"
    42	      configs:
    43	        # Never ship the dev key resource in a distributable (Release) bundle —
    44	        # it stays a DEBUG-only convenience (audit-3 #4). APIKeyBootstrap also
    45	        # #if DEBUG-gates the read; this removes the file from the bundle too.
    46	        Release:
    47	          EXCLUDED_SOURCE_FILE_NAMES: "openai-key.txt"
    48	
    49	  vrecorderTests:
    50	    type: bundle.unit-test
    51	    platform: iOS
    52	    deploymentTarget: "17.0"
    53	    sources:
    54	      - path: vrecorderTests
    55	    dependencies:
    56	      - target: vrecorder
    57	    settings:
    58	      base:
    59	        PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app.tests
    60	
    61	schemes:
    62	  vrecorder:
    63	    build:
    64	      targets:
    65	        vrecorder: all
    66	        vrecorderTests: [test]
    67	    test:
    68	      targets:
    69	        - vrecorderTests

exec
/bin/zsh -lc "sed -n '1,340p' vrecorderTests/LiveSessionModelTests.swift && sed -n '1,300p' vrecorderTests/APIKeyEntryModelTests.swift" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
//  LiveSessionModelTests.swift
//  Purpose: Smoke tests for the partial → final → history transcript lifecycle.

import Testing
@testable import vrecorder

@MainActor
@Suite("LiveSessionModel")
struct LiveSessionModelTests {
    @Test func partialIsReplacedNotAppended() {
        let m = LiveSessionModel()
        let before = m.partyA.count
        m.pushA(.init(status: .partial, text: "你好…"))
        m.pushA(.init(status: .partial, text: "你好吗…"))
        // Two partials in a row keep only one live line on top.
        #expect(m.partyA.count == before + 1)
        #expect(m.partyA.last?.text == "你好吗…")
        #expect(m.partyA.last?.status == .partial)
    }

    @Test func finalDemotesPreviousLinesToHistory() {
        let m = LiveSessionModel()
        m.pushA(.init(status: .final, text: "第一句。"))
        m.pushA(.init(status: .final, text: "第二句。"))
        // The earlier final becomes history once a newer line lands.
        #expect(m.partyA.dropLast().allSatisfy { $0.status == .history })
        #expect(m.partyA.last?.status == .final)
    }

    @Test func panelKeepsAtMostThreeLines() {
        let m = LiveSessionModel()
        for i in 0..<6 { m.pushA(.init(status: .final, text: "句\(i)")) }
        #expect(m.partyA.count <= 3)
    }

    @Test func micAndSpeechDenialHaveDistinctMessages() {
        let mic = LiveSessionModel.message(for: PipelineError.micPermissionDenied)
        let speech = LiveSessionModel.message(for: PipelineError.speechPermissionDenied)
        #expect(mic != speech)
        #expect(mic.contains("麦克风"))
        #expect(speech.contains("语音识别"))
    }

    @Test func timeoutIsNotLabeledOffline() {
        let timeout = LiveSessionModel.message(for: PipelineError.timeout)
        let offline = LiveSessionModel.message(for: PipelineError.offline)
        #expect(timeout != offline)
        #expect(!timeout.contains("网络不可用"))
    }
}
//  APIKeyEntryModelTests.swift
//  Purpose: Validation, masking, save/clear, and error-state coverage for the
//  key-entry view-model (feature #2). No UI, no real Keychain.

import Foundation
import Testing
@testable import vrecorder

@MainActor
@Suite("APIKeyEntryModel")
struct APIKeyEntryModelTests {
    private func model(_ seed: String? = nil, fail: Bool = false) -> (APIKeyEntryModel, InMemoryAPIKeyStore) {
        let store = InMemoryAPIKeyStore(seed.map { [APIProvider.openAI: $0] } ?? [:])
        store.failNextWrite = fail
        return (APIKeyEntryModel(store: store), store)
    }

    // MARK: validation

    @Test func isValidRejectsEmptyAndTooShort() {
        #expect(!APIKeyEntryModel.isValid(""))
        #expect(!APIKeyEntryModel.isValid("   "))
        #expect(!APIKeyEntryModel.isValid("sk-1234"))          // 7 chars
        #expect(APIKeyEntryModel.isValid("sk-12345"))          // 8 chars
    }

    @Test func isValidRejectsTooLong() {
        #expect(APIKeyEntryModel.isValid(String(repeating: "a", count: 500)))
        #expect(!APIKeyEntryModel.isValid(String(repeating: "a", count: 501)))
    }

    @Test func isValidRejectsInternalWhitespaceControlAndNonASCII() {
        #expect(!APIKeyEntryModel.isValid("sk-12 345678"))     // internal space
        #expect(!APIKeyEntryModel.isValid("sk-1234\n5678"))    // newline
        #expect(!APIKeyEntryModel.isValid("sk-1234😀5678"))    // emoji
        #expect(!APIKeyEntryModel.isValid("密钥key-12345"))    // CJK
    }

    @Test func isValidAcceptsPlainProjAndNonSkKeys() {
        #expect(APIKeyEntryModel.isValid("  sk-abcDEF123456  "))    // trims, ok
        #expect(APIKeyEntryModel.isValid("sk-proj-abcDEF_12-345"))  // project key
        #expect(APIKeyEntryModel.isValid("api_someProviderKey_99"))  // no sk- prefix
    }

    // MARK: masking

    @Test func maskRules() {
        #expect(APIKeyEntryModel.mask(nil) == nil)
        #expect(APIKeyEntryModel.mask("") == nil)
        #expect(APIKeyEntryModel.mask("short") == "已配置")        // < 12, never reveal
        #expect(APIKeyEntryModel.mask("sk-abcdefghAB12") == "…AB12") // last 4
    }

    // MARK: save / clear

    @Test func saveTrimsPersistsAndClearsDraft() {
        let (m, store) = model()
        m.draft = "  sk-abcDEF123456  "
        #expect(m.canSave)
        #expect(m.save())
        #expect(store.key(for: APIProvider.openAI) == "sk-abcDEF123456")
        #expect(m.draft.isEmpty)
        #expect(m.hasExistingKey)
        #expect(m.maskedExisting == "…3456")
        #expect(m.errorMessage == nil)
    }

    @Test func saveGuardsOnValidity() {
        let (m, store) = model()
        m.draft = "short"            // invalid
        #expect(!m.canSave)
        #expect(!m.save())           // direct call is a no-op
        #expect(store.key(for: APIProvider.openAI) == nil)
    }

    @Test func saveFailurePreservesPreviousKeyAndSetsError() {
        let (m, store) = model("sk-oldoldold111", fail: true)
        m.draft = "sk-newnewnew222"
        #expect(!m.save())
        #expect(store.key(for: APIProvider.openAI) == "sk-oldoldold111")  // old preserved
        #expect(m.errorMessage?.contains("保存失败") == true)
    }

    @Test func clearRemovesKeyAndUpdatesState() {
        let (m, store) = model("sk-abcdefghAB12")
        #expect(m.hasExistingKey)
        #expect(m.clear())
        #expect(store.key(for: APIProvider.openAI) == nil)
        #expect(!m.hasExistingKey)
        #expect(m.maskedExisting == nil)
    }

    @Test func clearFailureRetainsConfiguredStateAndSetsError() {
        let (m, _) = model("sk-abcdefghAB12", fail: true)
        #expect(!m.clear())
        #expect(m.hasExistingKey)                       // not flipped to 未配置
        #expect(m.errorMessage?.contains("清除失败") == true)
    }

    @Test func editingDraftClearsError() {
        let (m, _) = model("sk-oldoldold111", fail: true)
        m.draft = "sk-newnewnew222"; _ = m.save()       // sets error
        #expect(m.errorMessage != nil)
        m.draft = "sk-newnewnew333"                      // editing clears it
        #expect(m.errorMessage == nil)
    }

    @Test func initReflectsExistingKey() {
        let (withKey, _) = model("sk-abcdefghAB12")
        #expect(withKey.hasExistingKey)
        #expect(withKey.maskedExisting == "…AB12")
        let (empty, _) = model()
        #expect(!empty.hasExistingKey)
        #expect(empty.maskedExisting == nil)
    }
}

exec
/bin/zsh -lc "sed -n '1,320p' vrecorder/Security/APIKeyStore.swift && rg -n \"InMemoryAPIKeyStore|seedKey|APIKeyBootstrap|open\\(_.*URL|XCUIApplication\" ." in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
exec
/bin/zsh -lc "sed -n '1,280p' .claude/rules/50-codebase-conventions.md && sed -n '1,260p' .claude/rules/51-no-self-designed-ui.md && sed -n '1,280p' .claude/rules/52-test-sim-isolation.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
//  APIKeyStore.swift
//  Purpose: Keychain-backed storage for provider API keys. The key is the only
//  secret in the app and must never live in UserDefaults or the bundle.
//  A protocol lets tests substitute an in-memory store; an injectable KeychainOps
//  seam lets tests exercise SecItem status handling (feature #2).

import Foundation
import Security

protocol APIKeyStoring: Sendable {
    func key(for provider: String) -> String?
    /// Returns true on a confirmed write/delete. An update that fails (other than
    /// "not found") leaves the previous key untouched — never destroys it.
    @discardableResult
    func setKey(_ value: String?, for provider: String) -> Bool
}

/// Injectable Security operations so the update→add→preserve logic is testable
/// with scripted `OSStatus` (audit-3 #2: Sendable + @Sendable closures).
struct KeychainOps: Sendable {
    var update: @Sendable (CFDictionary, CFDictionary) -> OSStatus = SecItemUpdate
    var add:    @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemAdd
    var delete: @Sendable (CFDictionary) -> OSStatus = SecItemDelete
    var copy:   @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching
}

/// Real Keychain implementation (generic password, one item per provider).
struct KeychainAPIKeyStore: APIKeyStoring {
    private let service = "com.vrecorder.app.apikeys"
    private let ops: KeychainOps

    init(ops: KeychainOps = KeychainOps()) { self.ops = ops }

    func key(for provider: String) -> String? {
        var query = baseQuery(provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard ops.copy(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    @discardableResult
    func setKey(_ value: String?, for provider: String) -> Bool {
        let query = baseQuery(provider)
        guard let value, let data = value.data(using: .utf8) else {
            // Delete path: success or already-absent both count as cleared.
            let status = ops.delete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }
        // Atomic: update first (attributes carry ONLY the new data); add only on
        // "not found". Any other update failure leaves the existing key intact.
        let attrs: [String: Any] = [kSecValueData as String: data]
        let updateStatus = ops.update(query as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        if updateStatus == errSecItemNotFound {
            var addAttrs = query
            addAttrs[kSecValueData as String] = data
            return ops.add(addAttrs as CFDictionary, nil) == errSecSuccess
        }
        return false
    }

    private func baseQuery(_ provider: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: provider]
    }
}

/// In-memory store for tests and previews. `failNextWrite` injects one failure.
final class InMemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private var _failNextWrite = false
    private let lock = NSLock()
    init(_ seed: [String: String] = [:]) { storage = seed }
    /// All access guarded by `lock` (audit-G4 Low: was read/written off-lock).
    var failNextWrite: Bool {
        get { lock.withLock { _failNextWrite } }
        set { lock.withLock { _failNextWrite = newValue } }
    }
    func key(for provider: String) -> String? { lock.withLock { storage[provider] } }
    @discardableResult
    func setKey(_ value: String?, for provider: String) -> Bool {
        lock.withLock {
            if _failNextWrite { _failNextWrite = false; return false }   // preserve existing
            storage[provider] = value
            return true
        }
    }
}

enum APIProvider {
    static let openAI = "openai"
    static let claude = "claude"
}
./vrecorderTests/APIKeyEntryModelTests.swift:12:    private func model(_ seed: String? = nil, fail: Bool = false) -> (APIKeyEntryModel, InMemoryAPIKeyStore) {
./vrecorderTests/APIKeyEntryModelTests.swift:13:        let store = InMemoryAPIKeyStore(seed.map { [APIProvider.openAI: $0] } ?? [:])
./dev-docs/decisions/ADR-001-mvp-scaffold-audit-bypass.md:31:- **Residual High — Release API-key entry** (`APIKeyBootstrap` + `SettingsScreen`):
./dev-docs/plans/20260615-feature-6-verification-harness.md:32:launch mode (seeded `InMemoryAPIKeyStore`, bootstrap skipped) so tests don't touch
./dev-docs/plans/20260615-feature-6-verification-harness.md:72:  `InMemoryAPIKeyStore` and SKIP `APIKeyBootstrap`. UI tests set the launch arg
./dev-docs/plans/20260615-feature-6-verification-harness.md:73:  (and per-test seed via another arg, e.g. `-seedKey sk-…` / absent = unconfigured).
./dev-docs/plans/20260615-feature-6-verification-harness.md:127:  `#if DEBUG` file-scope gating is the established pattern (APIKeyBootstrap).
./dev-docs/plans/20260615-feature-6-verification-harness.md:154:  Transcript` — `XCUIApplication().open(URL("vrecorder-debug://inject?...")!)` then
./dev-docs/plans/20260615-feature-6-verification-harness.md:183:3. UI tests run under `-uiTesting` with a seeded `InMemoryAPIKeyStore` (bootstrap
./dev-docs/plans/20260614-feature-2-api-key-entry.md:75:  (existing callers — `APIKeyBootstrap.seedIfNeeded` — ignore the result, so this
./dev-docs/plans/20260614-feature-2-api-key-entry.md:82:- `InMemoryAPIKeyStore.setKey` returns `Bool` too (always succeeds; supports a
./dev-docs/plans/20260614-feature-2-api-key-entry.md:140:  - Injected `APIKeyStoring` (mockable; `InMemoryAPIKeyStore` exists).
./dev-docs/plans/20260614-feature-2-api-key-entry.md:163:- `APIKeyStoring` / `KeychainAPIKeyStore` / `InMemoryAPIKeyStore` + `APIProvider`
./config/README.md:16:the Keychain (`APIKeyBootstrap.seedIfNeeded`), then never reads it again. Release
./vrecorder.xcodeproj/project.pbxproj:43:		E01605210287AABC7035C0E6 /* APIKeyBootstrap.swift in Sources */ = {isa = PBXBuildFile; fileRef = 56738A58924D6D1A8F9258C9 /* APIKeyBootstrap.swift */; };
./vrecorder.xcodeproj/project.pbxproj:77:		56738A58924D6D1A8F9258C9 /* APIKeyBootstrap.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = APIKeyBootstrap.swift; sourceTree = "<group>"; };
./vrecorder.xcodeproj/project.pbxproj:163:				56738A58924D6D1A8F9258C9 /* APIKeyBootstrap.swift */,
./vrecorder.xcodeproj/project.pbxproj:349:				E01605210287AABC7035C0E6 /* APIKeyBootstrap.swift in Sources */,
./project.yml:44:        # it stays a DEBUG-only convenience (audit-3 #4). APIKeyBootstrap also
./vrecorder/App/AppEnvironment.swift:16:        APIKeyBootstrap.seedIfNeeded(store: store)
./vrecorder/Security/APIKeyStore.swift:73:final class InMemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
./vrecorder/Security/APIKeyBootstrap.swift:1://  APIKeyBootstrap.swift
./vrecorder/Security/APIKeyBootstrap.swift:9:enum APIKeyBootstrap {

 succeeded in 0ms:
# 50 - Codebase Conventions

Project conventions for vrecorder (iOS simultaneous-interpretation app). Follow these for consistency.

## 1. Actor Isolation

- Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY=complete`).
- ViewModels and observable stores are `@MainActor @Observable final class`.
- Pipeline stages (capture, VAD, ASR, translation, TTS) are actors or actor-isolated services. Cross-actor calls use `await`. No `assumeIsolated` except in narrow `App.init` contexts.
- Never pass `@Model` instances across actor boundaries — use value-type DTOs (`SessionRecord`, `TranscriptSegmentRecord`, etc.).

## 2. Streaming Pipeline Semantics

- Stages communicate via explicit streaming protocols emitting `partial` / `final` events.
- **Partials are replaceable, not append-only**: a later partial replaces the previous partial for the same segment; a `final` freezes it. Consumers must implement replacement.
- Every stage supports cancellation; cancelling a session must tear down the whole chain (no orphaned recognition tasks or network streams).
- Backpressure: stages must not buffer unboundedly; drop or coalesce partials when the consumer is slow.

## 3. Engine Abstraction

- ASR, translation, and TTS providers sit behind protocols (e.g. `SpeechRecognizing`, `TranslationEngine`, `SpeechSynthesizing`).
- Concrete providers (on-device SFSpeechRecognizer / Apple Translation vs cloud streaming APIs) are selected via a capabilities object (offline support, language pairs, latency class) — never hard-coded at call sites.
- UI code never calls a concrete provider directly.

## 4. Audio Session

- All `AVAudioSession` configuration, interruption handling, and route-change handling is centralized in one audio session controller.
- Interruptions (phone call, Siri, alarm) and route changes (AirPods connect/disconnect) must pause/resume the pipeline gracefully and are test-covered via simulated notifications.

## 5. Persistence

- All SwiftData mutations go through a single persistence actor.
- Sessions, transcripts, and translations persist as value-type DTO round-trips.

## 6. Logging & Errors

- No bare `print()` in production — `Logger(subsystem: "com.vrecorder.app", category: "...")`.
- Error types are domain-specific; user-presentable errors must distinguish: offline, timeout, rate-limited, permission-denied, provider-error. Never mislabel a timeout as "offline".

## 7. DEBUG Gating

- DEBUG-only code (fixtures, debug bridges, test seams) wrapped in `#if DEBUG` at file scope, never inline in production code paths.

## 8. File Size & Structure

- Code files stay under ~300 lines; split proactively.
- Features stay local; avoid cross-feature imports unless truly shared.

## 9. Testing

- Swift Testing is the default (`import Testing`, `@Test`, `#expect`); XCTest only for `XCTestExpectation` / notification-timing tests.
- Audio tests use recorded fixture clips (speech / silence / noise / CJK) and recorded transcript-event sequences — never live mic input.
# 51 — UI/UX from claude.ai/design only

Binding rule for every agent (Claude, Codex, others). Applies to every feature, bug fix, refactor, and verification slice that introduces a new visible UI element.

## Hard rule

**Do not invent UI/UX.** If a feature, bug fix, or slice needs a UI element on a surface that is NOT depicted in a committed design bundle under `dev-docs/designs/...`, stop that slice and file a `needs-design` GitHub issue. The user manually carries it through `claude.ai/design`, re-handoffs a fresh bundle, and only then does the slice resume.

This applies to:

- New SwiftUI / UIKit views, sheets, modals, popovers, alerts, toasts.
- New rows, sections, settings entries, buttons, indicators, or empty states within existing screens.
- New visual states (loading, error, empty, partial, in-progress) when not depicted in the design.
- "Placeholder" UI introduced with intent to re-skin later — same prohibition.
- UI affordances introduced by a bug fix (e.g., a new confirmation dialog, a new status chip) — same prohibition.
- AZW3/Foliate-js / EPUB CSS / WKWebView injection — same prohibition when it changes visible chrome.

## What "designed" means

A surface is **designed** when ALL of the following hold:

1. A committed design bundle exists at `dev-docs/designs/<bundle-name>/`.
2. The specific surface (screen, sheet, popover, interaction state) is depicted in that bundle's HTML/JSX/screenshots — by name and by visual content.
3. "Looks similar to existing X" does NOT count. "Inherits the same chrome" does NOT count. The actual surface must appear in the design.

If you cannot point at a file in `dev-docs/designs/` that shows the surface you are about to build, it is **not designed**.

## Workflow

When you reach a slice that would touch undesigned UI:

1. **Stop that slice.** Do not write the View. Do not write a placeholder. Do not improvise.
2. **File a GitHub issue**:
   - Title: `Design needed: <surface name> for feature #<N>` (or `for bug #<N>`)
   - Labels: `enhancement` + `needs-design`
   - Body must include:
     - The surface being requested (screen / sheet / state)
     - The parent feature or bug (`Refs #<N>`)
     - The user-facing behavior the UI must expose
     - Screenshots of the current chrome if any
     - List of states the design must cover (default, loading, error, empty, etc.)
3. **Pause that slice** in the tracker — add a `BLOCKED: needs-design (#<new-issue>)` note on the WI or bug row.
4. **Continue parallel slices** that DO have design — see `.claude/rules/48-parallel-execution.md` for safe parallel execution.
5. **User loop**: the user manually takes the `needs-design` issue through `claude.ai/design`, gets a handoff bundle, and commits it under `dev-docs/designs/...` in a separate PR. The slice can then resume.

## What is NOT covered by this rule

- **System chrome (status bar, home indicator, dynamic island)** — iOS / SwiftUI handles these by default; no design needed.
- **Pure code changes with no visible delta** — refactors, persistence-only fixes, performance fixes, test-only changes.
- **Existing-surface bug fixes that restore broken UI back to its designed state** — fixing a typo in a label, fixing a hidden button, etc.
- **Verification-only artifacts** — XCUITest helpers, DebugBridge surfaces (`vrecorder-debug://...`), `dev-docs/verification/*` markdown — these are dev-only, never user-visible in Release.
- **CLI / config / hook / script files** — never user-facing.

## Anti-patterns

| Anti-pattern | Why it fails | Right move |
|---|---|---|
| "I'll match the existing chrome for now" | That's self-designed UI. Existing chrome IS the thing being replaced (feature #60). | File `needs-design`. |
| "Just a placeholder until v2" | Placeholders are committed code that ships in releases. Fragmenting UI for 2-3 versions is worse than pausing. | File `needs-design`. |
| "It's a small dialog, an Apple HIG default works fine" | HIG defaults look fine in isolation but clash with the specified design system over time. | File `needs-design`. |
| Inventing UI for a bug-fix toast / status chip / error sheet | Bug fixes don't escape this rule — they can introduce UI debt the same way features do. | File `needs-design`. |
| Inventing UI in a feature-workflow Gate 3 implementation because the WI list said "small change" | Gate-3 must reference the designed surface; if no design exists for a WI's UI, that WI itself was misclassified in Gate 1 — escalate. | Stop the WI, file `needs-design`, fix the Gate-1 plan. |

## Origin

2026-05-15 user directive after filing feature #60 (visual identity v2 design bundle). The user wants a one-way design loop:

```
design tool → handoff bundle → commit → implement
```

and explicitly rejects the round-trip:

```
agent invents UI → ships → user notices → user redesigns → re-implement
```

The cost of pausing a slice to file `needs-design` is far below the cost of producing UI debt that has to be re-skinned later. This rule encodes that trade-off.
# 52 — Test / Simulator Isolation (no more ghost `xcodebuild test`)

## The recurring failure

`xcodebuild test` wedges: the process sits at **0% CPU with zero output** and
lingers for hours as a "ghost" (the task UI shows it running; `ps` shows it
sleeping forever). It never completes and never fails — it just hangs.

This has happened **many times**. Every instance shares one cause.

## Root cause (TWO distinct causes — both observed 2026-05-31)

### Cause A — simulator contention

A `xcodebuild test` run boots/installs onto a booted simulator and drives it. If
— while that run is in flight — the SAME simulator (same UDID) is ALSO driven by
verification traffic (`scripts/sim-tap.sh`, `idb`, `xcrun simctl openurl
vrecorder-debug://…`, `simctl io`, screenshots), the two contend for the one device
and the test runner deadlocks. With no timeout, the wedged process ghosts
indefinitely.

Aggravator: launching the test with `run_in_background: true` and then
immediately starting sim-driving in the next tool call — the collision is
guaranteed, and the ghost is invisible until someone checks `ps`.

### Cause B — orphaned/wedged build daemon (`SWBBuildService`)

`xcodebuild test` delegates compilation to Xcode's shared build daemon
`SWBBuildService`. When a hung `xcodebuild` is killed with `kill -9`, the daemon
is **left in a wedged state**. The NEXT `xcodebuild` build then hangs at 0% CPU
with NO compiler children and the **simulator completely idle** — i.e. it looks
identical to Cause A but contention is NOT involved. This is what produced the
"hung again?" recurrence right after killing the first ghost.

**Therefore:** never `kill -9` a hung `xcodebuild` without ALSO clearing the
daemon: `pkill -9 -x SWBBuildService`. The `scripts/run-tests.sh` watchdog now
does this automatically on timeout. A bare xcodebuild kill is a half-cleanup that
poisons the next run.

### Cause C — the full suite is just SLOW (not a hang)

The entire `vrecorderTests` suite takes **>20 min** to build + run (hundreds of
tests incl. slow SwiftUI view tests). Running it as a per-WI gate looks
identical to a hang — `xcodebuild` sits there for 20+ min — but it is genuinely
working (the log shows `◇ Test case … started` lines streaming). Observed
2026-05-31: a clean-environment full-suite run built fine and was mid-tests when
a 20-min watchdog killed it.

**Therefore: do NOT run the whole `vrecorderTests` suite as a per-WI gate.** Run the
**targeted `-only-testing:` suites that cover the change** — they finish in
seconds to a couple of minutes and are the appropriate gate. Reserve the full
suite for a periodic/CI sweep with a long budget (`TIMEOUT_SECS=2400`+).

```bash
# Per-WI gate — targeted, fast (seconds):
scripts/run-tests.sh vrecorderTests/DebugCommandTests
# (pass multiple via repeated -only-testing is not supported by the wrapper's
#  single-arg form; run the wrapper once per suite, or extend it if needed.)

# Full-suite sweep — periodic, long budget:
TIMEOUT_SECS=2400 scripts/run-tests.sh vrecorderTests
```

## Hard rules

1. **Never drive a simulator while `xcodebuild test` runs against it.** Tests and
   sim-driving (`sim-tap` / `idb` / `simctl openurl eval` / `simctl io` /
   screenshots / verification) are **mutually exclusive on one UDID**. Serialize:
   finish the test run, THEN drive the sim — or drive a DIFFERENT UDID
   (`TEST_UDID=<other>`).
2. **Always run unit-test gates through `scripts/run-tests.sh`.** It pins the
   destination by UDID, enforces a hard wall-clock timeout (default 900s), waits
   on the exact pid (rule 49), kills the process tree on timeout, and prints one
   unambiguous final line (`RUN-TESTS RESULT: SUCCEEDED|FAILED|TIMEOUT|NO_BOOTED_SIM`).
   A wedge now self-terminates in ≤15 min instead of ghosting for hours.
3. **A `RUN-TESTS RESULT: TIMEOUT` is not a flaky test — it's contention.** Do not
   "retry harder." Confirm nothing is driving the sim, then re-run. If you need
   verification in parallel, boot a second simulator and pass its UDID via
   `TEST_UDID`.
4. **Before ending a turn, confirm no live `xcodebuild`:** `pgrep -x xcodebuild`
   (NOT `pgrep -f xcodebuild` — `-f` matches the pattern inside your own grep
   command line and always returns ≥1, a false positive that has masked real
   state before). Zero = clean.
5. **Never pipe `scripts/run-tests.sh` through `tail` / `grep` / `head`.** `tail
   -N` on a PIPE emits NOTHING until EOF, so it buffers away every streaming `◇
   Test case` marker AND the single `RUN-TESTS RESULT:` line the watchdog exists
   to print. The output file stays empty mid-run, which makes a healthy run and a
   wedged run look identical — you lose the only cheap liveness signal. Let the
   watchdog's stdout go STRAIGHT to the output file (it already self-limits its
   output); read the file or wait for the native completion notification. Origin:
   2026-06-01, a `run-tests.sh … | tail -30` background invocation produced a
   0-byte output file for ~5 min; the run looked ghosted but the empty file was
   just `tail` buffering — the actual diagnosis required `ps`. (If you must
   shorten a FOREGROUND, already-finished log, `tail` the output FILE after the
   RESULT line lands — never insert `tail` into the live pipe.)

### Diagnosing "is it hung?" — process liveness, NOT the output file

When a backgrounded test run looks stalled, do NOT infer state from an empty or
silent output file (see rule 5 — it may just be pipe buffering). Infer it from
the **build process**:

```bash
# A genuine run ALWAYS has a live xcodebuild; during compile, also
# swift-frontend / clang. Zero of these = no work happening, full stop.
ps -Ao pid=,%cpu=,command= | grep -iE "xcodebuild|swift-frontend|clang|xctest|SWBBuildService" | grep -v grep
```

- **`xcodebuild` present (any CPU, even 0% briefly between phases)** → working;
  wait for the native completion notification.
- **`xcodebuild` totally absent + watchdog/wrapper still "alive"** → ghost. Kill
  the wrapper tree, `pkill -9 -x SWBBuildService` (Cause B), re-run.
- CoreSimulator runtime daemons (`…/RuntimeRoot/…` at 0%) are the booted sim's
  idle background services — unrelated noise, never evidence of a build.

## Quick reference

```bash
# Unit-test gate (default vrecorderTests, 15-min watchdog):
scripts/run-tests.sh

# A single suite, longer budget:
TIMEOUT_SECS=1200 scripts/run-tests.sh vrecorderTests/DebugCommandTests

# Tests on one sim while verifying on another (true parallelism):
TEST_UDID=<test-sim-udid> scripts/run-tests.sh    # tests here
#   ... drive <other-udid> with sim-tap in a separate step ...
```

## Relationship to other rules

- **Rule 49 (background shells):** this rule's watchdog waits on the exact pid and
  is cancelled when the test finishes first — it never re-arms on a future run.
  The `pgrep -f` false-positive warning here is the same class of bug rule 49
  flags for `pgrep -f "xcodebuild test"` waiters.
- **Rule 48 (parallel execution):** "single simulator → serialize" is the Gate-5
  decision-matrix row. This rule makes the test-vs-verification case explicit and
  gives it a tool.

exec
/bin/zsh -lc "rg -n \"func open\\(|openURL|class XCUIApplication|public.*open\" /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCTest.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Frameworks/XCTest.framework 2>/dev/null | head -120" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCTest.framework/Headers/XCTMetric+UIAutomation.h:7:@class XCUIApplication;
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Frameworks/XCTest.framework/Headers/XCTMetric+UIAutomation.h:7:@class XCUIApplication;

exec
/bin/zsh -lc "find /Applications/Xcode.app -path '*XCTest.swiftinterface' -o -path '*XCTestCore.swiftinterface' 2>/dev/null | head -40" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 4064ms:
web search: 
web search: site:developer.apple.com/documentation/xctest/xcuiapplication open URL XCUITest
web search: 
web search: https://developer.apple.com/documentation/xctest/xcuiapplication/open%28_%3A%29
exec
/bin/zsh -lc "nl -ba vrecorder/Views/APIKeyEntryView.swift | sed -n '1,320p' && nl -ba vrecorder/Views/SettingsScreen.swift | sed -n '1,360p' && nl -ba dev-docs/plans/20260614-feature-2-api-key-entry.md | sed -n '180,300p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	//  APIKeyEntryView.swift
     2	//  Purpose: Light-scope sheet to enter / clear the OpenAI API key (feature #2).
     3	//  Built from VR design tokens per dev-docs/designs/api-key-entry/. Owns exactly
     4	//  one APIKeyEntryModel via @State (constructed from the injected store). The
     5	//  model is the single source of truth; the view never touches the store directly.
     6	
     7	import SwiftUI
     8	
     9	struct APIKeyEntryView: View {
    10	    @State private var model: APIKeyEntryModel
    11	    @State private var confirmClear = false
    12	    let onClose: () -> Void
    13	
    14	    init(store: any APIKeyStoring, onClose: @escaping () -> Void) {
    15	        _model = State(initialValue: APIKeyEntryModel(store: store))
    16	        self.onClose = onClose
    17	    }
    18	
    19	    var body: some View {
    20	        VStack(alignment: .leading, spacing: 0) {
    21	            header
    22	            ScrollView {
    23	                VStack(alignment: .leading, spacing: 8) {
    24	                    Text("OPENAI")
    25	                        .font(.system(size: VR.FontSize.caption)).tracking(VR.capsTracking)
    26	                        .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
    27	                    keyCard
    28	                    if let err = model.errorMessage {
    29	                        Text(err).font(.system(size: VR.FontSize.caption))
    30	                            .foregroundStyle(VR.red500).padding(.horizontal, 16)
    31	                    } else if let masked = model.maskedExisting {
    32	                        Text("当前：\(masked)").font(.system(size: VR.FontSize.caption))
    33	                            .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
    34	                    }
    35	                    if model.hasExistingKey { clearCard }
    36	                    notice
    37	                }
    38	                .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 40)
    39	            }
    40	        }
    41	        .background(VR.surfaceApp)
    42	        .alert("清除密钥？", isPresented: $confirmClear) {
    43	            Button("取消", role: .cancel) {}
    44	            Button("清除", role: .destructive) { _ = model.clear() }
    45	        } message: { Text("清除后需重新输入才能继续同传。") }
    46	    }
    47	
    48	    private var header: some View {
    49	        VStack(alignment: .leading, spacing: 0) {
    50	            HStack {
    51	                Button("取消", action: onClose).foregroundStyle(VR.textFaint)
    52	                Spacer()
    53	                Button("保存") { if model.save() { onClose() } }
    54	                    .font(.system(size: VR.FontSize.body, weight: .semibold))
    55	                    .foregroundStyle(model.canSave ? VR.accentLight : VR.textFaint)
    56	                    .disabled(!model.canSave)
    57	            }
    58	            .font(.system(size: VR.FontSize.body))
    59	            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
    60	            Text("API 密钥")
    61	                .font(.system(size: VR.FontSize.title1, weight: .bold))
    62	                .foregroundStyle(VR.textPrimaryLight)
    63	                .padding(.horizontal, 20).padding(.bottom, 18)
    64	        }
    65	    }
    66	
    67	    private var keyCard: some View {
    68	        HStack(spacing: 12) {
    69	            Text("密钥").foregroundStyle(VR.textFaint)
    70	            SecureField("sk-…", text: $model.draft)
    71	                .textInputAutocapitalization(.never).autocorrectionDisabled()
    72	                .foregroundStyle(VR.textPrimaryLight)
    73	        }
    74	        .font(.system(size: VR.FontSize.body))
    75	        .frame(minHeight: 50).padding(.horizontal, 16)
    76	        .background(VR.surfaceCard)
    77	        .clipShape(RoundedRectangle(cornerRadius: 16))
    78	        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    79	    }
    80	
    81	    private var clearCard: some View {
    82	        Button { confirmClear = true } label: {
    83	            Text("清除密钥").foregroundStyle(VR.red500)
    84	                .font(.system(size: VR.FontSize.body))
    85	                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
    86	                .padding(.horizontal, 16)
    87	        }
    88	        .buttonStyle(.plain)
    89	        .background(VR.surfaceCard)
    90	        .clipShape(RoundedRectangle(cornerRadius: 16))
    91	        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    92	        .padding(.top, 16)
    93	    }
    94	
    95	    private var notice: some View {
    96	        Text("你的密钥保存在本机钥匙串（Keychain）。同传时会以 Bearer 凭证经 TLS 发送给你选择的服务商（OpenAI），不会发给其它第三方。设备被攻破时密钥仍可能泄露。")
    97	            .font(.system(size: VR.FontSize.caption))
    98	            .foregroundStyle(VR.textFaint)
    99	            .padding(.horizontal, 16).padding(.top, 28)
   100	    }
   101	}
     1	//  SettingsScreen.swift
     2	//  Purpose: Light-scope grouped settings list. Mirrors design/settings-screen.jsx.
     3	//  Stage-1 build keeps choices in local @State; Stage 2 backs them with
     4	//  UserDefaults + Keychain (API key). No real persistence yet.
     5	
     6	import SwiftUI
     7	
     8	struct SettingsScreen: View {
     9	    let onBack: () -> Void
    10	    private let store: any APIKeyStoring
    11	
    12	    /// Reflects real Keychain state — refreshed when the key-entry sheet closes
    13	    /// (single refresh path, audit-2 #3/#6). Never hardcode "已配置".
    14	    @State private var keyConfigured: Bool
    15	    @State private var showKeySheet = false
    16	
    17	    // Only the OpenAI engine is wired today; don't offer a selection the app
    18	    // can't honor (audit-4 #1). Re-add "Claude" when ClaudeTranslationEngine exists.
    19	    @State private var engine = "OpenAI"
    20	    @State private var stream = true
    21	    @State private var autoSpeak = true
    22	    @State private var speed = "1.0×"
    23	    @State private var subSize = "标准"
    24	    @State private var transcribeOnly = false
    25	
    26	    /// Real marketing version from the bundle (audit-G4 Low: was hardcoded 1.0.0).
    27	    static var appVersion: String {
    28	        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    29	    }
    30	
    31	    init(onBack: @escaping () -> Void, store: any APIKeyStoring) {
    32	        self.onBack = onBack
    33	        self.store = store
    34	        _keyConfigured = State(initialValue: store.key(for: APIProvider.openAI) != nil)
    35	    }
    36	
    37	    var body: some View {
    38	        VStack(alignment: .leading, spacing: 0) {
    39	            header
    40	            ScrollView {
    41	                VStack(spacing: 24) {
    42	                    group("翻译引擎") {
    43	                        cycleRow("翻译服务", $engine, ["OpenAI"])
    44	                        tapRow("API 密钥", value: keyConfigured ? "已配置" : "未配置") {
    45	                            showKeySheet = true
    46	                        }
    47	                        toggleRow("流式翻译", $stream, last: true)
    48	                    }
    49	                    group("语音播报") {
    50	                        toggleRow("自动播报译文", $autoSpeak)
    51	                        cycleRow("语速", $speed, ["0.8×", "1.0×", "1.2×"], last: true)
    52	                    }
    53	                    group("同声传译") {
    54	                        cycleRow("字幕字号", $subSize, ["标准", "大", "特大"])
    55	                        toggleRow("仅转写模式", $transcribeOnly, last: true)
    56	                    }
    57	                    group("通用") {
    58	                        navRow("历史记录", value: "保留 30 天")
    59	                        destructiveRow("清空翻译记录")
    60	                        navRow("关于", value: "版本 \(Self.appVersion)", last: true)
    61	                    }
    62	                }
    63	                .padding(.horizontal, 20)
    64	                .padding(.vertical, 6)
    65	                .padding(.bottom, 40)
    66	            }
    67	        }
    68	        .background(VR.surfaceApp)
    69	        .ignoresSafeArea(edges: .bottom)
    70	        .sheet(isPresented: $showKeySheet, onDismiss: {
    71	            keyConfigured = store.key(for: APIProvider.openAI) != nil
    72	        }) {
    73	            APIKeyEntryView(store: store, onClose: { showKeySheet = false })
    74	        }
    75	    }
    76	
    77	    private var header: some View {
    78	        HStack(spacing: 6) {
    79	            Button(action: onBack) {
    80	                Image(systemName: "chevron.left")
    81	                    .font(.system(size: 22, weight: .semibold))
    82	                    .foregroundStyle(VR.accentLight)
    83	            }
    84	            Text("设置")
    85	                .font(.system(size: VR.FontSize.title1, weight: .bold))
    86	                .foregroundStyle(VR.textPrimaryLight)
    87	        }
    88	        .padding(.horizontal, 16)
    89	        .padding(.top, 54)
    90	        .padding(.bottom, 10)
    91	    }
    92	
    93	    // MARK: Rows
    94	
    95	    @ViewBuilder
    96	    private func group<C: View>(_ caption: String, @ViewBuilder _ content: () -> C) -> some View {
    97	        VStack(alignment: .leading, spacing: 8) {
    98	            Text(caption)
    99	                .font(.system(size: VR.FontSize.caption))
   100	                .tracking(VR.capsTracking)
   101	                .foregroundStyle(VR.textFaint)
   102	                .padding(.horizontal, 16)
   103	            VStack(spacing: 0) { content() }
   104	                .background(VR.surfaceCard)
   105	                .clipShape(RoundedRectangle(cornerRadius: 16))
   106	                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
   107	        }
   108	    }
   109	
   110	    private func rowChrome<T: View>(_ last: Bool, @ViewBuilder _ content: () -> T) -> some View {
   111	        VStack(spacing: 0) {
   112	            content().frame(minHeight: 50).padding(.horizontal, 16)
   113	            if !last { Divider().background(VR.hairlineLight).padding(.leading, 16) }
   114	        }
   115	    }
   116	
   117	    private func navRow(_ label: String, value: String, last: Bool = false) -> some View {
   118	        rowChrome(last) {
   119	            HStack {
   120	                Text(label).foregroundStyle(VR.textPrimaryLight)
   121	                Spacer()
   122	                Text(value).foregroundStyle(VR.textFaint)
   123	                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
   124	            }.font(.system(size: VR.FontSize.body))
   125	        }
   126	    }
   127	
   128	    private func tapRow(_ label: String, value: String, last: Bool = false, _ action: @escaping () -> Void) -> some View {
   129	        rowChrome(last) {
   130	            Button(action: action) {
   131	                HStack {
   132	                    Text(label).foregroundStyle(VR.textPrimaryLight)
   133	                    Spacer()
   134	                    Text(value).foregroundStyle(VR.textFaint)
   135	                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
   136	                }.font(.system(size: VR.FontSize.body)).contentShape(Rectangle())
   137	            }.buttonStyle(.plain)
   138	        }
   139	    }
   140	
   141	    private func cycleRow(_ label: String, _ sel: Binding<String>, _ options: [String], last: Bool = false) -> some View {
   142	        rowChrome(last) {
   143	            Button {
   144	                let i = options.firstIndex(of: sel.wrappedValue) ?? 0
   145	                sel.wrappedValue = options[(i + 1) % options.count]
   146	            } label: {
   147	                HStack {
   148	                    Text(label).foregroundStyle(VR.textPrimaryLight)
   149	                    Spacer()
   150	                    Text(sel.wrappedValue).foregroundStyle(VR.textFaint)
   151	                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
   152	                }.font(.system(size: VR.FontSize.body))
   153	            }.buttonStyle(.plain)
   154	        }
   155	    }
   156	
   157	    private func toggleRow(_ label: String, _ on: Binding<Bool>, last: Bool = false) -> some View {
   158	        rowChrome(last) {
   159	            Toggle(isOn: on) {
   160	                Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.textPrimaryLight)
   161	            }.tint(VR.violet500)
   162	        }
   163	    }
   164	
   165	    private func destructiveRow(_ label: String) -> some View {
   166	        rowChrome(false) {
   167	            Button {} label: {
   168	                Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.red500)
   169	                    .frame(maxWidth: .infinity, alignment: .leading)
   170	            }.buttonStyle(.plain)
   171	        }
   172	    }
   173	}
   180	  the designed light-scope card system; user chose the design-system sheet.
   181	- *Push via `NavigationStack`* — RootView uses manual ZStack navigation; a sheet
   182	  is lighter than introducing a NavigationStack for one screen.
   183	- *Keep delete-then-add in the store* — rejected: destroys the old key on a
   184	  failed write and opens a missing-key window for concurrent translation.
   185	- *Validate only "non-empty"* — rejected: lets emoji/CJK/garbage through; a
   186	  provider-shaped regex catches paste errors early.
   187	
   188	## Work items (audit-1 #8 resolved — ONE cohesive WI/PR)
   189	
   190	- **WI-1 (behavioral)** — atomic store + `APIKeyEntryModel` + `APIKeyEntryView` +
   191	  Settings/Root wiring, in **one PR**. Foundational logic (store, model) is
   192	  unit-tested; the UI slice is simulator-verified. Small enough for a single
   193	  audit + verification gate.
   194	
   195	## Test catalogue (audit-1 #7)
   196	
   197	`vrecorderTests/APIKeyEntryModelTests.swift`:
   198	- `isValidRejectsEmptyAndTooShort` (len 7) / `isValidRejectsTooLong` (len 501)
   199	- `isValidRejectsInternalWhitespaceControlAndNonASCII` (emoji/CJK/newline)
   200	- `isValidAcceptsPlainKeyAndProjKey` (`sk-...` and `sk-proj-...` and a non-`sk` key)
   201	- `saveTrimsPersistsAndClearsDraft`
   202	- `saveGuardsOnValidity` (direct `save()` with invalid draft is a no-op, returns false)
   203	- `saveFailurePreservesPreviousKeyAndSetsError` (InMemory `failNextWrite`)
   204	- `clearRemovesKeyAndUpdatesState`
   205	- `maskShowsOnlyLast4` / `maskShortSecretDoesNotRevealIt` / `maskNilWhenAbsent`
   206	- `hasExistingKeyReflectsStoreOnInitAndAfterOps`
   207	
   208	`vrecorderTests/KeychainAPIKeyStoreTests.swift` (injected `KeychainOps` with
   209	scripted `OSStatus` — real status-handling coverage, audit-2 #3):
   210	- `updateSuccessReturnsTrueWithoutAdd`
   211	- `updateNotFoundFallsBackToAdd`
   212	- `addFailureReturnsFalseAndLeavesOldKey` (no destructive delete)
   213	- `updateFailureOtherThanNotFoundPreservesOldKey`
   214	- `clearSuccess` / `clearNotFoundCountsAsSuccess` / `clearFailureReturnsFalse`
   215	- Real-Keychain round-trip (`setThenGet`, `clearThenGetNil`) runs on the simulator
   216	  in Gate-5 verification, not in the unit suite.
   217	
   218	Plus `APIKeyEntryModelTests`: `clearFailureRetainsConfiguredStateAndSetsError`.
   219	
   220	## Edge cases
   221	
   222	- Empty / whitespace-only draft → invalid, 保存 disabled, direct save() no-op.
   223	- Pasted key with surrounding newline/space → trimmed; internal control/space → invalid.
   224	- `sk-` alone or very short → invalid (length guard).
   225	- CJK / emoji → invalid (no `sk-` prefix).
   226	- Clearing when no key exists → no-op, no crash.
   227	- Masking a short stored secret → never reveal it; show "已配置".
   228	- Overwrite existing key → atomic update; old key preserved if write fails.
   229	- Concurrent active translation during overwrite → no missing-key window (atomic).
   230	- DEBUG seed present → sheet shows masked existing; can overwrite/clear.
   231	
   232	## Acceptance criteria
   233	
   234	1. Tapping "API 密钥" opens the entry sheet.
   235	2. Valid `sk-...` key + 保存 → stored in Keychain, Settings row shows "已配置",
   236	   sheet dismisses.
   237	3. 清除密钥 (with confirm) → key removed, row shows "未配置".
   238	4. Empty/invalid input keeps 保存 disabled and direct save() is a no-op.
   239	5. A simulated Keychain write failure keeps the sheet open, shows an error, and
   240	   preserves the previous key.
   241	6. Works in a Release build (independent of the DEBUG bundled file).
   242	7. Reuses only existing design-system tokens — no new visual language.
   243	
   244	## Risks + mitigations
   245	
   246	- **Reactive refresh**: `apiKeyConfigured` is construction-time today → make it
   247	  `@State`, refreshed on sheet `onDismiss`.
   248	- **Keychain on simulator**: verify real round-trip (set/get/clear) on the sim.
   249	- **rule 51**: resolved via the committed design artifact + recorded authorization.
   250	
   251	## Docs sync + version bump (audit-2 #7, rules 24 + 40)
   252	
   253	- **`docs/architecture.md`**: add `APIKeyEntryModel` to the Services table and
   254	  note the Settings → key-entry sheet flow. **`README.md`** (rule 24, user-visible
   255	  feature lands): add a bullet noting in-app OpenAI key configuration (Settings ›
   256	  API 密钥). **`docs/features.md`**: row #2 → `IN PROGRESS` then `DONE`/`VERIFIED`.
   257	- **Version bump** (rule 40): minor — `0.1.0` → `0.2.0`, `CURRENT_PROJECT_VERSION`
   258	  `1` → `2`, via `project.yml` + `xcodegen generate`, as the tail commit before
   259	  the PR.
   260	
   261	## Backward compat
   262	
   263	Additive. `setKey` return value is `@discardableResult` (existing callers
   264	unaffected). DEBUG `config/openai-key.txt` seeding still works (same Keychain
   265	item, now written via atomic update). No schema, no migration.

web search: 
web search: site:github.com/yonaskolb/XcodeGen project spec Info.plist INFOPLIST_FILE configs GENERATE_INFOPLIST_FILE UI testing target
web search: 
web search: https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md
exec
/bin/zsh -lc 'find .claude/codex-audits -maxdepth 2 -type f -print 2>/dev/null | sort | tail -30' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
.claude/codex-audits/.gitkeep
.claude/codex-audits/feat-1-mvp-pipeline-scaffold-audit.md
.claude/codex-audits/feat-2-api-key-entry-audit.md
.claude/codex-audits/fix-3-vad-rollover-audit.md
.claude/codex-audits/fix-4-bounded-partials-audit.md
.claude/codex-audits/fix-5-bluetooth-route-audit.md
.claude/codex-audits/fix-8-http-timeout-mapping-audit.md
.claude/codex-audits/fix-9-recognizer-generation-audit.md
.claude/codex-audits/plan-feature-2-r2.md
.claude/codex-audits/plan-feature-2-r3.md
.claude/codex-audits/plan-feature-2-r4.md
.claude/codex-audits/plan-feature-2.md
.claude/codex-audits/plan-feature-6-r2.md
.claude/codex-audits/plan-feature-6-r3.md
.claude/codex-audits/plan-feature-6.md
.claude/codex-audits/prepush-01e5693.md
.claude/codex-audits/prepush-1f287ee.md
.claude/codex-audits/prepush-1f8798f.md
.claude/codex-audits/prepush-25e2320.md
.claude/codex-audits/prepush-6211616.md
.claude/codex-audits/prepush-64afb36.md
.claude/codex-audits/prepush-86728ad.md
.claude/codex-audits/prepush-d366761.md
.claude/codex-audits/prepush-d60140e.md
.claude/codex-audits/prepush-ea45f81.md
.claude/codex-audits/prepush-f62e8fa.md

exec
/bin/zsh -lc "sed -n '1,320p' .claude/codex-audits/plan-feature-6-r2.md && sed -n '1,320p' .claude/codex-audits/plan-feature-6-r3.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019ec6e1-7b4d-7ca0-af0e-0516173a531c
--------
user
INDEPENDENT plan auditor, vrecorder-v2 (Swift 6 / SwiftUI / XCUITest, iOS 26). REVISION 2 of the feature-#6 plan (verification harness), addressing your round-1 findings: (1) model fixture API since pushA/pushB are internal + no reset; (2) UI-testing launch mode with seeded InMemoryAPIKeyStore for Keychain isolation; (3) concrete Debug/Release INFOPLIST_FILE mechanism with GENERATE_INFOPLIST_FILE:NO + a Release-excludes-scheme assertion; (4) deterministic background-stop lifecycle test after lifting env to the App; (5) feature #2 VERIFIED gated on the FULL 7-criterion matrix + sim-tap scope split to feature #6b; (6) 4-WI split. Verify each is resolved and surface any NEW Critical/High/Medium. Read the repo to confirm symbols (LiveSessionModel.stop/pushA, AppEnvironment.init, the current GENERATE_INFOPLIST_FILE setup in project.yml). End with exactly 'VERDICT: BLOCK' if any Critical/High/Medium remains, else 'VERDICT: PASS'.

PLAN r2:
# Feature #6 — Verification harness (XCUITest + DebugBridge)

> Gate-1 plan, revision 2. Status: PLANNED after Gate-2 audit passes.
> **Estimated PR size**, per WI (separate PR each): WI-1 ~3 files / ~90 LOC
> (model fixture API + tests); WI-2 ~7 files (UITest target, a11y ids on 4 views,
> launch-mode wiring, smoke test) / ~160 LOC; WI-3 ~5 files (DebugBridge, plist
> restructure, app wiring, parser tests, lifecycle test) / ~200 LOC; WI-4 ~1 file
> + evidence / ~120 LOC. Medium feature, **4 WIs**.

## Revision history
- **r1** — initial plan. Gate-2 audit r1: 2 High + 4 Medium.
- **r2** — adds a named `@MainActor` fixture API (pushA/pushB are `internal`, no
  reset existed); a UI-testing launch mode with a seeded `InMemoryAPIKeyStore`
  (real-Keychain isolation); concrete Debug/Release `INFOPLIST_FILE` mechanism for
  the URL scheme + a Release-excludes-scheme assertion; a deterministic
  background-stop lifecycle test; feature #2 VERIFIED gated on its FULL 7-criterion
  acceptance matrix; sim-tap/gesture-driver scope reconciled (split to feature
  #6b); 4-WI split.

## Problem
The `cron-prompts/verify.md` workflow assumes a CU-free verification harness
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
feature #6b** (XCUITest's native tap/typeText covers feature #6; idb is not
installed) — the `docs/features.md` #6 row and the reference in
`cron-prompts/verify.md` are reconciled to point at #6b for the gesture driver.
The demo simulator path is unaffected.

## Model fixture API (audit-r1 #1 — resolves the reset-contract gap)
`LiveSessionModel.pushA/pushB` are `internal` and there is no reset; injecting mid
-session would race the recognizer/demo tasks. Add ONE named, `@MainActor`
operation, unit-tested independently of the bridge:

- `func installFixture(a: [TranscriptLine], b: [TranscriptLine])` — calls `stop()`
  first (tears down any live recognizer/demo work + bumps the session generation,
  so no in-flight task mutates the fixture), then atomically replaces `partyA` /
  `partyB`. `func resetTranscripts()` — installs empty/default state.
- These are normal model methods (DEBUG callers only, but the methods themselves
  compile in all configs — no `#if DEBUG` on the model API, only on the bridge
  that calls them). Unit tests: `installFixtureStopsActiveSessionAndReplaces`,
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
    `@MainActor func handle(_ url: URL)` parses `vrecorder-debug://inject?a=…&b=…`
    → `session.installFixture(...)`; `…/reset` → `resetTranscripts()`; malformed →
    no-op. Synchronous on the main actor (no Sendable / detached task).
  - MODIFY `VRecorderApp.swift`: `.onOpenURL { #if DEBUG; DebugBridge(env.session).handle($0); #endif }`.
  - **URL-scheme registration (audit-r1 #3):** set `GENERATE_INFOPLIST_FILE: NO`
    and provide explicit `vrecorder/Resources/Info-Debug.plist` (with the
    `CFBundleURLTypes` `vrecorder-debug` entry) and `Info-Release.plist` (without),
    selected via `settings.configs.Debug.INFOPLIST_FILE` /
    `settings.configs.Release.INFOPLIST_FILE`. Both plists carry the existing
    `INFOPLIST_KEY_*` values (mic/speech usage, orientation, etc.) as real keys.
  - NEW `vrecorderTests/DebugBridgeTests.swift` (`#if DEBUG`): URL parsing →
    fixture installed / reset / malformed no-op (drives a model directly, no UI).
  - NEW lifecycle regression: `vrecorderUITests/LifecycleUITests.swift` — inject a
    fixture, background+foreground the app, assert the session stopped (audit-r1 #4)
    — deterministic via the fixture, not a real recognizer.
- **WI-4 (final) — feature #2 full acceptance verification**
  - NEW `vrecorderUITests/APIKeyEntryUITests.swift`: with `-uiTesting` + seeded
    InMemory store, exercise feature #2's FULL acceptance matrix (audit-r1 #5):
    open sheet; valid key → 保存 → 已配置; invalid/empty → 保存 disabled; 清除 (with
    confirm) → 未配置; cancel leaves state. (Failure-preservation + Release-only
    criteria that can't be driven in a DEBUG sim UI test are recorded as covered by
    the feature-#2 unit suite in the evidence matrix, not silently skipped.)
  - Update `dev-docs/verification/feature-2-<date>.md` with the full matrix →
    feature #2 flips to VERIFIED only if every criterion is pass (per SCHEMA).

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
  `resetClears`, `malformedURLIsNoOp` (drives a model directly).
- `vrecorderUITests/LiveScreenUITests.swift`: `liveScreenShowsMicAndGear`.
- `vrecorderUITests/LifecycleUITests.swift`: `backgroundStopsActiveSession`.
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
4. feature #2's FULL acceptance matrix is exercised (UI tests for the drivable
   criteria + a cited unit-suite mapping for the rest) and recorded — feature #2
   flips to VERIFIED only if every criterion is pass.
5. The background-stop lifecycle still holds after lifting `env` to the App
   (deterministic UI test).
6. All UI tests run on the iPhone 17 Pro simulator through `run-tests.sh`.
7. No production behavior change; DebugBridge + the URL scheme are DEBUG-only.

## Scope reconciliation (audit-r1 #5)
The `docs/features.md` #6 row and `cron-prompts/verify.md` reference an idb
`sim-tap.sh` gesture driver + `docs/subsystems/sim-gesture-driver.md`. This plan
EXCLUDES them (XCUITest's native tap/typeText covers feature #6; idb isn't
installed). On Gate-1 acceptance: file **feature #6b — idb gesture-driver fallback**
and edit the #6 row to scope it to the XCUITest+DebugBridge core, so the tracker
matches this plan. The verify cron can already use XCUITest once #6 lands; #6b adds
gestures XCUITest can't express.

## Risks + mitigations
- **URL-scheme registration mechanism**: `CFBundleURLTypes` isn't an
  `INFOPLIST_KEY_…` one-liner. Mitigation: add a checked-in `Debug.xcconfig` or a
  partial Info.plist with the URL type (DEBUG config only); WI-2 confirms the exact
  xcodegen mechanism before coding.
- **App-owns-AppEnvironment refactor** could disturb the scene-phase teardown
  (audit-G4r2 #2 fix). Mitigation: keep `@State` ownership, just lift it one level
  (App → injected into RootView); a UI test asserts background still stops.
- **XCUITest flakiness**: bounded `waitForExistence`, no sleeps; UDID-pinned sim.

## Docs sync + version bump (rules 24 + 40)
- `docs/architecture.md`: note the DebugBridge + UITest target. `README.md`:
  Developer Tools / testing note. `docs/features.md`: row #6 PLANNED → IN PROGRESS
  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.

## Backward compat
Additive + DEBUG-only. No schema, no Release behavior change. The
App-owns-AppEnvironment change is internal wiring.
codex
I’ll audit this against the repository’s actual symbols, build settings, tracker rules, and feature #2 acceptance criteria. I’ll start with status and the architecture/rule files, then trace the model, environment, app lifecycle, and current project configuration.
exec
/bin/zsh -lc "git status -sb && printf '\\n-- files --\\n' && rg --files -g 'AGENTS.md' -g 'docs/architecture.md' -g '.claude/rules/47-feature-workflow.md' -g '.claude/rules/10-tdd.md' -g '.claude/rules/24-doc-sync.md' -g '.claude/rules/40-version-bump.md' -g '.claude/rules/51-no-self-designed-ui.md' -g 'docs/features.md' -g 'cron-prompts/verify.md' -g 'project.yml' -g 'vrecorder/**/*.swift' -g 'vrecorderTests/**/*.swift'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
## feat/6-verification-harness
?? dev-docs/plans/20260615-feature-6-verification-harness.md

-- files --
vrecorderTests/LiveSessionModelTests.swift
vrecorderTests/PipelineFlowTests.swift
vrecorderTests/OpenAITranslationEngineTests.swift
vrecorderTests/APIKeyEntryModelTests.swift
vrecorderTests/RecognitionEventCoalescerTests.swift
vrecorderTests/AudioSessionControllerTests.swift
vrecorderTests/AudioTapBridgeTests.swift
vrecorderTests/KeychainAPIKeyStoreTests.swift
vrecorderTests/PCMRolloverTests.swift
vrecorderTests/OpenAIStatusMappingTests.swift
AGENTS.md
docs/features.md
docs/architecture.md
project.yml
vrecorder/Views/LiveScreen.swift
vrecorder/Views/APIKeyEntryView.swift
vrecorder/Views/Components/MicButton.swift
vrecorder/Views/Components/LiveBadge.swift
vrecorder/Views/Components/WaterSurface.swift
vrecorder/Views/Components/TranscriptLineView.swift
vrecorder/Views/SettingsScreen.swift
vrecorder/Engines/AppleSpeechRecognizer.swift
vrecorder/Engines/StreamingEvents.swift
vrecorder/Engines/RecognitionEventCoalescer.swift
vrecorder/Engines/OpenAITranslationEngine.swift
vrecorder/Engines/EngineProtocols.swift
vrecorder/Audio/AudioSessionController.swift
vrecorder/Audio/PCMRollover.swift
vrecorder/Audio/AudioTapBridge.swift
vrecorder/Models/LiveSessionModel.swift
vrecorder/Models/TranscriptLine.swift
vrecorder/Security/APIKeyBootstrap.swift
vrecorder/Security/APIKeyStore.swift
vrecorder/Security/APIKeyEntryModel.swift
vrecorder/App/AppEnvironment.swift
vrecorder/App/VRecorderApp.swift
vrecorder/App/RootView.swift
vrecorder/App/Log.swift
vrecorder/DesignSystem/Palette.swift
vrecorder/DesignSystem/Typography.swift

codex
The branch contains only the untracked plan artifact, so there are no implementation changes to conflate with this review. I’m now reading the binding workflow and the exact code paths the plan proposes to change, including existing tests that define lifecycle and API-key behavior.
exec
/bin/zsh -lc 'nl -ba vrecorder/Views/LiveScreen.swift; nl -ba vrecorder/Views/Components/MicButton.swift' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	//  LiveScreen.swift
     2	//  Purpose: Main screen — full-screen two-party split (ink top / violet bottom).
     3	//  Mirrors design/live-screen.jsx. Stage-1 build is driven by LiveSessionModel's
     4	//  demo simulator; the real pipeline plugs into the same model in Stage 2.
     5	
     6	import SwiftUI
     7	
     8	struct LiveScreen: View {
     9	    @State private var session: LiveSessionModel
    10	    let onSettings: () -> Void
    11	
    12	    init(session: LiveSessionModel, onSettings: @escaping () -> Void) {
    13	        _session = State(initialValue: session)
    14	        self.onSettings = onSettings
    15	    }
    16	
    17	    var body: some View {
    18	        GeometryReader { _ in
    19	            VStack(spacing: 0) {
    20	                partyB
    21	                partyA
    22	            }
    23	        }
    24	        .background(VR.partyBSurface)
    25	        .ignoresSafeArea()
    26	        .alert("同传出错", isPresented: Binding(
    27	            get: { session.errorMessage != nil },
    28	            set: { if !$0 { session.clearError() } }
    29	        )) {
    30	            Button("好", role: .cancel) {}
    31	        } message: {
    32	            Text(session.errorMessage ?? "")
    33	        }
    34	    }
    35	
    36	    // MARK: Counterpart (ink, English)
    37	
    38	    private var partyB: some View {
    39	        ZStack(alignment: .top) {
    40	            VStack(alignment: .leading, spacing: 8) {
    41	                Spacer()
    42	                Text("ENGLISH")
    43	                    .font(.system(size: VR.FontSize.caption))
    44	                    .tracking(VR.capsTracking)
    45	                    .foregroundStyle(VR.partyBTextDim)
    46	                ForEach(session.partyB) { TranscriptLineView(line: $0, party: .b) }
    47	            }
    48	            .frame(maxWidth: .infinity, alignment: .leading)
Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019ec6e6-6264-79c2-b961-3650f9bfc51e
--------
user
INDEPENDENT plan auditor, vrecorder-v2 (Swift 6 / SwiftUI / XCUITest, iOS 26). REVISION 3 of the feature-#6 plan (verification harness), addressing your round-2 findings: (1) active-session fixture (installFixture listening: param sets the model's listening flag without a real recognizer) + observable MicButton accessibilityValue so the lifecycle test asserts a real stop; (2) DECOUPLED — feature #6 no longer claims to flip feature #2 to VERIFIED (WI-4 is a harness smoke; feature #2's real-Keychain+Release Gate-5 stays separate); (3) added a DebugBridge end-to-end UI test (open the URL, assert rendered transcript); (4) added feature-6's own evidence file; (5) #6b renamed to numeric #7, verify.md path corrected; removed stale plist wording. Verify each is resolved and surface any NEW Critical/High/Medium. End with exactly 'VERDICT: BLOCK' if any Critical/High/Medium remains, else 'VERDICT: PASS'.

PLAN r3:
# Feature #6 — Verification harness (XCUITest + DebugBridge)

> Gate-1 plan, revision 3. Status: PLANNED after Gate-2 audit passes.
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
  alternative wording.

## Problem
The `cron-prompts/verify.md` workflow assumes a CU-free verification harness
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
feature #6b** (XCUITest's native tap/typeText covers feature #6; idb is not
installed) — the `docs/features.md` #6 row and the reference in
`cron-prompts/verify.md` are reconciled to point at #6b for the gesture driver.
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
- These are normal model methods (DEBUG callers only, but compile in all configs —
  no `#if DEBUG` on the model API, only on the bridge that calls them). Unit tests:
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
    `@MainActor func handle(_ url: URL)` parses `vrecorder-debug://inject?a=…&b=…`
    → `session.installFixture(...)`; `…/reset` → `resetTranscripts()`; malformed →
    no-op. Synchronous on the main actor (no Sendable / detached task).
  - MODIFY `VRecorderApp.swift`: `.onOpenURL { #if DEBUG; DebugBridge(env.session).handle($0); #endif }`.
  - **URL-scheme registration (audit-r1 #3):** set `GENERATE_INFOPLIST_FILE: NO`
    and provide explicit `vrecorder/Resources/Info-Debug.plist` (with the
    `CFBundleURLTypes` `vrecorder-debug` entry) and `Info-Release.plist` (without),
    selected via `settings.configs.Debug.INFOPLIST_FILE` /
    `settings.configs.Release.INFOPLIST_FILE`. Both plists carry the existing
    `INFOPLIST_KEY_*` values (mic/speech usage, orientation, etc.) as real keys.
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
  `resetClears`, `malformedURLIsNoOp` (drives a model directly).
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
  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.

## Backward compat
Additive + DEBUG-only. No schema, no Release behavior change. The
App-owns-AppEnvironment change is internal wiring.
codex
I’ll audit revision 3 against the five claimed fixes and check the repository rules and current implementation for contradictions. I’ll start with `git status`, `docs/architecture.md`, the feature workflow/TDD rules, and the files this plan proposes to change.
exec
/bin/zsh -lc "git status -sb && printf '\\n-- files --\\n' && rg --files | sed -n '1,240p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
## feat/6-verification-harness
?? dev-docs/plans/20260615-feature-6-verification-harness.md

-- files --
CLAUDE.md
vrecorderTests/LiveSessionModelTests.swift
vrecorderTests/PipelineFlowTests.swift
vrecorderTests/OpenAITranslationEngineTests.swift
vrecorderTests/APIKeyEntryModelTests.swift
vrecorderTests/RecognitionEventCoalescerTests.swift
vrecorderTests/AudioSessionControllerTests.swift
vrecorderTests/AudioTapBridgeTests.swift
vrecorderTests/KeychainAPIKeyStoreTests.swift
vrecorderTests/PCMRolloverTests.swift
vrecorderTests/OpenAIStatusMappingTests.swift
AGENTS.md
scripts/run-codex.sh
scripts/run-tests.sh
scripts/git-hooks/pre-push
scripts/git-hooks/install.sh
README.md
dev-docs/audit/DIMENSIONS-ios.md
dev-docs/verification/bug-5-20260615.md
dev-docs/verification/bug-3-20260614.md
dev-docs/verification/bug-1-20260614.md
dev-docs/verification/SCHEMA.md
dev-docs/verification/bug-2-20260615.md
dev-docs/verification/feature-2-20260614.md
dev-docs/decisions/ADR-001-mvp-scaffold-audit-bypass.md
dev-docs/decisions/README.md
dev-docs/plans/20260615-feature-6-verification-harness.md
dev-docs/plans/20260614-feature-2-api-key-entry.md
dev-docs/无人值守开发-启动教程-vrecorder-v2.html
dev-docs/designs/api-key-entry/api-key-entry.html
dev-docs/designs/api-key-entry/README.md
dev-docs/无人值守开发-goal与cron辨析.html
dev-docs/冷启动手册-小白版-从初始化到无人值守.html
docs/features.md
docs/tasks.md
docs/bugs.md
docs/architecture.md
project.yml
config/README.md
vrecorder/Views/LiveScreen.swift
vrecorder/Views/APIKeyEntryView.swift
vrecorder/Views/Components/MicButton.swift
vrecorder/Views/Components/LiveBadge.swift
vrecorder/Views/Components/WaterSurface.swift
vrecorder/Views/Components/TranscriptLineView.swift
vrecorder/Views/SettingsScreen.swift
vrecorder/Engines/AppleSpeechRecognizer.swift
vrecorder/Engines/StreamingEvents.swift
vrecorder/Engines/RecognitionEventCoalescer.swift
vrecorder/Engines/OpenAITranslationEngine.swift
vrecorder/Engines/EngineProtocols.swift
vrecorder/Audio/AudioSessionController.swift
vrecorder/Audio/PCMRollover.swift
vrecorder/Audio/AudioTapBridge.swift
vrecorder/Models/LiveSessionModel.swift
vrecorder/Models/TranscriptLine.swift
vrecorder/Resources/Assets.xcassets/Contents.json
vrecorder/Resources/Assets.xcassets/AccentColor.colorset/Contents.json
vrecorder/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
vrecorder/Security/APIKeyBootstrap.swift
vrecorder/Security/APIKeyStore.swift
vrecorder/Security/APIKeyEntryModel.swift
vrecorder/App/AppEnvironment.swift
vrecorder/App/VRecorderApp.swift
vrecorder/App/RootView.swift
vrecorder/App/Log.swift
vrecorder/DesignSystem/Palette.swift
vrecorder/DesignSystem/Typography.swift
design/mvp.html
design/tokens/motion.css
design/tokens/effects.css
design/tokens/colors.css
design/tokens/spacing.css
design/tokens/typography.css

exec
/bin/zsh -lc 'rg -n -C 8 "VERDICT:|Critical|High|Medium" .claude/codex-audits/plan-feature-6-r2.md | tail -180' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
7238:769:   75  - Zero open Critical/High/Medium findings.
7239:834:  140  | Medium | 2-4 WIs | 1                       | 1 per WI                                                                                |
7240:866:  172  Feature #46 (WebDAV materializing restore, 11 WIs, High priority):
7241:1620:   54  | 1   | MVP 同传管线骨架（同传屏/设置屏 + 本地STT + OpenAI翻译 + Keychain key） | pipeline/ui | High | DONE | Scaffold, retro-registered outside gates 1-2 (course demo). Mirror: no. Pipeline-translate leg verified against live OpenAI; on-device STT needs device verify (Gate 5 deferred). Pre-push Codex audit (prepush-25e2320) found 6H+2M; fixes #3-8 + #1 applied (see Notes). |
7242:1621:   55  | 2   | Release 内 API 密钥录入页（Keychain 编辑器） | ui/settings | Medium | DONE | Shipped in v0.2.0 (PR #2, merge `1d3644d`). 4 plan-audit + 2 impl-audit rounds. Design bundle `dev-docs/designs/api-key-entry/` (owner-authorized). 31 tests. NOT yet VERIFIED — interactive tap flow needs a manual device pass (evidence `feature-2-20260614.md`, result: partial). Mirror: no. |
7243:1622:   56  | 3   | 打断后自动暂停/恢复（来电/Siri/AirPods 后续传） | audio/pipeline | Low | TODO | From audit-3 #5 (Medium, non-blocking): 当前打断即 stop()，需重新点麦克风。理想是 paused 态保留观察、interruption-ended `shouldResume` 时自动恢复。演示影响小。Mirror: no. |
7244:1623:   57  | 4   | 专用 VAD/分段阶段（无间隙轮转，连续传译鲁棒分句） | audio/pipeline | Medium | TODO | From bug-#1 audits: PCMRollover mitigates the common rotation gap but a long gap during sustained speech can still truncate. Robust fix = a dedicated VAD/segmentation stage that rotates recognition with no gap; ALSO owns the demand-aware bounded streaming pump (bug #2 residual: output stream + finals array not yet backpressured). Needs Gate-1 plan. Mirror: no. |
7245:1625:   59  | 6   | 验证 harness（XCUITest + DebugBridge + sim-gesture 驱动） | tooling/test | High | TODO | cron verify.md 假设的 harness（XCUITest target / vrecorder-debug:// DebugBridge / scripts/sim-tap.sh / sim-gesture-driver 文档）都不存在，导致 verify cron 全 blocked。建之以解锁 UI/可脚本化验证；音频真机验证仍需人工。GH issue filed. Mirror: no. |
7246:1646:   80  **Audit fixes (pre-push Codex `prepush-25e2320`, 6 High + 2 Medium):**
7247:1667:  101  documented `--no-verify` bypass — see **ADR-001**. Mediums (route
7248:1698:   28  | Pure data models  | If non-trivial | `BookRecord`, `HighlightRecord` — test invariants, not getters            |
7249:2168:     5	> WI-2 ~3 files / ~140 LOC; WI-3 ~1 file / ~90 LOC. Medium feature, 3 WIs.
7250-2557:## Rules
7251-2567:## How to use
7252-2582:## Statuses
7253-2592:## Plan Template
7254-2602:## Features
7255:2606:| 1   | MVP 同传管线骨架（同传屏/设置屏 + 本地STT + OpenAI翻译 + Keychain key） | pipeline/ui | High | DONE | Scaffold, retro-registered outside gates 1-2 (course demo). Mirror: no. Pipeline-translate leg verified against live OpenAI; on-device STT needs device verify (Gate 5 deferred). Pre-push Codex audit (prepush-25e2320) found 6H+2M; fixes #3-8 + #1 applied (see Notes). |
7256:2607:| 2   | Release 内 API 密钥录入页（Keychain 编辑器） | ui/settings | Medium | DONE | Shipped in v0.2.0 (PR #2, merge `1d3644d`). 4 plan-audit + 2 impl-audit rounds. Design bundle `dev-docs/designs/api-key-entry/` (owner-authorized). 31 tests. NOT yet VERIFIED — interactive tap flow needs a manual device pass (evidence `feature-2-20260614.md`, result: partial). Mirror: no. |
7257:2608:| 3   | 打断后自动暂停/恢复（来电/Siri/AirPods 后续传） | audio/pipeline | Low | TODO | From audit-3 #5 (Medium, non-blocking): 当前打断即 stop()，需重新点麦克风。理想是 paused 态保留观察、interruption-ended `shouldResume` 时自动恢复。演示影响小。Mirror: no. |
7258:2609:| 4   | 专用 VAD/分段阶段（无间隙轮转，连续传译鲁棒分句） | audio/pipeline | Medium | TODO | From bug-#1 audits: PCMRollover mitigates the common rotation gap but a long gap during sustained speech can still truncate. Robust fix = a dedicated VAD/segmentation stage that rotates recognition with no gap; ALSO owns the demand-aware bounded streaming pump (bug #2 residual: output stream + finals array not yet backpressured). Needs Gate-1 plan. Mirror: no. |
7259:2611:| 6   | 验证 harness（XCUITest + DebugBridge + sim-gesture 驱动） | tooling/test | High | TODO | cron verify.md 假设的 harness（XCUITest target / vrecorder-debug:// DebugBridge / scripts/sim-tap.sh / sim-gesture-driver 文档）都不存在，导致 verify cron 全 blocked。建之以解锁 UI/可脚本化验证；音频真机验证仍需人工。GH issue filed. Mirror: no. |
7260-2613:### Feature #1 — Notes (retro)
7261-2628:## Required frontmatter
7262-2647:## Required sections
7263-2654:## `result` semantics (decides whether the row may flip)
7264:2664:docs/features.md:54:| 1   | MVP 同传管线骨架（同传屏/设置屏 + 本地STT + OpenAI翻译 + Keychain key） | pipeline/ui | High | DONE | Scaffold, retro-registered outside gates 1-2 (course demo). Mirror: no. Pipeline-translate leg verified against live OpenAI; on-device STT needs device verify (Gate 5 deferred). Pre-push Codex audit (prepush-25e2320) found 6H+2M; fixes #3-8 + #1 applied (see Notes). |
7265:2665:docs/features.md:55:| 2   | Release 内 API 密钥录入页（Keychain 编辑器） | ui/settings | Medium | DONE | Shipped in v0.2.0 (PR #2, merge `1d3644d`). 4 plan-audit + 2 impl-audit rounds. Design bundle `dev-docs/designs/api-key-entry/` (owner-authorized). 31 tests. NOT yet VERIFIED — interactive tap flow needs a manual device pass (evidence `feature-2-20260614.md`, result: partial). Mirror: no. |
7266-2761:## Edge cases
7267-2773:## Acceptance criteria
7268-2785:## Risks + mitigations
7269-2792:## Docs sync + version bump (audit-2 #7, rules 24 + 40)
7270-2802:## Backward compat
7271-2823:## Revision history
7272:2825:- **r1** — initial plan. Audit round 1: 2 High + 7 Medium.
7273:2827:  validation/masking, one WI/PR, BYOK threat model. Audit round 2: 1 High + 6 Med.
7274:2832:  2 High + 3 Medium.
7275-2838:## Problem
7276-2846:## Design authority (audit-1 #1 / audit-2 #1)
7277-2859:## BYOK threat model (audit-1 #9 / audit-2 #2)
7278-2872:## Atomic Keychain write (audit-1 #2 + #5 resolved)
7279:3000:./docs/features.md:59:| 6   | 验证 harness（XCUITest + DebugBridge + sim-gesture 驱动） | tooling/test | High | TODO | cron verify.md 假设的 harness（XCUITest target / vrecorder-debug:// DebugBridge / scripts/sim-tap.sh / sim-gesture-driver 文档）都不存在，导致 verify cron 全 blocked。建之以解锁 UI/可脚本化验证；音频真机验证仍需人工。GH issue filed. Mirror: no. |
7280:3248:1. **High: DebugBridge cannot implement the planned reset contract.**  
7281:3252:2. **High: API-key UI tests are not isolated.**  
7282:3256:3. **Medium: DEBUG-only URL registration remains unresolved.**  
7283:3260:4. **Medium: lifecycle regression mitigation is not represented in the test catalogue.**  
7284:3265:5. **Medium: feature completion claims exceed the planned verification.**  
7285:3269:6. **Medium: WI estimates omit required files and tests.**  
7286:3280:VERDICT: BLOCK
7287:3285:1. **High: DebugBridge cannot implement the planned reset contract.**  
7288:3289:2. **High: API-key UI tests are not isolated.**  
7289:3293:3. **Medium: DEBUG-only URL registration remains unresolved.**  
7290:3297:4. **Medium: lifecycle regression mitigation is not represented in the test catalogue.**  
7291:3302:5. **Medium: feature completion claims exceed the planned verification.**  
7292:3306:6. **Medium: WI estimates omit required files and tests.**  
7293:3317:VERDICT: BLOCK
7294-
7295-exec
7296-/bin/zsh -lc "sed -n '3238,3282p' .claude/codex-audits/plan-feature-6.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
7297- succeeded in 0ms:
7298-   133	  is cancelled when the test finishes first — it never re-arms on a future run.
7299-   134	  The `pgrep -f` false-positive warning here is the same class of bug rule 49
7300-   135	  flags for `pgrep -f "xcodebuild test"` waiters.
7301-   136	- **Rule 48 (parallel execution):** "single simulator → serialize" is the Gate-5
7302-   137	  decision-matrix row. This rule makes the test-vs-verification case explicit and
7303-   138	  gives it a tool.
7304-
7305-codex
7306-**Findings**
7307-
7308:1. **High: DebugBridge cannot implement the planned reset contract.**  
7309-   `pushA`/`pushB` are `internal`, not public, and transcript arrays are `private(set)`. There is no reset API. Injection during an active session could also race with recognizer/demo tasks. See [LiveSessionModel.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Models/LiveSessionModel.swift:16) and [line 86](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Models/LiveSessionModel.swift:86).  
7310-   The plan must add a named `@MainActor` model operation that stops active work and atomically installs or resets a fixture, with unit tests.
7311-
7312:2. **High: API-key UI tests are not isolated.**  
7313-   `AppEnvironment` always uses the real Keychain and DEBUG bootstrap may load the developer’s real key. The enter/clear tests would overwrite or delete persistent simulator credentials and become order-dependent. See [AppEnvironment.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/AppEnvironment.swift:14) and [APIKeyBootstrap.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Security/APIKeyBootstrap.swift:11).  
7314-   Add an explicit UI-testing launch mode using a seeded `InMemoryAPIKeyStore`, skipping bootstrap, with per-test initial state.
7315-
7316:3. **Medium: DEBUG-only URL registration remains unresolved.**  
7317-   XcodeGen supports `bundle.ui-testing`. An app dependency also supplies `TEST_TARGET_NAME`. However, XcodeGen’s `info` definition generates one plist for every configuration. A partial plist is not merged, and an `.xcconfig` alone cannot express the nested `CFBundleURLTypes` structure.  
7318-   Specify complete Debug/Release plist files selected through `settings.configs.<config>.INFOPLIST_FILE`, with `GENERATE_INFOPLIST_FILE: NO`, or an equally concrete preprocessing design. Add built-product assertions that Debug contains `vrecorder-debug` and Release does not. [XcodeGen specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
7319-
7320:4. **Medium: lifecycle regression mitigation is not represented in the test catalogue.**  
7321-   Root currently owns the environment with `@State` specifically to fix teardown targeting the wrong session. See [RootView.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/RootView.swift:10). Moving that state to `VRecorderApp` is viable:
7322-   `@State` in the App, injected as a plain `let` into RootView.  
7323-   But the promised background-stop regression test is absent and cannot deterministically start a real session. Add a deterministic debug state plus a background/reactivation test, or extract and unit-test the lifecycle handler.
7324-
7325:5. **Medium: feature completion claims exceed the planned verification.**  
7326-   Feature #2 has seven acceptance criteria, including Release behavior, invalid input, failure preservation, and clear confirmation. Three Debug UI tests alone cannot justify `VERIFIED`; rerun and record the complete acceptance matrix. See [feature #2 plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260614-feature-2-api-key-entry.md:232).  
7327-   Feature #6 also still includes `sim-tap.sh` and gesture-driver documentation in both the tracker and verify cron, while this plan excludes them. Either retain that scope or split/update the tracker before marking #6 complete. See [features.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/docs/features.md:59) and [verify.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/cron-prompts/verify.md:3).
7328-
7329:6. **Medium: WI estimates omit required files and tests.**  
7330-   WI-1 is already at least six authored files plus generated project/version artifacts. WI-2 needs the model fixture API, parser unit tests, UI test, plist configuration, and lifecycle regression coverage, substantially more than three files. A four-WI split remains within rule 47’s medium-feature range and would better separate model/parser foundations from app wiring.
7331-
7332-**Verified Assumptions**
7333-
7334-- `.onOpenURL` is viable. The installed iOS 26 SwiftUI SDK exposes it, and XCUITest provides `XCUIApplication.open(_:)`.
7335-- `VRecorderApp` currently creates `RootView()` directly in its `WindowGroup`: [VRecorderApp.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/VRecorderApp.swift:9).
7336-- `AppEnvironment` and `LiveSessionModel` are `@MainActor`.
7337-- Make `DebugBridge.handle(_:)` explicitly `@MainActor`. No `Sendable` conformance is needed when URL parsing and mutation remain synchronous on the main actor; avoid detached tasks.
7338-- Accessibility identifiers are invisible verification metadata and are explicitly outside rule 51: [51-no-self-designed-ui.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/rules/51-no-self-designed-ui.md:46).
7339-
7340:VERDICT: BLOCK
7341-tokens used
7342-114,504
7343-
7344-exec
7345-/bin/zsh -lc "rg -n \"feature-<id>|features\\.md|VERIFIED|\\[0-9\\]|id:\" .claude/hooks/check_terminal_status_evidence.sh .claude -g '*.sh' -g '*.py' -g '*.js' --glob '"'!./.claude/codex-audits/**'"' | head -200; nl -ba .claude/hooks/check_terminal_status_evidence.sh | sed -n '1,220p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
7346- succeeded in 0ms:
7347-.claude/hooks/check_terminal_status_evidence.sh:4:# Purpose: blocks any tracker edit (docs/features.md, docs/bugs.md)
7348-.claude/hooks/check_terminal_status_evidence.sh:5:# that flips a row's status column to VERIFIED (features) or FIXED
--
7592-   202	    exit 2
7593-   203	fi
7594-   204	
7595-   205	exit 0
7596-
7597-codex
7598-**Findings**
7599-
7600:1. **High: lifecycle regression test still passes vacuously.**  
7601-   `installFixture` calls `stop()`, leaving the session inactive before backgrounding. The planned accessibility metadata exposes no listening state to assert. See [plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:44) and [MicButton.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Views/Components/MicButton.swift:12). Add a deterministic active-session fixture plus an observable accessibility value/state.
7602-
7603:2. **High: feature #2 cannot reach `VERIFIED` with the proposed matrix.**  
7604-   Its criteria require actual Keychain persistence, visible failure handling, and Release operation. Debug XCUITests using `InMemoryAPIKeyStore` plus unit-test citations do not exercise these end-to-end. The feature #2 plan explicitly reserves a real-Keychain round trip for Gate 5. See [feature #2 plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260614-feature-2-api-key-entry.md:232). Add:
7605-   - UI failure injection and visible-error assertion.
7606-   - Isolated real-Keychain set/get/clear verification.
7607-   - A Release build launch/UI pass.
7608-
7609:3. **Medium: DebugBridge lacks its promised end-to-end XCUITest.**  
7610-   WI-3 lists parser unit tests and lifecycle coverage, but no test that opens the URL and confirms the shared session renders the transcript. Parser tests cannot validate URL delivery, `.onOpenURL`, environment identity, or rendering.
7611-
7612:4. **Medium: feature #6 verification evidence is omitted.**  
7613-   The plan creates only feature #2 evidence, while also proposing to move feature #6 to `VERIFIED`. Gate 5 requires a separate `dev-docs/verification/feature-6-<date>.md`.
7614-
7615:5. **Medium: scope reconciliation targets an invalid ID and wrong path.**  
7616-   Tracker hooks recognize numeric IDs only, so `feature #6b` is ignored. Use the next numeric feature ID, currently `#7`. The authoritative cron file is [.claude/cron-prompts/verify.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/cron-prompts/verify.md:3), not `cron-prompts/verify.md`.
7617-
7618-**Round-1 Resolution Status**
7619-
7620-- Model fixture API: resolved.
7621-- UI-test Keychain isolation: resolved.
7622-- Debug/Release plist mechanism: resolved, though the stale alternative wording under Risks should be removed.
7623-- Background lifecycle test: not resolved.
7624-- Full feature #2 matrix and gesture split: partially resolved.
7625-- Four-WI split: resolved.
7626-
7627:VERDICT: BLOCK
7628-tokens used
7629-85,274
7630-**Findings**
7631-
7632:1. **High: lifecycle regression test still passes vacuously.**  
7633-   `installFixture` calls `stop()`, leaving the session inactive before backgrounding. The planned accessibility metadata exposes no listening state to assert. See [plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:44) and [MicButton.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Views/Components/MicButton.swift:12). Add a deterministic active-session fixture plus an observable accessibility value/state.
7634-
7635:2. **High: feature #2 cannot reach `VERIFIED` with the proposed matrix.**  
7636-   Its criteria require actual Keychain persistence, visible failure handling, and Release operation. Debug XCUITests using `InMemoryAPIKeyStore` plus unit-test citations do not exercise these end-to-end. The feature #2 plan explicitly reserves a real-Keychain round trip for Gate 5. See [feature #2 plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260614-feature-2-api-key-entry.md:232). Add:
7637-   - UI failure injection and visible-error assertion.
7638-   - Isolated real-Keychain set/get/clear verification.
7639-   - A Release build launch/UI pass.
7640-
7641:3. **Medium: DebugBridge lacks its promised end-to-end XCUITest.**  
7642-   WI-3 lists parser unit tests and lifecycle coverage, but no test that opens the URL and confirms the shared session renders the transcript. Parser tests cannot validate URL delivery, `.onOpenURL`, environment identity, or rendering.
7643-
7644:4. **Medium: feature #6 verification evidence is omitted.**  
7645-   The plan creates only feature #2 evidence, while also proposing to move feature #6 to `VERIFIED`. Gate 5 requires a separate `dev-docs/verification/feature-6-<date>.md`.
7646-
7647:5. **Medium: scope reconciliation targets an invalid ID and wrong path.**  
7648-   Tracker hooks recognize numeric IDs only, so `feature #6b` is ignored. Use the next numeric feature ID, currently `#7`. The authoritative cron file is [.claude/cron-prompts/verify.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/cron-prompts/verify.md:3), not `cron-prompts/verify.md`.
7649-
7650-**Round-1 Resolution Status**
7651-
7652-- Model fixture API: resolved.
7653-- UI-test Keychain isolation: resolved.
7654-- Debug/Release plist mechanism: resolved, though the stale alternative wording under Risks should be removed.
7655-- Background lifecycle test: not resolved.
7656-- Full feature #2 matrix and gesture split: partially resolved.
7657-- Four-WI split: resolved.
7658-
7659:VERDICT: BLOCK

codex
The repository confirms `XCUIApplication.open(_:)` is a valid approach and the XcodeGen UI-test dependency can supply `TEST_TARGET_NAME`. The remaining blockers are plan-contract issues, not platform feasibility; I’m doing a final pass for severity and exact line references before issuing the verdict.
exec
/bin/zsh -lc "sed -n '1,360p' dev-docs/audit/DIMENSIONS-ios.md && nl -ba .claude/rules/50-codebase-conventions.md | sed -n '1,180p' && nl -ba scripts/run-tests.sh | sed -n '1,180p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
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
     1	# 50 - Codebase Conventions
     2	
     3	Project conventions for vrecorder (iOS simultaneous-interpretation app). Follow these for consistency.
     4	
     5	## 1. Actor Isolation
     6	
     7	- Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY=complete`).
     8	- ViewModels and observable stores are `@MainActor @Observable final class`.
     9	- Pipeline stages (capture, VAD, ASR, translation, TTS) are actors or actor-isolated services. Cross-actor calls use `await`. No `assumeIsolated` except in narrow `App.init` contexts.
    10	- Never pass `@Model` instances across actor boundaries — use value-type DTOs (`SessionRecord`, `TranscriptSegmentRecord`, etc.).
    11	
    12	## 2. Streaming Pipeline Semantics
    13	
    14	- Stages communicate via explicit streaming protocols emitting `partial` / `final` events.
    15	- **Partials are replaceable, not append-only**: a later partial replaces the previous partial for the same segment; a `final` freezes it. Consumers must implement replacement.
    16	- Every stage supports cancellation; cancelling a session must tear down the whole chain (no orphaned recognition tasks or network streams).
    17	- Backpressure: stages must not buffer unboundedly; drop or coalesce partials when the consumer is slow.
    18	
    19	## 3. Engine Abstraction
    20	
    21	- ASR, translation, and TTS providers sit behind protocols (e.g. `SpeechRecognizing`, `TranslationEngine`, `SpeechSynthesizing`).
    22	- Concrete providers (on-device SFSpeechRecognizer / Apple Translation vs cloud streaming APIs) are selected via a capabilities object (offline support, language pairs, latency class) — never hard-coded at call sites.
    23	- UI code never calls a concrete provider directly.
    24	
    25	## 4. Audio Session
    26	
    27	- All `AVAudioSession` configuration, interruption handling, and route-change handling is centralized in one audio session controller.
    28	- Interruptions (phone call, Siri, alarm) and route changes (AirPods connect/disconnect) must pause/resume the pipeline gracefully and are test-covered via simulated notifications.
    29	
    30	## 5. Persistence
    31	
    32	- All SwiftData mutations go through a single persistence actor.
    33	- Sessions, transcripts, and translations persist as value-type DTO round-trips.
    34	
    35	## 6. Logging & Errors
    36	
    37	- No bare `print()` in production — `Logger(subsystem: "com.vrecorder.app", category: "...")`.
    38	- Error types are domain-specific; user-presentable errors must distinguish: offline, timeout, rate-limited, permission-denied, provider-error. Never mislabel a timeout as "offline".
    39	
    40	## 7. DEBUG Gating
    41	
    42	- DEBUG-only code (fixtures, debug bridges, test seams) wrapped in `#if DEBUG` at file scope, never inline in production code paths.
    43	
    44	## 8. File Size & Structure
    45	
    46	- Code files stay under ~300 lines; split proactively.
    47	- Features stay local; avoid cross-feature imports unless truly shared.
    48	
    49	## 9. Testing
    50	
    51	- Swift Testing is the default (`import Testing`, `@Test`, `#expect`); XCTest only for `XCTestExpectation` / notification-timing tests.
    52	- Audio tests use recorded fixture clips (speech / silence / noise / CJK) and recorded transcript-event sequences — never live mic input.
     1	#!/usr/bin/env bash
     2	# scripts/run-tests.sh — bounded, watchdogged unit-test gate.
     3	#
     4	# Why (.claude/rules/52-test-sim-isolation.md): `xcodebuild test` can wedge at
     5	# 0% CPU and ghost for hours (sim contention, or a wedged SWBBuildService build
     6	# daemon after a kill -9). This wrapper turns an indefinite hang into a bounded,
     7	# self-terminating run:
     8	#   1. pins the destination by UDID (prefers iPhone 17 Pro, else booted, else any)
     9	#   2. enforces a hard wall-clock timeout (default 900s) on the EXACT pid (rule 49)
    10	#   3. on timeout kills the process tree AND clears the wedged build daemon
    11	#      `SWBBuildService` (rule 52 Cause B) — a bare kill is a half-cleanup that
    12	#      poisons the next run
    13	#   4. prints ONE unambiguous final line:
    14	#      RUN-TESTS RESULT: SUCCEEDED|FAILED|TIMEOUT|NO_BOOTED_SIM
    15	#
    16	# Usage:
    17	#   scripts/run-tests.sh                          # default suite (vrecorderTests)
    18	#   scripts/run-tests.sh vrecorderTests/FooTests  # one targeted suite (fast per-WI gate)
    19	#   TIMEOUT_SECS=2400 scripts/run-tests.sh vrecorderTests   # full-suite periodic sweep
    20	#   TEST_UDID=<udid> scripts/run-tests.sh         # specific simulator (true parallelism)
    21	#
    22	# NEVER pipe this through tail/grep/head (rule 52 #5): `tail -N` on a pipe buffers
    23	# away the streaming markers AND the single RESULT line. Let stdout go straight to
    24	# a file or the task-output; read the file after the RESULT line lands.
    25	set -uo pipefail
    26	
    27	PROJECT="vrecorder.xcodeproj"
    28	SCHEME="vrecorder"
    29	SUITE="${1:-vrecorderTests}"
    30	TIMEOUT="${TIMEOUT_SECS:-900}"
    31	export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
    32	
    33	cd "$(dirname "$0")/.." || { echo "RUN-TESTS RESULT: FAILED (cannot cd to project root)"; exit 1; }
    34	
    35	# Resolve a simulator UDID. Pin by UDID to avoid name/OS-matching surprises.
    36	# Order: explicit TEST_UDID > iPhone 17 Pro (project convention) > booted sim > any iPhone.
    37	udid="${TEST_UDID:-}"
    38	[ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone 17 Pro (' | grep -oE '[0-9A-F-]{36}' | head -1)"
    39	[ -z "$udid" ] && udid="$(xcrun simctl list devices booted    2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1)"
    40	[ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone' | grep -oE '[0-9A-F-]{36}' | head -1)"
    41	if [ -z "$udid" ]; then
    42	  echo "RUN-TESTS RESULT: NO_BOOTED_SIM (no usable iOS Simulator found — install a runtime)"
    43	  exit 1
    44	fi
    45	
    46	# Clear a stale app instance that wedges the test-host launch with a "Busy
    47	# (Application failed preflight checks)" error (recurring sim-state flake). No-op
    48	# if the sim is shut down or the app isn't installed.
    49	xcrun simctl terminate "$udid" com.vrecorder.app >/dev/null 2>&1 || true
    50	
    51	echo "RUN-TESTS START: suite=$SUITE udid=$udid timeout=${TIMEOUT}s"
    52	
    53	STATUS="$(mktemp)"; TIMED_OUT="$(mktemp -u)"
    54	run() {
    55	  xcodebuild test \
    56	    -project "$PROJECT" -scheme "$SCHEME" \
    57	    -destination "id=$udid" \
    58	    -only-testing:"$SUITE" 2>&1
    59	  echo "$?" >"$STATUS"
    60	}
    61	run & RUN_PID=$!
    62	
    63	# Watchdog on the EXACT pid; cancelled the instant the test finishes (never re-arms — rule 49).
    64	( sleep "$TIMEOUT"
    65	  if kill -0 "$RUN_PID" 2>/dev/null; then
    66	    : >"$TIMED_OUT"
    67	    pkill -TERM -P "$RUN_PID" 2>/dev/null; kill -TERM "$RUN_PID" 2>/dev/null
    68	    sleep 3
    69	    pkill -KILL -P "$RUN_PID" 2>/dev/null; kill -KILL "$RUN_PID" 2>/dev/null
    70	    pkill -9 -x SWBBuildService 2>/dev/null   # rule 52 Cause B: clear the wedged daemon
    71	  fi ) & WD=$!
    72	
    73	wait "$RUN_PID" 2>/dev/null
    74	kill "$WD" 2>/dev/null; wait "$WD" 2>/dev/null
    75	
    76	RC="$(cat "$STATUS" 2>/dev/null || echo 1)"; rm -f "$STATUS"
    77	echo
    78	if [ -e "$TIMED_OUT" ]; then
    79	  rm -f "$TIMED_OUT"
    80	  echo "RUN-TESTS RESULT: TIMEOUT (${TIMEOUT}s) — killed process tree + SWBBuildService"
    81	  exit 124
    82	elif [ "$RC" = "0" ]; then
    83	  echo "RUN-TESTS RESULT: SUCCEEDED"
    84	  exit 0
    85	else
    86	  echo "RUN-TESTS RESULT: FAILED (xcodebuild rc=$RC)"
    87	  exit 1
    88	fi

exec
/bin/zsh -lc "nl -ba vrecorder/Security/APIKeyBootstrap.swift | sed -n '1,200p'; nl -ba dev-docs/plans/20260615-feature-6-verification-harness.md | sed -n '130,245p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	//  APIKeyBootstrap.swift
     2	//  Purpose: DEBUG-only convenience — on first launch, if config/openai-key.txt was
     3	//  bundled into the app (dev builds only) and the Keychain has no OpenAI key yet,
     4	//  copy it into the Keychain once. Release builds never read a file; the key is
     5	//  entered through Settings. See AGENTS.md › AI coding tool auth / rules/50 §7.
     6	
     7	import Foundation
     8	
     9	enum APIKeyBootstrap {
    10	    /// Seed the Keychain from a bundled `openai-key.txt` resource if present and unset.
    11	    static func seedIfNeeded(store: APIKeyStoring) {
    12	        #if DEBUG
    13	        guard store.key(for: APIProvider.openAI) == nil else { return }
    14	        guard let url = Bundle.main.url(forResource: "openai-key", withExtension: "txt"),
    15	              let raw = try? String(contentsOf: url, encoding: .utf8) else { return }
    16	        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    17	        guard !key.isEmpty else { return }
    18	        store.setKey(key, for: APIProvider.openAI)
    19	        #endif
    20	    }
    21	}
   130	- **Rejected:** (a) idb/`sim-tap.sh` as the primary driver — XCUITest's native
   131	  tap/typeText covers this feature; idb isn't installed; defer as optional. (b)
   132	  Snapshot/pixel testing — brittle, and rule-51 governs visual design, not tests.
   133	  (c) Driving the real recognizer in UI tests — non-deterministic; the DebugBridge
   134	  injects fixtures instead.
   135	
   136	## Work items (4 WIs, one PR each — rule 47, audit-r1 #6)
   137	- **WI-1 (foundational)**: model fixture API + unit tests. No UI, no Release change.
   138	- **WI-2 (behavioral)**: XCUITest target + a11y ids + UI-testing launch mode +
   139	  live-screen smoke. Slice-verify: smoke UI test green on the sim.
   140	- **WI-3 (behavioral)**: DebugBridge + Debug/Release plist restructure + app
   141	  wiring + parser unit tests + background-stop lifecycle UI test. Slice-verify:
   142	  `vrecorder-debug://inject` seeds the asserted transcript; built-product check
   143	  that Debug `.app` Info.plist contains `vrecorder-debug` and Release does NOT.
   144	- **WI-4 (final)**: feature #2 full-acceptance UI test → flips feature #2 to
   145	  VERIFIED (complete matrix recorded). Completes feature #6.
   146	
   147	## Test catalogue
   148	- `vrecorderTests/LiveSessionFixtureTests.swift`:
   149	  `installFixtureStopsActiveSessionAndReplaces`, `resetClears`.
   150	- `vrecorderTests/DebugBridgeTests.swift` (`#if DEBUG`): `injectSeedsTranscript`,
   151	  `resetClears`, `malformedURLIsNoOp` (drives a model directly).
   152	- `vrecorderUITests/LiveScreenUITests.swift`: `liveScreenShowsMicAndGear`.
   153	- `vrecorderUITests/DebugBridgeUITests.swift` (audit-r2 #3): `openInjectURLRenders
   154	  Transcript` — `XCUIApplication().open(URL("vrecorder-debug://inject?...")!)` then
   155	  assert the seeded transcript text is on screen (validates URL delivery,
   156	  `.onOpenURL`, shared-env identity, and rendering — which the parser unit tests
   157	  can't).
   158	- `vrecorderUITests/LifecycleUITests.swift`: `backgroundStopsActiveSession` —
   159	  inject an `installFixture(..., listening: true)` fixture (via the debug URL),
   160	  assert MicButton a11y value `listening`, background+foreground, assert `idle`.
   161	- `vrecorderUITests/APIKeyEntryUITests.swift`: `enterKeyFlipsRowToConfigured`,
   162	  `emptyInputKeepsSaveDisabled`, `clearKeyFlipsRowToUnconfigured`,
   163	  `cancelLeavesRowUnchanged`.
   164	- **Built-product assertion** (WI-3 verification step, in the PR description):
   165	  `plutil`/`grep` the Debug vs Release `.app/Info.plist` for `vrecorder-debug`.
   166	
   167	## Edge cases
   168	- App not built for UI testing → XCUITest target launches its own host (handled by
   169	  the target type).
   170	- DebugBridge active only in DEBUG (Release ignores the URL scheme entirely).
   171	- Malformed `vrecorder-debug://` URL → no-op, no crash.
   172	- Sheet/keyboard timing in XCUITest → use `waitForExistence(timeout:)`, never bare
   173	  sleeps.
   174	- Simulator wedge (seen this session) → run UI tests through `scripts/run-tests.sh`
   175	  (UDID-pinned, watchdog) on a clean sim.
   176	- a11y identifiers must not collide → namespaced (`vr.live.mic`, `vr.settings.apiKeyRow`…).
   177	
   178	## Acceptance criteria
   179	1. `vrecorderUITests` target builds and runs via the scheme; smoke test green.
   180	2. A `vrecorder-debug://inject` URL deterministically seeds an on-screen transcript
   181	   (DEBUG); **built-product check**: Debug `.app/Info.plist` contains
   182	   `vrecorder-debug`, Release does NOT.
   183	3. UI tests run under `-uiTesting` with a seeded `InMemoryAPIKeyStore` (bootstrap
   184	   skipped) — they never read/write the real Keychain and are order-independent.
   185	4. The API-key UI smoke drives the drivable behaviors (enter/save/clear/cancel);
   186	   it demonstrates the harness but does NOT flip feature #2 to VERIFIED (that needs
   187	   feature #2's own real-Keychain + Release Gate-5).
   188	5. The background-stop lifecycle still holds after lifting `env` to the App
   189	   (deterministic UI test).
   190	6. All UI tests run on the iPhone 17 Pro simulator through `run-tests.sh`.
   191	7. No production behavior change; DebugBridge + the URL scheme are DEBUG-only.
   192	
   193	## Scope reconciliation (audit-r1 #5, audit-r2 #5)
   194	The `docs/features.md` #6 row and `.claude/cron-prompts/verify.md` reference an idb
   195	`sim-tap.sh` gesture driver + `docs/subsystems/sim-gesture-driver.md`. This plan
   196	EXCLUDES them (XCUITest's native tap/typeText covers feature #6; idb isn't
   197	installed). On Gate-1 acceptance: file **feature #7 — idb gesture-driver fallback**
   198	(numeric ID — tracker hooks recognize numbers only, not `#6b`) and edit the #6 row
   199	to scope it to the XCUITest+DebugBridge core, so the tracker matches this plan. The
   200	verify cron can use XCUITest once #6 lands; #7 adds gestures XCUITest can't express.
   201	
   202	## Risks + mitigations
   203	- **URL-scheme registration mechanism**: resolved — `GENERATE_INFOPLIST_FILE: NO`
   204	  + explicit `Info-Debug.plist` (with `CFBundleURLTypes`) / `Info-Release.plist`
   205	  (without), selected via `settings.configs.<config>.INFOPLIST_FILE`. Both plists
   206	  carry the existing `INFOPLIST_KEY_*` values as real keys. (A `.xcconfig` or
   207	  partial plist can't express/merge the nested `CFBundleURLTypes` — not used.)
   208	- **App-owns-AppEnvironment refactor** could disturb the scene-phase teardown
   209	  (audit-G4r2 #2 fix). Mitigation: keep `@State` ownership, just lift it one level
   210	  (App → injected into RootView); a UI test asserts background still stops.
   211	- **XCUITest flakiness**: bounded `waitForExistence`, no sleeps; UDID-pinned sim.
   212	
   213	## Docs sync + version bump (rules 24 + 40)
   214	- `docs/architecture.md`: note the DebugBridge + UITest target. `README.md`:
   215	  Developer Tools / testing note. `docs/features.md`: row #6 PLANNED → IN PROGRESS
   216	  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
   217	- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.
   218	
   219	## Backward compat
   220	Additive + DEBUG-only. No schema, no Release behavior change. The
   221	App-owns-AppEnvironment change is internal wiring.

exec
/bin/zsh -lc 'find "$HOME/Library/Developer/Xcode/DerivedData" -path '"'*/Build/Products/*/vrecorder.app/Info.plist' -print 2>/dev/null | tail -4" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 741ms:
/Users/deanlee/Library/Developer/Xcode/DerivedData/vrecorder-bhlopyilnailbwdbvrqagylosjnn/Build/Products/Release-iphonesimulator/vrecorder.app/Info.plist
/Users/deanlee/Library/Developer/Xcode/DerivedData/vrecorder-bhlopyilnailbwdbvrqagylosjnn/Build/Products/Debug-iphonesimulator/vrecorder.app/Info.plist
/Users/deanlee/Library/Developer/Xcode/DerivedData/vrecorder-bhlopyilnailbwdbvrqagylosjnn/Build/Products/Debug-iphoneos/vrecorder.app/Info.plist
/Users/deanlee/Library/Developer/Xcode/DerivedData/vrecorder-bhlopyilnailbwdbvrqagylosjnn/Build/Products/Debug-iphoneos/.XCInstall/vrecorder.app/Wrapper/vrecorder.app/Info.plist

exec
/bin/zsh -lc 'plutil -p /Users/deanlee/Library/Developer/Xcode/DerivedData/vrecorder-bhlopyilnailbwdbvrqagylosjnn/Build/Products/Debug-iphonesimulator/vrecorder.app/Info.plist' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
{
  "BuildMachineOSBuild" => "25F80"
  "CFBundleDevelopmentRegion" => "en"
  "CFBundleExecutable" => "vrecorder"
  "CFBundleIdentifier" => "com.vrecorder.app"
  "CFBundleInfoDictionaryVersion" => "6.0"
  "CFBundleName" => "vrecorder"
  "CFBundlePackageType" => "APPL"
  "CFBundleShortVersionString" => "0.2.4"
  "CFBundleSupportedPlatforms" => [
    0 => "iPhoneSimulator"
  ]
  "CFBundleVersion" => "6"
  "DTCompiler" => "com.apple.compilers.llvm.clang.1_0"
  "DTPlatformBuild" => "23F73"
  "DTPlatformName" => "iphonesimulator"
  "DTPlatformVersion" => "26.5"
  "DTSDKBuild" => "23F73"
  "DTSDKName" => "iphonesimulator26.5"
  "DTXcode" => "2650"
  "DTXcodeBuild" => "17F42"
  "LSRequiresIPhoneOS" => true
  "MinimumOSVersion" => "17.0"
  "NSAccentColorName" => "AccentColor"
  "NSMicrophoneUsageDescription" => "VRecorder 需要使用麦克风进行实时同声传译。"
  "NSSpeechRecognitionUsageDescription" => "VRecorder 使用语音识别将你的发言实时转写为文字。"
  "UIApplicationSceneManifest" => {
    "UIApplicationSupportsMultipleScenes" => true
    "UISceneConfigurations" => {
    }
  }
  "UIDeviceFamily" => [
    0 => 1
  ]
  "UILaunchScreen" => {
    "UILaunchScreen" => {
    }
  }
  "UIStatusBarStyle" => "UIStatusBarStyleLightContent"
  "UISupportedInterfaceOrientations" => [
    0 => "UIInterfaceOrientationPortrait"
  ]
}

exec
/bin/zsh -lc "sed -n '1,220p' dev-docs/verification/bug-5-20260615.md && sed -n '1,220p' dev-docs/verification/feature-2-20260614.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
---
kind: bug
id: 5
status_target: FIXED
commit_sha: 7aa198a0be7136d490590e10aa2d22118b036e0a
app_version: 0.2.4 (build 6)
date: 2026-06-15
verifier: claude
device_or_simulator: "iPhone 17 Pro Simulator"
os_version: "iOS 26.x"
build_configuration: Debug
backend: "n/a (recognizer concurrency — code review + regression)"
result: pass
---

# Bug #5 (GH #9) — recognizer session identity — verification

## Acceptance criteria
| # | Criterion | Observed | Pass/Fail |
|---|-----------|----------|-----------|
| 1 | A stale recognition callback can't rotate the new session | recognitionTask callback captures `gen = generation`; `rotateAfterFinal(gen:)` guards `gen == generation`. | pass (review) |
| 2 | A stale callback can't terminate the new session | `finish(gen:throwing:)` guards `gen == generation`. | pass (review) |
| 3 | start/stop invalidate in-flight callbacks | `begin()` and `stop()` bump `generation`. | pass (review) |
| 4 | Stale partial/final pushes are isolated | The callback captures THIS session's `coalescer`; a restart makes a new one, so stale pushes hit the old (finished, pump-cancelled) coalescer — harmless. | pass (review) |
| 5 | No regression | 45 tests green; build clean. | pass |

## Commands run
```
xcodebuild build ...  # SUCCEEDED
scripts/run-tests.sh vrecorderTests  # 45 tests SUCCEEDED
```

## Observations
Recognizer concurrency isn't unit-testable without a real SFSpeechRecognizer +
audio harness; verified by code review (generation-token pattern, same as
LiveSessionModel) + regression. GH #9 stays open `awaiting-device-verification`
for a real-mic stop/restart race check.
---
kind: feature
id: 2
status_target: VERIFIED
commit_sha: 258097c2dffe525cde97749cea770ec8fbb8476c
app_version: 0.2.0 (build 2)
date: 2026-06-14
verifier: claude
device_or_simulator: "iPhone 17 Pro Simulator"
os_version: "iOS 26.x"
build_configuration: Debug
backend: "n/a (Keychain-local; no network in this slice)"
result: partial
---

# Feature #2 — API key entry — verification

## Acceptance criteria

| # | Criterion | Observed | Pass/Fail |
|---|-----------|----------|-----------|
| 1 | Tapping "API 密钥" opens the entry sheet | Wired via `.sheet`; build + launch clean. Tap not driveable headlessly (no idb/sim-tap). | logic+build pass; **tap deferred** |
| 2 | Valid key + 保存 → stored, row shows 已配置, dismiss | `saveTrimsPersistsAndClearsDraft` + `initReflectsExistingKey` + onDismiss refresh cover the logic. Pixel flow deferred. | logic pass; **pixel deferred** |
| 3 | 清除密钥 (confirm) → removed, row 未配置 | `clearRemovesKeyAndUpdatesState`; system `.alert` confirm wired. | logic pass; **pixel deferred** |
| 4 | Empty/invalid keeps 保存 disabled; direct save no-op | `saveGuardsOnValidity`, `isValid*` tests. | pass |
| 5 | Keychain write failure keeps sheet open, shows error, preserves old key | `saveFailurePreservesPreviousKeyAndSetsError`, `clearFailureRetainsConfiguredStateAndSetsError`, `updateFailureOtherThanNotFoundPreservesOldKeyNoAdd` | pass |
| 6 | Works in Release (no DEBUG file dependence) | Release build of feature #1 already excludes the seed file; the sheet is the Release key path. Release build not re-run this slice. | build-level pass; **on-device deferred** |
| 7 | Reuses only existing design-system tokens | `APIKeyEntryView` uses only `VR.*` tokens; no new colors/type. | pass |

## Commands run

```
xcodegen generate
xcodebuild build -scheme vrecorder -destination 'platform=iOS Simulator,name=iPhone 17 Pro'  # BUILD SUCCEEDED
scripts/run-tests.sh vrecorderTests   # RUN-TESTS RESULT: SUCCEEDED, 31 tests / 5 suites
xcrun simctl boot 1DFF0691-… ; install ; launch com.vrecorder.app   # pid 92878, no crash
xcrun simctl io … screenshot /tmp/vr-f2-live.png
```

## Observations

- The interactive tap→type→save→row-flips pixel flow is **not** exercised: this
  headless environment has no tap driver (idb / sim-tap absent — confirmed). The
  security-critical logic (atomic write, old-key preservation on failure,
  validation, masking) IS exhaustively unit-tested, including scripted `OSStatus`
  sequences through the injected `KeychainOps`.
- App launches with the new SettingsScreen `init(store:)` wiring without crashing.

## Artifacts

- `/tmp/vr-f2-live.png` — post-launch live screen (smoke).
- 31 passing tests (see `scripts/run-tests.sh vrecorderTests`).

## Why `partial`

The logic layer is fully verified; the on-screen tap-driven flow needs a manual
device/simulator tap pass (no headless tap tooling). Per the Gate-5 rule this is a
named, confirmed tool-unavailability. Row stays **DONE** (after merge), not
VERIFIED, until the manual pixel pass is recorded.

codex
**Findings**

1. **High: active lifecycle fixture is not reachable through DebugBridge.**  
   The model accepts `listening:`, but the bridge only parses `a`/`b`. The lifecycle test therefore cannot inject `listening: true`. The surface signature and test catalogue also omit the new parameter/test. See [plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:49), [bridge contract](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:94), and [lifecycle test](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:158). Add a strictly parsed URL parameter such as `listening=true`, including parser tests.

2. **Medium: feature #2 decoupling remains internally contradicted.**  
   WI-4 still says it flips feature #2 to `VERIFIED`, and Docs Sync still schedules that transition, contradicting the corrected acceptance criterion. See [WI-4](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:144) and [Docs Sync](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:213).

3. **Medium: the `#6b` and path correction was not propagated throughout the plan.**  
   Scope still says `feature #6b` and `cron-prompts/verify.md`, despite the later correct `#7` and `.claude/cron-prompts/verify.md`. See [Scope](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:36).

4. **Medium: DEBUG gating contradicts the binding convention.**  
   Fixture methods are explicitly planned for Release compilation, and `.onOpenURL` uses an inline conditional. Rule 50 requires fixtures, bridges, and test seams to be gated at file scope. See [plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:60) and [rule 50](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/rules/50-codebase-conventions.md:40).

5. **Medium: explicit plist contents remain underspecified.**  
   With generated plists disabled, both files must define core bundle/version keys and actual nested `UILaunchScreen`/`UIApplicationSceneManifest` structures, not merely translate existing `INFOPLIST_KEY_*` settings. Add the complete key templates and validate Release installation/version, not only URL-scheme absence. XcodeGen documents the normally generated core keys in its [project specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md#target).

The DebugBridge UI test and feature-6 evidence additions are resolved.

VERDICT: BLOCK
tokens used
192,208
**Findings**

1. **High: active lifecycle fixture is not reachable through DebugBridge.**  
   The model accepts `listening:`, but the bridge only parses `a`/`b`. The lifecycle test therefore cannot inject `listening: true`. The surface signature and test catalogue also omit the new parameter/test. See [plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:49), [bridge contract](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:94), and [lifecycle test](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:158). Add a strictly parsed URL parameter such as `listening=true`, including parser tests.

2. **Medium: feature #2 decoupling remains internally contradicted.**  
   WI-4 still says it flips feature #2 to `VERIFIED`, and Docs Sync still schedules that transition, contradicting the corrected acceptance criterion. See [WI-4](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:144) and [Docs Sync](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:213).

3. **Medium: the `#6b` and path correction was not propagated throughout the plan.**  
   Scope still says `feature #6b` and `cron-prompts/verify.md`, despite the later correct `#7` and `.claude/cron-prompts/verify.md`. See [Scope](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:36).

4. **Medium: DEBUG gating contradicts the binding convention.**  
   Fixture methods are explicitly planned for Release compilation, and `.onOpenURL` uses an inline conditional. Rule 50 requires fixtures, bridges, and test seams to be gated at file scope. See [plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260615-feature-6-verification-harness.md:60) and [rule 50](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/rules/50-codebase-conventions.md:40).

5. **Medium: explicit plist contents remain underspecified.**  
   With generated plists disabled, both files must define core bundle/version keys and actual nested `UILaunchScreen`/`UIApplicationSceneManifest` structures, not merely translate existing `INFOPLIST_KEY_*` settings. Add the complete key templates and validate Release installation/version, not only URL-scheme absence. XcodeGen documents the normally generated core keys in its [project specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md#target).

The DebugBridge UI test and feature-6 evidence additions are resolved.

VERDICT: BLOCK
