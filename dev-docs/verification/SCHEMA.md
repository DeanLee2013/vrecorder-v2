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
