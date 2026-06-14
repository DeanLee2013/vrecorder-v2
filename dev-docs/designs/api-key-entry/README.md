# Design — API Key Entry sheet (feature #2)

> **Committed design artifact** for the OpenAI API-key entry surface. The
> dedicated page was not in the original `design/` handoff (only the Settings row
> + a prose "→ 密钥录入页" mention). The design owner (user, 2026-06-14)
> authorized building it from the **committed design system** — reusing the exact
> light-scope tokens/components already shipped in `SettingsScreen`, inventing no
> new visual language. This file is that committed design (satisfies rule 51).

## Surface

A modal **sheet** presented from Settings › "API 密钥" (light scope, same as
SettingsScreen). System sheet chrome (corner radius, grabber) — not hand-drawn.

## Layout (ASCII spec — tokens, not pixels)

```
┌─────────────────────────────────────────────┐  surface-app  (#F7F7FB)
│  [取消]                              [保存]   │  header row, 54pt top inset
│                                               │  保存 = violet600, disabled→faint
│  API 密钥                                     │  title1 (28, bold), textPrimary
│                                               │
│  ┌─────────────────────────────────────────┐ │  group caption "OPENAI" (caption,
│  │  密钥        [ sk-•••••••••••••• ]        │ │   faint, tracking-caps)
│  └─────────────────────────────────────────┘ │  card: surface-card, radius 16,
│   当前：sk-…AB12  (masked, last 4)            │   shadow-card, 50pt row
│                                               │
│  ┌─────────────────────────────────────────┐ │  (only when a key exists)
│  │  清除密钥                                 │ │  destructive row, red500 text
│  └─────────────────────────────────────────┘ │
│                                               │
│  密钥存于本机 Keychain；同传时以 Bearer 凭证  │  caption, faint — BYOK notice
│  经 TLS 发给所选服务商，不发给第三方。设备     │  (key IS transmitted to the
│  被攻破仍可能泄露。                            │   chosen provider — disclosed)
└─────────────────────────────────────────────┘
```

## Tokens (all already in `vrecorder/DesignSystem/`)

| Element | Token |
|---|---|
| Sheet background | `VR.surfaceApp` (#F7F7FB) |
| Card | `VR.surfaceCard` + radius 16 + `VR` card shadow |
| Title | `VR.FontSize.title1`, bold, `VR.textPrimaryLight` |
| Group caption | `VR.FontSize.caption`, `VR.textFaint`, `VR.capsTracking` |
| Row label / value | `VR.FontSize.body`, `VR.textPrimaryLight` / `VR.textFaint` |
| 保存 (primary) | `VR.accentLight` (violet600); disabled → `VR.textFaint` |
| 清除密钥 (destructive) | `VR.red500` |
| Hairline | `VR.hairlineLight` |

## States

- **Empty draft / invalid** → 保存 disabled (faint).
- **Valid draft** (`sk-` + body, no control chars) → 保存 enabled (violet).
- **Existing key present** → masked "当前：sk-…XXXX" shown; 清除密钥 row visible.
- **No existing key** → no masked line, no 清除密钥 row.
- **Save success** → dismiss; Settings row → "已配置".
- **Save failure** (Keychain error) → stay open, inline error caption (red500),
  the previous key is preserved (atomic update — never destroyed on failure).

## Interactions

- 取消 → dismiss, no change.
- 保存 → validate → atomic Keychain write → on success dismiss; on failure show
  error, keep sheet open, draft retained.
- 清除密钥 → confirm via system alert → remove key → row shows 未配置.
- Secret never fully rendered: input uses `SecureField`; existing key shown masked
  (last ≤4 chars only; if the stored secret is too short to mask safely, show a
  generic "已配置" instead of any characters).

No new colors, type ramp, or component shapes — every value above is an existing
`VR` token or system chrome.
