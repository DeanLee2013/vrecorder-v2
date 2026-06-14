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
session id: 019ec6d9-6621-71f0-88dd-c461acba8df4
--------
user
INDEPENDENT plan auditor for vrecorder-v2 (Swift 6 / SwiftUI / XCUITest, iOS 26). Audit this Gate-1 plan for feature #6 (verification harness: XCUITest target + DebugBridge). Read the actual repo. Focus:
1. MODEL ASSUMPTION VERIFICATION — do the named symbols exist? Check: LiveSessionModel.pushA/pushB visibility; AppEnvironment + how RootView owns it today (the plan wants to lift ownership to the App); VRecorderApp WindowGroup/RootView(); whether .onOpenURL is viable; whether xcodegen can register a CFBundleURLTypes URL scheme (vrecorder-debug) for DEBUG only and HOW; bundle.ui-testing target type in xcodegen.
2. Risks: the App-owns-AppEnvironment refactor vs the scene-phase teardown (@State env) fix; XCUITest flakiness; DEBUG-only gating of the URL scheme.
3. WI sizing/cohesion (3 WIs) per rule 47.
4. Whether accessibility identifiers count as rule-51 UI (they should NOT — invisible).
5. Concurrency/Sendable for DebugBridge driving @MainActor LiveSessionModel from .onOpenURL.
End with a line exactly: 'VERDICT: BLOCK' if any Critical/High/Medium, otherwise 'VERDICT: PASS'.

PLAN:
# Feature #6 — Verification harness (XCUITest + DebugBridge)

> Gate-1 plan, revision 1. Status: PLANNED after Gate-2 audit passes.
> **Estimated PR size**, per WI (separate PR each): WI-1 ~4 files / ~120 LOC;
> WI-2 ~3 files / ~140 LOC; WI-3 ~1 file / ~90 LOC. Medium feature, 3 WIs.

## Revision history
- **r1** — initial plan.

## Problem
The `cron-prompts/verify.md` workflow assumes a CU-free verification harness
(XCUITest + a `vrecorder-debug://` DebugBridge + a gesture fallback) that does NOT
exist in the repo. So the verify cron is permanently `blocked`, and shipped work
(feature #2 DONE-not-VERIFIED; bugs awaiting device verification) can't be
machine-verified at all. This builds the scriptable core of that harness so the
verify cron can flip at least the UI/state-driven targets.

## Scope
**In:** an XCUITest target; accessibility identifiers on the key UI; a DEBUG-only
`vrecorder-debug://` DebugBridge that drives `LiveSessionModel` deterministically
(inject a scripted transcript) so UI states are reachable without a mic; an
XCUITest that verifies feature #2's API-key sheet flow end-to-end.
**Out:** real-mic / AirPods / interruption verification (inherently human-on-device
— bugs #1/#3/#5/#9 stay `awaiting-device-verification`); idb/`sim-tap.sh` gesture
fallback (optional follow-up — XCUITest's own tap/typeText covers this feature's
needs; idb is not installed). The demo simulator path is unaffected.

## Surface area (file-by-file)
- **WI-1 — XCUITest target + a11y ids + smoke**
  - `project.yml`: NEW target `vrecorderUITests` (type `bundle.ui-testing`, deps:
    `vrecorder`); add to the `vrecorder` scheme's test action. `xcodegen generate`.
  - NEW `vrecorderUITests/LiveScreenUITests.swift`: launch the app, assert the
    live screen's mic button + settings gear exist (by a11y id).
  - MODIFY `vrecorder/Views/LiveScreen.swift`, `MicButton.swift`,
    `SettingsScreen.swift`, `APIKeyEntryView.swift`: add
    `.accessibilityIdentifier(...)` to the gear, mic button, "API 密钥" row,
    SecureField, 保存/清除 buttons (identifiers are not user-visible UI → not a
    rule-51 surface).
- **WI-2 — DebugBridge (DEBUG only)**
  - NEW `vrecorder/Debug/DebugBridge.swift` (`#if DEBUG` whole file): parses
    `vrecorder-debug://inject?…` URLs and drives `LiveSessionModel` via its
    existing `pushA`/`pushB` (already `func`-public on the @MainActor model) to
    seed deterministic transcript states; `vrecorder-debug://reset` clears.
  - MODIFY `vrecorder/App/VRecorderApp.swift`: `.onOpenURL` (DEBUG) → DebugBridge,
    holding the `AppEnvironment.session`. Requires lifting `AppEnvironment` to the
    App so the bridge and `RootView` share one session (today `RootView` owns it).
  - MODIFY `vrecorder/App/RootView.swift` / `AppEnvironment.swift`: accept an
    injected `AppEnvironment` instead of constructing its own, so the App owns it.
  - `project.yml`: register `vrecorder-debug` URL scheme (DEBUG via
    `INFOPLIST_KEY_…`? URL schemes need `CFBundleURLTypes` — add a Debug-config
    Info.plist fragment or an `.xcconfig`; confirm the mechanism in the plan).
- **WI-3 — feature #2 UI verification test**
  - NEW `vrecorderUITests/APIKeyEntryUITests.swift`: launch → tap gear → tap
    "API 密钥" → typeText a key → tap 保存 → assert the row shows "已配置". This is
    the end-to-end Gate-5 check that flips feature #2 → VERIFIED.

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

## Work items (3 WIs, one PR each — rule 47)
- **WI-1 (foundational)**: XCUITest target + a11y ids + smoke test. Unit/UI-test
  only; no behavior change. Slice-verify: the UI smoke test runs green on the sim.
- **WI-2 (behavioral)**: DebugBridge + App-owns-AppEnvironment wiring. Slice-verify:
  a `vrecorder-debug://inject` URL produces the expected on-screen transcript
  (asserted by a UI test).
- **WI-3 (final)**: feature #2 API-key UI test → flips feature #2 to VERIFIED with
  a `dev-docs/verification/feature-2-…` update.

## Test catalogue
- `vrecorderUITests/LiveScreenUITests.swift`: `liveScreenShowsMicAndGear`.
- `vrecorderUITests/DebugBridgeUITests.swift`: `injectURLSeedsTranscript`,
  `resetURLClears`.
- `vrecorderUITests/APIKeyEntryUITests.swift`: `enterKeyFlipsRowToConfigured`,
  `cancelLeavesRowUnchanged`, `clearKeyFlipsRowToUnconfigured`.

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
   (DEBUG); Release ignores the scheme.
3. The API-key UI test drives 设置 → API 密钥 → enter → 保存 and asserts 已配置 —
   flipping feature #2 to VERIFIED.
4. All UI tests run on the iPhone 17 Pro simulator through `run-tests.sh`.
5. No production behavior change; DebugBridge is `#if DEBUG` only.

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
I’m auditing the plan against the repository and binding workflow rules. I’ll first inspect git state, architecture, project generation settings, and the named Swift symbols, then validate the xcodegen and concurrency claims.
exec
/bin/zsh -lc "git status -sb && printf '\\n-- files --\\n' && rg --files -g 'AGENTS.md' -g 'docs/architecture.md' -g 'project.yml' -g '.claude/rules/47-feature-workflow.md' -g '.claude/rules/51-no-self-designed-ui.md' -g 'vrecorder/**/*.swift' -g 'scripts/run-tests.sh' | sort" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
## feat/6-verification-harness
?? dev-docs/plans/20260615-feature-6-verification-harness.md

-- files --
AGENTS.md
docs/architecture.md
project.yml
scripts/run-tests.sh
vrecorder/App/AppEnvironment.swift
vrecorder/App/Log.swift
vrecorder/App/RootView.swift
vrecorder/App/VRecorderApp.swift
vrecorder/Audio/AudioSessionController.swift
vrecorder/Audio/AudioTapBridge.swift
vrecorder/Audio/PCMRollover.swift
vrecorder/DesignSystem/Palette.swift
vrecorder/DesignSystem/Typography.swift
vrecorder/Engines/AppleSpeechRecognizer.swift
vrecorder/Engines/EngineProtocols.swift
vrecorder/Engines/OpenAITranslationEngine.swift
vrecorder/Engines/RecognitionEventCoalescer.swift
vrecorder/Engines/StreamingEvents.swift
vrecorder/Models/LiveSessionModel.swift
vrecorder/Models/TranscriptLine.swift
vrecorder/Security/APIKeyBootstrap.swift
vrecorder/Security/APIKeyEntryModel.swift
vrecorder/Security/APIKeyStore.swift
vrecorder/Views/APIKeyEntryView.swift
vrecorder/Views/Components/LiveBadge.swift
vrecorder/Views/Components/MicButton.swift
vrecorder/Views/Components/TranscriptLineView.swift
vrecorder/Views/Components/WaterSurface.swift
vrecorder/Views/LiveScreen.swift
vrecorder/Views/SettingsScreen.swift

codex
The worktree is on `feat/6-verification-harness` with only the plan file untracked, so there are no implementation changes to confuse the audit. I’m now tracing ownership/lifecycle and checking the exact tracker and rule requirements that constrain the three WIs.
exec
/bin/zsh -lc "rg -n \"pushA|pushB|@MainActor|AppEnvironment|RootView|WindowGroup|onOpenURL|scenePhase|bundle\\.ui-testing|info:|INFOPLIST|URLTypes|APIKeyBootstrap|accessibilityIdentifier\" vrecorder project.yml docs/architecture.md .claude/rules/47-feature-workflow.md .claude/rules/51-no-self-designed-ui.md docs/features.md scripts/run-tests.sh" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
docs/features.md:98:Release key resource excluded from the bundle, scenePhase background stop,
project.yml:12:    GENERATE_INFOPLIST_FILE: "YES"
project.yml:33:        GENERATE_INFOPLIST_FILE: "YES"
project.yml:34:        INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
project.yml:35:        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: "YES"
project.yml:36:        INFOPLIST_KEY_NSMicrophoneUsageDescription: "VRecorder 需要使用麦克风进行实时同声传译。"
project.yml:37:        INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: "VRecorder 使用语音识别将你的发言实时转写为文字。"
project.yml:38:        INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait"
project.yml:39:        INFOPLIST_KEY_UIStatusBarStyle: UIStatusBarStyleLightContent
project.yml:44:        # it stays a DEBUG-only convenience (audit-3 #4). APIKeyBootstrap also
.claude/rules/47-feature-workflow.md:70:- VRecorder compliance (Swift 6 concurrency, @MainActor correctness, file size <300 lines)
docs/architecture.md:13:LiveSessionModel (@MainActor @Observable)   ← composition root: AppEnvironment
docs/architecture.md:35:| ViewModels | services, engines (protocols) | `@MainActor @Observable` |
docs/architecture.md:43:| `AppEnvironment` | Composition root — builds the session model with concrete engines + Keychain store |
docs/architecture.md:44:| `LiveSessionModel` | `@MainActor @Observable` session state machine; runs the STT→translate→display pipeline (or demo simulator) |
docs/architecture.md:49:| `APIKeyEntryModel` | `@MainActor @Observable` view-model for the Settings → API-key sheet; format-agnostic validation + masking, atomic save/clear over `APIKeyStoring` |
vrecorder/Models/LiveSessionModel.swift:13:@MainActor
vrecorder/Models/LiveSessionModel.swift:86:    func pushA(_ line: TranscriptLine) { push(into: &partyA, line) }
vrecorder/Models/LiveSessionModel.swift:87:    func pushB(_ line: TranscriptLine) { push(into: &partyB, line) }
vrecorder/Models/LiveSessionModel.swift:126:            pushA(.init(status: .partial, text: t))
vrecorder/Models/LiveSessionModel.swift:128:            pushA(.init(status: .final, text: t))
vrecorder/Models/LiveSessionModel.swift:148:                    if !english.isEmpty { self.pushB(.init(status: .final, text: english)) }
vrecorder/Models/LiveSessionModel.swift:196:                isA ? self.pushA(line) : self.pushB(line)
vrecorder/Engines/AppleSpeechRecognizer.swift:12:@MainActor
vrecorder/Engines/AppleSpeechRecognizer.swift:51:                Task { @MainActor in self?.stop() }
vrecorder/Engines/AppleSpeechRecognizer.swift:118:                    Task { @MainActor in self?.rotateAfterFinal(gen: gen) }
vrecorder/Engines/AppleSpeechRecognizer.swift:123:                Task { @MainActor in self?.finish(gen: gen, throwing: error) }
vrecorder/Security/APIKeyBootstrap.swift:1://  APIKeyBootstrap.swift
vrecorder/Security/APIKeyBootstrap.swift:9:enum APIKeyBootstrap {
vrecorder/Audio/AudioSessionController.swift:10:@MainActor
vrecorder/Audio/AudioSessionController.swift:50:        // mutates @MainActor state) on the main actor (audit-G4r2 #1).
vrecorder/App/AppEnvironment.swift:1://  AppEnvironment.swift
vrecorder/App/AppEnvironment.swift:9:@MainActor
vrecorder/App/AppEnvironment.swift:10:final class AppEnvironment {
vrecorder/App/AppEnvironment.swift:16:        APIKeyBootstrap.seedIfNeeded(store: store)
vrecorder/Engines/EngineProtocols.swift:12:@MainActor
vrecorder/Security/APIKeyEntryModel.swift:10:@MainActor
vrecorder/App/RootView.swift:1://  RootView.swift
vrecorder/App/RootView.swift:7:struct RootView: View {
vrecorder/App/RootView.swift:9:    @Environment(\.scenePhase) private var scenePhase
vrecorder/App/RootView.swift:11:    // stored property is rebuilt on each RootView init, which let scene-phase
vrecorder/App/RootView.swift:13:    @State private var env = AppEnvironment()
vrecorder/App/RootView.swift:31:        .onChange(of: scenePhase) { _, phase in
vrecorder/App/VRecorderApp.swift:10:        WindowGroup {
vrecorder/App/VRecorderApp.swift:11:            RootView()

exec
/bin/zsh -lc "awk 'FNR==1 {print \"\\n===== \" FILENAME \" =====\"} {printf \"%5d  %s\\n\", FNR, "'$0}'"' vrecorder/App/AppEnvironment.swift vrecorder/App/RootView.swift vrecorder/App/VRecorderApp.swift vrecorder/Models/LiveSessionModel.swift vrecorder/Security/APIKeyBootstrap.swift project.yml docs/architecture.md .claude/rules/47-feature-workflow.md .claude/rules/51-no-self-designed-ui.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:

===== vrecorder/App/AppEnvironment.swift =====
    1  //  AppEnvironment.swift
    2  //  Purpose: Composition root. Builds the live-session model with real engines
    3  //  (on-device STT + OpenAI translation, Keychain-backed key) and seeds the key
    4  //  from a bundled config/openai-key.txt on first DEBUG launch. This is the only
    5  //  place concrete providers are chosen; everything downstream sees protocols.
    6  
    7  import SwiftUI
    8  
    9  @MainActor
   10  final class AppEnvironment {
   11      let keyStore: APIKeyStoring
   12      let session: LiveSessionModel
   13  
   14      init() {
   15          let store = KeychainAPIKeyStore()
   16          APIKeyBootstrap.seedIfNeeded(store: store)
   17          self.keyStore = store
   18  
   19          let translator = OpenAITranslationEngine(keyProvider: { store.key(for: APIProvider.openAI) })
   20          self.session = LiveSessionModel(
   21              recognizer: AppleSpeechRecognizer(),
   22              translator: translator,
   23              audio: AudioSessionController()
   24          )
   25      }
   26  }

===== vrecorder/App/RootView.swift =====
    1  //  RootView.swift
    2  //  Purpose: Top-level navigation. Live IS the home screen; the gear pushes
    3  //  Settings and the chevron returns (session state is retained). design/README.md.
    4  
    5  import SwiftUI
    6  
    7  struct RootView: View {
    8      @State private var showSettings = false
    9      @Environment(\.scenePhase) private var scenePhase
   10      // @State so SwiftUI keeps ONE environment for this view's identity — a plain
   11      // stored property is rebuilt on each RootView init, which let scene-phase
   12      // teardown stop() a different session than the screen holds (audit-G4r2 #2).
   13      @State private var env = AppEnvironment()
   14  
   15      var body: some View {
   16          ZStack {
   17              // Color scheme is per-surface (audit-G4 #5): the live stage is dark,
   18              // Settings + its key-entry sheet are light — forcing dark globally gave
   19              // the light sheet low-contrast system chrome.
   20              LiveScreen(session: env.session, onSettings: { showSettings = true })
   21                  .preferredColorScheme(.dark)
   22  
   23              if showSettings {
   24                  SettingsScreen(onBack: { showSettings = false }, store: env.keyStore)
   25                      .preferredColorScheme(.light)
   26                      .transition(.move(edge: .trailing))
   27                      .zIndex(1)
   28              }
   29          }
   30          .animation(.easeOut(duration: 0.42), value: showSettings)
   31          .onChange(of: scenePhase) { _, phase in
   32              // Don't leave the mic + audio session live in the background
   33              // (audit-4 #6) — tear down explicitly instead of relying on the OS.
   34              if phase == .background { env.session.stop() }
   35          }
   36      }
   37  }

===== vrecorder/App/VRecorderApp.swift =====
    1  //  VRecorderApp.swift
    2  //  Purpose: App entry point. Launches straight into the live-interpretation
    3  //  screen (no onboarding for the MVP). design/README.md.
    4  
    5  import SwiftUI
    6  
    7  @main
    8  struct VRecorderApp: App {
    9      var body: some Scene {
   10          WindowGroup {
   11              RootView()
   12          }
   13      }
   14  }

===== vrecorder/Models/LiveSessionModel.swift =====
    1  //  LiveSessionModel.swift
    2  //  Purpose: Observable session state for the live-interpretation screen. Runs the
    3  //  STT→translate→display pipeline (or a no-network demo simulator).
    4  //  Correctness guards: a session-generation token invalidates stale async paths
    5  //  on stop/restart (#3); translations run through ONE bounded sequential queue so
    6  //  tasks don't accumulate and results commit in source order (#4, audit-2 High);
    7  //  audio interruptions stop the session (#5); teardown always deactivates the
    8  //  audio session (#6). Engines are referenced via protocols so they're mockable.
    9  //  rules/50 §2-4.
   10  
   11  import SwiftUI
   12  
   13  @MainActor
   14  @Observable
   15  final class LiveSessionModel {
   16      private(set) var listening = false
   17      private(set) var partyA: [TranscriptLine]   // you (中文)
   18      private(set) var partyB: [TranscriptLine]   // counterpart (English)
   19      private(set) var errorMessage: String?
   20  
   21      private let maxLines = 3
   22      private let recognizer: (any SpeechRecognizing)?
   23      private let translator: (any TranslationEngine)?
   24      private let audio: AudioSessionController?
   25  
   26      /// Bumped on every start/stop; stale async work compares against it and bails.
   27      private var generation = 0
   28      private var sttTask: Task<Void, Never>?
   29      private var translationConsumer: Task<Void, Never>?
   30      private var finalsContinuation: AsyncStream<String>.Continuation?
   31      private var demoTask: Task<Void, Never>?
   32  
   33      private let sourceLocale = Locale(identifier: "zh-CN")
   34      private let targetLocale = Locale(identifier: "en-US")
   35  
   36      init(recognizer: (any SpeechRecognizing)? = nil,
   37           translator: (any TranslationEngine)? = nil,
   38           audio: AudioSessionController? = nil) {
   39          self.recognizer = recognizer
   40          self.translator = translator
   41          self.audio = audio
   42          partyA = [TranscriptLine(status: .history, text: "中国有很多美食。")]
   43          partyB = [TranscriptLine(status: .history, text: "There is a lot of delicious food in China.")]
   44      }
   45  
   46      private var hasPipeline: Bool { recognizer != nil && translator != nil }
   47      var showPrompt: Bool { listening && partyA.allSatisfy { $0.status == .history } }
   48  
   49      func toggle() { listening ? stop() : start() }
   50      func clearError() { errorMessage = nil }
   51  
   52      /// Authoritative teardown. Bumps generation so any in-flight async path bails,
   53      /// cancels owned tasks, closes the translation queue, releases the audio
   54      /// session. Safe to call repeatedly.
   55      func stop() {
   56          generation += 1
   57          listening = false
   58          recognizer?.stop()
   59          sttTask?.cancel(); sttTask = nil
   60          finalsContinuation?.finish(); finalsContinuation = nil
   61          translationConsumer?.cancel(); translationConsumer = nil
   62          demoTask?.cancel(); demoTask = nil
   63          audio?.deactivate()
   64      }
   65  
   66      // MARK: - Event ingestion
   67  
   68      /// Push a line into a panel. If the active (trailing) line is a partial, the
   69      /// incoming line continues that same segment — reuse its id so SwiftUI
   70      /// animates partial→final in place rather than as a remove/insert (audit Low).
   71      private func push(into lines: inout [TranscriptLine], _ line: TranscriptLine) {
   72          var incoming = line
   73          var kept = lines
   74          if let last = kept.last, last.status == .partial {
   75              incoming = TranscriptLine(id: last.id, status: line.status, text: line.text)
   76              kept.removeLast()
   77          }
   78          kept = kept.map { l -> TranscriptLine in
   79              var l = l; if l.status == .final { l.status = .history }; return l
   80          }
   81          if kept.count > maxLines - 1 { kept.removeFirst(kept.count - (maxLines - 1)) }
   82          kept.append(incoming)
   83          lines = kept
   84      }
   85  
   86      func pushA(_ line: TranscriptLine) { push(into: &partyA, line) }
   87      func pushB(_ line: TranscriptLine) { push(into: &partyB, line) }
   88  
   89      // MARK: - Real pipeline
   90  
   91      private func start() {
   92          errorMessage = nil
   93          guard hasPipeline, let recognizer else { startDemo(); return }
   94          generation += 1
   95          let gen = generation
   96          listening = true
   97          startTranslationQueue(gen: gen)
   98          audio?.onEvent = { [weak self] event in
   99              switch event {
  100              case .interruptionBegan, .routeLost, .routeChanged: self?.stop()
  101              case .interruptionEnded: break        // require an explicit re-tap to resume
  102              }
  103          }
  104          sttTask = Task { [weak self] in
  105              guard let self else { return }
  106              do {
  107                  try await recognizer.requestAuthorization()
  108                  guard gen == self.generation, !Task.isCancelled else { return }
  109                  try self.audio?.activate()
  110                  guard gen == self.generation, !Task.isCancelled else { self.audio?.deactivate(); return }
  111                  let stream = try recognizer.start(locale: self.sourceLocale)
  112                  for try await event in stream {
  113                      guard gen == self.generation else { break }
  114                      self.handle(event)
  115                  }
  116              } catch {
  117                  self.fail(error, gen: gen)
  118              }
  119              if gen == self.generation { self.stop() }
  120          }
  121      }
  122  
  123      private func handle(_ event: TranscriptEvent) {
  124          switch event {
  125          case .partial(let t):
  126              pushA(.init(status: .partial, text: t))
  127          case .final(let t):
  128              pushA(.init(status: .final, text: t))
  129              finalsContinuation?.yield(t)          // enqueue for ordered translation
  130          }
  131      }
  132  
  133      /// One consumer translates finals sequentially (bounded — no task pile-up)
  134      /// and commits in source order.
  135      private func startTranslationQueue(gen: Int) {
  136          guard let translator else { return }
  137          // Bounded buffer: if translation falls behind speech, drop the oldest
  138          // pending finals deterministically rather than growing unboundedly
  139          // (audit-3 #3). A live interpreter values latest speech over backlog.
  140          let (stream, cont) = AsyncStream<String>.makeStream(bufferingPolicy: .bufferingNewest(8))
  141          finalsContinuation = cont
  142          translationConsumer = Task { [weak self] in
  143              for await chinese in stream {
  144                  guard let self, gen == self.generation, !Task.isCancelled else { continue }
  145                  do {
  146                      let english = try await translator.translate(chinese, from: self.sourceLocale, to: self.targetLocale)
  147                      guard gen == self.generation, !Task.isCancelled else { continue }
  148                      if !english.isEmpty { self.pushB(.init(status: .final, text: english)) }
  149                  } catch {
  150                      guard gen == self.generation else { continue }
  151                      self.fail(error, gen: gen)
  152                  }
  153              }
  154          }
  155      }
  156  
  157      private func fail(_ error: Error, gen: Int) {
  158          guard gen == generation else { return }
  159          errorMessage = Self.message(for: error)
  160          stop()
  161      }
  162  
  163      static func message(for error: Error) -> String {
  164          switch error {
  165          case PipelineError.offline:                return "网络不可用，请检查连接"
  166          case PipelineError.timeout:                return "翻译超时，请重试"
  167          case PipelineError.rateLimited:            return "请求过于频繁，请稍后再试"
  168          case PipelineError.micPermissionDenied:    return "需要麦克风权限，请在设置中开启"
  169          case PipelineError.speechPermissionDenied: return "需要语音识别权限，请在设置中开启"
  170          case PipelineError.missingAPIKey:          return "未配置 API 密钥"
  171          case PipelineError.invalidAPIKey:          return "API 密钥无效或已失效，请在设置中更新"
  172          case PipelineError.recognizerUnavailable:  return "当前语言的语音识别不可用"
  173          case PipelineError.recognitionFailed:      return "语音识别失败，请重试"
  174          case PipelineError.providerError(let m):   return "翻译服务错误：\(m)"
  175          default:                                   return "发生未知错误"
  176          }
  177      }
  178  
  179      // MARK: - Demo simulator (no network — course-demo fallback)
  180  
  181      private func startDemo() {
  182          generation += 1
  183          let gen = generation
  184          listening = true
  185          let steps: [(UInt64, Bool, TranscriptLine)] = [
  186              (500,  true,  .init(status: .partial, text: "重庆火锅很辣，但是…")),
  187              (500,  false, .init(status: .partial, text: "Chongqing hot pot is spicy, but…")),
  188              (1000, true,  .init(status: .final,   text: "重庆火锅很辣，但是很好吃！")),
  189              (600,  false, .init(status: .final,   text: "Chongqing hot pot is spicy, but delicious!")),
  190          ]
  191          demoTask = Task { [weak self] in
  192              for (ms, isA, line) in steps {
  193                  do { try await Task.sleep(nanoseconds: ms * 1_000_000) }
  194                  catch { return }                              // cancelled → stop mutating
  195                  guard let self, gen == self.generation, !Task.isCancelled else { return }
  196                  isA ? self.pushA(line) : self.pushB(line)
  197              }
  198              if let self, gen == self.generation { self.listening = false }
  199          }
  200      }
  201  }

===== vrecorder/Security/APIKeyBootstrap.swift =====
    1  //  APIKeyBootstrap.swift
    2  //  Purpose: DEBUG-only convenience — on first launch, if config/openai-key.txt was
    3  //  bundled into the app (dev builds only) and the Keychain has no OpenAI key yet,
    4  //  copy it into the Keychain once. Release builds never read a file; the key is
    5  //  entered through Settings. See AGENTS.md › AI coding tool auth / rules/50 §7.
    6  
    7  import Foundation
    8  
    9  enum APIKeyBootstrap {
   10      /// Seed the Keychain from a bundled `openai-key.txt` resource if present and unset.
   11      static func seedIfNeeded(store: APIKeyStoring) {
   12          #if DEBUG
   13          guard store.key(for: APIProvider.openAI) == nil else { return }
   14          guard let url = Bundle.main.url(forResource: "openai-key", withExtension: "txt"),
   15                let raw = try? String(contentsOf: url, encoding: .utf8) else { return }
   16          let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
   17          guard !key.isEmpty else { return }
   18          store.setKey(key, for: APIProvider.openAI)
   19          #endif
   20      }
   21  }

===== project.yml =====
    1  name: vrecorder
    2  options:
    3    bundleIdPrefix: com.vrecorder
    4    deploymentTarget:
    5      iOS: "17.0"
    6    createIntermediateGroups: true
    7  
    8  settings:
    9    base:
   10      SWIFT_VERSION: "6.0"
   11      SWIFT_STRICT_CONCURRENCY: complete
   12      GENERATE_INFOPLIST_FILE: "YES"
   13      MARKETING_VERSION: "0.2.5"
   14      CURRENT_PROJECT_VERSION: "7"
   15      DEVELOPMENT_TEAM: ""
   16      CODE_SIGN_STYLE: Automatic
   17  
   18  targets:
   19    vrecorder:
   20      type: application
   21      platform: iOS
   22      deploymentTarget: "17.0"
   23      sources:
   24        - path: vrecorder
   25        - path: config/openai-key.txt
   26          optional: true
   27          buildPhase: resources
   28      settings:
   29        base:
   30          PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app
   31          MARKETING_VERSION: "0.2.5"
   32          CURRENT_PROJECT_VERSION: "7"
   33          GENERATE_INFOPLIST_FILE: "YES"
   34          INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
   35          INFOPLIST_KEY_UIApplicationSceneManifest_Generation: "YES"
   36          INFOPLIST_KEY_NSMicrophoneUsageDescription: "VRecorder 需要使用麦克风进行实时同声传译。"
   37          INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: "VRecorder 使用语音识别将你的发言实时转写为文字。"
   38          INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait"
   39          INFOPLIST_KEY_UIStatusBarStyle: UIStatusBarStyleLightContent
   40          ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
   41          TARGETED_DEVICE_FAMILY: "1"
   42        configs:
   43          # Never ship the dev key resource in a distributable (Release) bundle —
   44          # it stays a DEBUG-only convenience (audit-3 #4). APIKeyBootstrap also
   45          # #if DEBUG-gates the read; this removes the file from the bundle too.
   46          Release:
   47            EXCLUDED_SOURCE_FILE_NAMES: "openai-key.txt"
   48  
   49    vrecorderTests:
   50      type: bundle.unit-test
   51      platform: iOS
   52      deploymentTarget: "17.0"
   53      sources:
   54        - path: vrecorderTests
   55      dependencies:
   56        - target: vrecorder
   57      settings:
   58        base:
   59          PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app.tests
   60  
   61  schemes:
   62    vrecorder:
   63      build:
   64        targets:
   65          vrecorder: all
   66          vrecorderTests: [test]
   67      test:
   68        targets:
   69          - vrecorderTests

===== docs/architecture.md =====
    1  # vrecorder-v2 Architecture
    2  
    3  > Fact source. AGENTS.md requires every agent to read this before changing code.
    4  > Update it in the SAME PR whenever layers, services, schema, or notifications change
    5  > (rule 24). Stale-but-passing doc text is worse than none.
    6  
    7  ## System diagram
    8  
    9  ```
   10  LiveScreen / SettingsScreen (SwiftUI)
   11     │
   12     ▼
   13  LiveSessionModel (@MainActor @Observable)   ← composition root: AppEnvironment
   14     │            │
   15     │            ├── SpeechRecognizing  → AppleSpeechRecognizer (SFSpeechRecognizer + AVAudioEngine)
   16     │            ├── TranslationEngine  → OpenAITranslationEngine (Chat Completions)
   17     │            └── AudioSessionController (single AVAudioSession owner)
   18     │
   19     ▼
   20  TranscriptLine[]  (partial → final → history, max 3/panel)
   21  
   22  API key: KeychainAPIKeyStore (DEBUG seed from bundled config/openai.key)
   23  ```
   24  
   25  Pipeline (MVP): mic → on-device 中文 STT (partial/final) → per-final OpenAI
   26  translate 中文→English → push English final to the counterpart panel. When no
   27  engines are injected, LiveSessionModel runs a built-in demo simulator (no
   28  network) for course demos / offline fallback.
   29  
   30  ## Layers
   31  
   32  | Layer | May import | Notes |
   33  |-------|-----------|-------|
   34  | Views (SwiftUI) | ViewModels, DesignSystem | no business logic |
   35  | ViewModels | services, engines (protocols) | `@MainActor @Observable` |
   36  | Services / pipeline actors | other services, AVFoundation, Speech | actor-isolated |
   37  | Persistence | SwiftData | single actor owns all mutations |
   38  
   39  ## Services
   40  
   41  | Name | Purpose |
   42  |------|---------|
   43  | `AppEnvironment` | Composition root — builds the session model with concrete engines + Keychain store |
   44  | `LiveSessionModel` | `@MainActor @Observable` session state machine; runs the STT→translate→display pipeline (or demo simulator) |
   45  | `AppleSpeechRecognizer` | On-device `SpeechRecognizing` (SFSpeechRecognizer + AVAudioEngine), emits partial/final |
   46  | `OpenAITranslationEngine` | `TranslationEngine` over OpenAI Chat Completions; pure request/parse helpers are unit-tested |
   47  | `AudioSessionController` | Single owner of `AVAudioSession` config + interruption handling |
   48  | `KeychainAPIKeyStore` | `APIKeyStoring` over the Keychain (atomic update→add via injectable `KeychainOps`); DEBUG-seeded from bundled `config/openai-key.txt` |
   49  | `APIKeyEntryModel` | `@MainActor @Observable` view-model for the Settings → API-key sheet; format-agnostic validation + masking, atomic save/clear over `APIKeyStoring` |
   50  
   51  ## Key design patterns
   52  
   53  - **Engine-behind-protocol**: `SpeechRecognizing` / `TranslationEngine` so providers
   54    (Apple on-device, OpenAI cloud) are swappable and mockable; capabilities are
   55    declared, not hard-coded at call sites.
   56  - **Replaceable partials**: a `.partial` line is replaced in place; `.final` freezes
   57    it; older lines demote to `.history` (max 3 per panel).
   58  - **Single audio-session owner**: only `AudioSessionController` touches `AVAudioSession`.
   59  - **VAD segment rotation with rollover**: `AudioTapBridge` does RMS silence
   60    detection and `endAudio()`s to segment utterances; audio captured during the
   61    request-rotation gap is held in a bounded `PCMRollover` and replayed into the
   62    next request so the next utterance's start isn't dropped (bug #3 fix).
   63  - **Demo fallback**: `LiveSessionModel` with no injected engines runs a scripted
   64    partial→final sequence — zero network, for course demos.
   65  
   66  ## Data layer
   67  _(SwiftData schema version + entities — fill in at M4)_
   68  
   69  ## Notification bus
   70  _(name | payload | direction — add rows as cross-component events appear)_
   71  

===== .claude/rules/47-feature-workflow.md =====
    1  # 47 — Feature Implementation Workflow
    2  
    3  Binding sequence for every feature implementation. Six gates, never skip one.
    4  
    5  > **Plan → Independent plan audit → TDD implementation → Implementation audit loop → Device/integration verification → Merge**
    6  
    7  This is a **gate model**, not a chronological task list. Each gate has an explicit acceptance bar; you do not enter the next gate until the current gate's bar is met. Multiple iterations within a gate are normal.
    8  
    9  ## Gate 1 — Plan
   10  
   11  Write `dev-docs/plans/YYYYMMDD-feature-N-<slug>.md` covering, at minimum:
   12  
   13  - **Problem** — what user need this addresses (mirror or refine the row's `Problem` field).
   14  - **Surface area** — file-by-file with concrete signatures (which protocols, types, methods get added or modified). Includes a "files OUT of scope" subsection.
   15  - **Prior art / project precedent / rejected alternatives** — what existing patterns we're building on, what we considered and rejected, and why. **Research is part of the plan**, not a separate step.
   16  - **Work-item sequencing** — small, testable units (typically 1-15 WIs). Each WI is one PR's worth of work. Estimated PR size per WI.
   17  - **Test catalogue** — concrete test files, what each covers, including the audit-driven additions (corruption, partial failure, idempotency edge cases).
   18  - **Risks + mitigations** — known unknowns and how we'll handle them.
   19  - **Backward compat** — what happens to existing data / older clients / older backups when this ships.
   20  
   21  The features.md "Plan Template" fields (Problem, Scope, Edge Cases, Test plan, Acceptance criteria) live in the row; the implementation-detail plan in `dev-docs/plans/` expands on them with file paths, signatures, and sequencing.
   22  
   23  **Acceptance bar**: plan exists at the documented path; status moves to `PLANNED` only when this gate passes.
   24  
   25  ## Gate 2 — Independent Plan Audit
   26  
   27  Send the plan to an independent AI auditor (not the same agent/model/context as the plan author). cc-suite (driving Codex via `codex exec`) is the current default; Gemini, OpenCode, or any equivalent satisfies the gate. The invariant is **independence**, not the brand.
   28  
   29  Audit prompt must explicitly request:
   30  
   31  - **Model assumption verification** — do the SwiftData fields, enum cases, function signatures, file paths I named actually exist? (This catches the largest class of pre-implementation bugs.)
   32  - **Risks + missing edge cases** — what failure modes the plan misses.
   33  - **Protocol signature critique** — are new interfaces well-shaped, or do they leak implementation concerns?
   34  - **Concurrency hazards** — actor isolation, Sendable, race conditions in mutable state.
   35  - **Cohesion check** — is the WI split right, or are some WIs too big or too small?
   36  
   37  **Acceptance bar**:
   38  
   39  - Zero open Critical/High/Medium findings.
   40  - Low findings either fixed in the plan or explicitly accepted with rationale (in the plan's "Known limitations" or "Audit fixes applied" section).
   41  - **Maximum 3 audit rounds**. If unresolved findings remain after round 3, stop and escalate to the user — accept, defer, or redesign.
   42  
   43  Track audit rounds in the plan's revision history. The author rewrites the plan to address findings; the auditor re-reviews. Same loop until clean.
   44  
   45  **Why this gate exists**: Codex audits routinely catch 5-10 real bugs per round on non-trivial plans (compile-breaking model assumptions, missing preconditions, protocol shape mistakes). Skipping the audit shifts that cost into wasted implementation work.
   46  
   47  ## Gate 3 — TDD Implementation
   48  
   49  Per work item:
   50  
   51  1. **RED** — write a failing test that captures the WI's behavior. See `.claude/rules/10-tdd.md` for pattern catalogue.
   52  2. **GREEN** — write minimal implementation to make the test pass.
   53  3. **REFACTOR** — clean up without changing behavior. Tests stay green.
   54  4. **PR** — small, focused PR per WI. Apply per-PR rules: docs sync (`24-doc-sync.md`), version bump (`40-version-bump.md`).
   55  
   56  Status: feature → `IN PROGRESS` when WI-1's PR opens.
   57  
   58  **Acceptance bar per WI**: tests pass under `xcodebuild test -only-testing:vrecorderTests`; new code follows codebase conventions (`.claude/rules/50-codebase-conventions.md`).
   59  
   60  ## Gate 4 — Implementation Audit Loop
   61  
   62  After implementation but before merge: independent audit of the changed files (read-only sandbox). This is what `/fix-issue` already runs.
   63  
   64  Audit prompt focuses on:
   65  
   66  - Correctness against the plan
   67  - Edge cases in the diff (boundary conditions, nil, Unicode/CJK, concurrent access)
   68  - Security (JS injection in evaluateJavaScript, WKWebView bridge safety, etc.)
   69  - Duplicate / dead code introduced
   70  - VRecorder compliance (Swift 6 concurrency, @MainActor correctness, file size <300 lines)
   71  - Bridge safety (FoliateJSEscaper for JS interpolation, message parser edge cases)
   72  
   73  **Acceptance bar**:
   74  
   75  - Zero open Critical/High/Medium findings.
   76  - Low findings fixed or explicitly accepted with rationale in the PR body.
   77  - **Maximum 3 audit-fix rounds**. After round 3, escalate.
   78  
   79  Same author/auditor separation as Gate 2.
   80  
   81  ## Gate 5 — Device / Integration Verification
   82  
   83  For each PR before it merges:
   84  
   85  - **Foundational WIs** (DTOs, protocols, utilities, pure types — no user-observable behavior): unit + integration tests + audit are sufficient. No device verification required.
   86  - **Behavioral WIs** (anything that changes app behavior, persistence, networking, backup format, reader rendering, or UI flow): **slice verification** — exercise the slice end-to-end against the real environment available at this point. Run on iPhone 17 Pro Simulator with `vrecorder-debug://` harness; for backup/network features, against a real WebDAV server (or local Docker WebDAV equivalent); for reader features, with a fixture book.
   87  - **Final WI** (the one that completes the feature): full end-to-end acceptance pass — every acceptance criterion exercised. This is what flips the feature row from `DONE` to `VERIFIED`.
   88  
   89  Record slice verification in the PR description (what was run, what was observed). Record final acceptance verification in a structured evidence file at `dev-docs/verification/feature-<id>-<YYYYMMDD>.md` per the schema in `dev-docs/verification/SCHEMA.md`. The PreToolUse hook `.claude/hooks/check_terminal_status_evidence.sh` blocks any tracker edit that flips a row to `VERIFIED` (features) or `FIXED` (bugs) without a matching evidence file.
   90  
   91  **Acceptance bar per PR**: every behavioral slice in the PR has been verified end-to-end at the level appropriate to its WI tier. Final WI requires full acceptance pass + evidence file.
   92  
   93  **"Tooling unavailable" is NOT an acceptable deferral reason** unless a specific tool is named and confirmed missing (e.g., `xcrun simctl` returns "command not found", a real device is required and none is connected, the rclone WebDAV server is down). "I'll do it next session" is not a tool-unavailability claim — it's a discipline lapse. The Stop hook (`.claude/hooks/check_unfinished_verification.sh`) surfaces unverified `DONE` rows at session end so the gap doesn't quietly carry over.
   94  
   95  ## Gate 6 — Merge
   96  
   97  PR may merge when ALL of the following hold:
   98  
   99  - Tests pass (the merge gate from `AGENTS.md`).
  100  - Implementation audit loop is clean (Gate 4).
  101  - Device / integration verification is complete for the PR's tier (Gate 5).
  102  - Docs sync completed if triggered (`.claude/rules/24-doc-sync.md`).
  103  - Version bump committed as the last commit before opening the PR (`.claude/rules/40-version-bump.md`).
  104  - For PRs that reference an open bug/feature: the referenced row has reached its terminal status (`FIXED` for bugs, `DONE` for features) — the existing fix-or-implement merge gate.
  105  
  106  After merge:
  107  
  108  - Feature status moves to `DONE` only after **all** WIs are merged AND every acceptance criterion is implemented.
  109  - `VERIFIED` is a separate post-implementation status, set after Gate 5's final-WI acceptance pass lands and is recorded in the row. Requires a `dev-docs/verification/feature-<id>-<YYYYMMDD>.md` evidence file (PreToolUse hook enforces).
  110  - GH issue closes per close-gate rule (closure comment cites the verification: commit SHA + what was tested + what was observed).
  111  
  112  ## Gate progress is recorded in the GH issue (binding)
  113  
  114  The GH issue mirror is not just a creation-time pointer — it is the **running record** of the feature's path through the six gates. Once the issue exists (created at the Gate 2 → `PLANNED` flip), every gate transition posts a short, append-only comment so the issue reads as a verifiable timeline of the workflow. A reviewer who only sees GitHub can then audit gate compliance without cloning the repo.
  115  
  116  Post one comment at each of these transitions:
  117  
  118  | Transition | Comment records |
  119  | --- | --- |
  120  | Gate 2 passes (issue just created) | plan path + audit verdict (Codex threadId + rounds, or `manual-fallback`) + the WI list with foundational/behavioral tiers |
  121  | Each WI's PR merges (Gate 6) | WI number + tier, PR number, version bumped to, merge-commit SHA, Gate 4 audit verdict, Gate 5a slice result |
  122  | Final WI merges → row `DONE` | "shipped in vX.Y.Z (commit `<sha>`), awaiting verification" — this is the existing close-gate comment |
  123  | Gate 5b acceptance pass → row `VERIFIED` | evidence-file path + `result:` + a one-line acceptance-criteria summary — this is the existing closure comment, posted just before `gh issue close` |
  124  
  125  Rules for these comments:
  126  
  127  - **Append-only, short, factual.** Paths, SHAs, verdicts, version numbers — not prose. One comment per transition; do not edit prior comments.
  128  - **The markdown artifacts stay the source of truth.** The `dev-docs/plans/` plan, the `.claude/codex-audits/` logs, `docs/features.md`, and the `dev-docs/verification/` evidence file are authoritative. The issue comments are a timeline that *points at* them; never copy a plan's full contents into the issue.
  129  - **A skipped comment is a gate-process lapse, not a hard-blocked one.** No hook enforces these (they are post-action `gh issue comment` calls), so the discipline is the gate. If a transition happened without its comment, back-fill it before the next transition.
  130  
  131  The two bottom rows already exist in the close-gate / finalizer flow; this rule adds the Gate-2 and per-WI-merge rows so the *middle* of the workflow is visible on GitHub, not just its endpoints.
  132  
  133  ## Audit count by feature size
  134  
  135  To keep the audit cost honest:
  136  
  137  | Size   | WIs     | Plan audits             | PR audits                                                                               |
  138  | ------ | ------- | ----------------------- | --------------------------------------------------------------------------------------- |
  139  | Small  | 1 PR    | 1                       | 1                                                                                       |
  140  | Medium | 2-4 WIs | 1                       | 1 per WI                                                                                |
  141  | Large  | 5+ WIs  | 1+ rounds (until clean) | 1 per WI; mechanical low-risk WIs that share the same surface MAY batch under one audit |
  142  
  143  If a feature is genuinely 10+ WIs, consider whether the plan should split into multiple features.
  144  
  145  ## Author / auditor separation (invariant)
  146  
  147  The agent that writes the plan must NOT be the same agent that audits it. Today this happens by accident (cc-suite runs Codex as a separate `codex exec` process from the implementing Claude Code session). The rule preserves this invariant explicitly so a future single-agent setup doesn't degenerate into self-marking.
  148  
  149  If a future setup runs everything through one agent, the audit step requires invoking a different model/context boundary explicitly (e.g., a fresh subagent with read-only sandbox + explicit "audit, don't implement" framing).
  150  
  151  ## Manual fallback when AI auditor unavailable
  152  
  153  When Codex / Gemini / equivalent is unavailable (network, quota, outage), do the audit manually AND record evidence in the plan or PR. Required `Manual Audit Evidence` section:
  154  
  155  - **Files read** (paths)
  156  - **Symbols / signatures verified** (which fields/types/enums you confirmed exist)
  157  - **Edge cases checked** (the list)
  158  - **Risks accepted** (with rationale)
  159  - **Tests added or intentionally deferred**
  160  
  161  Manual fallback is allowed only when the independent audit tool is genuinely unavailable, not just inconvenient. The audit step is non-negotiable; manual fallback is an evidence-bearing alternative, not a way to skip.
  162  
  163  ## What this rule does NOT change
  164  
  165  - TDD discipline (`10-tdd.md`) is unchanged.
  166  - Per-PR Codex audit in `/fix-issue` skill is exactly Gate 4 — reference, don't duplicate.
  167  - Merge gate (fix-or-implement) and close gate (verified, not just merged) are unchanged — this rule names where they fit in the workflow.
  168  - Bug fix workflow (`docs/bugs.md` `## Rules`) is unchanged — bugs follow Understand → RED → GREEN → REFACTOR → Verify → Track. Bugs do NOT require a separate plan + plan audit (they're reactive); they do require the implementation audit loop and verification gates.
  169  
  170  ## Worked example
  171  
  172  Feature #46 (WebDAV materializing restore, 11 WIs, High priority):
  173  
  174  - **Gate 1 (Plan)**: `dev-docs/plans/20260503-feature-46-materializing-restore.md` — drafted v1.
  175  - **Gate 2 (Plan audit)**: 2 Codex rounds. Round 1 found compile-breaking model assumptions (`Book.originalFilename` doesn't exist), missing `ImportSource.restore`, MOBI handling gap, idempotency hole in `BookImporter`, MOVE 501 silent fallback. Round 2 found `Book.fileExtension` also doesn't exist, weak `BackupBlobStore` signature, weak error shape. Plan v2 incorporates all findings.
  176  - **Gate 3 (TDD impl)**: 11 WIs sequenced (WI-0a model migration, WI-0b enum case, WI-1 BlobPath, etc.). Each ships its own PR.
  177  - **Gate 4 (Impl audit)**: per-PR via `/fix-issue` audit loop.
  178  - **Gate 5 (Verification)**: WI-0a, WI-0b, WI-1, WI-2 = foundational, no device verify. WI-7 (provider integration) = slice verify against Docker WebDAV. WI-10 (UI) = device verify on simulator. Final WI = full acceptance pass (backup → wipe → restore with positions/annotations).
  179  - **Gate 6 (Merge + close)**: each WI's PR merges through its own gate. Final WI moves feature row to `DONE`. After Gate 5 final acceptance pass: row → `VERIFIED`, GH #144 closes with citation.
  180  

===== .claude/rules/51-no-self-designed-ui.md =====
    1  # 51 — UI/UX from claude.ai/design only
    2  
    3  Binding rule for every agent (Claude, Codex, others). Applies to every feature, bug fix, refactor, and verification slice that introduces a new visible UI element.
    4  
    5  ## Hard rule
    6  
    7  **Do not invent UI/UX.** If a feature, bug fix, or slice needs a UI element on a surface that is NOT depicted in a committed design bundle under `dev-docs/designs/...`, stop that slice and file a `needs-design` GitHub issue. The user manually carries it through `claude.ai/design`, re-handoffs a fresh bundle, and only then does the slice resume.
    8  
    9  This applies to:
   10  
   11  - New SwiftUI / UIKit views, sheets, modals, popovers, alerts, toasts.
   12  - New rows, sections, settings entries, buttons, indicators, or empty states within existing screens.
   13  - New visual states (loading, error, empty, partial, in-progress) when not depicted in the design.
   14  - "Placeholder" UI introduced with intent to re-skin later — same prohibition.
   15  - UI affordances introduced by a bug fix (e.g., a new confirmation dialog, a new status chip) — same prohibition.
   16  - AZW3/Foliate-js / EPUB CSS / WKWebView injection — same prohibition when it changes visible chrome.
   17  
   18  ## What "designed" means
   19  
   20  A surface is **designed** when ALL of the following hold:
   21  
   22  1. A committed design bundle exists at `dev-docs/designs/<bundle-name>/`.
   23  2. The specific surface (screen, sheet, popover, interaction state) is depicted in that bundle's HTML/JSX/screenshots — by name and by visual content.
   24  3. "Looks similar to existing X" does NOT count. "Inherits the same chrome" does NOT count. The actual surface must appear in the design.
   25  
   26  If you cannot point at a file in `dev-docs/designs/` that shows the surface you are about to build, it is **not designed**.
   27  
   28  ## Workflow
   29  
   30  When you reach a slice that would touch undesigned UI:
   31  
   32  1. **Stop that slice.** Do not write the View. Do not write a placeholder. Do not improvise.
   33  2. **File a GitHub issue**:
   34     - Title: `Design needed: <surface name> for feature #<N>` (or `for bug #<N>`)
   35     - Labels: `enhancement` + `needs-design`
   36     - Body must include:
   37       - The surface being requested (screen / sheet / state)
   38       - The parent feature or bug (`Refs #<N>`)
   39       - The user-facing behavior the UI must expose
   40       - Screenshots of the current chrome if any
   41       - List of states the design must cover (default, loading, error, empty, etc.)
   42  3. **Pause that slice** in the tracker — add a `BLOCKED: needs-design (#<new-issue>)` note on the WI or bug row.
   43  4. **Continue parallel slices** that DO have design — see `.claude/rules/48-parallel-execution.md` for safe parallel execution.
   44  5. **User loop**: the user manually takes the `needs-design` issue through `claude.ai/design`, gets a handoff bundle, and commits it under `dev-docs/designs/...` in a separate PR. The slice can then resume.
   45  
   46  ## What is NOT covered by this rule
   47  
   48  - **System chrome (status bar, home indicator, dynamic island)** — iOS / SwiftUI handles these by default; no design needed.
   49  - **Pure code changes with no visible delta** — refactors, persistence-only fixes, performance fixes, test-only changes.
   50  - **Existing-surface bug fixes that restore broken UI back to its designed state** — fixing a typo in a label, fixing a hidden button, etc.
   51  - **Verification-only artifacts** — XCUITest helpers, DebugBridge surfaces (`vrecorder-debug://...`), `dev-docs/verification/*` markdown — these are dev-only, never user-visible in Release.
   52  - **CLI / config / hook / script files** — never user-facing.
   53  
   54  ## Anti-patterns
   55  
   56  | Anti-pattern | Why it fails | Right move |
   57  |---|---|---|
   58  | "I'll match the existing chrome for now" | That's self-designed UI. Existing chrome IS the thing being replaced (feature #60). | File `needs-design`. |
   59  | "Just a placeholder until v2" | Placeholders are committed code that ships in releases. Fragmenting UI for 2-3 versions is worse than pausing. | File `needs-design`. |
   60  | "It's a small dialog, an Apple HIG default works fine" | HIG defaults look fine in isolation but clash with the specified design system over time. | File `needs-design`. |
   61  | Inventing UI for a bug-fix toast / status chip / error sheet | Bug fixes don't escape this rule — they can introduce UI debt the same way features do. | File `needs-design`. |
   62  | Inventing UI in a feature-workflow Gate 3 implementation because the WI list said "small change" | Gate-3 must reference the designed surface; if no design exists for a WI's UI, that WI itself was misclassified in Gate 1 — escalate. | Stop the WI, file `needs-design`, fix the Gate-1 plan. |
   63  
   64  ## Origin
   65  
   66  2026-05-15 user directive after filing feature #60 (visual identity v2 design bundle). The user wants a one-way design loop:
   67  
   68  ```
   69  design tool → handoff bundle → commit → implement
   70  ```
   71  
   72  and explicitly rejects the round-trip:
   73  
   74  ```
   75  agent invents UI → ships → user notices → user redesigns → re-implement
   76  ```
   77  
   78  The cost of pausing a slice to file `needs-design` is far below the cost of producing UI debt that has to be re-skinned later. This rule encodes that trade-off.

exec
/bin/zsh -lc "awk 'FNR==1 {print \"\\n===== \" FILENAME \" =====\"} {printf \"%5d  %s\\n\", FNR, "'$0}'"' vrecorder/Views/LiveScreen.swift vrecorder/Views/Components/MicButton.swift vrecorder/Views/SettingsScreen.swift vrecorder/Views/APIKeyEntryView.swift vrecorder/Security/APIKeyEntryModel.swift scripts/run-tests.sh docs/features.md .claude/rules/10-tdd.md .claude/rules/40-version-bump.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:

===== vrecorder/Views/LiveScreen.swift =====
    1  //  LiveScreen.swift
    2  //  Purpose: Main screen — full-screen two-party split (ink top / violet bottom).
    3  //  Mirrors design/live-screen.jsx. Stage-1 build is driven by LiveSessionModel's
    4  //  demo simulator; the real pipeline plugs into the same model in Stage 2.
    5  
    6  import SwiftUI
    7  
    8  struct LiveScreen: View {
    9      @State private var session: LiveSessionModel
   10      let onSettings: () -> Void
   11  
   12      init(session: LiveSessionModel, onSettings: @escaping () -> Void) {
   13          _session = State(initialValue: session)
   14          self.onSettings = onSettings
   15      }
   16  
   17      var body: some View {
   18          GeometryReader { _ in
   19              VStack(spacing: 0) {
   20                  partyB
   21                  partyA
   22              }
   23          }
   24          .background(VR.partyBSurface)
   25          .ignoresSafeArea()
   26          .alert("同传出错", isPresented: Binding(
   27              get: { session.errorMessage != nil },
   28              set: { if !$0 { session.clearError() } }
   29          )) {
   30              Button("好", role: .cancel) {}
   31          } message: {
   32              Text(session.errorMessage ?? "")
   33          }
   34      }
   35  
   36      // MARK: Counterpart (ink, English)
   37  
   38      private var partyB: some View {
   39          ZStack(alignment: .top) {
   40              VStack(alignment: .leading, spacing: 8) {
   41                  Spacer()
   42                  Text("ENGLISH")
   43                      .font(.system(size: VR.FontSize.caption))
   44                      .tracking(VR.capsTracking)
   45                      .foregroundStyle(VR.partyBTextDim)
   46                  ForEach(session.partyB) { TranscriptLineView(line: $0, party: .b) }
   47              }
   48              .frame(maxWidth: .infinity, alignment: .leading)
   49              .padding(.horizontal, 24)
   50              .padding(.bottom, 28)
   51  
   52              topBar
   53                  .padding(.horizontal, 12)
   54                  .padding(.top, 54)
   55          }
   56          .frame(maxWidth: .infinity, maxHeight: .infinity)
   57      }
   58  
   59      private var topBar: some View {
   60          HStack {
   61              Button(action: onSettings) {
   62                  Image(systemName: "gearshape")
   63                      .font(.system(size: 20))
   64                      .foregroundStyle(VR.partyBTextDim)
   65                      .frame(width: 40, height: 40)
   66              }
   67              Spacer()
   68              LiveBadge().opacity(session.listening ? 1 : 0)
   69              Spacer()
   70              Button {} label: {
   71                  Image(systemName: "arrow.left.arrow.right")
   72                      .font(.system(size: 20))
   73                      .foregroundStyle(VR.partyBTextDim)
   74                      .frame(width: 40, height: 40)
   75              }
   76          }
   77      }
   78  
   79      // MARK: You (violet "water", 中文)
   80  
   81      private var partyA: some View {
   82          ZStack(alignment: .top) {
   83              VR.partyASurface
   84              WaterSurface(listening: session.listening)
   85                  .offset(y: -44)
   86                  .frame(maxHeight: .infinity, alignment: .top)
   87  
   88              VStack(alignment: .leading, spacing: 8) {
   89                  Text("中文 · 普通话")
   90                      .font(.system(size: VR.FontSize.caption))
   91                      .tracking(VR.capsTracking)
   92                      .foregroundStyle(VR.partyATextDim)
   93                  if session.showPrompt {
   94                      Text("请开始说话吧")
   95                          .font(.system(size: VR.FontSize.partial))
   96                          .foregroundStyle(VR.partyATextDim)
   97                  }
   98                  ForEach(session.partyA) { TranscriptLineView(line: $0, party: .a) }
   99  
  100                  Spacer()
  101                  VStack(spacing: 10) {
  102                      MicButton(listening: session.listening) { session.toggle() }
  103                      Text("为保证同传效果，请靠近麦克风说话")
  104                          .font(.system(size: VR.FontSize.caption))
  105                          .foregroundStyle(VR.partyATextDim)
  106                  }
  107                  .frame(maxWidth: .infinity)
  108                  .padding(.bottom, 30)
  109              }
  110              .padding(.horizontal, 24)
  111              .padding(.top, 28)
  112          }
  113          .frame(maxWidth: .infinity, maxHeight: .infinity)
  114          .clipped()
  115      }
  116  }

===== vrecorder/Views/Components/MicButton.swift =====
    1  //  MicButton.swift
    2  //  Purpose: 64pt circular mic control. Idle = violet; listening = aqua with
    3  //  glow + breathing pulse. design/README.md › LiveScreen. No spring overshoot.
    4  
    5  import SwiftUI
    6  
    7  struct MicButton: View {
    8      let listening: Bool
    9      let action: () -> Void
   10      @State private var pulse = false
   11  
   12      var body: some View {
   13          Button(action: action) {
   14              ZStack {
   15                  Circle()
   16                      .fill(listening ? VR.aqua500 : VR.violet500)
   17                  Image(systemName: "mic.fill")
   18                      .font(.system(size: 64 * 0.36, weight: .regular))
   19                      .foregroundStyle(.white)
   20              }
   21              .frame(width: 64, height: 64)
   22              .scaleEffect(listening && pulse ? 1.08 : 1.0)
   23              .shadow(color: listening ? VR.aqua500.opacity(0.30) : .black.opacity(0.25),
   24                      radius: listening ? 14 : 8, y: listening ? 0 : 4)
   25              .overlay(
   26                  Circle().stroke(VR.aqua500.opacity(listening ? 0.16 : 0), lineWidth: 6)
   27              )
   28          }
   29          .buttonStyle(.plain)
   30          .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
   31          .onChange(of: listening) { _, on in pulse = on }
   32      }
   33  }

===== vrecorder/Views/SettingsScreen.swift =====
    1  //  SettingsScreen.swift
    2  //  Purpose: Light-scope grouped settings list. Mirrors design/settings-screen.jsx.
    3  //  Stage-1 build keeps choices in local @State; Stage 2 backs them with
    4  //  UserDefaults + Keychain (API key). No real persistence yet.
    5  
    6  import SwiftUI
    7  
    8  struct SettingsScreen: View {
    9      let onBack: () -> Void
   10      private let store: any APIKeyStoring
   11  
   12      /// Reflects real Keychain state — refreshed when the key-entry sheet closes
   13      /// (single refresh path, audit-2 #3/#6). Never hardcode "已配置".
   14      @State private var keyConfigured: Bool
   15      @State private var showKeySheet = false
   16  
   17      // Only the OpenAI engine is wired today; don't offer a selection the app
   18      // can't honor (audit-4 #1). Re-add "Claude" when ClaudeTranslationEngine exists.
   19      @State private var engine = "OpenAI"
   20      @State private var stream = true
   21      @State private var autoSpeak = true
   22      @State private var speed = "1.0×"
   23      @State private var subSize = "标准"
   24      @State private var transcribeOnly = false
   25  
   26      /// Real marketing version from the bundle (audit-G4 Low: was hardcoded 1.0.0).
   27      static var appVersion: String {
   28          Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
   29      }
   30  
   31      init(onBack: @escaping () -> Void, store: any APIKeyStoring) {
   32          self.onBack = onBack
   33          self.store = store
   34          _keyConfigured = State(initialValue: store.key(for: APIProvider.openAI) != nil)
   35      }
   36  
   37      var body: some View {
   38          VStack(alignment: .leading, spacing: 0) {
   39              header
   40              ScrollView {
   41                  VStack(spacing: 24) {
   42                      group("翻译引擎") {
   43                          cycleRow("翻译服务", $engine, ["OpenAI"])
   44                          tapRow("API 密钥", value: keyConfigured ? "已配置" : "未配置") {
   45                              showKeySheet = true
   46                          }
   47                          toggleRow("流式翻译", $stream, last: true)
   48                      }
   49                      group("语音播报") {
   50                          toggleRow("自动播报译文", $autoSpeak)
   51                          cycleRow("语速", $speed, ["0.8×", "1.0×", "1.2×"], last: true)
   52                      }
   53                      group("同声传译") {
   54                          cycleRow("字幕字号", $subSize, ["标准", "大", "特大"])
   55                          toggleRow("仅转写模式", $transcribeOnly, last: true)
   56                      }
   57                      group("通用") {
   58                          navRow("历史记录", value: "保留 30 天")
   59                          destructiveRow("清空翻译记录")
   60                          navRow("关于", value: "版本 \(Self.appVersion)", last: true)
   61                      }
   62                  }
   63                  .padding(.horizontal, 20)
   64                  .padding(.vertical, 6)
   65                  .padding(.bottom, 40)
   66              }
   67          }
   68          .background(VR.surfaceApp)
   69          .ignoresSafeArea(edges: .bottom)
   70          .sheet(isPresented: $showKeySheet, onDismiss: {
   71              keyConfigured = store.key(for: APIProvider.openAI) != nil
   72          }) {
   73              APIKeyEntryView(store: store, onClose: { showKeySheet = false })
   74          }
   75      }
   76  
   77      private var header: some View {
   78          HStack(spacing: 6) {
   79              Button(action: onBack) {
   80                  Image(systemName: "chevron.left")
   81                      .font(.system(size: 22, weight: .semibold))
   82                      .foregroundStyle(VR.accentLight)
   83              }
   84              Text("设置")
   85                  .font(.system(size: VR.FontSize.title1, weight: .bold))
   86                  .foregroundStyle(VR.textPrimaryLight)
   87          }
   88          .padding(.horizontal, 16)
   89          .padding(.top, 54)
   90          .padding(.bottom, 10)
   91      }
   92  
   93      // MARK: Rows
   94  
   95      @ViewBuilder
   96      private func group<C: View>(_ caption: String, @ViewBuilder _ content: () -> C) -> some View {
   97          VStack(alignment: .leading, spacing: 8) {
   98              Text(caption)
   99                  .font(.system(size: VR.FontSize.caption))
  100                  .tracking(VR.capsTracking)
  101                  .foregroundStyle(VR.textFaint)
  102                  .padding(.horizontal, 16)
  103              VStack(spacing: 0) { content() }
  104                  .background(VR.surfaceCard)
  105                  .clipShape(RoundedRectangle(cornerRadius: 16))
  106                  .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
  107          }
  108      }
  109  
  110      private func rowChrome<T: View>(_ last: Bool, @ViewBuilder _ content: () -> T) -> some View {
  111          VStack(spacing: 0) {
  112              content().frame(minHeight: 50).padding(.horizontal, 16)
  113              if !last { Divider().background(VR.hairlineLight).padding(.leading, 16) }
  114          }
  115      }
  116  
  117      private func navRow(_ label: String, value: String, last: Bool = false) -> some View {
  118          rowChrome(last) {
  119              HStack {
  120                  Text(label).foregroundStyle(VR.textPrimaryLight)
  121                  Spacer()
  122                  Text(value).foregroundStyle(VR.textFaint)
  123                  Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
  124              }.font(.system(size: VR.FontSize.body))
  125          }
  126      }
  127  
  128      private func tapRow(_ label: String, value: String, last: Bool = false, _ action: @escaping () -> Void) -> some View {
  129          rowChrome(last) {
  130              Button(action: action) {
  131                  HStack {
  132                      Text(label).foregroundStyle(VR.textPrimaryLight)
  133                      Spacer()
  134                      Text(value).foregroundStyle(VR.textFaint)
  135                      Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
  136                  }.font(.system(size: VR.FontSize.body)).contentShape(Rectangle())
  137              }.buttonStyle(.plain)
  138          }
  139      }
  140  
  141      private func cycleRow(_ label: String, _ sel: Binding<String>, _ options: [String], last: Bool = false) -> some View {
  142          rowChrome(last) {
  143              Button {
  144                  let i = options.firstIndex(of: sel.wrappedValue) ?? 0
  145                  sel.wrappedValue = options[(i + 1) % options.count]
  146              } label: {
  147                  HStack {
  148                      Text(label).foregroundStyle(VR.textPrimaryLight)
  149                      Spacer()
  150                      Text(sel.wrappedValue).foregroundStyle(VR.textFaint)
  151                      Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
  152                  }.font(.system(size: VR.FontSize.body))
  153              }.buttonStyle(.plain)
  154          }
  155      }
  156  
  157      private func toggleRow(_ label: String, _ on: Binding<Bool>, last: Bool = false) -> some View {
  158          rowChrome(last) {
  159              Toggle(isOn: on) {
  160                  Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.textPrimaryLight)
  161              }.tint(VR.violet500)
  162          }
  163      }
  164  
  165      private func destructiveRow(_ label: String) -> some View {
  166          rowChrome(false) {
  167              Button {} label: {
  168                  Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.red500)
  169                      .frame(maxWidth: .infinity, alignment: .leading)
  170              }.buttonStyle(.plain)
  171          }
  172      }
  173  }

===== vrecorder/Views/APIKeyEntryView.swift =====
    1  //  APIKeyEntryView.swift
    2  //  Purpose: Light-scope sheet to enter / clear the OpenAI API key (feature #2).
    3  //  Built from VR design tokens per dev-docs/designs/api-key-entry/. Owns exactly
    4  //  one APIKeyEntryModel via @State (constructed from the injected store). The
    5  //  model is the single source of truth; the view never touches the store directly.
    6  
    7  import SwiftUI
    8  
    9  struct APIKeyEntryView: View {
   10      @State private var model: APIKeyEntryModel
   11      @State private var confirmClear = false
   12      let onClose: () -> Void
   13  
   14      init(store: any APIKeyStoring, onClose: @escaping () -> Void) {
   15          _model = State(initialValue: APIKeyEntryModel(store: store))
   16          self.onClose = onClose
   17      }
   18  
   19      var body: some View {
   20          VStack(alignment: .leading, spacing: 0) {
   21              header
   22              ScrollView {
   23                  VStack(alignment: .leading, spacing: 8) {
   24                      Text("OPENAI")
   25                          .font(.system(size: VR.FontSize.caption)).tracking(VR.capsTracking)
   26                          .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
   27                      keyCard
   28                      if let err = model.errorMessage {
   29                          Text(err).font(.system(size: VR.FontSize.caption))
   30                              .foregroundStyle(VR.red500).padding(.horizontal, 16)
   31                      } else if let masked = model.maskedExisting {
   32                          Text("当前：\(masked)").font(.system(size: VR.FontSize.caption))
   33                              .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
   34                      }
   35                      if model.hasExistingKey { clearCard }
   36                      notice
   37                  }
   38                  .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 40)
   39              }
   40          }
   41          .background(VR.surfaceApp)
   42          .alert("清除密钥？", isPresented: $confirmClear) {
   43              Button("取消", role: .cancel) {}
   44              Button("清除", role: .destructive) { _ = model.clear() }
   45          } message: { Text("清除后需重新输入才能继续同传。") }
   46      }
   47  
   48      private var header: some View {
   49          VStack(alignment: .leading, spacing: 0) {
   50              HStack {
   51                  Button("取消", action: onClose).foregroundStyle(VR.textFaint)
   52                  Spacer()
   53                  Button("保存") { if model.save() { onClose() } }
   54                      .font(.system(size: VR.FontSize.body, weight: .semibold))
   55                      .foregroundStyle(model.canSave ? VR.accentLight : VR.textFaint)
   56                      .disabled(!model.canSave)
   57              }
   58              .font(.system(size: VR.FontSize.body))
   59              .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
   60              Text("API 密钥")
   61                  .font(.system(size: VR.FontSize.title1, weight: .bold))
   62                  .foregroundStyle(VR.textPrimaryLight)
   63                  .padding(.horizontal, 20).padding(.bottom, 18)
   64          }
   65      }
   66  
   67      private var keyCard: some View {
   68          HStack(spacing: 12) {
   69              Text("密钥").foregroundStyle(VR.textFaint)
   70              SecureField("sk-…", text: $model.draft)
   71                  .textInputAutocapitalization(.never).autocorrectionDisabled()
   72                  .foregroundStyle(VR.textPrimaryLight)
   73          }
   74          .font(.system(size: VR.FontSize.body))
   75          .frame(minHeight: 50).padding(.horizontal, 16)
   76          .background(VR.surfaceCard)
   77          .clipShape(RoundedRectangle(cornerRadius: 16))
   78          .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
   79      }
   80  
   81      private var clearCard: some View {
   82          Button { confirmClear = true } label: {
   83              Text("清除密钥").foregroundStyle(VR.red500)
   84                  .font(.system(size: VR.FontSize.body))
   85                  .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
   86                  .padding(.horizontal, 16)
   87          }
   88          .buttonStyle(.plain)
   89          .background(VR.surfaceCard)
   90          .clipShape(RoundedRectangle(cornerRadius: 16))
   91          .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
   92          .padding(.top, 16)
   93      }
   94  
   95      private var notice: some View {
   96          Text("你的密钥保存在本机钥匙串（Keychain）。同传时会以 Bearer 凭证经 TLS 发送给你选择的服务商（OpenAI），不会发给其它第三方。设备被攻破时密钥仍可能泄露。")
   97              .font(.system(size: VR.FontSize.caption))
   98              .foregroundStyle(VR.textFaint)
   99              .padding(.horizontal, 16).padding(.top, 28)
  100      }
  101  }

===== vrecorder/Security/APIKeyEntryModel.swift =====
    1  //  APIKeyEntryModel.swift
    2  //  Purpose: Single-owner view-model for the API key-entry sheet (feature #2).
    3  //  Holds draft + derived UI state; validation and masking are static/pure so
    4  //  they're unit-tested without UI. Writes go through the injected APIKeyStoring
    5  //  (atomic — a failed write preserves the previous key). Format-agnostic
    6  //  validation: no provider key-shape assumption (audit-4 #2).
    7  
    8  import Foundation
    9  
   10  @MainActor
   11  @Observable
   12  final class APIKeyEntryModel {
   13      var draft: String = "" {
   14          didSet { if errorMessage != nil { errorMessage = nil } }   // clear error on edit
   15      }
   16      private(set) var hasExistingKey: Bool
   17      private(set) var maskedExisting: String?
   18      private(set) var errorMessage: String?
   19  
   20      private let store: any APIKeyStoring
   21      private let provider: String
   22  
   23      init(store: any APIKeyStoring, provider: String = APIProvider.openAI) {
   24          self.store = store
   25          self.provider = provider
   26          let existing = store.key(for: provider)
   27          hasExistingKey = existing != nil
   28          maskedExisting = Self.mask(existing)
   29      }
   30  
   31      var canSave: Bool { Self.isValid(draft) }
   32  
   33      /// Atomic save. Guards on validity so a direct call can't bypass the disabled
   34      /// button. On success: refresh state, clear draft. On failure: keep state,
   35      /// set the save-specific error. Returns success.
   36      @discardableResult
   37      func save() -> Bool {
   38          let key = draft.trimmingCharacters(in: .whitespacesAndNewlines)
   39          guard Self.isValid(key) else { return false }
   40          guard store.setKey(key, for: provider) else {
   41              errorMessage = "保存失败，请重试（已保留原密钥）"
   42              return false
   43          }
   44          hasExistingKey = true
   45          maskedExisting = Self.mask(key)
   46          draft = ""
   47          errorMessage = nil
   48          return true
   49      }
   50  
   51      /// Remove the key. On failure: retain configured state + set clear-specific
   52      /// error (a failed delete must not flip the UI to 未配置).
   53      @discardableResult
   54      func clear() -> Bool {
   55          guard store.setKey(nil, for: provider) else {
   56              errorMessage = "清除失败，请重试"
   57              return false
   58          }
   59          hasExistingKey = false
   60          maskedExisting = nil
   61          errorMessage = nil
   62          return true
   63      }
   64  
   65      // MARK: - Pure validation / masking (unit-tested)
   66  
   67      /// Format-agnostic: trimmed, non-empty, printable ASCII only (no control /
   68      /// internal whitespace / emoji / CJK), length 8…500. No `sk-` / length
   69      /// provider assumption (OpenAI does not guarantee key shape).
   70      static func isValid(_ raw: String) -> Bool {
   71          let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
   72          guard (8...500).contains(key.count) else { return false }
   73          return key.unicodeScalars.allSatisfy { $0.value >= 0x21 && $0.value <= 0x7E }
   74      }
   75  
   76      /// Reveal `…` + last 4 only when length ≥ 12; else "已配置" (never the whole
   77      /// secret); nil when absent.
   78      static func mask(_ key: String?) -> String? {
   79          guard let key, !key.isEmpty else { return nil }
   80          guard key.count >= 12 else { return "已配置" }
   81          return "…" + String(key.suffix(4))
   82      }
   83  }

===== scripts/run-tests.sh =====
    1  #!/usr/bin/env bash
    2  # scripts/run-tests.sh — bounded, watchdogged unit-test gate.
    3  #
    4  # Why (.claude/rules/52-test-sim-isolation.md): `xcodebuild test` can wedge at
    5  # 0% CPU and ghost for hours (sim contention, or a wedged SWBBuildService build
    6  # daemon after a kill -9). This wrapper turns an indefinite hang into a bounded,
    7  # self-terminating run:
    8  #   1. pins the destination by UDID (prefers iPhone 17 Pro, else booted, else any)
    9  #   2. enforces a hard wall-clock timeout (default 900s) on the EXACT pid (rule 49)
   10  #   3. on timeout kills the process tree AND clears the wedged build daemon
   11  #      `SWBBuildService` (rule 52 Cause B) — a bare kill is a half-cleanup that
   12  #      poisons the next run
   13  #   4. prints ONE unambiguous final line:
   14  #      RUN-TESTS RESULT: SUCCEEDED|FAILED|TIMEOUT|NO_BOOTED_SIM
   15  #
   16  # Usage:
   17  #   scripts/run-tests.sh                          # default suite (vrecorderTests)
   18  #   scripts/run-tests.sh vrecorderTests/FooTests  # one targeted suite (fast per-WI gate)
   19  #   TIMEOUT_SECS=2400 scripts/run-tests.sh vrecorderTests   # full-suite periodic sweep
   20  #   TEST_UDID=<udid> scripts/run-tests.sh         # specific simulator (true parallelism)
   21  #
   22  # NEVER pipe this through tail/grep/head (rule 52 #5): `tail -N` on a pipe buffers
   23  # away the streaming markers AND the single RESULT line. Let stdout go straight to
   24  # a file or the task-output; read the file after the RESULT line lands.
   25  set -uo pipefail
   26  
   27  PROJECT="vrecorder.xcodeproj"
   28  SCHEME="vrecorder"
   29  SUITE="${1:-vrecorderTests}"
   30  TIMEOUT="${TIMEOUT_SECS:-900}"
   31  export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
   32  
   33  cd "$(dirname "$0")/.." || { echo "RUN-TESTS RESULT: FAILED (cannot cd to project root)"; exit 1; }
   34  
   35  # Resolve a simulator UDID. Pin by UDID to avoid name/OS-matching surprises.
   36  # Order: explicit TEST_UDID > iPhone 17 Pro (project convention) > booted sim > any iPhone.
   37  udid="${TEST_UDID:-}"
   38  [ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone 17 Pro (' | grep -oE '[0-9A-F-]{36}' | head -1)"
   39  [ -z "$udid" ] && udid="$(xcrun simctl list devices booted    2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1)"
   40  [ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone' | grep -oE '[0-9A-F-]{36}' | head -1)"
   41  if [ -z "$udid" ]; then
   42    echo "RUN-TESTS RESULT: NO_BOOTED_SIM (no usable iOS Simulator found — install a runtime)"
   43    exit 1
   44  fi
   45  
   46  # Clear a stale app instance that wedges the test-host launch with a "Busy
   47  # (Application failed preflight checks)" error (recurring sim-state flake). No-op
   48  # if the sim is shut down or the app isn't installed.
   49  xcrun simctl terminate "$udid" com.vrecorder.app >/dev/null 2>&1 || true
   50  
   51  echo "RUN-TESTS START: suite=$SUITE udid=$udid timeout=${TIMEOUT}s"
   52  
   53  STATUS="$(mktemp)"; TIMED_OUT="$(mktemp -u)"
   54  run() {
   55    xcodebuild test \
   56      -project "$PROJECT" -scheme "$SCHEME" \
   57      -destination "id=$udid" \
   58      -only-testing:"$SUITE" 2>&1
   59    echo "$?" >"$STATUS"
   60  }
   61  run & RUN_PID=$!
   62  
   63  # Watchdog on the EXACT pid; cancelled the instant the test finishes (never re-arms — rule 49).
   64  ( sleep "$TIMEOUT"
   65    if kill -0 "$RUN_PID" 2>/dev/null; then
   66      : >"$TIMED_OUT"
   67      pkill -TERM -P "$RUN_PID" 2>/dev/null; kill -TERM "$RUN_PID" 2>/dev/null
   68      sleep 3
   69      pkill -KILL -P "$RUN_PID" 2>/dev/null; kill -KILL "$RUN_PID" 2>/dev/null
   70      pkill -9 -x SWBBuildService 2>/dev/null   # rule 52 Cause B: clear the wedged daemon
   71    fi ) & WD=$!
   72  
   73  wait "$RUN_PID" 2>/dev/null
   74  kill "$WD" 2>/dev/null; wait "$WD" 2>/dev/null
   75  
   76  RC="$(cat "$STATUS" 2>/dev/null || echo 1)"; rm -f "$STATUS"
   77  echo
   78  if [ -e "$TIMED_OUT" ]; then
   79    rm -f "$TIMED_OUT"
   80    echo "RUN-TESTS RESULT: TIMEOUT (${TIMEOUT}s) — killed process tree + SWBBuildService"
   81    exit 124
   82  elif [ "$RC" = "0" ]; then
   83    echo "RUN-TESTS RESULT: SUCCEEDED"
   84    exit 0
   85  else
   86    echo "RUN-TESTS RESULT: FAILED (xcodebuild rc=$RC)"
   87    exit 1
   88  fi

===== docs/features.md =====
    1  # Feature Tracker
    2  
    3  Track features to be implemented here. Must be planned before implementation.
    4  
    5  ## Rules
    6  
    7  > **Binding for this file.** The rules, statuses, and plan template below govern every change made to `docs/features.md`. AGENTS.md treats them as the authoritative feature-tracker workflow.
    8  
    9  - **Bugs vs features**: If something was implemented but doesn't work correctly, it is a **bug** — track it in `docs/bugs.md`. If something was never implemented, it is a **feature** — track it here. Never mix them.
   10  - **Partial implementations**: If something is partially implemented, the broken part is a bug in `docs/bugs.md`; the missing capability is a feature here. Link them.
   11  - **Cross-links**: When a bug fix resolves a feature, update the feature status to `DONE` with note `Resolved by bug #N`. When a feature depends on a bug fix, use `TODO` status with note `Blocked by bug #N`.
   12  - **Plan before implementation**: Every feature must be planned before any code is written. Status must reach `PLANNED` before moving to `IN PROGRESS`. A plan requires the fields listed in the "Plan Template" section below.
   13  - **Exception — resolved by bug fix**: If a bug fix incidentally delivers a feature, the feature may be set to `DONE` with `Resolved by bug #N` without a full plan.
   14  
   15  ## How to use
   16  
   17  1. Add features as you identify them (fill in Summary and Area at minimum)
   18  2. Plan the feature (fill in required plan fields) → set status to `PLANNED`
   19  3. Tell the agent: "implement feature #N" to start implementation
   20  4. Agent updates Status when done
   21  
   22  - **GitHub Issue closure** (post-merge finalizer — see `AGENTS.md` for full policy):
   23    - If the feature has a `GH: #N` in Notes, close the GitHub Issue only after:
   24      1. All acceptance criteria met and status is VERIFIED in this file.
   25      2. Implementation is merged to `main`.
   26      3. Closure comment posted with commit SHA and acceptance result.
   27    - Partial delivery: keep GitHub Issue open; use checklist or split follow-ups.
   28    - PRs use `Refs #N`, not `Fixes #N` (prevents premature auto-close).
   29  
   30  ## Statuses
   31  
   32  - `TODO` — not started
   33  - `PLANNED` — plan complete (problem, scope, edge cases, tests, acceptance criteria), ready to implement
   34  - `IN PROGRESS` — being worked on
   35  - `DONE` — implemented; correctness not yet verified end-to-end
   36  - `VERIFIED` — covered by an automated end-to-end test or an explicit on-device manual verification log
   37  - `DEFERRED` — postponed to a later milestone
   38  - `WONT DO` — out of scope or rejected
   39  
   40  ## Plan Template
   41  
   42  Before setting a feature to `PLANNED`, fill in these fields in a sub-section under the feature table (e.g., `### Feature #1 — Plan`):
   43  
   44  - **Problem**: What user need does this address?
   45  - **Scope**: What is included and excluded?
   46  - **Edge cases**: Empty input, nil, boundary values, concurrent access, audio-session interruptions, network failures, language-pair specifics.
   47  - **Test plan**: What tests will verify the feature?
   48  - **Acceptance criteria**: How do we know it's done?
   49  
   50  ## Features
   51  
   52  | #   | Summary | Area | Priority | Status | Notes |
   53  | --- | ------- | ---- | -------- | ------ | ----- |
   54  | 1   | MVP 同传管线骨架（同传屏/设置屏 + 本地STT + OpenAI翻译 + Keychain key） | pipeline/ui | High | DONE | Scaffold, retro-registered outside gates 1-2 (course demo). Mirror: no. Pipeline-translate leg verified against live OpenAI; on-device STT needs device verify (Gate 5 deferred). Pre-push Codex audit (prepush-25e2320) found 6H+2M; fixes #3-8 + #1 applied (see Notes). |
   55  | 2   | Release 内 API 密钥录入页（Keychain 编辑器） | ui/settings | Medium | DONE | Shipped in v0.2.0 (PR #2, merge `1d3644d`). 4 plan-audit + 2 impl-audit rounds. Design bundle `dev-docs/designs/api-key-entry/` (owner-authorized). 31 tests. NOT yet VERIFIED — interactive tap flow needs a manual device pass (evidence `feature-2-20260614.md`, result: partial). Mirror: no. |
   56  | 3   | 打断后自动暂停/恢复（来电/Siri/AirPods 后续传） | audio/pipeline | Low | TODO | From audit-3 #5 (Medium, non-blocking): 当前打断即 stop()，需重新点麦克风。理想是 paused 态保留观察、interruption-ended `shouldResume` 时自动恢复。演示影响小。Mirror: no. |
   57  | 4   | 专用 VAD/分段阶段（无间隙轮转，连续传译鲁棒分句） | audio/pipeline | Medium | TODO | From bug-#1 audits: PCMRollover mitigates the common rotation gap but a long gap during sustained speech can still truncate. Robust fix = a dedicated VAD/segmentation stage that rotates recognition with no gap; ALSO owns the demand-aware bounded streaming pump (bug #2 residual: output stream + finals array not yet backpressured). Needs Gate-1 plan. Mirror: no. |
   58  | 5   | 仅转写模式（不翻译，只上屏转写） | settings/pipeline | Low | TODO | Settings toggle exists (designed) but is a no-op; wire into LiveSessionModel to bypass translation. Disable the toggle until implemented. GH: #10. Mirror: no. |
   59  | 6   | 验证 harness（XCUITest + DebugBridge + sim-gesture 驱动） | tooling/test | High | TODO | cron verify.md 假设的 harness（XCUITest target / vrecorder-debug:// DebugBridge / scripts/sim-tap.sh / sim-gesture-driver 文档）都不存在，导致 verify cron 全 blocked。建之以解锁 UI/可脚本化验证；音频真机验证仍需人工。GH issue filed. Mirror: no. |
   60  
   61  ### Feature #1 — Notes (retro)
   62  
   63  Built as the initial environment/scaffold, not through the formal 6-gate flow
   64  (no Gate-1 plan / Gate-2 plan audit — code preceded planning here, recorded
   65  honestly). What exists:
   66  
   67  - **Design-faithful UI**: LiveScreen (ink/violet split, water surface, mic
   68    button), SettingsScreen (light grouped list). From `design/`.
   69  - **Engine abstraction**: `SpeechRecognizing` / `TranslationEngine` protocols;
   70    `AppleSpeechRecognizer` (on-device) + `OpenAITranslationEngine` (cloud).
   71  - **Pipeline**: mic → 中文 partial/final → per-final OpenAI translate → English
   72    panel; demo simulator fallback (no network).
   73  - **Secrets**: Keychain store, DEBUG-seeded from `config/openai-key.txt`.
   74  
   75  Verification done: 11 unit tests green; live OpenAI translation confirmed
   76  (`重庆火锅…` → English). **Outstanding (future gate 5)**: on-device mic STT
   77  end-to-end on a real device; settings persistence + TTS (Stage 3) tracked as
   78  new features that WILL go through gates 1-6.
   79  
   80  **Audit fixes (pre-push Codex `prepush-25e2320`, 6 High + 2 Medium):**
   81  - #1 continuous interpretation — recognizer now rotates recognition segments on
   82    each final instead of stopping; one session handles many utterances.
   83  - #3 session-generation token invalidates stale async paths on stop/restart.
   84  - #4 translation tasks owned, cancelled on stop, committed in source order.
   85  - #5 `AudioSessionController` exposes interruption/route events; session stops on
   86    interruption-began / route loss (resume requires an explicit re-tap).
   87  - #6 teardown always deactivates `AVAudioSession` (no leftover ducking).
   88  - #7 recognition errors finish the stream with a mapped `PipelineError`.
   89  - #8 mic vs speech-recognition denial are distinct errors + messages.
   90  - #2 → split out as **feature #2** (Release key-entry UI, BLOCKED: needs-design).
   91    The Settings row now reflects real Keychain state instead of hardcoding "已配置".
   92  
   93  **Audit rounds 2–4** (artifacts `prepush-1f8798f / 6211616 / f62e8fa`): a further
   94  ~15 findings fixed — sequential bounded translation queue, error finishes the
   95  stream exactly once, protocol-typed engines (deterministic pipeline tests),
   96  partial-id in-place transition, AudioTapBridge thread-safe VAD with
   97  duration-based silence + atomic request handoff, on-device recognition enforced,
   98  Release key resource excluded from the bundle, scenePhase background stop,
   99  distinct recognition error. **Residual:** Release key-entry UI (feature #2,
  100  design-blocked, rule 51) keeps the gate from PASS, so the scaffold ships via
  101  documented `--no-verify` bypass — see **ADR-001**. Mediums (route
  102  `.newDeviceAvailable`, bounded partial ingress) + feature #3 tracked, non-blocking.

===== .claude/rules/10-tdd.md =====
    1  # 10 - TDD Workflow
    2  
    3  
    4  > NOTE: Code examples below are inherited from the vreader reference project — apply the same TDD patterns to vrecorder domain types (SessionRecord, pipeline actors, engines).
    5  Test-Driven Development for vrecorder. Tests live in `vrecorderTests/`. Run via `xcodebuild test`. Coverage thresholds are not currently gated structurally; discipline is the gate.
    6  
    7  **vrecorder uses Swift Testing as the primary framework** (`import Testing`, `@Test`, `#expect`). XCTest is used only for tests that need `XCTestExpectation` (notification / async-callback timing) or `XCUnwrap`-style helpers — minority of tests, ~5% of the suite. New tests should default to Swift Testing unless they specifically need XCTest's expectation/notification machinery.
    8  
    9  ## Core Discipline: RED → GREEN → REFACTOR
   10  
   11  1. **RED** — Write a failing test that describes the expected behavior.
   12  2. **GREEN** — Write the minimum code to make the test pass.
   13  3. **REFACTOR** — Clean up without changing behavior. Tests must still pass.
   14  
   15  Never skip RED. If you write code first, you don't know your test actually catches regressions.
   16  
   17  ## When Tests Are Required
   18  
   19  | Category          | Required?      | Examples                                                                  |
   20  | ----------------- | -------------- | ------------------------------------------------------------------------- |
   21  | Services / actors | **ALWAYS**     | `PersistenceActor`, `BookImporter`, `TXTService`, encoding detectors      |
   22  | Pure utilities    | **ALWAYS**     | `DocumentFingerprint`, `Locator`, parsers, formatters                     |
   23  | ViewModels        | **ALWAYS**     | State transitions, async flows, error paths                               |
   24  | Bug fixes         | **ALWAYS**     | Regression test that fails on the pre-fix commit                          |
   25  | Edge cases        | **ALWAYS**     | Empty input, nil, boundary values, Unicode/CJK, RTL, race conditions      |
   26  | SwiftUI views     | Case-by-case   | Test behavior (callbacks, observable state), not pixel rendering          |
   27  | Reader bridges    | Case-by-case   | Test message parsing, JS escaping, locator math — not WebView interaction |
   28  | Pure data models  | If non-trivial | `BookRecord`, `HighlightRecord` — test invariants, not getters            |
   29  
   30  ## Pattern Catalog
   31  
   32  The patterns below show XCTest first because vrecorder's actor/ViewModel/notification tests rely on `XCTestCase`-specific helpers (`XCTestExpectation`, `XCUnwrap`, async `setUp`, isolation pinning). For straightforward tests, prefer Swift Testing.
   33  
   34  ### 0. Swift Testing (default for new tests)
   35  
   36  ```swift
   37  import Testing
   38  @testable import vrecorder
   39  
   40  @Suite("DocumentFingerprint")
   41  struct DocumentFingerprintSuite {
   42      @Test func canonicalKeyRoundTrips() {
   43          let fp = DocumentFingerprint(contentSHA256: "abc...", fileByteCount: 1024, format: .epub)
   44          let parsed = DocumentFingerprint(canonicalKey: fp.canonicalKey)
   45          #expect(parsed == fp)
   46      }
   47  
   48      @Test(arguments: [
   49          ("hello world", 11),
   50          ("",            0),
   51          ("héllo",       6),  // 5 chars but 6 UTF-8 bytes
   52      ])
   53      func byteCountMatchesUTF8(_ input: String, _ expected: Int) {
   54          #expect(input.utf8.count == expected)
   55      }
   56  }
   57  ```
   58  
   59  **Use Swift Testing for:** pure functions, value types, parameterized tests, anything that doesn't need XCTest's async-callback machinery.
   60  
   61  **Use XCTest (patterns 1-5 below) for:** actor tests with async setUp, MainActor-isolated ViewModels, notification observers needing `XCTestExpectation`, anywhere you need `XCUnwrap` over `#require`.
   62  
   63  ### 1. Actor / Service Tests
   64  
   65  ```swift
   66  import XCTest
   67  @testable import vrecorder
   68  
   69  final class PersistenceActorTests: XCTestCase {
   70      private var container: ModelContainer!
   71      private var actor: PersistenceActor!
   72  
   73      override func setUp() async throws {
   74          let schema = Schema(SchemaV4.models)
   75          let config = ModelConfiguration(isStoredInMemoryOnly: true)
   76          container = try ModelContainer(for: schema, configurations: [config])
   77          actor = PersistenceActor(modelContainer: container)
   78      }
   79  
   80      func test_insertBook_dedupesByFingerprintKey() async throws {
   81          let record = makeBookRecord(sha: String(repeating: "a", count: 64))
   82          let first = try await actor.insertBook(record)
   83          let second = try await actor.insertBook(record)
   84          XCTAssertEqual(first.fingerprintKey, second.fingerprintKey)
   85      }
   86  }
   87  ```
   88  
   89  **Key patterns:**
   90  
   91  - In-memory `ModelContainer` for SwiftData isolation.
   92  - `setUp() async throws` to construct dependencies.
   93  - Test public actor methods directly — actors serialize, no manual locking.
   94  
   95  ### 2. ViewModel Tests
   96  
   97  ```swift
   98  @MainActor
   99  final class LibraryViewModelTests: XCTestCase {
  100      func test_deleteBook_removesFromBooksArray() async {
  101          let persistence = MockPersistence()
  102          let viewModel = LibraryViewModel(persistence: persistence, importer: ..., preferenceStore: ...)
  103          await viewModel.loadBooks()
  104          await viewModel.deleteBook(fingerprintKey: "key-1")
  105          XCTAssertFalse(viewModel.books.contains { $0.fingerprintKey == "key-1" })
  106      }
  107  }
  108  ```
  109  
  110  **Key patterns:**
  111  
  112  - `@MainActor` on the test class for ViewModels marked `@MainActor`.
  113  - Inject mocks via protocol parameters (`LibraryPersisting`, `BookImporting`).
  114  - Assert on observable state, not internal helpers.
  115  
  116  ### 3. Pure-Function Tests
  117  
  118  ```swift
  119  final class DocumentFingerprintTests: XCTestCase {
  120      func test_canonicalKey_roundTrips() {
  121          let fp = DocumentFingerprint(contentSHA256: "abc...", fileByteCount: 1024, format: .epub)
  122          let parsed = DocumentFingerprint(canonicalKey: fp.canonicalKey)
  123          XCTAssertEqual(parsed, fp)
  124      }
  125  }
  126  ```
  127  
  128  **Key patterns:**
  129  
  130  - Pure functions = no setUp, no mocks.
  131  - Use `XCTAssertEqual(_:_:_)` for `Equatable` types.
  132  - Cover all branches in one test class via `func test_` methods.
  133  
  134  ### 4. Async / Concurrency Tests
  135  
  136  ```swift
  137  @MainActor
  138  func test_bridge_concurrentCalls_doNotInterleave() async {
  139      let bridge = MyBridge(...)
  140      async let a = bridge.handle(...)
  141      async let b = bridge.handle(...)
  142      _ = await (a, b)
  143      // assert ordering invariants on the recorded calls
  144  }
  145  ```
  146  
  147  **Key patterns:**
  148  
  149  - `async let` for concurrent calls; `await (a, b, ...)` to join.
  150  - For deterministic timing, use a clock probe pattern (see `DebugBridgeTests.SlowDebugBridgeContext`).
  151  - Avoid `Task.sleep` for synchronization; use `XCTestExpectation` + `fulfillment(of:timeout:)`.
  152  
  153  ### 5. Notification / Bridge Tests
  154  
  155  ```swift
  156  func test_handler_postsExpectedNotification() async {
  157      let exp = expectation(description: "notification posted")
  158      nonisolated(unsafe) var receivedKey: String?
  159      let token = NotificationCenter.default.addObserver(
  160          forName: .myNotification, object: nil, queue: .main
  161      ) { notification in
  162          receivedKey = notification.userInfo?["key"] as? String
  163          exp.fulfill()
  164      }
  165      defer { NotificationCenter.default.removeObserver(token) }
  166  
  167      handler.fire(key: "test-key")
  168      await fulfillment(of: [exp], timeout: 2.0)
  169      XCTAssertEqual(receivedKey, "test-key")
  170  }
  171  ```
  172  
  173  **Key patterns:**
  174  
  175  - `XCTestExpectation` + `fulfillment(of:timeout:)` — never bare `sleep`.
  176  - Always `removeObserver` in `defer`.
  177  - `nonisolated(unsafe)` to capture into a notification closure that runs on a different queue.
  178  
  179  ## Anti-Patterns — What NOT to Do
  180  
  181  | Anti-pattern                       | Why it's wrong                                 | Do this instead                                              |
  182  | ---------------------------------- | ---------------------------------------------- | ------------------------------------------------------------ |
  183  | Write code first, tests after      | You can't verify your test catches regressions | RED first — always                                           |
  184  | `func test_loadsWithoutCrashing()` | Tests nothing meaningful                       | Test specific observable behavior                            |
  185  | Testing `private` implementation   | Breaks on refactor                             | Test public API only                                         |
  186  | Mocking everything                 | Tests prove nothing                            | Mock boundaries (network, filesystem), not internal logic    |
  187  | Skipping edge cases                | Bugs live at boundaries                        | Empty input, nil, max values, concurrent access, Unicode/CJK |
  188  | Bare `Task.sleep(...)` for sync    | Flaky in CI                                    | `XCTestExpectation` with timeout                             |
  189  | `XCTAssertNotNil(x); x!.foo()`     | Crashes on failure                             | `let x = try XCTUnwrap(opt); x.foo()`                        |
  190  | Tests that depend on order         | Flaky                                          | Reset state in `setUp`; never share state across tests       |
  191  
  192  ## Test Commands
  193  
  194  ```bash
  195  # Build then run unit tests only (skip UI tests during dev)
  196  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  197      -project vrecorder.xcodeproj -scheme vrecorder \
  198      -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  199      -only-testing:vrecorderTests
  200  
  201  # Single test class (faster iteration)
  202  ... -only-testing:vrecorderTests/MyClassTests
  203  
  204  # Single test method
  205  ... -only-testing:vrecorderTests/MyClassTests/test_specificThing
  206  ```
  207  
  208  The TDD Guardian config at `.claude/tdd-guardian/config.json` invokes the same `xcodebuild test` flow.
  209  
  210  ## File Placement
  211  
  212  - Tests go next to the production code, mirroring the source tree:
  213    `vrecorder/Services/Foo/Bar.swift` → `vrecorderTests/Services/Foo/BarTests.swift`
  214  - Larger test suites use a `__tests__` or feature subdirectory.
  215  - Shared test helpers go in `vrecorderTests/Helpers/` (e.g., `CollectionTestHelper`).
  216  
  217  ## Exceptions to Mandatory TDD
  218  
  219  These categories don't require tests:
  220  
  221  - CSS/asset-only changes (don't apply to vrecorder, but listed for completeness)
  222  - Documentation, config, comments
  223  - Type-only changes with no runtime effect
  224  - Pure file moves / renames
  225  
  226  If unsure, write the test.

===== .claude/rules/40-version-bump.md =====
    1  # 40 - Version Bump Procedure
    2  
    3  vrecorder's version lives in `project.yml` (xcodegen) under `targets: vrecorder: settings: base:`. xcodegen regenerates `vrecorder.xcodeproj/project.pbxproj` from it; pbxproj is checked in but should not be hand-edited for a bump.
    4  
    5  ## When to bump
    6  
    7  **Every PR must include a version bump.** The version line is owned by the PR
    8  that ships the change, not by a separate release commit, so:
    9  
   10  - **Bump before opening the PR** — bumping after the PR is open and rebasing
   11    conflicts with reviews.
   12  - **Bump as the last step on the branch** — after the feature commits are in,
   13    not interleaved with them. A clean tail commit `chore: bump version to X.Y.Z`
   14    is easier to revert than a bump folded into a feature commit.
   15  - **Choose increment by impact:**
   16    - `patch` — bug fix, docs, chores, refactors with no externally-visible change.
   17    - `minor` — new user-visible feature or capability.
   18    - `major` — breaking change to data, schema, or public contract.
   19  - `CURRENT_PROJECT_VERSION` always increments by ≥1 — App Store Connect rejects
   20    uploads with a non-monotonic build number.
   21  
   22  The post-merge tag (`git tag v{version}` on the merge commit) is cut by the
   23  finalizer once the PR lands on `main`.
   24  
   25  ## Files to Update
   26  
   27  | File          | Field                                                       |
   28  | ------------- | ----------------------------------------------------------- |
   29  | `project.yml` | `MARKETING_VERSION` (visible version, e.g. `0.1.0`)         |
   30  | `project.yml` | `CURRENT_PROJECT_VERSION` (build number, monotonic integer) |
   31  
   32  After editing `project.yml`, regenerate the Xcode project and commit BOTH:
   33  
   34  ```bash
   35  # 1. Edit project.yml — change MARKETING_VERSION (and bump CURRENT_PROJECT_VERSION)
   36  # 2. Regenerate
   37  xcodegen generate
   38  
   39  # 3. Confirm the regen actually changed pbxproj
   40  git diff vrecorder.xcodeproj/project.pbxproj | grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION"
   41  ```
   42  
   43  ## Bump Procedure
   44  
   45  1. \*\*Edit \*\***`project.yml`** — change `MARKETING_VERSION` to the new version. Bump `CURRENT_PROJECT_VERSION` too (always increasing — App Store requires a higher build number than any previously-uploaded build).
   46  
   47  2. **Regenerate the Xcode project**:
   48  
   49     ```bash
   50     xcodegen generate
   51     ```
   52  
   53  3. **Verify both files updated**:
   54  
   55     ```bash
   56     grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" project.yml
   57     grep -E "MARKETING_VERSION =|CURRENT_PROJECT_VERSION =" vrecorder.xcodeproj/project.pbxproj
   58     ```
   59  
   60  4. **Build to confirm**:
   61  
   62     ```bash
   63     DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
   64         -project vrecorder.xcodeproj -scheme vrecorder \
   65         -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   66     ```
   67  
   68  5. **Commit** (single commit, both files together):
   69  
   70     ```bash
   71     git add project.yml vrecorder.xcodeproj/project.pbxproj
   72     git commit -m "chore: bump version to {version}"
   73     ```
   74  
   75  6. **Tag and push** (only after commit lands on main):
   76  
   77     ```bash
   78     git tag v{version}
   79     git push origin main --tags
   80     ```
   81  
   82  ## Common Mistakes
   83  
   84  - Editing `pbxproj` directly without updating `project.yml` — next `xcodegen` overwrites your change.
   85  - Forgetting `CURRENT_PROJECT_VERSION` — App Store Connect rejects uploads with the same build number as a previous build.
   86  - Tagging before the commit lands on `main` — orphan tag.
   87  
   88  ## Verification
   89  
   90  After a bump, the App's About / TestFlight build number both should reflect the new `MARKETING_VERSION`. The build number from `CURRENT_PROJECT_VERSION` is shown in TestFlight's release lists.

exec
/bin/zsh -lc 'nl -ba vrecorder/Security/APIKeyEntryModel.swift && nl -ba scripts/run-tests.sh && nl -ba dev-docs/plans/20260615-feature-6-verification-harness.md && xcodegen --version && xcodegen dump --spec project.yml' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	//  APIKeyEntryModel.swift
     2	//  Purpose: Single-owner view-model for the API key-entry sheet (feature #2).
     3	//  Holds draft + derived UI state; validation and masking are static/pure so
     4	//  they're unit-tested without UI. Writes go through the injected APIKeyStoring
     5	//  (atomic — a failed write preserves the previous key). Format-agnostic
     6	//  validation: no provider key-shape assumption (audit-4 #2).
     7	
     8	import Foundation
     9	
    10	@MainActor
    11	@Observable
    12	final class APIKeyEntryModel {
    13	    var draft: String = "" {
    14	        didSet { if errorMessage != nil { errorMessage = nil } }   // clear error on edit
    15	    }
    16	    private(set) var hasExistingKey: Bool
    17	    private(set) var maskedExisting: String?
    18	    private(set) var errorMessage: String?
    19	
    20	    private let store: any APIKeyStoring
    21	    private let provider: String
    22	
    23	    init(store: any APIKeyStoring, provider: String = APIProvider.openAI) {
    24	        self.store = store
    25	        self.provider = provider
    26	        let existing = store.key(for: provider)
    27	        hasExistingKey = existing != nil
    28	        maskedExisting = Self.mask(existing)
    29	    }
    30	
    31	    var canSave: Bool { Self.isValid(draft) }
    32	
    33	    /// Atomic save. Guards on validity so a direct call can't bypass the disabled
    34	    /// button. On success: refresh state, clear draft. On failure: keep state,
    35	    /// set the save-specific error. Returns success.
    36	    @discardableResult
    37	    func save() -> Bool {
    38	        let key = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    39	        guard Self.isValid(key) else { return false }
    40	        guard store.setKey(key, for: provider) else {
    41	            errorMessage = "保存失败，请重试（已保留原密钥）"
    42	            return false
    43	        }
    44	        hasExistingKey = true
    45	        maskedExisting = Self.mask(key)
    46	        draft = ""
    47	        errorMessage = nil
    48	        return true
    49	    }
    50	
    51	    /// Remove the key. On failure: retain configured state + set clear-specific
    52	    /// error (a failed delete must not flip the UI to 未配置).
    53	    @discardableResult
    54	    func clear() -> Bool {
    55	        guard store.setKey(nil, for: provider) else {
    56	            errorMessage = "清除失败，请重试"
    57	            return false
    58	        }
    59	        hasExistingKey = false
    60	        maskedExisting = nil
    61	        errorMessage = nil
    62	        return true
    63	    }
    64	
    65	    // MARK: - Pure validation / masking (unit-tested)
    66	
    67	    /// Format-agnostic: trimmed, non-empty, printable ASCII only (no control /
    68	    /// internal whitespace / emoji / CJK), length 8…500. No `sk-` / length
    69	    /// provider assumption (OpenAI does not guarantee key shape).
    70	    static func isValid(_ raw: String) -> Bool {
    71	        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    72	        guard (8...500).contains(key.count) else { return false }
    73	        return key.unicodeScalars.allSatisfy { $0.value >= 0x21 && $0.value <= 0x7E }
    74	    }
    75	
    76	    /// Reveal `…` + last 4 only when length ≥ 12; else "已配置" (never the whole
    77	    /// secret); nil when absent.
    78	    static func mask(_ key: String?) -> String? {
    79	        guard let key, !key.isEmpty else { return nil }
    80	        guard key.count >= 12 else { return "已配置" }
    81	        return "…" + String(key.suffix(4))
    82	    }
    83	}
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
     1	# Feature #6 — Verification harness (XCUITest + DebugBridge)
     2	
     3	> Gate-1 plan, revision 1. Status: PLANNED after Gate-2 audit passes.
     4	> **Estimated PR size**, per WI (separate PR each): WI-1 ~4 files / ~120 LOC;
     5	> WI-2 ~3 files / ~140 LOC; WI-3 ~1 file / ~90 LOC. Medium feature, 3 WIs.
     6	
     7	## Revision history
     8	- **r1** — initial plan.
     9	
    10	## Problem
    11	The `cron-prompts/verify.md` workflow assumes a CU-free verification harness
    12	(XCUITest + a `vrecorder-debug://` DebugBridge + a gesture fallback) that does NOT
    13	exist in the repo. So the verify cron is permanently `blocked`, and shipped work
    14	(feature #2 DONE-not-VERIFIED; bugs awaiting device verification) can't be
    15	machine-verified at all. This builds the scriptable core of that harness so the
    16	verify cron can flip at least the UI/state-driven targets.
    17	
    18	## Scope
    19	**In:** an XCUITest target; accessibility identifiers on the key UI; a DEBUG-only
    20	`vrecorder-debug://` DebugBridge that drives `LiveSessionModel` deterministically
    21	(inject a scripted transcript) so UI states are reachable without a mic; an
    22	XCUITest that verifies feature #2's API-key sheet flow end-to-end.
    23	**Out:** real-mic / AirPods / interruption verification (inherently human-on-device
    24	— bugs #1/#3/#5/#9 stay `awaiting-device-verification`); idb/`sim-tap.sh` gesture
    25	fallback (optional follow-up — XCUITest's own tap/typeText covers this feature's
    26	needs; idb is not installed). The demo simulator path is unaffected.
    27	
    28	## Surface area (file-by-file)
    29	- **WI-1 — XCUITest target + a11y ids + smoke**
    30	  - `project.yml`: NEW target `vrecorderUITests` (type `bundle.ui-testing`, deps:
    31	    `vrecorder`); add to the `vrecorder` scheme's test action. `xcodegen generate`.
    32	  - NEW `vrecorderUITests/LiveScreenUITests.swift`: launch the app, assert the
    33	    live screen's mic button + settings gear exist (by a11y id).
    34	  - MODIFY `vrecorder/Views/LiveScreen.swift`, `MicButton.swift`,
    35	    `SettingsScreen.swift`, `APIKeyEntryView.swift`: add
    36	    `.accessibilityIdentifier(...)` to the gear, mic button, "API 密钥" row,
    37	    SecureField, 保存/清除 buttons (identifiers are not user-visible UI → not a
    38	    rule-51 surface).
    39	- **WI-2 — DebugBridge (DEBUG only)**
    40	  - NEW `vrecorder/Debug/DebugBridge.swift` (`#if DEBUG` whole file): parses
    41	    `vrecorder-debug://inject?…` URLs and drives `LiveSessionModel` via its
    42	    existing `pushA`/`pushB` (already `func`-public on the @MainActor model) to
    43	    seed deterministic transcript states; `vrecorder-debug://reset` clears.
    44	  - MODIFY `vrecorder/App/VRecorderApp.swift`: `.onOpenURL` (DEBUG) → DebugBridge,
    45	    holding the `AppEnvironment.session`. Requires lifting `AppEnvironment` to the
    46	    App so the bridge and `RootView` share one session (today `RootView` owns it).
    47	  - MODIFY `vrecorder/App/RootView.swift` / `AppEnvironment.swift`: accept an
    48	    injected `AppEnvironment` instead of constructing its own, so the App owns it.
    49	  - `project.yml`: register `vrecorder-debug` URL scheme (DEBUG via
    50	    `INFOPLIST_KEY_…`? URL schemes need `CFBundleURLTypes` — add a Debug-config
    51	    Info.plist fragment or an `.xcconfig`; confirm the mechanism in the plan).
    52	- **WI-3 — feature #2 UI verification test**
    53	  - NEW `vrecorderUITests/APIKeyEntryUITests.swift`: launch → tap gear → tap
    54	    "API 密钥" → typeText a key → tap 保存 → assert the row shows "已配置". This is
    55	    the end-to-end Gate-5 check that flips feature #2 → VERIFIED.
    56	
    57	## Prior art / project precedent / rejected alternatives
    58	- **Precedent:** `LiveSessionModel.pushA/pushB` are already public seams (used by
    59	  the demo simulator) — the DebugBridge reuses them, inventing no new state API.
    60	  `#if DEBUG` file-scope gating is the established pattern (APIKeyBootstrap).
    61	- **Industry:** XCUITest + accessibility identifiers + a debug URL scheme to drive
    62	  deterministic UI state is the standard iOS UI-verification approach.
    63	- **Rejected:** (a) idb/`sim-tap.sh` as the primary driver — XCUITest's native
    64	  tap/typeText covers this feature; idb isn't installed; defer as optional. (b)
    65	  Snapshot/pixel testing — brittle, and rule-51 governs visual design, not tests.
    66	  (c) Driving the real recognizer in UI tests — non-deterministic; the DebugBridge
    67	  injects fixtures instead.
    68	
    69	## Work items (3 WIs, one PR each — rule 47)
    70	- **WI-1 (foundational)**: XCUITest target + a11y ids + smoke test. Unit/UI-test
    71	  only; no behavior change. Slice-verify: the UI smoke test runs green on the sim.
    72	- **WI-2 (behavioral)**: DebugBridge + App-owns-AppEnvironment wiring. Slice-verify:
    73	  a `vrecorder-debug://inject` URL produces the expected on-screen transcript
    74	  (asserted by a UI test).
    75	- **WI-3 (final)**: feature #2 API-key UI test → flips feature #2 to VERIFIED with
    76	  a `dev-docs/verification/feature-2-…` update.
    77	
    78	## Test catalogue
    79	- `vrecorderUITests/LiveScreenUITests.swift`: `liveScreenShowsMicAndGear`.
    80	- `vrecorderUITests/DebugBridgeUITests.swift`: `injectURLSeedsTranscript`,
    81	  `resetURLClears`.
    82	- `vrecorderUITests/APIKeyEntryUITests.swift`: `enterKeyFlipsRowToConfigured`,
    83	  `cancelLeavesRowUnchanged`, `clearKeyFlipsRowToUnconfigured`.
    84	
    85	## Edge cases
    86	- App not built for UI testing → XCUITest target launches its own host (handled by
    87	  the target type).
    88	- DebugBridge active only in DEBUG (Release ignores the URL scheme entirely).
    89	- Malformed `vrecorder-debug://` URL → no-op, no crash.
    90	- Sheet/keyboard timing in XCUITest → use `waitForExistence(timeout:)`, never bare
    91	  sleeps.
    92	- Simulator wedge (seen this session) → run UI tests through `scripts/run-tests.sh`
    93	  (UDID-pinned, watchdog) on a clean sim.
    94	- a11y identifiers must not collide → namespaced (`vr.live.mic`, `vr.settings.apiKeyRow`…).
    95	
    96	## Acceptance criteria
    97	1. `vrecorderUITests` target builds and runs via the scheme; smoke test green.
    98	2. A `vrecorder-debug://inject` URL deterministically seeds an on-screen transcript
    99	   (DEBUG); Release ignores the scheme.
   100	3. The API-key UI test drives 设置 → API 密钥 → enter → 保存 and asserts 已配置 —
   101	   flipping feature #2 to VERIFIED.
   102	4. All UI tests run on the iPhone 17 Pro simulator through `run-tests.sh`.
   103	5. No production behavior change; DebugBridge is `#if DEBUG` only.
   104	
   105	## Risks + mitigations
   106	- **URL-scheme registration mechanism**: `CFBundleURLTypes` isn't an
   107	  `INFOPLIST_KEY_…` one-liner. Mitigation: add a checked-in `Debug.xcconfig` or a
   108	  partial Info.plist with the URL type (DEBUG config only); WI-2 confirms the exact
   109	  xcodegen mechanism before coding.
   110	- **App-owns-AppEnvironment refactor** could disturb the scene-phase teardown
   111	  (audit-G4r2 #2 fix). Mitigation: keep `@State` ownership, just lift it one level
   112	  (App → injected into RootView); a UI test asserts background still stops.
   113	- **XCUITest flakiness**: bounded `waitForExistence`, no sleeps; UDID-pinned sim.
   114	
   115	## Docs sync + version bump (rules 24 + 40)
   116	- `docs/architecture.md`: note the DebugBridge + UITest target. `README.md`:
   117	  Developer Tools / testing note. `docs/features.md`: row #6 PLANNED → IN PROGRESS
   118	  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
   119	- Version: **minor** per WI as shipped (0.2.5 → 0.3.0 on the first WI), per rule 40.
   120	
   121	## Backward compat
   122	Additive + DEBUG-only. No schema, no Release behavior change. The
   123	App-owns-AppEnvironment change is internal wiring.
Version: 2.45.4
name: vrecorder
options:
  bundleIdPrefix: com.vrecorder
  createIntermediateGroups: true
  deploymentTarget:
    iOS: '17.0'
schemes:
  vrecorder:
    build:
      targets:
        vrecorder: all
        vrecorderTests:
        - test
    test:
      targets:
      - vrecorderTests
settings:
  base:
    CODE_SIGN_STYLE: Automatic
    CURRENT_PROJECT_VERSION: '7'
    DEVELOPMENT_TEAM: ''
    GENERATE_INFOPLIST_FILE: 'YES'
    MARKETING_VERSION: 0.2.5
    SWIFT_STRICT_CONCURRENCY: complete
    SWIFT_VERSION: '6.0'
targets:
  vrecorder:
    deploymentTarget: '17.0'
    platform: iOS
    settings:
      base:
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        CURRENT_PROJECT_VERSION: '7'
        GENERATE_INFOPLIST_FILE: 'YES'
        INFOPLIST_KEY_NSMicrophoneUsageDescription: "VRecorder \u9700\u8981\u4F7F\u7528\u9EA6\u514B\u98CE\u8FDB\u884C\u5B9E\u65F6\u540C\u58F0\u4F20\u8BD1\u3002"
        INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: "VRecorder \u4F7F\u7528\u8BED\u97F3\u8BC6\u522B\u5C06\u4F60\u7684\u53D1\u8A00\u5B9E\u65F6\u8F6C\u5199\u4E3A\u6587\u5B57\u3002"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: 'YES'
        INFOPLIST_KEY_UILaunchScreen_Generation: 'YES'
        INFOPLIST_KEY_UIStatusBarStyle: UIStatusBarStyleLightContent
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
        MARKETING_VERSION: 0.2.5
        PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app
        TARGETED_DEVICE_FAMILY: '1'
      configs:
        Release:
          EXCLUDED_SOURCE_FILE_NAMES: openai-key.txt
    sources:
    - path: vrecorder
    - buildPhase: resources
      optional: true
      path: config/openai-key.txt
    type: application
  vrecorderTests:
    dependencies:
    - target: vrecorder
    deploymentTarget: '17.0'
    platform: iOS
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vrecorder.app.tests
    sources:
    - path: vrecorderTests
    type: bundle.unit-test


codex
Several plan assumptions are already disproven or underspecified: `pushA`/`pushB` are internal, not public; `reset` cannot be implemented through them because transcript arrays are `private(set)` and there is no reset API; and `run-tests.sh` defaults to and filters a single unit-test suite, so the plan’s “all UI tests through run-tests.sh” criterion requires a script change that is not scoped. I’m validating the remaining xcodegen and lifecycle details before assigning severity.
web search: 
web search: site:github.com/yonaskolb/XcodeGen Spec target type bundle.ui-testing info properties config files CFBundleURLTypes
web search: 
web search: https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md
web search: 
web search: 'bundle.ui-testing' in https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md
exec
/bin/zsh -lc 'SDK=$(xcrun --sdk iphonesimulator --show-sdk-path) /usr/bin/grep -R -n -m 5 "func onOpenURL'"\\|struct OpenURLAction\\|protocol App\" \""'$SDK/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule"' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 exited 2 in 2409ms:
2026-06-15 00:57:43.597 xcodebuild[8520:11806427]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-06-15 00:57:43.901 xcodebuild[8520:11806426] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
2026-06-15 00:57:44.441 xcodebuild[8522:11806483]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-06-15 00:57:44.608 xcodebuild[8522:11806481] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
xcrun: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
xcrun: error: couldn't create cache file '/tmp/xcrun_db-Q1tCZCVL' (errno=Operation not permitted)
2026-06-15 00:57:45.128 xcodebuild[8526:11806525]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-06-15 00:57:45.289 xcodebuild[8526:11806524] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
grep: /System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule: No such file or directory

exec
/bin/zsh -lc 'rg -n -m 10 "onOpenURL|protocol App|struct OpenURLAction" /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64-apple-ios-simulator.swiftinterface:2488:  nonisolated public func onOpenURL(perform action: @escaping (Foundation.URL) -> ()) -> some SwiftUICore.View
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64-apple-ios-simulator.swiftinterface:8157:@preconcurrency @_Concurrency.MainActor public protocol App {
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/x86_64-apple-ios-simulator.swiftinterface:2488:  nonisolated public func onOpenURL(perform action: @escaping (Foundation.URL) -> ()) -> some SwiftUICore.View
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/x86_64-apple-ios-simulator.swiftinterface:8157:@preconcurrency @_Concurrency.MainActor public protocol App {

exec
/bin/zsh -lc "sed -n '2478,2495p;8148,8175p' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64-apple-ios-simulator.swiftinterface" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public var _defaultSwiftUIActivityEnvironmentLoggingEnabled: Swift.Bool
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension SwiftUICore.View {
  nonisolated public func userActivity(_ activityType: Swift.String, isActive: Swift.Bool = true, _ update: @escaping (Foundation.NSUserActivity) -> ()) -> some SwiftUICore.View
  
  nonisolated public func userActivity<P>(_ activityType: Swift.String, element: P?, _ update: @escaping (P, Foundation.NSUserActivity) -> ()) -> some SwiftUICore.View
  
  nonisolated public func onContinueUserActivity(_ activityType: Swift.String, perform action: @escaping (Foundation.NSUserActivity) -> ()) -> some SwiftUICore.View
  
  nonisolated public func onOpenURL(perform action: @escaping (Foundation.URL) -> ()) -> some SwiftUICore.View
  
}
@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SwiftUICore.View {
  nonisolated public func handlesExternalEvents(preferring: Swift.Set<Swift.String>, allowing: Swift.Set<Swift.String>) -> some SwiftUICore.View
@usableFromInline
internal class LimitedAvailabilityPrintContentStorageBase {
  @objc @usableFromInline
  deinit
}
@available(*, unavailable)
extension SwiftUI.LimitedAvailabilityPrintContentStorageBase : Swift.Sendable {
}
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@preconcurrency @_Concurrency.MainActor public protocol App {
  associatedtype Body : SwiftUI.Scene
  @SwiftUI.SceneBuilder @_Concurrency.MainActor @preconcurrency var body: Self.Body { get }
  @_Concurrency.MainActor @preconcurrency init()
}
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension SwiftUI.App {
  @_Concurrency.MainActor @preconcurrency public static func main()
}
@available(macOS 15.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@frozen public enum FrameResizePosition : Swift.Int8, Swift.CaseIterable {
  case top
  case leading
  case bottom
  case trailing

exec
/bin/zsh -lc "rg -n -m 30 \"func open\\(|openURL|XCUIApplication\" /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCTest.framework/Modules/XCTest.swiftmodule/arm64-apple-ios-simulator.swiftinterface /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Modules/XCUIAutomation.swiftmodule/arm64-apple-ios-simulator.swiftinterface" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 exited 2 in 0ms:
rg: /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCTest.framework/Modules/XCTest.swiftmodule/arm64-apple-ios-simulator.swiftinterface: No such file or directory (os error 2)
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Modules/XCUIAutomation.swiftmodule/arm64-apple-ios-simulator.swiftinterface:12:extension XCUIAutomation.XCUIApplication {

exec
/bin/zsh -lc "sed -n '1,80p' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Modules/XCUIAutomation.swiftmodule/arm64-apple-ios-simulator.swiftinterface && rg -n \"openURL|open.*URL|activate\\(|launch\\(\" /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
// swift-interface-format-version: 1.0
// swift-compiler-version: Apple Swift version 6.3.2 effective-5.10 (swiftlang-6.3.2.1.108 clang-2100.1.1.101)
// swift-module-flags: -target arm64-apple-ios13.0-simulator -enable-objc-interop -enable-library-evolution -swift-version 5 -Osize -enable-upcoming-feature ConciseMagicFile -enable-upcoming-feature DeprecateApplicationMain -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature ExistentialAny -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -user-module-version 24904 -module-name XCUIAutomation -package-name com.apple.dt.xctest
// swift-module-flags-ignorable:  -formal-cxx-interoperability-mode=off -interface-compiler-version 6.3.2
import Foundation
import Swift
@_exported import XCUIAutomation
import _Concurrency
import _StringProcessing
import _SwiftConcurrencyShims
import os
extension XCUIAutomation.XCUIApplication {
  @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
  @nonobjc @_Concurrency.MainActor @preconcurrency public func performAccessibilityAudit(for auditTypes: XCUIAutomation.XCUIAccessibilityAuditType = .all, _ issueHandler: ((XCUIAutomation.XCUIAccessibilityAuditIssue) throws -> Swift.Bool)? = nil) throws
}
@available(swift 4.0)
extension XCUIAutomation.XCUIElement {
  @nonobjc @_Concurrency.MainActor @preconcurrency public func typeKey(_ key: XCUIAutomation.XCUIKeyboardKey, modifierFlags: XCUIAutomation.XCUIElement.KeyModifierFlags)
}
extension XCUIAutomation.XCUIElement {
  @_Concurrency.MainActor @preconcurrency public func wait<V>(for keyPath: Swift.KeyPath<XCUIAutomation.XCUIElement, V>, toEqual expectedValue: V, timeout: Foundation.TimeInterval) -> Swift.Bool where V : Swift.Equatable
}
extension XCUIAutomation.XCUIGestureVelocity : Swift.ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Swift.Int)
  public typealias IntegerLiteralType = Swift.Int
}
extension XCUIAutomation.XCUIGestureVelocity : Swift.ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = CoreFoundation.CGFloat.NativeType
  public init(floatLiteral value: XCUIAutomation.XCUIGestureVelocity.FloatLiteralType)
}
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUISystem.h:22:- (void)openURL:(NSURL *)url;
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUIAutomation.apinotes:61:    SwiftName: 'activate(voiceRecognitionText:)'
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUIApplication.h:63:- (void)openURL:(NSURL *)url API_AVAILABLE(macos(13.3), ios(16.4), tvos(16.4), watchos(9.4));

exec
/bin/zsh -lc "sed -n '45,75p' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUIApplication.h && sed -n '1,45p' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUISystem.h" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:

/*!
 * Launches the application synchronously. On return the application ready to handle events. If the
 * application is already running, the existing instance will be terminated to ensure a clean state
 * for the launched instance.
 *
 * Any failure in the launch sequence will be reported as a test failure and the test will be halted
 * at that point.
*/
- (void)launch;

/*!
 * Launches the application synchronously using the provided URL. On return the application is ready
 * to handle events, similar to the behavior of -launch.
 *
 * Any failure in the launch sequence, or any failure in using the provided URL, will be reported as a
 * test failure and the test will be halted at that point.
*/
- (void)openURL:(NSURL *)url API_AVAILABLE(macos(13.3), ios(16.4), tvos(16.4), watchos(9.4));

/*!
 * Activates the application synchronously. On return the application is ready to handle events.
 * If the application was not running prior, it will be launched automatically. If the application
 * would be launched as a result of this method and was previously launched via -launch, the launch
 * arguments and environment variables that were used then will be supplied again for the new launch.
 *
 * Unlike -launch, if the application is already running this call will not terminate the existing
 * instance.
 *
 * Any failure in the activation or launch sequence will be reported as a test failure and the test
 * will be halted at that point.
//
//  Copyright © 2022 Apple Inc. All rights reserved.
//

#import <XCUIAutomation/XCUIAutomationDefines.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class XCUISystem
 * Represents a device's base system, providing an interface for performing OS-specific actions like opening universal links.
 */
XCUI_SWIFT_MAIN_ACTOR
@interface XCUISystem : NSObject

+ (instancetype)new XCUI_UNAVAILABLE("Access XCUISystem through the system property on XCUIDevice.");
- (instancetype)init XCUI_UNAVAILABLE("Access XCUISystem through the system property on XCUIDevice.");

/*!
 * Open a URL on the system using the default application for it.
 */
- (void)openURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

web search: 
web search: site:github.com/yonaskolb/XcodeGen CFBundleURLTypes INFOPLIST_KEY
web search: 
web search: site:developer.apple.com/documentation/xcode INFOPLIST_KEY generated Info.plist array dictionary build setting
exec
/bin/zsh -lc 'rg -n -m 30 "INFOPLIST_KEY_" /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Specifications /Applications/Xcode.app/Contents/Developer/Library/Xcode/Specifications /Applications/Xcode.app/Contents/Developer/Library/Xcode/Plug-ins' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 exited 2 in 0ms:
rg: /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Specifications: No such file or directory (os error 2)
rg: /Applications/Xcode.app/Contents/Developer/Library/Xcode/Specifications: No such file or directory (os error 2)
rg: /Applications/Xcode.app/Contents/Developer/Library/Xcode/Plug-ins: No such file or directory (os error 2)

exec
/bin/zsh -lc "find . -path '*Build/Products/*/vrecorder.app/Info.plist' -o -path '*DerivedData*/Build/Products/*/vrecorder.app/Info.plist'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
exec
/bin/zsh -lc "sed -n '1,65p' docs/features.md && sed -n '1,180p' dev-docs/verification/SCHEMA.md && rg -n \"feature #2|Feature #2|API key|API 密钥|VERIFIED|DONE\" dev-docs/verification docs/features.md README.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
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
docs/features.md:11:- **Cross-links**: When a bug fix resolves a feature, update the feature status to `DONE` with note `Resolved by bug #N`. When a feature depends on a bug fix, use `TODO` status with note `Blocked by bug #N`.
docs/features.md:13:- **Exception — resolved by bug fix**: If a bug fix incidentally delivers a feature, the feature may be set to `DONE` with `Resolved by bug #N` without a full plan.
docs/features.md:24:    1. All acceptance criteria met and status is VERIFIED in this file.
docs/features.md:35:- `DONE` — implemented; correctness not yet verified end-to-end
docs/features.md:36:- `VERIFIED` — covered by an automated end-to-end test or an explicit on-device manual verification log
docs/features.md:54:| 1   | MVP 同传管线骨架（同传屏/设置屏 + 本地STT + OpenAI翻译 + Keychain key） | pipeline/ui | High | DONE | Scaffold, retro-registered outside gates 1-2 (course demo). Mirror: no. Pipeline-translate leg verified against live OpenAI; on-device STT needs device verify (Gate 5 deferred). Pre-push Codex audit (prepush-25e2320) found 6H+2M; fixes #3-8 + #1 applied (see Notes). |
docs/features.md:55:| 2   | Release 内 API 密钥录入页（Keychain 编辑器） | ui/settings | Medium | DONE | Shipped in v0.2.0 (PR #2, merge `1d3644d`). 4 plan-audit + 2 impl-audit rounds. Design bundle `dev-docs/designs/api-key-entry/` (owner-authorized). 31 tests. NOT yet VERIFIED — interactive tap flow needs a manual device pass (evidence `feature-2-20260614.md`, result: partial). Mirror: no. |
docs/features.md:90:- #2 → split out as **feature #2** (Release key-entry UI, BLOCKED: needs-design).
docs/features.md:99:distinct recognition error. **Residual:** Release key-entry UI (feature #2,
README.md:10:hook runs a Codex audit (ChatGPT-subscription auth — no OpenAI API key) over the
README.md:19:codex --version                # confirm Codex CLI present (ChatGPT login, no API key)
README.md:60:key, demo-simulator fallback. Plus feature #2: in-app OpenAI key configuration
README.md:61:(Settings › API 密钥) with an atomic Keychain write. 31 unit tests green.
dev-docs/verification/SCHEMA.md:3:Every flip of a tracker row to `VERIFIED` (features) or `FIXED` (bugs) requires a
dev-docs/verification/SCHEMA.md:17:status_target: VERIFIED | FIXED
dev-docs/verification/SCHEMA.md:39:- `pass` — every criterion exercised end-to-end → may flip to VERIFIED/FIXED
dev-docs/verification/SCHEMA.md:40:- `partial` — some passed + explicit deferral → **must NOT** flip; stays DONE/awaiting
dev-docs/verification/feature-2-20260614.md:4:status_target: VERIFIED
dev-docs/verification/feature-2-20260614.md:16:# Feature #2 — API key entry — verification
dev-docs/verification/feature-2-20260614.md:22:| 1 | Tapping "API 密钥" opens the entry sheet | Wired via `.sheet`; build + launch clean. Tap not driveable headlessly (no idb/sim-tap). | logic+build pass; **tap deferred** |
dev-docs/verification/feature-2-20260614.md:58:named, confirmed tool-unavailability. Row stays **DONE** (after merge), not
dev-docs/verification/feature-2-20260614.md:59:VERIFIED, until the manual pixel pass is recorded.

exec
/bin/zsh -lc 'rg -n "Feature #2|feature #2|Acceptance criteria|API key entry" dev-docs/plans docs/features.md && nl -ba dev-docs/verification/feature-2-20260614.md' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
docs/features.md:48:- **Acceptance criteria**: How do we know it's done?
docs/features.md:90:- #2 → split out as **feature #2** (Release key-entry UI, BLOCKED: needs-design).
docs/features.md:99:distinct recognition error. **Residual:** Release key-entry UI (feature #2,
dev-docs/plans/20260615-feature-6-verification-harness.md:14:(feature #2 DONE-not-VERIFIED; bugs awaiting device verification) can't be
dev-docs/plans/20260615-feature-6-verification-harness.md:22:XCUITest that verifies feature #2's API-key sheet flow end-to-end.
dev-docs/plans/20260615-feature-6-verification-harness.md:52:- **WI-3 — feature #2 UI verification test**
dev-docs/plans/20260615-feature-6-verification-harness.md:55:    the end-to-end Gate-5 check that flips feature #2 → VERIFIED.
dev-docs/plans/20260615-feature-6-verification-harness.md:75:- **WI-3 (final)**: feature #2 API-key UI test → flips feature #2 to VERIFIED with
dev-docs/plans/20260615-feature-6-verification-harness.md:96:## Acceptance criteria
dev-docs/plans/20260615-feature-6-verification-harness.md:101:   flipping feature #2 to VERIFIED.
dev-docs/plans/20260615-feature-6-verification-harness.md:118:  → DONE → VERIFIED; feature #2 → VERIFIED on WI-3.
dev-docs/plans/20260614-feature-2-api-key-entry.md:1:# Feature #2 — API key entry (Keychain editor)
dev-docs/plans/20260614-feature-2-api-key-entry.md:232:## Acceptance criteria
     1	---
     2	kind: feature
     3	id: 2
     4	status_target: VERIFIED
     5	commit_sha: 258097c2dffe525cde97749cea770ec8fbb8476c
     6	app_version: 0.2.0 (build 2)
     7	date: 2026-06-14
     8	verifier: claude
     9	device_or_simulator: "iPhone 17 Pro Simulator"
    10	os_version: "iOS 26.x"
    11	build_configuration: Debug
    12	backend: "n/a (Keychain-local; no network in this slice)"
    13	result: partial
    14	---
    15	
    16	# Feature #2 — API key entry — verification
    17	
    18	## Acceptance criteria
    19	
    20	| # | Criterion | Observed | Pass/Fail |
    21	|---|-----------|----------|-----------|
    22	| 1 | Tapping "API 密钥" opens the entry sheet | Wired via `.sheet`; build + launch clean. Tap not driveable headlessly (no idb/sim-tap). | logic+build pass; **tap deferred** |
    23	| 2 | Valid key + 保存 → stored, row shows 已配置, dismiss | `saveTrimsPersistsAndClearsDraft` + `initReflectsExistingKey` + onDismiss refresh cover the logic. Pixel flow deferred. | logic pass; **pixel deferred** |
    24	| 3 | 清除密钥 (confirm) → removed, row 未配置 | `clearRemovesKeyAndUpdatesState`; system `.alert` confirm wired. | logic pass; **pixel deferred** |
    25	| 4 | Empty/invalid keeps 保存 disabled; direct save no-op | `saveGuardsOnValidity`, `isValid*` tests. | pass |
    26	| 5 | Keychain write failure keeps sheet open, shows error, preserves old key | `saveFailurePreservesPreviousKeyAndSetsError`, `clearFailureRetainsConfiguredStateAndSetsError`, `updateFailureOtherThanNotFoundPreservesOldKeyNoAdd` | pass |
    27	| 6 | Works in Release (no DEBUG file dependence) | Release build of feature #1 already excludes the seed file; the sheet is the Release key path. Release build not re-run this slice. | build-level pass; **on-device deferred** |
    28	| 7 | Reuses only existing design-system tokens | `APIKeyEntryView` uses only `VR.*` tokens; no new colors/type. | pass |
    29	
    30	## Commands run
    31	
    32	```
    33	xcodegen generate
    34	xcodebuild build -scheme vrecorder -destination 'platform=iOS Simulator,name=iPhone 17 Pro'  # BUILD SUCCEEDED
    35	scripts/run-tests.sh vrecorderTests   # RUN-TESTS RESULT: SUCCEEDED, 31 tests / 5 suites
    36	xcrun simctl boot 1DFF0691-… ; install ; launch com.vrecorder.app   # pid 92878, no crash
    37	xcrun simctl io … screenshot /tmp/vr-f2-live.png
    38	```
    39	
    40	## Observations
    41	
    42	- The interactive tap→type→save→row-flips pixel flow is **not** exercised: this
    43	  headless environment has no tap driver (idb / sim-tap absent — confirmed). The
    44	  security-critical logic (atomic write, old-key preservation on failure,
    45	  validation, masking) IS exhaustively unit-tested, including scripted `OSStatus`
    46	  sequences through the injected `KeychainOps`.
    47	- App launches with the new SettingsScreen `init(store:)` wiring without crashing.
    48	
    49	## Artifacts
    50	
    51	- `/tmp/vr-f2-live.png` — post-launch live screen (smoke).
    52	- 31 passing tests (see `scripts/run-tests.sh vrecorderTests`).
    53	
    54	## Why `partial`
    55	
    56	The logic layer is fully verified; the on-screen tap-driven flow needs a manual
    57	device/simulator tap pass (no headless tap tooling). Per the Gate-5 rule this is a
    58	named, confirmed tool-unavailability. Row stays **DONE** (after merge), not
    59	VERIFIED, until the manual pixel pass is recorded.

exec
/bin/zsh -lc "sed -n '220,270p' dev-docs/plans/20260614-feature-2-api-key-entry.md && sed -n '1,80p' dev-docs/plans/20260614-feature-2-api-key-entry.md" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
## Edge cases

- Empty / whitespace-only draft → invalid, 保存 disabled, direct save() no-op.
- Pasted key with surrounding newline/space → trimmed; internal control/space → invalid.
- `sk-` alone or very short → invalid (length guard).
- CJK / emoji → invalid (no `sk-` prefix).
- Clearing when no key exists → no-op, no crash.
- Masking a short stored secret → never reveal it; show "已配置".
- Overwrite existing key → atomic update; old key preserved if write fails.
- Concurrent active translation during overwrite → no missing-key window (atomic).
- DEBUG seed present → sheet shows masked existing; can overwrite/clear.

## Acceptance criteria

1. Tapping "API 密钥" opens the entry sheet.
2. Valid `sk-...` key + 保存 → stored in Keychain, Settings row shows "已配置",
   sheet dismisses.
3. 清除密钥 (with confirm) → key removed, row shows "未配置".
4. Empty/invalid input keeps 保存 disabled and direct save() is a no-op.
5. A simulated Keychain write failure keeps the sheet open, shows an error, and
   preserves the previous key.
6. Works in a Release build (independent of the DEBUG bundled file).
7. Reuses only existing design-system tokens — no new visual language.

## Risks + mitigations

- **Reactive refresh**: `apiKeyConfigured` is construction-time today → make it
  `@State`, refreshed on sheet `onDismiss`.
- **Keychain on simulator**: verify real round-trip (set/get/clear) on the sim.
- **rule 51**: resolved via the committed design artifact + recorded authorization.

## Docs sync + version bump (audit-2 #7, rules 24 + 40)

- **`docs/architecture.md`**: add `APIKeyEntryModel` to the Services table and
  note the Settings → key-entry sheet flow. **`README.md`** (rule 24, user-visible
  feature lands): add a bullet noting in-app OpenAI key configuration (Settings ›
  API 密钥). **`docs/features.md`**: row #2 → `IN PROGRESS` then `DONE`/`VERIFIED`.
- **Version bump** (rule 40): minor — `0.1.0` → `0.2.0`, `CURRENT_PROJECT_VERSION`
  `1` → `2`, via `project.yml` + `xcodegen generate`, as the tail commit before
  the PR.

## Backward compat

Additive. `setKey` return value is `@discardableResult` (existing callers
unaffected). DEBUG `config/openai-key.txt` seeding still works (same Keychain
item, now written via atomic update). No schema, no migration.
# Feature #2 — API key entry (Keychain editor)

> Gate-1 plan, **revision 5** (addresses Codex plan-audit rounds 1–4).
> Status: **PLANNED → IN PROGRESS.** Plan audit ran 4 rounds and converged
> (round 4 resolved all of round 3; remaining items were polish: op-specific
> error message + format-agnostic validation, both folded in here). Per rule 47's
> 3-round plan-audit cap + the design owner's standing autonomous authorization,
> proceeding to Gate 3. Gate 4 (pre-push Codex audit on the implementation) is the
> code-level safety net.
> **Estimated PR size** (audit-3 #5), single WI/PR: **5 production** files
> (`APIKeyStore.swift` mod, `APIKeyEntryModel.swift` new, `APIKeyEntryView.swift`
> new, `SettingsScreen.swift` mod, `RootView.swift` mod) + **2 test** files +
> **3 docs** (`features.md`, `architecture.md`, `README.md`) + **version** files
> (`project.yml` + regenerated `project.pbxproj`) + **1 verification** evidence
> file. ≈ 450–550 net LOC incl. tests.

## Revision history

- **r1** — initial plan. Audit round 1: 2 High + 7 Medium.
- **r2** — committed design artifact, atomic Keychain write, single state owner,
  validation/masking, one WI/PR, BYOK threat model. Audit round 2: 1 High + 6 Med.
- **r3** — HTML design mockup committed (rule-51 format), injectable Security
  boundary for real failure tests, `clear()` reports failure, provider-compatible
  validation + explicit masking bounds, explicit `@State` model ownership,
  corrected BYOK transmission disclosure, Gate-1 completeness. Audit round 3:
  2 High + 3 Medium.
- **r4** — HTML mockup adds failure + clear-confirm states; `KeychainOps: Sendable`
  with `@Sendable` closures + explicit init; validation regex `{13,197}` (total
  16–200) + boundary tests; README sync added; prior-art/rejected-alternatives
  section restored; accurate file-count estimate.

## Problem

A fresh **Release** install has no way to configure an OpenAI API key: the only
seeding path is the DEBUG-bundled `config/openai-key.txt`, so in Release the key
is always missing and every translation fails with `missingAPIKey`. The Settings
"API 密钥" row exists and reports real state ("已配置"/"未配置") but its tap does
nothing. This was audit finding #2 across all four feature-#1 audit rounds.

## Design authority (audit-1 #1 / audit-2 #1)

The committed design bundle at `dev-docs/designs/api-key-entry/` now contains
**both** an `api-key-entry.html` mockup *depicting* the two surface states
(rule-51's HTML format) **and** a `README.md` token spec, built entirely from the
existing light-scope design system (no new visual language). The design owner
(user, 2026-06-14) explicitly authorized building this surface from the committed
design system in lieu of a claude.ai/design round. These files + the plan are
committed to the branch (resolving the "untracked" objection). The tracker row
moves off `BLOCKED: needs-design`. Per rule 47 author/auditor independence, the
final acceptance of the authorization rests with the design owner, who recorded
it here.

## BYOK threat model (audit-1 #9 / audit-2 #2)

This is **bring-your-own-key** on a client device.
- **At rest:** the key is stored in the iOS Keychain on this device only.
- **In transit:** during interpretation the key **is transmitted to the chosen
  provider (OpenAI)** as a `Bearer` credential over TLS
  (`OpenAITranslationEngine.makeRequest`). It is **not** sent to vrecorder
  servers or any third party. The earlier "不会上传" wording was inaccurate and is
  corrected in the design notice.
- **Limitation:** a mobile-held key is not equivalent to a server-side secret
  (OpenAI discourages client-side keys); a jailbroken/compromised device can
  extract it. Accepted for an MVP/course-demo BYOK app; not mitigated further.

## Atomic Keychain write (audit-1 #2 + #5 resolved)

`KeychainAPIKeyStore.setKey` currently does `SecItemDelete` → `SecItemAdd`,
ignoring every `OSStatus`. An add failure **destroys the previous key** while the
UI would report success, and the delete→add window can make a concurrent
translation read `missingAPIKey`. **Fix (in scope):** make the write atomic and
error-reporting.

- `APIKeyStoring.setKey` becomes `@discardableResult func setKey(_:for:) -> Bool`
  (existing callers — `APIKeyBootstrap.seedIfNeeded` — ignore the result, so this
  is source-compatible).
- `KeychainAPIKeyStore` implementation:
  - non-nil value: `SecItemUpdate` first; on `errSecItemNotFound`, `SecItemAdd`;
    return `status == errSecSuccess`. **Never delete-then-add**, so an existing
    key survives a failed write and there is no missing-key window.

exec
/bin/zsh -lc 'ls -la config 2>/dev/null; git ls-files config; rg -n "Keychain|launchArguments|launchEnvironment|UI_TEST|UITest|test mode|reset" vrecorder vrecorderTests scripts project.yml .gitignore' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
total 32
drwxr-xr-x@  5 deanlee  staff   160 Jun 14 18:24 .
drwxr-xr-x@ 18 deanlee  staff   576 Jun 15 00:30 ..
-rw-r--r--@  1 deanlee  staff  6148 Jun 14 17:28 .DS_Store
-rw-r--r--@  1 deanlee  staff   763 Jun 14 18:24 README.md
-rw-r--r--@  1 deanlee  staff   164 Jun 13 18:39 openai-key.txt
config/README.md
.gitignore:13:# Secrets — keys live outside the repo / in Keychain, never committed
vrecorder/Views/APIKeyEntryView.swift:96:        Text("你的密钥保存在本机钥匙串（Keychain）。同传时会以 Bearer 凭证经 TLS 发送给你选择的服务商（OpenAI），不会发给其它第三方。设备被攻破时密钥仍可能泄露。")
vrecorderTests/APIKeyEntryModelTests.swift:3://  key-entry view-model (feature #2). No UI, no real Keychain.
vrecorderTests/KeychainAPIKeyStoreTests.swift:1://  KeychainAPIKeyStoreTests.swift
vrecorderTests/KeychainAPIKeyStoreTests.swift:3://  via the injected KeychainOps seam (feature #2, audit-2 #3). The real Keychain
vrecorderTests/KeychainAPIKeyStoreTests.swift:11:@Suite("KeychainAPIKeyStore (scripted OSStatus)")
vrecorderTests/KeychainAPIKeyStoreTests.swift:12:struct KeychainAPIKeyStoreTests {
vrecorderTests/KeychainAPIKeyStoreTests.swift:22:                       delete: OSStatus = errSecSuccess, calls: Calls) -> KeychainAPIKeyStore {
vrecorderTests/KeychainAPIKeyStoreTests.swift:23:        let ops = KeychainOps(
vrecorderTests/KeychainAPIKeyStoreTests.swift:28:        return KeychainAPIKeyStore(ops: ops)
vrecorder/Views/SettingsScreen.swift:4://  UserDefaults + Keychain (API key). No real persistence yet.
vrecorder/Views/SettingsScreen.swift:12:    /// Reflects real Keychain state — refreshed when the key-entry sheet closes
vrecorder/Security/APIKeyBootstrap.swift:3://  bundled into the app (dev builds only) and the Keychain has no OpenAI key yet,
vrecorder/Security/APIKeyBootstrap.swift:4://  copy it into the Keychain once. Release builds never read a file; the key is
vrecorder/Security/APIKeyBootstrap.swift:10:    /// Seed the Keychain from a bundled `openai-key.txt` resource if present and unset.
vrecorder/Engines/OpenAITranslationEngine.swift:5://  PipelineError. Key comes from the injected provider (Keychain-backed).
vrecorder/Security/APIKeyStore.swift:2://  Purpose: Keychain-backed storage for provider API keys. The key is the only
vrecorder/Security/APIKeyStore.swift:4://  A protocol lets tests substitute an in-memory store; an injectable KeychainOps
vrecorder/Security/APIKeyStore.swift:20:struct KeychainOps: Sendable {
vrecorder/Security/APIKeyStore.swift:27:/// Real Keychain implementation (generic password, one item per provider).
vrecorder/Security/APIKeyStore.swift:28:struct KeychainAPIKeyStore: APIKeyStoring {
vrecorder/Security/APIKeyStore.swift:30:    private let ops: KeychainOps
vrecorder/Security/APIKeyStore.swift:32:    init(ops: KeychainOps = KeychainOps()) { self.ops = ops }
vrecorder/Audio/PCMRollover.swift:35:    /// Return the retained buffers in arrival order and reset the ring.
vrecorder/App/AppEnvironment.swift:3://  (on-device STT + OpenAI translation, Keychain-backed key) and seeds the key
vrecorder/App/AppEnvironment.swift:15:        let store = KeychainAPIKeyStore()

web search: 
web search: https://github.com/yonaskolb/XcodeGen/blob/2.45.4/Docs/ProjectSpec.md
codex
The configuration route is viable, but the plan cannot defer it to WI-2: XcodeGen’s `info` applies one plist across configurations, while `settings.configs` can select build settings per configuration. A Debug-only scheme therefore needs an explicit config-specific `INFOPLIST_FILE` strategy with complete plist contents; a “partial plist” or standalone `.xcconfig` does not merge `CFBundleURLTypes` into the generated plist.
exec
/bin/zsh -lc 'nl -ba cron-prompts/verify.md && nl -ba .claude/rules/52-test-sim-isolation.md && rg -n "sim-tap|sim-gesture|vrecorder-debug|XCUITest|DebugBridge" .' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 exited 1 in 0ms:
nl: cron-prompts/verify.md: No such file or directory

exec
/bin/zsh -lc "rg --files | rg 'verify\\.md"'$|cron|sim-tap|gesture'"'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
dev-docs/无人值守开发-goal与cron辨析.html

exec
/bin/zsh -lc "rg --hidden --files | rg 'verify\\.md"'$|cron|sim-tap|gesture'"'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
.claude/cron-prompts/bugfix.md
.claude/cron-prompts/feature.md
.claude/cron-prompts/watchdog.md
.claude/cron-prompts/verify.md
dev-docs/无人值守开发-goal与cron辨析.html

exec
/bin/zsh -lc 'nl -ba .claude/cron-prompts/verify.md && rg -n --hidden "sim-tap|sim-gesture|vrecorder-debug|XCUITest|DebugBridge" .' in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	First, log the fire: run `mkdir -p .claude/cron-logs && echo "$(date -Iseconds) verify FIRED" >> .claude/cron-logs/verify.log`. Then perform the task below. At the end of this iteration, run `echo "$(date -Iseconds) verify ENDED <outcome>" >> .claude/cron-logs/verify.log` where <outcome> is one of: work_done | no_work_in_scope | blocked | error.
     2	
     3	Run the `/verify` skill with no explicit target. It auto-picks per its Pick order — the `awaiting-device-verification` GH-issue backlog first (Mode A, bug close-gate verification), then `DONE` features needing Gate-5 (Mode B, feature verification). The skill owns the whole verification workflow: both modes, the CU-free method (XCUITest + DebugBridge, with `scripts/sim-tap.sh` (idb) as the gesture fallback for taps/swipes the first two can't express — see `docs/subsystems/sim-gesture-driver.md`), the UDID-pinned simulator, the close gate, the scope guardrail, and the known harness gaps.
     4	
     5	Map the skill's result to the ENDED outcome: `work_done` if it verified and closed or flipped at least one target; `no_work_in_scope` if nothing needed (or could be) verified this iteration; `blocked` if a required tool/harness was genuinely unavailable; `error` on failure.
     6	
     7	Verification scope only — if the skill discovers a bug it FILES it (GH issue + `docs/bugs.md` row) but never fixes it; fixes are the bugfix cron's job.
./AGENTS.md:18:Grafted from vmark for `/feature-workflow` (planner / implementer / auditor / verifier / spec-guardian / impact-analyst / test-runner / release-steward / manual-test-author). **They still reference vmark's Tauri/React/tiptap skills — retarget those to iOS (Swift/SwiftUI/XCUITest) before relying on them.** See `.claude/agents/README.md`.
./AGENTS.md:50:  - **Features**: `DONE` means "merged with passing tests". Closing requires `VERIFIED`: every acceptance criterion exercised end-to-end (XCUITest, scripted verification harness, or an explicit on-device manual verification log). For pipeline features, "end-to-end" means against a real ASR/translation backend or a recorded-session replay — not just in-memory mocks.
./dev-docs/verification/feature-2-20260614.md:22:| 1 | Tapping "API 密钥" opens the entry sheet | Wired via `.sheet`; build + launch clean. Tap not driveable headlessly (no idb/sim-tap). | logic+build pass; **tap deferred** |
./dev-docs/verification/feature-2-20260614.md:43:  headless environment has no tap driver (idb / sim-tap absent — confirmed). The
./dev-docs/plans/20260615-feature-6-verification-harness.md:1:# Feature #6 — Verification harness (XCUITest + DebugBridge)
./dev-docs/plans/20260615-feature-6-verification-harness.md:12:(XCUITest + a `vrecorder-debug://` DebugBridge + a gesture fallback) that does NOT
./dev-docs/plans/20260615-feature-6-verification-harness.md:19:**In:** an XCUITest target; accessibility identifiers on the key UI; a DEBUG-only
./dev-docs/plans/20260615-feature-6-verification-harness.md:20:`vrecorder-debug://` DebugBridge that drives `LiveSessionModel` deterministically
./dev-docs/plans/20260615-feature-6-verification-harness.md:22:XCUITest that verifies feature #2's API-key sheet flow end-to-end.
./dev-docs/plans/20260615-feature-6-verification-harness.md:24:— bugs #1/#3/#5/#9 stay `awaiting-device-verification`); idb/`sim-tap.sh` gesture
./dev-docs/plans/20260615-feature-6-verification-harness.md:25:fallback (optional follow-up — XCUITest's own tap/typeText covers this feature's
./dev-docs/plans/20260615-feature-6-verification-harness.md:29:- **WI-1 — XCUITest target + a11y ids + smoke**
./dev-docs/plans/20260615-feature-6-verification-harness.md:39:- **WI-2 — DebugBridge (DEBUG only)**
./dev-docs/plans/20260615-feature-6-verification-harness.md:40:  - NEW `vrecorder/Debug/DebugBridge.swift` (`#if DEBUG` whole file): parses
./dev-docs/plans/20260615-feature-6-verification-harness.md:41:    `vrecorder-debug://inject?…` URLs and drives `LiveSessionModel` via its
./dev-docs/plans/20260615-feature-6-verification-harness.md:43:    seed deterministic transcript states; `vrecorder-debug://reset` clears.
./dev-docs/plans/20260615-feature-6-verification-harness.md:44:  - MODIFY `vrecorder/App/VRecorderApp.swift`: `.onOpenURL` (DEBUG) → DebugBridge,
./dev-docs/plans/20260615-feature-6-verification-harness.md:49:  - `project.yml`: register `vrecorder-debug` URL scheme (DEBUG via
./dev-docs/plans/20260615-feature-6-verification-harness.md:59:  the demo simulator) — the DebugBridge reuses them, inventing no new state API.
./dev-docs/plans/20260615-feature-6-verification-harness.md:61:- **Industry:** XCUITest + accessibility identifiers + a debug URL scheme to drive
./dev-docs/plans/20260615-feature-6-verification-harness.md:63:- **Rejected:** (a) idb/`sim-tap.sh` as the primary driver — XCUITest's native
./dev-docs/plans/20260615-feature-6-verification-harness.md:66:  (c) Driving the real recognizer in UI tests — non-deterministic; the DebugBridge
./dev-docs/plans/20260615-feature-6-verification-harness.md:70:- **WI-1 (foundational)**: XCUITest target + a11y ids + smoke test. Unit/UI-test
./dev-docs/plans/20260615-feature-6-verification-harness.md:72:- **WI-2 (behavioral)**: DebugBridge + App-owns-AppEnvironment wiring. Slice-verify:
./dev-docs/plans/20260615-feature-6-verification-harness.md:73:  a `vrecorder-debug://inject` URL produces the expected on-screen transcript
./dev-docs/plans/20260615-feature-6-verification-harness.md:80:- `vrecorderUITests/DebugBridgeUITests.swift`: `injectURLSeedsTranscript`,
./dev-docs/plans/20260615-feature-6-verification-harness.md:86:- App not built for UI testing → XCUITest target launches its own host (handled by
./dev-docs/plans/20260615-feature-6-verification-harness.md:88:- DebugBridge active only in DEBUG (Release ignores the URL scheme entirely).
./dev-docs/plans/20260615-feature-6-verification-harness.md:89:- Malformed `vrecorder-debug://` URL → no-op, no crash.
./dev-docs/plans/20260615-feature-6-verification-harness.md:90:- Sheet/keyboard timing in XCUITest → use `waitForExistence(timeout:)`, never bare
./dev-docs/plans/20260615-feature-6-verification-harness.md:98:2. A `vrecorder-debug://inject` URL deterministically seeds an on-screen transcript
./dev-docs/plans/20260615-feature-6-verification-harness.md:103:5. No production behavior change; DebugBridge is `#if DEBUG` only.
./dev-docs/plans/20260615-feature-6-verification-harness.md:113:- **XCUITest flakiness**: bounded `waitForExistence`, no sleeps; UDID-pinned sim.
./dev-docs/plans/20260615-feature-6-verification-harness.md:116:- `docs/architecture.md`: note the DebugBridge + UITest target. `README.md`:
./.claude/cron-prompts/verify.md:3:Run the `/verify` skill with no explicit target. It auto-picks per its Pick order — the `awaiting-device-verification` GH-issue backlog first (Mode A, bug close-gate verification), then `DONE` features needing Gate-5 (Mode B, feature verification). The skill owns the whole verification workflow: both modes, the CU-free method (XCUITest + DebugBridge, with `scripts/sim-tap.sh` (idb) as the gesture fallback for taps/swipes the first two can't express — see `docs/subsystems/sim-gesture-driver.md`), the UDID-pinned simulator, the close gate, the scope guardrail, and the known harness gaps.
./.claude/rules/51-no-self-designed-ui.md:51:- **Verification-only artifacts** — XCUITest helpers, DebugBridge surfaces (`vrecorder-debug://...`), `dev-docs/verification/*` markdown — these are dev-only, never user-visible in Release.
./.claude/rules/47-feature-workflow.md:86:- **Behavioral WIs** (anything that changes app behavior, persistence, networking, backup format, reader rendering, or UI flow): **slice verification** — exercise the slice end-to-end against the real environment available at this point. Run on iPhone 17 Pro Simulator with `vrecorder-debug://` harness; for backup/network features, against a real WebDAV server (or local Docker WebDAV equivalent); for reader features, with a fixture book.
./.claude/rules/10-tdd.md:150:- For deterministic timing, use a clock probe pattern (see `DebugBridgeTests.SlowDebugBridgeContext`).
./.claude/rules/52-test-sim-isolation.md:17:verification traffic (`scripts/sim-tap.sh`, `idb`, `xcrun simctl openurl
./.claude/rules/52-test-sim-isolation.md:18:vrecorder-debug://…`, `simctl io`, screenshots), the two contend for the one device
./.claude/rules/52-test-sim-isolation.md:67:   sim-driving (`sim-tap` / `idb` / `simctl openurl eval` / `simctl io` /
./.claude/rules/52-test-sim-isolation.md:127:#   ... drive <other-udid> with sim-tap in a separate step ...
./docs/features.md:59:| 6   | 验证 harness（XCUITest + DebugBridge + sim-gesture 驱动） | tooling/test | High | TODO | cron verify.md 假设的 harness（XCUITest target / vrecorder-debug:// DebugBridge / scripts/sim-tap.sh / sim-gesture-driver 文档）都不存在，导致 verify cron 全 blocked。建之以解锁 UI/可脚本化验证；音频真机验证仍需人工。GH issue filed. Mirror: no. |
./.claude/agents/README.md:15:| `test-runner` | run unit + (E2E) | `scripts/run-tests.sh` + XCUITest, not Tauri MCP E2E |

exec
/bin/zsh -lc "rg --hidden --files .claude | rg '/verify/|verify.*SKILL|SKILL\\.md'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 exited 1 in 0ms:
exec
/bin/zsh -lc "nl -ba vrecorder/Security/APIKeyStore.swift && nl -ba .claude/rules/52-test-sim-isolation.md | sed -n '1,145p'" in /Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2
 succeeded in 0ms:
     1	//  APIKeyStore.swift
     2	//  Purpose: Keychain-backed storage for provider API keys. The key is the only
     3	//  secret in the app and must never live in UserDefaults or the bundle.
     4	//  A protocol lets tests substitute an in-memory store; an injectable KeychainOps
     5	//  seam lets tests exercise SecItem status handling (feature #2).
     6	
     7	import Foundation
     8	import Security
     9	
    10	protocol APIKeyStoring: Sendable {
    11	    func key(for provider: String) -> String?
    12	    /// Returns true on a confirmed write/delete. An update that fails (other than
    13	    /// "not found") leaves the previous key untouched — never destroys it.
    14	    @discardableResult
    15	    func setKey(_ value: String?, for provider: String) -> Bool
    16	}
    17	
    18	/// Injectable Security operations so the update→add→preserve logic is testable
    19	/// with scripted `OSStatus` (audit-3 #2: Sendable + @Sendable closures).
    20	struct KeychainOps: Sendable {
    21	    var update: @Sendable (CFDictionary, CFDictionary) -> OSStatus = SecItemUpdate
    22	    var add:    @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemAdd
    23	    var delete: @Sendable (CFDictionary) -> OSStatus = SecItemDelete
    24	    var copy:   @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching
    25	}
    26	
    27	/// Real Keychain implementation (generic password, one item per provider).
    28	struct KeychainAPIKeyStore: APIKeyStoring {
    29	    private let service = "com.vrecorder.app.apikeys"
    30	    private let ops: KeychainOps
    31	
    32	    init(ops: KeychainOps = KeychainOps()) { self.ops = ops }
    33	
    34	    func key(for provider: String) -> String? {
    35	        var query = baseQuery(provider)
    36	        query[kSecReturnData as String] = true
    37	        query[kSecMatchLimit as String] = kSecMatchLimitOne
    38	        var item: CFTypeRef?
    39	        guard ops.copy(query as CFDictionary, &item) == errSecSuccess,
    40	              let data = item as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
    41	        return s
    42	    }
    43	
    44	    @discardableResult
    45	    func setKey(_ value: String?, for provider: String) -> Bool {
    46	        let query = baseQuery(provider)
    47	        guard let value, let data = value.data(using: .utf8) else {
    48	            // Delete path: success or already-absent both count as cleared.
    49	            let status = ops.delete(query as CFDictionary)
    50	            return status == errSecSuccess || status == errSecItemNotFound
    51	        }
    52	        // Atomic: update first (attributes carry ONLY the new data); add only on
    53	        // "not found". Any other update failure leaves the existing key intact.
    54	        let attrs: [String: Any] = [kSecValueData as String: data]
    55	        let updateStatus = ops.update(query as CFDictionary, attrs as CFDictionary)
    56	        if updateStatus == errSecSuccess { return true }
    57	        if updateStatus == errSecItemNotFound {
    58	            var addAttrs = query
    59	            addAttrs[kSecValueData as String] = data
    60	            return ops.add(addAttrs as CFDictionary, nil) == errSecSuccess
    61	        }
    62	        return false
    63	    }
    64	
    65	    private func baseQuery(_ provider: String) -> [String: Any] {
    66	        [kSecClass as String: kSecClassGenericPassword,
    67	         kSecAttrService as String: service,
    68	         kSecAttrAccount as String: provider]
    69	    }
    70	}
    71	
    72	/// In-memory store for tests and previews. `failNextWrite` injects one failure.
    73	final class InMemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    74	    private var storage: [String: String] = [:]
    75	    private var _failNextWrite = false
    76	    private let lock = NSLock()
    77	    init(_ seed: [String: String] = [:]) { storage = seed }
    78	    /// All access guarded by `lock` (audit-G4 Low: was read/written off-lock).
    79	    var failNextWrite: Bool {
    80	        get { lock.withLock { _failNextWrite } }
    81	        set { lock.withLock { _failNextWrite = newValue } }
    82	    }
    83	    func key(for provider: String) -> String? { lock.withLock { storage[provider] } }
    84	    @discardableResult
    85	    func setKey(_ value: String?, for provider: String) -> Bool {
    86	        lock.withLock {
    87	            if _failNextWrite { _failNextWrite = false; return false }   // preserve existing
    88	            storage[provider] = value
    89	            return true
    90	        }
    91	    }
    92	}
    93	
    94	enum APIProvider {
    95	    static let openAI = "openai"
    96	    static let claude = "claude"
    97	}
     1	# 52 — Test / Simulator Isolation (no more ghost `xcodebuild test`)
     2	
     3	## The recurring failure
     4	
     5	`xcodebuild test` wedges: the process sits at **0% CPU with zero output** and
     6	lingers for hours as a "ghost" (the task UI shows it running; `ps` shows it
     7	sleeping forever). It never completes and never fails — it just hangs.
     8	
     9	This has happened **many times**. Every instance shares one cause.
    10	
    11	## Root cause (TWO distinct causes — both observed 2026-05-31)
    12	
    13	### Cause A — simulator contention
    14	
    15	A `xcodebuild test` run boots/installs onto a booted simulator and drives it. If
    16	— while that run is in flight — the SAME simulator (same UDID) is ALSO driven by
    17	verification traffic (`scripts/sim-tap.sh`, `idb`, `xcrun simctl openurl
    18	vrecorder-debug://…`, `simctl io`, screenshots), the two contend for the one device
    19	and the test runner deadlocks. With no timeout, the wedged process ghosts
    20	indefinitely.
    21	
    22	Aggravator: launching the test with `run_in_background: true` and then
    23	immediately starting sim-driving in the next tool call — the collision is
    24	guaranteed, and the ghost is invisible until someone checks `ps`.
    25	
    26	### Cause B — orphaned/wedged build daemon (`SWBBuildService`)
    27	
    28	`xcodebuild test` delegates compilation to Xcode's shared build daemon
    29	`SWBBuildService`. When a hung `xcodebuild` is killed with `kill -9`, the daemon
    30	is **left in a wedged state**. The NEXT `xcodebuild` build then hangs at 0% CPU
    31	with NO compiler children and the **simulator completely idle** — i.e. it looks
    32	identical to Cause A but contention is NOT involved. This is what produced the
    33	"hung again?" recurrence right after killing the first ghost.
    34	
    35	**Therefore:** never `kill -9` a hung `xcodebuild` without ALSO clearing the
    36	daemon: `pkill -9 -x SWBBuildService`. The `scripts/run-tests.sh` watchdog now
    37	does this automatically on timeout. A bare xcodebuild kill is a half-cleanup that
    38	poisons the next run.
    39	
    40	### Cause C — the full suite is just SLOW (not a hang)
    41	
    42	The entire `vrecorderTests` suite takes **>20 min** to build + run (hundreds of
    43	tests incl. slow SwiftUI view tests). Running it as a per-WI gate looks
    44	identical to a hang — `xcodebuild` sits there for 20+ min — but it is genuinely
    45	working (the log shows `◇ Test case … started` lines streaming). Observed
    46	2026-05-31: a clean-environment full-suite run built fine and was mid-tests when
    47	a 20-min watchdog killed it.
    48	
    49	**Therefore: do NOT run the whole `vrecorderTests` suite as a per-WI gate.** Run the
    50	**targeted `-only-testing:` suites that cover the change** — they finish in
    51	seconds to a couple of minutes and are the appropriate gate. Reserve the full
    52	suite for a periodic/CI sweep with a long budget (`TIMEOUT_SECS=2400`+).
    53	
    54	```bash
    55	# Per-WI gate — targeted, fast (seconds):
    56	scripts/run-tests.sh vrecorderTests/DebugCommandTests
    57	# (pass multiple via repeated -only-testing is not supported by the wrapper's
    58	#  single-arg form; run the wrapper once per suite, or extend it if needed.)
    59	
    60	# Full-suite sweep — periodic, long budget:
    61	TIMEOUT_SECS=2400 scripts/run-tests.sh vrecorderTests
    62	```
    63	
    64	## Hard rules
    65	
    66	1. **Never drive a simulator while `xcodebuild test` runs against it.** Tests and
    67	   sim-driving (`sim-tap` / `idb` / `simctl openurl eval` / `simctl io` /
    68	   screenshots / verification) are **mutually exclusive on one UDID**. Serialize:
    69	   finish the test run, THEN drive the sim — or drive a DIFFERENT UDID
    70	   (`TEST_UDID=<other>`).
    71	2. **Always run unit-test gates through `scripts/run-tests.sh`.** It pins the
    72	   destination by UDID, enforces a hard wall-clock timeout (default 900s), waits
    73	   on the exact pid (rule 49), kills the process tree on timeout, and prints one
    74	   unambiguous final line (`RUN-TESTS RESULT: SUCCEEDED|FAILED|TIMEOUT|NO_BOOTED_SIM`).
    75	   A wedge now self-terminates in ≤15 min instead of ghosting for hours.
    76	3. **A `RUN-TESTS RESULT: TIMEOUT` is not a flaky test — it's contention.** Do not
    77	   "retry harder." Confirm nothing is driving the sim, then re-run. If you need
    78	   verification in parallel, boot a second simulator and pass its UDID via
    79	   `TEST_UDID`.
    80	4. **Before ending a turn, confirm no live `xcodebuild`:** `pgrep -x xcodebuild`
    81	   (NOT `pgrep -f xcodebuild` — `-f` matches the pattern inside your own grep
    82	   command line and always returns ≥1, a false positive that has masked real
    83	   state before). Zero = clean.
    84	5. **Never pipe `scripts/run-tests.sh` through `tail` / `grep` / `head`.** `tail
    85	   -N` on a PIPE emits NOTHING until EOF, so it buffers away every streaming `◇
    86	   Test case` marker AND the single `RUN-TESTS RESULT:` line the watchdog exists
    87	   to print. The output file stays empty mid-run, which makes a healthy run and a
    88	   wedged run look identical — you lose the only cheap liveness signal. Let the
    89	   watchdog's stdout go STRAIGHT to the output file (it already self-limits its
    90	   output); read the file or wait for the native completion notification. Origin:
    91	   2026-06-01, a `run-tests.sh … | tail -30` background invocation produced a
    92	   0-byte output file for ~5 min; the run looked ghosted but the empty file was
    93	   just `tail` buffering — the actual diagnosis required `ps`. (If you must
    94	   shorten a FOREGROUND, already-finished log, `tail` the output FILE after the
    95	   RESULT line lands — never insert `tail` into the live pipe.)
    96	
    97	### Diagnosing "is it hung?" — process liveness, NOT the output file
    98	
    99	When a backgrounded test run looks stalled, do NOT infer state from an empty or
   100	silent output file (see rule 5 — it may just be pipe buffering). Infer it from
   101	the **build process**:
   102	
   103	```bash
   104	# A genuine run ALWAYS has a live xcodebuild; during compile, also
   105	# swift-frontend / clang. Zero of these = no work happening, full stop.
   106	ps -Ao pid=,%cpu=,command= | grep -iE "xcodebuild|swift-frontend|clang|xctest|SWBBuildService" | grep -v grep
   107	```
   108	
   109	- **`xcodebuild` present (any CPU, even 0% briefly between phases)** → working;
   110	  wait for the native completion notification.
   111	- **`xcodebuild` totally absent + watchdog/wrapper still "alive"** → ghost. Kill
   112	  the wrapper tree, `pkill -9 -x SWBBuildService` (Cause B), re-run.
   113	- CoreSimulator runtime daemons (`…/RuntimeRoot/…` at 0%) are the booted sim's
   114	  idle background services — unrelated noise, never evidence of a build.
   115	
   116	## Quick reference
   117	
   118	```bash
   119	# Unit-test gate (default vrecorderTests, 15-min watchdog):
   120	scripts/run-tests.sh
   121	
   122	# A single suite, longer budget:
   123	TIMEOUT_SECS=1200 scripts/run-tests.sh vrecorderTests/DebugCommandTests
   124	
   125	# Tests on one sim while verifying on another (true parallelism):
   126	TEST_UDID=<test-sim-udid> scripts/run-tests.sh    # tests here
   127	#   ... drive <other-udid> with sim-tap in a separate step ...
   128	```
   129	
   130	## Relationship to other rules
   131	
   132	- **Rule 49 (background shells):** this rule's watchdog waits on the exact pid and
   133	  is cancelled when the test finishes first — it never re-arms on a future run.
   134	  The `pgrep -f` false-positive warning here is the same class of bug rule 49
   135	  flags for `pgrep -f "xcodebuild test"` waiters.
   136	- **Rule 48 (parallel execution):** "single simulator → serialize" is the Gate-5
   137	  decision-matrix row. This rule makes the test-vs-verification case explicit and
   138	  gives it a tool.

codex
**Findings**

1. **High: DebugBridge cannot implement the planned reset contract.**  
   `pushA`/`pushB` are `internal`, not public, and transcript arrays are `private(set)`. There is no reset API. Injection during an active session could also race with recognizer/demo tasks. See [LiveSessionModel.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Models/LiveSessionModel.swift:16) and [line 86](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Models/LiveSessionModel.swift:86).  
   The plan must add a named `@MainActor` model operation that stops active work and atomically installs or resets a fixture, with unit tests.

2. **High: API-key UI tests are not isolated.**  
   `AppEnvironment` always uses the real Keychain and DEBUG bootstrap may load the developer’s real key. The enter/clear tests would overwrite or delete persistent simulator credentials and become order-dependent. See [AppEnvironment.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/AppEnvironment.swift:14) and [APIKeyBootstrap.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Security/APIKeyBootstrap.swift:11).  
   Add an explicit UI-testing launch mode using a seeded `InMemoryAPIKeyStore`, skipping bootstrap, with per-test initial state.

3. **Medium: DEBUG-only URL registration remains unresolved.**  
   XcodeGen supports `bundle.ui-testing`. An app dependency also supplies `TEST_TARGET_NAME`. However, XcodeGen’s `info` definition generates one plist for every configuration. A partial plist is not merged, and an `.xcconfig` alone cannot express the nested `CFBundleURLTypes` structure.  
   Specify complete Debug/Release plist files selected through `settings.configs.<config>.INFOPLIST_FILE`, with `GENERATE_INFOPLIST_FILE: NO`, or an equally concrete preprocessing design. Add built-product assertions that Debug contains `vrecorder-debug` and Release does not. [XcodeGen specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)

4. **Medium: lifecycle regression mitigation is not represented in the test catalogue.**  
   Root currently owns the environment with `@State` specifically to fix teardown targeting the wrong session. See [RootView.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/RootView.swift:10). Moving that state to `VRecorderApp` is viable:
   `@State` in the App, injected as a plain `let` into RootView.  
   But the promised background-stop regression test is absent and cannot deterministically start a real session. Add a deterministic debug state plus a background/reactivation test, or extract and unit-test the lifecycle handler.

5. **Medium: feature completion claims exceed the planned verification.**  
   Feature #2 has seven acceptance criteria, including Release behavior, invalid input, failure preservation, and clear confirmation. Three Debug UI tests alone cannot justify `VERIFIED`; rerun and record the complete acceptance matrix. See [feature #2 plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260614-feature-2-api-key-entry.md:232).  
   Feature #6 also still includes `sim-tap.sh` and gesture-driver documentation in both the tracker and verify cron, while this plan excludes them. Either retain that scope or split/update the tracker before marking #6 complete. See [features.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/docs/features.md:59) and [verify.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/cron-prompts/verify.md:3).

6. **Medium: WI estimates omit required files and tests.**  
   WI-1 is already at least six authored files plus generated project/version artifacts. WI-2 needs the model fixture API, parser unit tests, UI test, plist configuration, and lifecycle regression coverage, substantially more than three files. A four-WI split remains within rule 47’s medium-feature range and would better separate model/parser foundations from app wiring.

**Verified Assumptions**

- `.onOpenURL` is viable. The installed iOS 26 SwiftUI SDK exposes it, and XCUITest provides `XCUIApplication.open(_:)`.
- `VRecorderApp` currently creates `RootView()` directly in its `WindowGroup`: [VRecorderApp.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/VRecorderApp.swift:9).
- `AppEnvironment` and `LiveSessionModel` are `@MainActor`.
- Make `DebugBridge.handle(_:)` explicitly `@MainActor`. No `Sendable` conformance is needed when URL parsing and mutation remain synchronous on the main actor; avoid detached tasks.
- Accessibility identifiers are invisible verification metadata and are explicitly outside rule 51: [51-no-self-designed-ui.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/rules/51-no-self-designed-ui.md:46).

VERDICT: BLOCK
tokens used
114,504
**Findings**

1. **High: DebugBridge cannot implement the planned reset contract.**  
   `pushA`/`pushB` are `internal`, not public, and transcript arrays are `private(set)`. There is no reset API. Injection during an active session could also race with recognizer/demo tasks. See [LiveSessionModel.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Models/LiveSessionModel.swift:16) and [line 86](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Models/LiveSessionModel.swift:86).  
   The plan must add a named `@MainActor` model operation that stops active work and atomically installs or resets a fixture, with unit tests.

2. **High: API-key UI tests are not isolated.**  
   `AppEnvironment` always uses the real Keychain and DEBUG bootstrap may load the developer’s real key. The enter/clear tests would overwrite or delete persistent simulator credentials and become order-dependent. See [AppEnvironment.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/AppEnvironment.swift:14) and [APIKeyBootstrap.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/Security/APIKeyBootstrap.swift:11).  
   Add an explicit UI-testing launch mode using a seeded `InMemoryAPIKeyStore`, skipping bootstrap, with per-test initial state.

3. **Medium: DEBUG-only URL registration remains unresolved.**  
   XcodeGen supports `bundle.ui-testing`. An app dependency also supplies `TEST_TARGET_NAME`. However, XcodeGen’s `info` definition generates one plist for every configuration. A partial plist is not merged, and an `.xcconfig` alone cannot express the nested `CFBundleURLTypes` structure.  
   Specify complete Debug/Release plist files selected through `settings.configs.<config>.INFOPLIST_FILE`, with `GENERATE_INFOPLIST_FILE: NO`, or an equally concrete preprocessing design. Add built-product assertions that Debug contains `vrecorder-debug` and Release does not. [XcodeGen specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)

4. **Medium: lifecycle regression mitigation is not represented in the test catalogue.**  
   Root currently owns the environment with `@State` specifically to fix teardown targeting the wrong session. See [RootView.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/RootView.swift:10). Moving that state to `VRecorderApp` is viable:
   `@State` in the App, injected as a plain `let` into RootView.  
   But the promised background-stop regression test is absent and cannot deterministically start a real session. Add a deterministic debug state plus a background/reactivation test, or extract and unit-test the lifecycle handler.

5. **Medium: feature completion claims exceed the planned verification.**  
   Feature #2 has seven acceptance criteria, including Release behavior, invalid input, failure preservation, and clear confirmation. Three Debug UI tests alone cannot justify `VERIFIED`; rerun and record the complete acceptance matrix. See [feature #2 plan](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/dev-docs/plans/20260614-feature-2-api-key-entry.md:232).  
   Feature #6 also still includes `sim-tap.sh` and gesture-driver documentation in both the tracker and verify cron, while this plan excludes them. Either retain that scope or split/update the tracker before marking #6 complete. See [features.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/docs/features.md:59) and [verify.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/cron-prompts/verify.md:3).

6. **Medium: WI estimates omit required files and tests.**  
   WI-1 is already at least six authored files plus generated project/version artifacts. WI-2 needs the model fixture API, parser unit tests, UI test, plist configuration, and lifecycle regression coverage, substantially more than three files. A four-WI split remains within rule 47’s medium-feature range and would better separate model/parser foundations from app wiring.

**Verified Assumptions**

- `.onOpenURL` is viable. The installed iOS 26 SwiftUI SDK exposes it, and XCUITest provides `XCUIApplication.open(_:)`.
- `VRecorderApp` currently creates `RootView()` directly in its `WindowGroup`: [VRecorderApp.swift](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/vrecorder/App/VRecorderApp.swift:9).
- `AppEnvironment` and `LiveSessionModel` are `@MainActor`.
- Make `DebugBridge.handle(_:)` explicitly `@MainActor`. No `Sendable` conformance is needed when URL parsing and mutation remain synchronous on the main actor; avoid detached tasks.
- Accessibility identifiers are invisible verification metadata and are explicitly outside rule 51: [51-no-self-designed-ui.md](/Users/deanlee/Documents/Claude/Projects/agents/vrecorder-v2/.claude/rules/51-no-self-designed-ui.md:46).

VERDICT: BLOCK
