# Bug Tracker

Track bugs here. Tell the agent "fix bug #N" to start a fix.

## Rules

> **Binding for this file.** The rules and workflow below govern every change made to `docs/bugs.md`. AGENTS.md treats them as the authoritative bug-tracker workflow.

- **Bugs vs features**: If something was implemented but doesn't work correctly, it is a **bug** — track it here. If something was never implemented, it is a **feature** — track it in `docs/features.md`. Never mix them.
- **Partial implementations**: If something is partially implemented, the broken part is a bug here; the missing capability is a feature in `docs/features.md`. Link them.
- **Source of truth**: This **Summary table** is the single source of truth for bug status.
- **Open bug details**: Bugs with status TODO/IN PROGRESS/REOPENED should have an entry in `## Open Bug Details` with repro context. Move to archive on FIXED.
- **History**: Root causes, solutions, and lessons for FIXED bugs are archived in `archive/bugs-history.md`.

## How to use

1. Add bugs as you find them (fill in Summary and File/Area at minimum)
2. Tell the agent: "fix bug #N" — it will follow the workflow below
3. Agent updates Status when done

- **Bug fix workflow** (follow this order for every bug):
  1. **Understand**: Read the file/area, reproduce the symptom, identify root cause (not just location). If it is not a bug, move it to `docs/features.md`.
  2. **RED**: Write a failing test that proves the bug exists.
  3. **GREEN**: Minimal fix to make the test pass.
  4. **REFACTOR**: Clean up without changing behavior.
  5. **Verify**: Run tests, confirm the fix, check for regressions.
  6. **Track**: Update status in the Summary table to FIXED.
  7. Do NOT commit unless explicitly requested.
  8. Record cause, solution, and lessons in `archive/bugs-history.md`. Remove the bug's entry from `## Open Bug Details`.
- **GitHub Issue closure** (post-merge finalizer — see `AGENTS.md` for full policy):
  - If the bug has a `GH: #N` in Notes, close the GitHub Issue only after:
    1. Status is FIXED in this file.
    2. Fix is merged to `main`.
    3. Closure comment posted with commit SHA, test evidence, and cause summary.
  - PRs use `Refs #N`, not `Fixes #N` (prevents premature auto-close).

## Statuses

- `TODO` — not started
- `IN PROGRESS` — being worked on
- `FIXED` — fix verified in working tree (not necessarily committed)
- `PARTIALLY FIXED` — primary cause / mitigation shipped, but a documented follow-up scope remains tracked in Notes. The GH issue stays open until the remaining scope lands or is explicitly deferred.
- `REOPENED` — previously fixed but regressed; link to original fix
- `DUPLICATE` — duplicate of another bug; note `DUPLICATE OF #N`
- `WONT FIX` — intentional behavior or out of scope

## Bugs (summary)

| # | Summary | File/Area | Severity | Status | Notes |
|---|---------|-----------|----------|--------|-------|
| 1 | VAD rotation truncates the start of the next utterance | `AudioTapBridge` / `AppleSpeechRecognizer` | High | PARTIALLY FIXED | Surfaced by feature-#2 Gate-4 audit (prepush-64afb36); pre-existing feature-#1 pipeline residual on main. Bridge nulls the request at `endAudio()` but the new request installs only after the async final callback — audio in that gap is dropped. Fix: segment-ID parallel rotation or a bounded PCM rollover buffer. Demo uses the simulator/scripted path, so demo unaffected. GH: #3. Fixed by bounded PCMRollover replayed into the next request; PCMRolloverTests cover the ring. Device verify (real-mic) deferred — close-gate. PARTIAL: realistic (short) rotation gap fixed by the rollover ring + VAD replay; a pathologically long gap (>ring cap during sustained speech) can still truncate — robust fix needs a dedicated VAD stage, tracked as feature #4. |
| 2 | Unbounded partial-result stream + per-callback Task accumulation | `AppleSpeechRecognizer` | Medium | TODO | Same audit; long live sessions can accumulate partials/tasks. Fix: bounded event pump that coalesces partials, preserves finals. GH: #4. |
| 3 | AirPods/Bluetooth mic unavailable + route-add ignored | `AudioSessionController` | Medium | FIXED | From bug-#1 Gate-4 audit. `.playAndRecord` omits `.allowBluetoothHFP`; only `.oldDeviceUnavailable` handled. Fix: add BT option + handle `.newDeviceAvailable` (reconfigure/restart). GH: #5. |

> Interruption auto-resume (related Gate-4 Medium) is tracked as **feature #3**, not a bug.

## Open Bug Details

### Bug #1 — VAD rotation truncates next utterance
Repro: continuous real-mic speech with brief pauses. Expected: each utterance
recognized whole. Actual: the first audio after a pause can be dropped during the
request-rotation gap, fragmenting the next utterance. (Real-mic only; the demo
simulator path doesn't exercise the recognizer.)

### Bug #2 — Unbounded partial stream
Repro: very long live session with a slow consumer. Expected: bounded memory.
Actual: partial events + main-actor Tasks can accumulate without bound.

<!-- For each TODO/IN PROGRESS/REOPENED bug, add a short entry here.
     Max 6 lines per bug: repro, expected, actual. Remove on FIXED (move to archive). -->
