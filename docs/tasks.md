# Task Inbox

Describe issues in plain text below. The agent will triage them.

## Rules

> **Binding for this file.** The triage rules, classification policy, and record format below govern every change made to `docs/tasks.md`. AGENTS.md treats them as the authoritative inbox-triage workflow.

- **This file is an inbox, not a tracker.** Items stay here only until triaged.
- **User writes free-form descriptions** under the "New" section. No table, no formatting required.
- **Triage is classification only — not execution.** The agent does NOT fix bugs or implement features during triage. It only classifies and records.
- **Classification rules**:
  - Implemented but doesn't work correctly → **bug** → record in `docs/bugs.md`.
  - Never implemented → **feature** → record in `docs/features.md`.
  - Partially implemented + incorrect behavior → **bug** for the broken part; split off a separate **feature** for the missing capability. Link them.
  - Not a bug or feature (docs, config, chores, environment) → mark as `NO-ACTION` with reason.
  - Invalid or unclear → mark as `NEEDS-INFO` and ask the user.
- **Deduplication**: Before creating a new entry, search existing bugs and features. If a match exists:
  - Exact duplicate of an **open** bug (TODO/IN PROGRESS/REOPENED) → mark as `DUPLICATE OF bug #N` or `feature #N`.
  - Matches a **FIXED** bug → it's a regression, not a duplicate → mark as `REOPENED bug #N` and set that bug's status back to `REOPENED` in `docs/bugs.md`.
- **Agent workflow**: For each new item, the agent will:
  1. Read the description and investigate the codebase.
  2. Search `docs/bugs.md` and `docs/features.md` for existing matches.
  3. Classify per the rules above.
  4. Record based on classification:
     - **New bug/feature** → assign next available ID in the appropriate file. For bugs, also add an entry to `## Open Bug Details` in `docs/bugs.md` with the user's description (max 6 lines: repro, expected, actual).
     - **DUPLICATE** → no new ID; reference existing `bug #N` or `feature #N`.
     - **REOPENED** → no new ID; set existing bug's status to `REOPENED` in `docs/bugs.md`. Add/update `## Open Bug Details` entry with the new context.
     - **NO-ACTION / NEEDS-INFO** → no tracker entry; record only here.
  5. Move the description from "New" to "Triaged" with a one-line record: classification + destination ID + date.

## New

<!-- Write new issues here in plain language. One paragraph per issue is fine. -->

## Triaged

<!-- Agent moves processed items here: `- YYYY-MM-DD — <one-line summary> → bug #N / feature #N / NO-ACTION / NEEDS-INFO` -->
