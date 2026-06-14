---
branch: fix/4-bounded-partials
threadId: prepush-1f287ee / d60140e (gpt-5.5, read-only)
rounds: 2 impl-audit
final_verdict: follow-up-recommended
date: 2026-06-15
---

# Gate-4 audit log — bug #2 (GH #4) bounded partial stream

2 Codex rounds:
- r1 (prepush-1f287ee): `.bufferingNewest(64)` drops oldest regardless of type →
  could silently evict an unconsumed `.final`. Replaced with
  `RecognitionEventCoalescer` (partials coalesce, finals queued FIFO, never
  dropped) + one pump task (no per-callback Task) + begin() rollback on failure.
- r2 (prepush-d60140e): coalescer fixed the finals-dropping High; remaining are
  pre-existing/residual (below).

## Final verdict: follow-up-recommended → bug #2 PARTIALLY FIXED

Core fixed: per-callback Task pile-up removed; partials coalesce; finals never
dropped at the coalescer (4 unit tests incl. delayed-consumer burst). Residual:
the returned AsyncThrowingStream + the finals array aren't demand-aware bounded —
true backpressure is the **feature #4** streaming redesign.

Newly-discovered, filed (bugfix scope guard — not fixed here):
- **bug #5 / GH #9 (High)**: recognizer callbacks lack session/segment identity
  (stale callback can corrupt a restarted session).
- **feature #5 / GH #10**: 仅转写模式 toggle is a no-op (capability unimplemented).
- **bug #4 / GH #8**: OpenAI 408/504 → timeout mapping.
- feature #3 (interruption resume) — tracked.

Ships via documented --no-verify bypass for those tracked items. 45 unit tests
green.
