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
| 6   | 验证 harness（XCUITest target + DebugBridge + UI-test 隔离） | tooling/test | High | PLANNED | Plan `dev-docs/plans/20260615-feature-6-verification-harness.md` (r4, Gate-2 audit 3 rounds → rule-47 cap). 4 WIs: 模型 fixture API / UITest target+a11y+launch-mode / DebugBridge+plist+lifecycle / feature#2 UI 冒烟+harness 证据。**不**含 idb 手势驱动（拆为 feature #7）。GH: #13. Mirror: no. |
| 7   | idb 手势驱动 fallback（sim-tap.sh + sim-gesture-driver 文档） | tooling/test | Low | TODO | 从 feature #6 拆出：XCUITest 的 tap/typeText 覆盖 #6；idb 提供 XCUITest 无法表达的手势（多指/精确滑动）。需 idb 安装。GH issue filed. Mirror: no. |

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
