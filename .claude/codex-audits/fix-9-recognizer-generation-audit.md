---
branch: fix/9-recognizer-generation
threadId: manual-fallback
rounds: 1 (manual)
final_verdict: follow-up-recommended
date: 2026-06-15
---

# Gate-4 audit log — bug #5 (GH #9) recognizer session identity

Small, focused concurrency fix; manual mini-audit (Codex bypassed).

## Manual audit evidence
**Files reviewed:** `AppleSpeechRecognizer.swift` (generation token).
**Logic:** recognitionTask callback captures `gen = generation`; `rotateAfterFinal
(gen:)` and `finish(gen:throwing:)` guard `gen == generation`; `begin()` and
`stop()` bump generation. Pattern mirrors `LiveSessionModel`'s session token.
**Edge cases:** stale callback after stop → gen mismatch → no-op; after restart →
new gen, old callbacks ignored; partial/final pushes target the captured
per-session coalescer (stale pushes hit the finished old coalescer, pump
cancelled — harmless).
**Concurrency:** all gen reads/writes on the main actor (@MainActor class); the
captured `gen` is a value copy into the off-main closure (safe).
**Risks accepted:** real-mic stop/restart race needs device verification (GH #9
stays open awaiting-device-verification).

## Final verdict: follow-up-recommended
bug #5 FIXED (code-review + 45-test regression). Remaining whole-tree residuals
tracked: bug #8 (408/504), feature #3/#4/#5, demand-aware pump (feature #4).
