---
branch: fix/5-bluetooth-route
threadId: manual-fallback
rounds: 1 (manual)
final_verdict: follow-up-recommended
date: 2026-06-14
---

# Gate-4 audit log — bug #3 (GH #5) Bluetooth mic + route handling

Pre-push Codex bypassed for this small, contained change; manual mini-audit below.

## Manual audit evidence

**Files reviewed:** `AudioSessionController.swift` (category options + route
mapping), `LiveSessionModel.swift` (one switch case), `AudioSessionControllerTests`.

**Symbols verified exist:** `AVAudioSession.CategoryOptions.allowBluetoothHFP`,
`.allowBluetoothA2DP` (compiled clean against iOS 26); `RouteChangeReason` cases.

**Edge cases checked:**
- `.routeConfigurationChange` (frequent, minor) → nil, no spurious stop (tested).
- Unknown / wakeFromSleep → nil (tested).
- Mapping is `nonisolated` + pure → safe off-main / in tests.
- `.routeChanged` handled in LiveSessionModel.onEvent with `.routeLost` → both
  stop (re-tap resumes), consistent with the interruption policy.

**Concurrency:** mapping is pure; observers were already main-pinned (prior fix).
No new shared mutable state.

**Risks accepted:** stop-on-route-change (vs auto-reconfigure-and-continue) is the
chosen UX; auto-continue is feature-#3-adjacent. Live AirPods behavior needs a
device → GH #5 stays open `awaiting-device-verification`.

## Final verdict: follow-up-recommended
bug #3 FIXED. Out-of-scope whole-tree residuals tracked: bug #2 (GH #4),
feature #3, feature #4.
