# vrecorder-v2

A clean restart of the vrecorder iOS simultaneous-interpretation app — **built from
commit #1 with an unattended-development governance workflow and a commit-time
independent audit gate.**

## What makes this restart different

Every push is independently audited before it leaves the machine. A git `pre-push`
hook runs a Codex audit (ChatGPT-subscription auth — no OpenAI API key) over the
changed Swift, and blocks the push on Critical/High findings. That gate exists from
the very first commit, not bolted on later. See `AGENTS.md` → "Commit-time audit gate".

## First-time setup

```bash
git init                       # if not already a repo
bash scripts/git-hooks/install.sh   # installs the pre-push Codex audit gate
codex --version                # confirm Codex CLI present (ChatGPT login, no API key)
```

After that, `git push` triggers the audit automatically. Bypass intentionally with
`git push --no-verify` (and say why).

## Layout

```
AGENTS.md / CLAUDE.md      # the contract every AI agent reads first
.claude/
  settings.json            # hook wiring (evidence, GH mirror, audit artifact, Stop checks)
  rules/                   # the binding workflow (TDD, 6-gate feature flow, isolation rules)
  hooks/                   # governance PreToolUse + Stop hooks
  cron-prompts/            # verify / bugfix / feature / watchdog unattended loops
  agents/                  # /feature-workflow subagents (grafted from vmark — retarget pending)
scripts/
  run-codex.sh             # bounded, stdin-isolated Codex runner (rule 53)
  run-tests.sh             # bounded xcodebuild test runner (rule 52)
  git-hooks/pre-push       # the commit-time audit gate
docs/
  features.md bugs.md tasks.md   # the living trackers (cron fuel)
  architecture.md          # the fact source
dev-docs/
  audit/DIMENSIONS-ios.md  # what the audit checks
  verification/SCHEMA.md   # evidence schema (verified ≠ merged)
  decisions/               # ADRs
  plans/  designs/         # feature plans + committed UI designs
```

## How to drive it
See the cold-start tutorial: `dev-docs/冷启动手册-小白版-从初始化到无人值守.html`.

Status: bootstrapped governance skeleton; **no app code yet** (M0).
