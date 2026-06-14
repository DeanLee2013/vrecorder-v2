# vrecorder-v2 Architecture

> Fact source. AGENTS.md requires every agent to read this before changing code.
> Update it in the SAME PR whenever layers, services, schema, or notifications change
> (rule 24). Stale-but-passing doc text is worse than none.

## System diagram

```
LiveScreen / SettingsScreen (SwiftUI)
   │
   ▼
LiveSessionModel (@MainActor @Observable)   ← composition root: AppEnvironment
   │            │
   │            ├── SpeechRecognizing  → AppleSpeechRecognizer (SFSpeechRecognizer + AVAudioEngine)
   │            ├── TranslationEngine  → OpenAITranslationEngine (Chat Completions)
   │            └── AudioSessionController (single AVAudioSession owner)
   │
   ▼
TranscriptLine[]  (partial → final → history, max 3/panel)

API key: KeychainAPIKeyStore (DEBUG seed from bundled config/openai.key)
```

Pipeline (MVP): mic → on-device 中文 STT (partial/final) → per-final OpenAI
translate 中文→English → push English final to the counterpart panel. When no
engines are injected, LiveSessionModel runs a built-in demo simulator (no
network) for course demos / offline fallback.

## Layers

| Layer | May import | Notes |
|-------|-----------|-------|
| Views (SwiftUI) | ViewModels, DesignSystem | no business logic |
| ViewModels | services, engines (protocols) | `@MainActor @Observable` |
| Services / pipeline actors | other services, AVFoundation, Speech | actor-isolated |
| Persistence | SwiftData | single actor owns all mutations |

## Services

| Name | Purpose |
|------|---------|
| `AppEnvironment` | Composition root — builds the session model with concrete engines + Keychain store |
| `LiveSessionModel` | `@MainActor @Observable` session state machine; runs the STT→translate→display pipeline (or demo simulator) |
| `AppleSpeechRecognizer` | On-device `SpeechRecognizing` (SFSpeechRecognizer + AVAudioEngine), emits partial/final |
| `OpenAITranslationEngine` | `TranslationEngine` over OpenAI Chat Completions; pure request/parse helpers are unit-tested |
| `AudioSessionController` | Single owner of `AVAudioSession` config + interruption handling |
| `KeychainAPIKeyStore` | `APIKeyStoring` over the Keychain; DEBUG-seeded from bundled `config/openai.key` |

## Key design patterns

- **Engine-behind-protocol**: `SpeechRecognizing` / `TranslationEngine` so providers
  (Apple on-device, OpenAI cloud) are swappable and mockable; capabilities are
  declared, not hard-coded at call sites.
- **Replaceable partials**: a `.partial` line is replaced in place; `.final` freezes
  it; older lines demote to `.history` (max 3 per panel).
- **Single audio-session owner**: only `AudioSessionController` touches `AVAudioSession`.
- **Demo fallback**: `LiveSessionModel` with no injected engines runs a scripted
  partial→final sequence — zero network, for course demos.

## Data layer
_(SwiftData schema version + entities — fill in at M4)_

## Notification bus
_(name | payload | direction — add rows as cross-component events appear)_

