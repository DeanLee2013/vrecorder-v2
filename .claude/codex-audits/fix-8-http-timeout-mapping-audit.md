---
branch: fix/8-http-timeout-mapping
threadId: manual-fallback
rounds: 1 (manual)
final_verdict: ship-as-is
date: 2026-06-15
---

# Gate-4 audit log — bug #8 (GH #8) HTTP 408/504 → timeout

Trivial, fully-tested change; Codex bypassed; manual mini-audit.

## Manual audit evidence
**File:** `OpenAITranslationEngine.swift` — added `case 408, 504: throw .timeout`
to the response-status switch.
**Test:** `OpenAIStatusMappingTests` injects a stub `URLProtocol`/URLSession and
asserts 408/504 → .timeout, 401 → .invalidAPIKey, 429 → .rateLimited, 200 → content.
This is the "injected URLSession" coverage the bug-#2 audit asked for, and it also
backfills tests for the earlier status mappings.
**Edge cases:** 408 (request timeout) and 504 (gateway timeout) both map to the
user-facing timeout taxonomy; no other status behavior changed.
**Risks:** none — additive case in an existing switch, fully unit-tested.

## Final verdict: ship-as-is
bug #8 FIXED. 48 tests green.
