# Subagents — grafted from vmark, pending iOS retarget

These 9 role definitions drive `/feature-workflow` (rule 47's gate model). They were
copied verbatim from vmark (a Tauri v2 + React project) and **must be retargeted to
vrecorder-v2's iOS stack before they're relied on**.

| Agent | Role | Retarget TODO |
|-------|------|---------------|
| `planner` | goal → modular WIs + tests + acceptance | swap React/Tauri examples for Swift/actors |
| `implementer` | scoped TDD changes, minimal diffs | `pnpm`/Vitest → `xcodebuild`/Swift Testing |
| `auditor` | diff review for correctness + rule compliance | drop `skills: tiptap-dev, tauri-app-dev`; point at iOS rules 50/52/53 |
| `verifier` | final gate/rule check before release | simulator/device verification, not Tauri MCP |
| `spec-guardian` | validate work against specs/rules | reference vrecorder-v2 rules |
| `impact-analyst` | smallest correct change set | Swift module boundaries |
| `test-runner` | run unit + (E2E) | `scripts/run-tests.sh` + XCUITest, not Tauri MCP E2E |
| `release-steward` | commit messages + release notes | rule 40 version bump (`project.yml`) |
| `manual-test-author` | manual test guides | iOS device steps |

Until retargeted, treat their stack-specific instructions (tooling, skill names) as
**inapplicable** and follow the vrecorder-v2 rules in `.claude/rules/` instead.
