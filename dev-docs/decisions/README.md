# Architecture Decision Records (ADR)

One file per hard decision: `ADR-NNN-short-title.md`. Records **why** a design is
the way it is, and — via `Negative space` — what it must **not** be "good-idea"
refactored into. Format: MADR + the two vmark extensions.

## Template

```markdown
# ADR-NNN: <Title>
> Status: Proposed | Accepted | Date: YYYY-MM-DD

## Context            # 2-3 sentences: the problem, why a decision is needed
## Considered Options # 1. A  2. B  3. C
## Decision           # chose X because… (give the concrete interface/signature)
## Consequences       # Good: …  Bad: … (migration cost, what it touches)
## Verification gate  # a grep-checkable assertion, e.g. `grep -rn "X" returns zero`
## Negative space     # what this decision does NOT own (prevents over-reaching refactors)
## Dependencies       # other ADRs this depends on / is depended on by
## Migration outcome  # (filled in AFTER): what was deleted, N files updated, result
```

## Index

| ADR | Title | Status |
|-----|-------|--------|
| _none yet_ | First decisions to record: engine abstraction, persistence actor, audio-session ownership | — |
