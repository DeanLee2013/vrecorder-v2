# Feature #2 — API key entry (Keychain editor)

> Gate-1 plan, **revision 4** (addresses Codex plan-audit rounds 1–3).
> Status: PLANNED after Gate-2 audit passes.
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
  - nil value: `SecItemDelete`; success = `errSecSuccess || errSecItemNotFound`.
- `InMemoryAPIKeyStore.setKey` returns `Bool` too (always succeeds; supports a
  `failNextWrite` flag for failure-injection tests).

### Injectable Security boundary (audit-2 #3)

To actually test the `SecItemUpdate` → `SecItemAdd` → preserve-old-key logic
(InMemory can't exercise `OSStatus` handling), `KeychainAPIKeyStore` takes an
injected operation seam:

```swift
struct KeychainOps: Sendable {                // Sendable — stored in a Sendable store (audit-3 #2)
    var update: @Sendable (CFDictionary, CFDictionary) -> OSStatus = SecItemUpdate
    var add:    @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemAdd
    var delete: @Sendable (CFDictionary) -> OSStatus = SecItemDelete
    var copy:   @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching
}
```

`KeychainAPIKeyStore` gets an explicit `init(ops: KeychainOps = KeychainOps())`.
Scripted test state (the status sequence + a call counter) is held behind a
lock/atomic so the `@Sendable` closures stay race-free (the SecItem fns are
themselves thread-safe).

Tests inject a `KeychainOps` returning scripted status sequences (e.g.
`update→errSecDuplicateItem` then assert old key preserved; `update→errSecItemNotFound`
→ `add→errSecSuccess`; `add→failure` → old key untouched). `KeychainAPIKeyStoreTests`
become real status-sequence tests, not InMemory stand-ins.

## Surface area (file-by-file)

- **MODIFY `vrecorder/Security/APIKeyStore.swift`** — protocol `setKey` returns
  `Bool` (atomic update/add, see above); both implementations updated.
- **NEW `vrecorder/Security/APIKeyEntryModel.swift`** — `@MainActor @Observable`
  view-model; the **single owner** of UI state (audit-1 #3):
  - `var draft: String = ""`
  - `private(set) var hasExistingKey: Bool` — set in `init` and after save/clear
  - `private(set) var maskedExisting: String?` — recomputed on the same events
  - `private(set) var saveError: Bool = false`
  - `var canSave: Bool` — `Self.isValid(draft)`
  - `func save() -> Bool` — guards on `canSave` (so a direct call can't bypass the
    disabled button), trims, atomic write; on success refreshes state + clears
    `draft`; on failure sets `saveError`, keeps state, returns false
  - `@discardableResult func clear() -> Bool` — removes key; on failure sets
    `saveError`, **retains** `hasExistingKey`/`maskedExisting` (a failed delete
    must not flip the UI to 未配置) (audit-2 #4)
  - `static func isValid(_:) -> Bool` — provider-compatible (audit-2 #5): after
    trimming surrounding whitespace, the key must match
    `^sk-[A-Za-z0-9_-]{13,197}$` — i.e. `sk-` prefix, **ASCII** alphanumeric +
    `-`/`_` only (rejects emoji/CJK/control/internal whitespace), **total length
    16–200** (3 prefix + 13..197 body) (audit-3 #3). Boundary tests at total
    length 15 (reject), 16 (accept), 200 (accept), 201 (reject).
  - `static func mask(_:) -> String?` — reveal `sk-…` + last 4 **only when total
    length ≥ 12**; otherwise return `"已配置"` (never the whole secret) (audit-1 #4).
  - Injected `APIKeyStoring` (mockable; `InMemoryAPIKeyStore` exists).
- **NEW `vrecorder/Views/APIKeyEntryView.swift`** — light-scope sheet per
  `dev-docs/designs/api-key-entry/`. **Builds its own card/rows from `VR` tokens**
  — it does NOT reuse `SettingsScreen`'s `group`/`rowChrome`/`cycleRow` (those are
  `private`) (audit-1 #6). `SecureField` for entry; uses system sheet chrome (no
  hand-set radius; the CSS "sheet 28" is not a Swift token) (audit-1 #6).
  **Ownership (audit-2 #6):** the View owns exactly one `APIKeyEntryModel` via
  `@State`, constructed in the View's `init` from the injected `any APIKeyStoring`
  (`_model = State(initialValue: APIKeyEntryModel(store: store))`). The model is
  the single source of truth; the View never reads the store directly.
- **MODIFY `vrecorder/Views/SettingsScreen.swift`** — inject
  `store: any APIKeyStoring`; the "API 密钥" row presents `APIKeyEntryView` via
  `.sheet`; `apiKeyConfigured` becomes local `@State`, refreshed in the sheet's
  `onDismiss` by re-reading the store (single refresh path, no duplication).
- **MODIFY `vrecorder/App/RootView.swift`** — pass `env.keyStore` into Settings.
- **`xcodegen generate`** required (new files; checked-in project has explicit
  file refs) (audit-1 #6).
- **Files OUT of scope**: engine selection, pipeline, audio, demo simulator,
  feature #3, the Claude engine.

## Prior art / project precedent / rejected alternatives (rule 47, audit-3 #5)

**Project precedent reused:**
- `APIKeyStoring` / `KeychainAPIKeyStore` / `InMemoryAPIKeyStore` + `APIProvider`
  (feature #1, `vrecorder/Security/`) — this feature adds a model + view over the
  existing store; it does not introduce a new persistence layer.
- The `@MainActor @Observable` view-model + `@State`-owned-in-`init` pattern is
  exactly how `LiveScreen` owns `LiveSessionModel` (feature #1) — reused verbatim.
- Light-scope `VR` design tokens + grouped-card visual language from
  `SettingsScreen` (feature #1) — reused (tokens, not the private helpers).
- The audit-driven error taxonomy (`PipelineError`) precedent: surface failures
  as typed state, never silently — mirrored by `saveError`/`clear() -> Bool`.

**Industry prior art:** SwiftUI `SecureField` + Keychain `SecItemUpdate`-first
(not delete-then-add) is the standard iOS pattern for editable secrets; BYOK key
entry mirrors common client apps that store a user-supplied provider key in the
Keychain.

**Rejected alternatives:**
- *System `UIAlertController` text field for entry* — minimal, but clashes with
  the designed light-scope card system; user chose the design-system sheet.
- *Push via `NavigationStack`* — RootView uses manual ZStack navigation; a sheet
  is lighter than introducing a NavigationStack for one screen.
- *Keep delete-then-add in the store* — rejected: destroys the old key on a
  failed write and opens a missing-key window for concurrent translation.
- *Validate only "non-empty"* — rejected: lets emoji/CJK/garbage through; a
  provider-shaped regex catches paste errors early.

## Work items (audit-1 #8 resolved — ONE cohesive WI/PR)

- **WI-1 (behavioral)** — atomic store + `APIKeyEntryModel` + `APIKeyEntryView` +
  Settings/Root wiring, in **one PR**. Foundational logic (store, model) is
  unit-tested; the UI slice is simulator-verified. Small enough for a single
  audit + verification gate.

## Test catalogue (audit-1 #7)

`vrecorderTests/APIKeyEntryModelTests.swift`:
- `isValidRejectsEmptyWhitespaceAndShort` / `isValidRejectsNonSkPrefix`
- `isValidRejectsInternalControlOrWhitespace`
- `isValidAcceptsWellFormedSkKey`
- `saveTrimsPersistsAndClearsDraft`
- `saveGuardsOnValidity` (direct `save()` with invalid draft is a no-op, returns false)
- `saveFailurePreservesPreviousKeyAndSetsError` (InMemory `failNextWrite`)
- `clearRemovesKeyAndUpdatesState`
- `maskShowsOnlyLast4` / `maskShortSecretDoesNotRevealIt` / `maskNilWhenAbsent`
- `hasExistingKeyReflectsStoreOnInitAndAfterOps`

`vrecorderTests/KeychainAPIKeyStoreTests.swift` (injected `KeychainOps` with
scripted `OSStatus` — real status-handling coverage, audit-2 #3):
- `updateSuccessReturnsTrueWithoutAdd`
- `updateNotFoundFallsBackToAdd`
- `addFailureReturnsFalseAndLeavesOldKey` (no destructive delete)
- `updateFailureOtherThanNotFoundPreservesOldKey`
- `clearSuccess` / `clearNotFoundCountsAsSuccess` / `clearFailureReturnsFalse`
- Real-Keychain round-trip (`setThenGet`, `clearThenGetNil`) runs on the simulator
  in Gate-5 verification, not in the unit suite.

Plus `APIKeyEntryModelTests`: `clearFailureRetainsConfiguredStateAndSetsError`.

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
