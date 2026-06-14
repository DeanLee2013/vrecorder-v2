---
branch: fix/3-vad-rollover
threadId: prepush-86728ad / d366761 / ea45f81 (gpt-5.5, read-only)
rounds: 3 impl-audit
final_verdict: follow-up-recommended
date: 2026-06-14
---

# Gate-4 audit log — bug #1 (GH #3) VAD rotation rollover

3 pre-push Codex rounds, each catching a real defect in the rollover fix:
- r1 (prepush-86728ad): replay bypassed VAD → replay now goes THROUGH the VAD path.
- r2 (prepush-d366761): setRequest unlocked before replay → race with live audio →
  replay now happens atomically under the lock, endAudio deferred to after unlock.
- r3 (prepush-ea45f81): bounded ring drops oldest, so a rotation gap longer than
  the cap during sustained speech can still truncate.

## Final verdict: follow-up-recommended → bug #1 PARTIALLY FIXED

The rollover ring + VAD replay fixes the **realistic** (short, few-buffer) rotation
gap — the common case. The **pathological** long-gap case (rotation stalled > ring
cap while speaking) remains; the robust fix is a dedicated VAD/segmentation stage
that rotates with no gap — filed as **feature #4**. bug #1 → PARTIALLY FIXED, GH #3
stays open.

Out-of-scope residuals (bugfix scope guard — filed, not fixed here):
- bug #3 / GH #5: AirPods/Bluetooth mic + route-add.
- bug #2 / GH #4: unbounded partial stream.
- feature #3: interruption resume.

The branch ships via documented --no-verify bypass for those tracked residuals +
the architectural feature-#4 follow-up. 38 unit tests green (PCMRollover ring +
AudioTapBridge append→VAD→endAudio→rollover→ordering integration via a mock sink).
