#!/usr/bin/env bash
# scripts/run-tests.sh — bounded, watchdogged unit-test gate.
#
# Why (.claude/rules/52-test-sim-isolation.md): `xcodebuild test` can wedge at
# 0% CPU and ghost for hours (sim contention, or a wedged SWBBuildService build
# daemon after a kill -9). This wrapper turns an indefinite hang into a bounded,
# self-terminating run:
#   1. pins the destination by UDID (prefers iPhone 17 Pro, else booted, else any)
#   2. enforces a hard wall-clock timeout (default 900s) on the EXACT pid (rule 49)
#   3. on timeout kills the process tree AND clears the wedged build daemon
#      `SWBBuildService` (rule 52 Cause B) — a bare kill is a half-cleanup that
#      poisons the next run
#   4. prints ONE unambiguous final line:
#      RUN-TESTS RESULT: SUCCEEDED|FAILED|TIMEOUT|NO_BOOTED_SIM
#
# Usage:
#   scripts/run-tests.sh                          # default suite (vrecorderTests)
#   scripts/run-tests.sh vrecorderTests/FooTests  # one targeted suite (fast per-WI gate)
#   TIMEOUT_SECS=2400 scripts/run-tests.sh vrecorderTests   # full-suite periodic sweep
#   TEST_UDID=<udid> scripts/run-tests.sh         # specific simulator (true parallelism)
#
# NEVER pipe this through tail/grep/head (rule 52 #5): `tail -N` on a pipe buffers
# away the streaming markers AND the single RESULT line. Let stdout go straight to
# a file or the task-output; read the file after the RESULT line lands.
set -uo pipefail

PROJECT="vrecorder.xcodeproj"
SCHEME="vrecorder"
SUITE="${1:-vrecorderTests}"
TIMEOUT="${TIMEOUT_SECS:-900}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$(dirname "$0")/.." || { echo "RUN-TESTS RESULT: FAILED (cannot cd to project root)"; exit 1; }

# Resolve a simulator UDID. Pin by UDID to avoid name/OS-matching surprises.
# Order: explicit TEST_UDID > iPhone 17 Pro (project convention) > booted sim > any iPhone.
udid="${TEST_UDID:-}"
[ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone 17 Pro (' | grep -oE '[0-9A-F-]{36}' | head -1)"
[ -z "$udid" ] && udid="$(xcrun simctl list devices booted    2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1)"
[ -z "$udid" ] && udid="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone' | grep -oE '[0-9A-F-]{36}' | head -1)"
if [ -z "$udid" ]; then
  echo "RUN-TESTS RESULT: NO_BOOTED_SIM (no usable iOS Simulator found — install a runtime)"
  exit 1
fi

# Clear a stale app instance that wedges the test-host launch with a "Busy
# (Application failed preflight checks)" error (recurring sim-state flake). No-op
# if the sim is shut down or the app isn't installed.
xcrun simctl terminate "$udid" com.vrecorder.app >/dev/null 2>&1 || true

echo "RUN-TESTS START: suite=$SUITE udid=$udid timeout=${TIMEOUT}s"

STATUS="$(mktemp)"; TIMED_OUT="$(mktemp -u)"
run() {
  xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" \
    -destination "id=$udid" \
    -only-testing:"$SUITE" 2>&1
  echo "$?" >"$STATUS"
}
run & RUN_PID=$!

# Watchdog on the EXACT pid; cancelled the instant the test finishes (never re-arms — rule 49).
( sleep "$TIMEOUT"
  if kill -0 "$RUN_PID" 2>/dev/null; then
    : >"$TIMED_OUT"
    pkill -TERM -P "$RUN_PID" 2>/dev/null; kill -TERM "$RUN_PID" 2>/dev/null
    sleep 3
    pkill -KILL -P "$RUN_PID" 2>/dev/null; kill -KILL "$RUN_PID" 2>/dev/null
    pkill -9 -x SWBBuildService 2>/dev/null   # rule 52 Cause B: clear the wedged daemon
  fi ) & WD=$!

wait "$RUN_PID" 2>/dev/null
kill "$WD" 2>/dev/null; wait "$WD" 2>/dev/null

RC="$(cat "$STATUS" 2>/dev/null || echo 1)"; rm -f "$STATUS"
echo
if [ -e "$TIMED_OUT" ]; then
  rm -f "$TIMED_OUT"
  echo "RUN-TESTS RESULT: TIMEOUT (${TIMEOUT}s) — killed process tree + SWBBuildService"
  exit 124
elif [ "$RC" = "0" ]; then
  echo "RUN-TESTS RESULT: SUCCEEDED"
  exit 0
else
  echo "RUN-TESTS RESULT: FAILED (xcodebuild rc=$RC)"
  exit 1
fi
