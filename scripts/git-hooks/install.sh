#!/usr/bin/env bash
# Install recorder-v2's git hooks into .git/hooks. Run once after `git init` / clone.
# Idempotent. Re-run after pulling new hook versions.
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
SRC="$REPO_ROOT/scripts/git-hooks"
DST="$REPO_ROOT/.git/hooks"

for hook in pre-push; do
  install -m 0755 "$SRC/$hook" "$DST/$hook"
  echo "installed: .git/hooks/$hook  ->  scripts/git-hooks/$hook"
done

echo ""
echo "Done. The Codex audit gate now runs on every 'git push'."
echo "Bypass intentionally with:  git push --no-verify   (or SKIP_AUDIT=1 git push)"
