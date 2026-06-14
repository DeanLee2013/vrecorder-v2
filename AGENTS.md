# AGENTS.md

Shared instructions for all AI agents (Claude, Codex, etc.) working on **vrecorder-v2** — an iOS simultaneous-interpretation (real-time speech translation) app. A clean restart of the vrecorder project: the governance skeleton (rules, hooks, cron prompts, scripts) is the proven vrecorder/vmark iOS workflow, but the codebase starts from zero — with one new thing wired from commit #1: a **commit-time Codex audit gate** (see below).

> **Inherited-rules note.** The files under `.claude/rules/` were proven on `vrecorder` and still use the name `vrecorder` (and `vrecorderTests`, `com.vrecorder.app`, etc.) as the running example. Read those as **placeholders for the vrecorder-v2 equivalents** — apply the same discipline to this project's own target/bundle/test names once they exist. The rules are the contract; the example names are illustrative.

## Commit-time audit gate (the reason vrecorder-v2 exists)

The single thing vrecorder-v2 adds over a normal restart: **new code is independently audited before it leaves your machine.** A git `pre-push` hook (`scripts/git-hooks/pre-push`) runs an independent Codex audit (`scripts/run-codex.sh`, ChatGPT-subscription auth — **no OpenAI API key**) over the changed Swift files against `dev-docs/audit/DIMENSIONS-ios.md`, and **blocks the push** on any Critical/High finding. The audit artifact lands in `.claude/codex-audits/`.

- **Install once after `git init`/clone**: `bash scripts/git-hooks/install.sh`
- **Trigger**: every `git push`. (Per-commit was rejected — a Codex audit takes minutes; pre-push audits the batch at the moment it becomes shared.)
- **Bypass intentionally** (say why): `git push --no-verify` or `SKIP_AUDIT=1 git push`.
- Tool failure (timeout/auth) does **not** hard-block — it writes the artifact and lets you review; only a real `VERDICT: BLOCK` blocks.

## Subagents (`.claude/agents/`)

Grafted from vmark for `/feature-workflow` (planner / implementer / auditor / verifier / spec-guardian / impact-analyst / test-runner / release-steward / manual-test-author). **They still reference vmark's Tauri/React/tiptap skills — retarget those to iOS (Swift/SwiftUI/XCUITest) before relying on them.** See `.claude/agents/README.md`.

## Project

- **Stack**: Swift 6 (strict concurrency), SwiftUI, SwiftData, AVAudioEngine, Speech / ASR, iOS 17+.
- **Core pipeline**: audio capture → VAD/segmentation → streaming ASR → incremental translation → TTS / bilingual subtitle display. Each stage is actor-isolated with explicit streaming protocols (partial/final events).
- Read `docs/architecture.md` before making any code changes. Update it when adding new layers, patterns, services, or changing how components communicate.
- Use English in code, comments, and docs unless another language is requested.

## Working agreement

- Run `git status -sb` at session start.
- Read relevant files before editing.
- Keep diffs focused; avoid drive-by refactors.
- Do not commit unless explicitly requested.
- Keep code files under ~300 lines (split proactively).
- Keep features local; avoid cross-feature imports unless truly shared.
- **Research before building**: for new features, search for industry best practices, established conventions, and proven solutions (web search, official docs, prior art in popular open-source projects). Don't invent when a well-tested pattern exists.
- **Edge cases are not optional**: brainstorm as many as possible — empty input, nil, max values, concurrent access, Unicode/CJK, RTL text, rapid repeated actions, network failures, permission denials, and audio-specific ones: audio session interruptions (phone call, Siri, alarm), route changes (AirPods connect/disconnect, speaker↔receiver), backgrounding mid-stream, mic permission revoked mid-session, silence/noise-only input, very long sessions, ASR partial-result retraction, translation provider timeouts and rate limits. Write tests for every one.
- **Test-first is mandatory** for new behavior: failing test (RED) → minimal implementation (GREEN) → refactor (REFACTOR). Exceptions: pure UI layout, docs, config. Full scope in `.claude/rules/10-tdd.md`.
- **Deterministic audio fixtures**: tests that need audio use pre-recorded fixture files (short WAV/CAF clips covering speech, silence, noise, CJK speech) — never live mic input in automated tests. Streaming stages are tested against recorded event sequences (partial/final transcripts) so runs are reproducible.
- **Engine abstraction**: ASR, translation, and TTS providers sit behind protocols (e.g. `TranslationEngine`) so on-device and cloud implementations are swappable and mockable. Capability differences (offline support, language pairs, latency class) are declared, not hard-coded at call sites.
- Default simulator: **iPhone 17 Pro** (Dynamic Island — catches safe-area bugs). Note the simulator cannot exercise real mic capture quality, haptics, or real interruption timing — those legs need a physical device and are tracked in verification logs.
- **Version bump per PR**: every PR includes a `chore: bump version to X.Y.Z` commit as its last commit — patch for fixes/docs/chores, minor for new features, major for breaking changes. Versions live in `project.yml` (`MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`); run `xcodegen generate` after editing. See `.claude/rules/40-version-bump.md`.
- **Docs sync per PR**: when a PR adds a service, schema, notification, environment key, or user-visible feature, update `docs/architecture.md` and/or `README.md` in the same PR (separate commit before the version bump). See `.claude/rules/24-doc-sync.md`.

## Gates and workflows

- **Feature implementation workflow** (binding 6-gate sequence — never skip a gate): Plan → Independent plan audit → TDD implementation → Implementation audit loop → Device/integration verification → Merge. Full rule at `.claude/rules/47-feature-workflow.md`.
- **Merge gate — fix-or-implement**: a PR that references an open bug (`Refs #N` against `docs/bugs.md`) does not merge until that bug's status is `FIXED`. A PR that references an open feature does not merge until the feature reaches `DONE`. Pure meta-process changes (rules, tooling, repo organization) are exempt.
- **Close gate — verified, not just merged**: a GitHub Issue does NOT close until the work is verified end-to-end against a real environment:
  - **Bugs**: `FIXED` means "code on main with passing tests". Closing the GH issue additionally requires device verification — run the original repro on a device/simulator and confirm the symptom is gone. Apply the `awaiting-device-verification` label between merge and verification. Narrow exception for failure modes that physically cannot be reproduced on a device (races, fault-injection paths): close with a high-fidelity integration test through the real subsystem boundaries + the `verification-exception` label + a closure comment citing the test and its evidence file in `dev-docs/verification/`.
  - **Features**: `DONE` means "merged with passing tests". Closing requires `VERIFIED`: every acceptance criterion exercised end-to-end (XCUITest, scripted verification harness, or an explicit on-device manual verification log). For pipeline features, "end-to-end" means against a real ASR/translation backend or a recorded-session replay — not just in-memory mocks.
  - Closure comments cite commit SHA + what was tested + what was observed. Until then the issue stays open with a "shipped in vX.Y.Z, awaiting verification" comment.
- **UI/UX from committed designs only**: if work needs UI on a surface not depicted in a committed design bundle under `dev-docs/designs/...`, do NOT invent it. File a GH issue `Design needed: <surface> for feature #<N>` (labels `enhancement` + `needs-design`), mark the row `BLOCKED: needs-design (#<issue>)`, and wait for the design. Full rule at `.claude/rules/51-no-self-designed-ui.md`.
- **Parallel execution**: follow `.claude/rules/48-parallel-execution.md` — parallelism is an isolation tool first, a speed tool second; author/auditor separation; one writer per file/area; worktree subagents must `cd` into the worktree at the start of every Bash call.
- **Background shells**: follow `.claude/rules/49-background-shells.md` — wait on identity (exact PID, sentinel file), never `pgrep -f` a tool name; one async job = one owner = one completion channel.
- **Simulator/test isolation**: never drive the simulator (taps, openurl, screenshots) while an `xcodebuild test` run is in flight against the same UDID. See `.claude/rules/52-test-sim-isolation.md`.

## Task workflow (three files, one flow)

The `## Rules` section at the top of each tracker is **binding** — the authoritative workflow for that file:

- `docs/tasks.md` — **inbox**. User writes free-form descriptions. Agent triages (classify only; never fix or implement during triage).
- `docs/bugs.md` — **bug tracker**. Something implemented but broken. Workflow: Understand → RED → GREEN → REFACTOR → Verify → Track.
- `docs/features.md` — **feature tracker**. Something never implemented. Must reach `PLANNED` (problem, scope, edge cases, test plan, acceptance criteria) before `IN PROGRESS`. Exception: features resolved incidentally by a bug fix.

Key rules: broken implementation → bugs; never implemented → features; never mix. Triage is classification only.

## GitHub Issues (mechanical mirror — every feature + every bug gets one)

- **When to create — features**: every feature reaching `PLANNED` gets a GH issue. Mechanical trigger: status = PLANNED + no `GH: #N` in Notes → create. Idempotent: skip if `GH: #N` present.
- **When to create — bugs**: every new bug row gets a GH issue. Mechanical trigger: new row + no `GH: #N` in Notes → create. Idempotent.
- **When NOT to create**: status `DEFERRED`, `WONT DO`, `DUPLICATE`, or resolved incidentally by a bug fix.
- **Local-only escape hatch**: `Mirror: no` in the Notes column skips creation.
- **GH issue body = pointer, not second source of truth**: title `Feature #N: <summary>` or `Bug #N: <summary>`; body links back to the tracker row, copies acceptance criteria once, and states "Source of truth: `docs/features.md`" (or `docs/bugs.md`). Scope changes happen in the markdown tracker; material GH comments are ported back in the same PR.
- **On create**: add `GH: #123` to Notes. Labels: `bug` or `enhancement`, plus `severity:high`/`severity:medium` when warranted.
- **PRs use `Refs #N`**, not `Fixes #N` (prevents premature auto-close). Exception: small single-issue fixes may use `Fixes #N`.
- **On resolve** (post-merge finalizer; never close before merge AND verification — see close gate): verify tracker status is terminal-verified → verify fix is on `main` → run the verification pass → post closure comment (commit SHA, what was tested, what was observed, cause/acceptance summary) → `gh issue close #N`.
- **Partial delivery**: keep the issue open; use a checklist or split follow-ups.

## AI coding tool auth

- Prefer subscription auth over API keys (Claude Code: Claude subscription; Codex CLI: `codex login` with ChatGPT Plus/Pro). API keys are a fallback for light/automated usage.
