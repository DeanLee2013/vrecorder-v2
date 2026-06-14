---
branch: fix/24-speech-error-mapping
threadId: manual-fallback
rounds: 1 (manual)
final_verdict: ship-as-is
date: 2026-06-15
---
# Gate-4 audit log — bug #9 (GH #24) Speech error mapping
Small, fully-tested change; Codex bypassed; manual mini-audit.
## Manual audit evidence
**File:** AppleSpeechRecognizer.swift — extracted `nonisolated static
mapRecognitionError(_:authorized:)`: !authorized → speechPermissionDenied;
NSURLErrorDomain timeout → timeout, else → offline; otherwise recognitionFailed.
finish() passes the current SFSpeechRecognizer.authorizationStatus.
**Tests:** RecognitionErrorMappingTests (3) — revoked-permission, network
offline/timeout, generic fallback — synthetic NSErrors, no device. 59 tests green.
**Risk:** none — pure mapping, additive; the recognizer's behavior on a genuine
PipelineError throw is unchanged (still short-circuits).
## Final verdict: ship-as-is. bug #9 FIXED.
