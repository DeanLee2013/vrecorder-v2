# config/

Local-only runtime config. **Never committed** — `.gitignore` ignores `config/*key*`.

## OpenAI key

Put your OpenAI API key in `config/openai-key.txt` (single line, the raw `sk-...`
token — a plain `.txt` so Xcode copies it into the app bundle verbatim; a `.key`
extension is silently skipped by the resource copy phase):

```
sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

On first DEBUG launch the app reads this bundled file once and stores the key in
the Keychain (`APIKeyBootstrap.seedIfNeeded`), then never reads it again. Release
builds never read the file; the key comes only from Settings › API 密钥
(Keychain-backed). After editing the file, run `xcodegen generate` and do a
clean build so the new contents are re-copied into the `.app`.
