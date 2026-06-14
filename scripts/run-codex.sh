#!/usr/bin/env bash
# scripts/run-codex.sh — bounded, stdin-isolated Codex runner.
#
# Why this exists (.claude/rules/53-codex-runner-isolation.md):
#   `codex exec "<prompt>"` ALSO reads stdin. In a non-tty / backgrounded shell
#   stdin never reaches EOF, so Codex blocks forever at 0% CPU — an invisible
#   "ghost" that lingers for hours. This wrapper:
#     1. closes stdin (< /dev/null) — the single load-bearing fix
#     2. watchdogs the EXACT pid with a wall-clock timeout (never `pgrep -f` a class)
#     3. prints ONE unambiguous `RUN-CODEX RESULT:` line (SUCCEEDED|FAILED|TIMEOUT)
#
# Usage:
#   scripts/run-codex.sh [-m model] [-e effort] [-s sandbox] [-o outfile] "<prompt>"
#   CODEX_TIMEOUT_SECS=600 scripts/run-codex.sh -m gpt-5.5 -e high -o /tmp/audit.txt "Audit ..."
#
# Defaults: model gpt-5.5, effort medium, sandbox read-only (audits are read-only), 300s.
# (gpt-5.5 because a ChatGPT-account login rejects gpt-5.4: "model is not supported
#  when using Codex with a ChatGPT account".) Project audit defaults (.cc-suite.md): -e high.
# Runs with --ignore-user-config so ~/.codex/config.toml (incl. unrelated MCP servers
# like Linear that may be unauthenticated) can't inject noise/errors into an audit;
# auth still resolves via CODEX_HOME. Model/sandbox/effort are passed explicitly below.
#
# The wrapper's `-o` tees the FULL transcript to a file (codex's own `-o` only
# writes the last message). Output also streams to stdout so the harness liveness
# display + completion notification keep working (rule 53 aggravator #3).
set -uo pipefail

MODEL="gpt-5.5"; EFFORT="medium"; SANDBOX="read-only"; OUT=""
TIMEOUT="${CODEX_TIMEOUT_SECS:-300}"

usage(){ echo "usage: scripts/run-codex.sh [-m model] [-e effort] [-s sandbox] [-o outfile] \"<prompt>\"" >&2; exit 2; }
while getopts "m:e:s:o:h" opt; do case "$opt" in
  m) MODEL="$OPTARG";; e) EFFORT="$OPTARG";; s) SANDBOX="$OPTARG";; o) OUT="$OPTARG";; *) usage;;
esac; done
shift $((OPTIND-1))
PROMPT="${1:-}"; [ -z "$PROMPT" ] && usage

command -v codex >/dev/null 2>&1 || { echo "RUN-CODEX RESULT: FAILED (codex not on PATH)"; exit 1; }

echo "RUN-CODEX START: model=$MODEL effort=$EFFORT sandbox=$SANDBOX timeout=${TIMEOUT}s${OUT:+ out=$OUT}"

STATUS="$(mktemp)"; TIMED_OUT="$(mktemp -u)"
launch(){
  # prompt as ARG + stdin closed (< /dev/null): immediate EOF, no <stdin> block, no wedge.
  if [ -n "$OUT" ]; then
    codex exec --color never --ignore-user-config -m "$MODEL" -s "$SANDBOX" \
      -c model_reasoning_effort="$EFFORT" "$PROMPT" </dev/null 2>&1 | tee "$OUT"
    echo "${PIPESTATUS[0]}" >"$STATUS"
  else
    codex exec --color never --ignore-user-config -m "$MODEL" -s "$SANDBOX" \
      -c model_reasoning_effort="$EFFORT" "$PROMPT" </dev/null 2>&1
    echo "$?" >"$STATUS"
  fi
}
launch & CODEX_PID=$!

# Watchdog on the EXACT pid; cancelled the instant Codex finishes (never re-arms — rule 49).
( sleep "$TIMEOUT"
  if kill -0 "$CODEX_PID" 2>/dev/null; then
    : >"$TIMED_OUT"
    pkill -TERM -P "$CODEX_PID" 2>/dev/null; kill -TERM "$CODEX_PID" 2>/dev/null
    sleep 3
    pkill -KILL -P "$CODEX_PID" 2>/dev/null; kill -KILL "$CODEX_PID" 2>/dev/null
  fi ) & WD=$!

wait "$CODEX_PID" 2>/dev/null
kill "$WD" 2>/dev/null; wait "$WD" 2>/dev/null

RC="$(cat "$STATUS" 2>/dev/null || echo 1)"; rm -f "$STATUS"
echo
if [ -e "$TIMED_OUT" ]; then rm -f "$TIMED_OUT"; echo "RUN-CODEX RESULT: TIMEOUT (${TIMEOUT}s)"; exit 124
elif [ "$RC" = "0" ]; then echo "RUN-CODEX RESULT: SUCCEEDED"; exit 0
else echo "RUN-CODEX RESULT: FAILED (codex rc=$RC)"; exit 1; fi
