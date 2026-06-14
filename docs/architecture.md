# vrecorder-v2 Architecture

> Fact source. AGENTS.md requires every agent to read this before changing code.
> Update it in the SAME PR whenever layers, services, schema, or notifications change
> (rule 24). Stale-but-passing doc text is worse than none.

## System diagram

```
(fill in once the first feature lands)
UI (SwiftUI)  →  Coordinators / ViewModels (@MainActor @Observable)
              →  Pipeline actors: capture → VAD → ASR → translation → TTS
              →  Persistence actor (SwiftData)
```

## Layers

| Layer | May import | Notes |
|-------|-----------|-------|
| Views (SwiftUI) | ViewModels, DesignSystem | no business logic |
| ViewModels | services, engines (protocols) | `@MainActor @Observable` |
| Services / pipeline actors | other services, AVFoundation, Speech | actor-isolated |
| Persistence | SwiftData | single actor owns all mutations |

## Services
_(table: name | one-line purpose — add rows as services land)_

## Data layer
_(SwiftData schema version + entities — fill in at M4)_

## Notification bus
_(name | payload | direction — add rows as cross-component events appear)_

## Key design patterns
_(engine-behind-protocol, replaceable partials, single audio-session owner — link ADRs)_
