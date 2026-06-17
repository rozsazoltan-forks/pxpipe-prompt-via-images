#!/usr/bin/env bash
# Effective-context demo setup: generate the big context, kill old proxies, build,
# start BOTH proxies (background, fresh logs), seed two fresh /tmp working copies.
# Run this ONCE, then run a.sh and b.sh in two other terminals.
#
#   bash demo/effective-context/setup.sh
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1   # -> repo root

PORT_ON=47824          # pxpipe      -> b.sh (right)
PORT_OFF=47823         # passthrough -> a.sh (left, plain but logged)
LOG_ON="$HOME/.pxpipe/ec-on.jsonl"
LOG_OFF="$HOME/.pxpipe/ec-off.jsonl"
MODELS="claude-fable-5,claude-opus-4-8"
EC="demo/effective-context"

kill_port() { local p; p=$(lsof -ti tcp:"$1" 2>/dev/null || true); [ -n "$p" ] && kill "$p" 2>/dev/null || true; }

echo "[1/5] kill old proxies ($PORT_ON, $PORT_OFF)"
kill_port "$PORT_ON"; kill_port "$PORT_OFF"; sleep 1

echo "[2/5] build"
pnpm run build >/tmp/ec-build.log 2>&1 || { echo "  build FAILED -> /tmp/ec-build.log"; exit 1; }

echo "[3/5] generate context (flood + needle)"
ANSWER=$(node "$EC/generate.mjs" | tee /tmp/ec-gen.log | sed -n 's/^--- expected answer (ground truth): \(.*\) ---$/\1/p')

echo "[4/5] start proxies (background, fresh logs)"
: >"$LOG_ON"; : >"$LOG_OFF"
PXPIPE_LOG="$LOG_ON"  PORT="$PORT_ON"  PXPIPE_MODELS="$MODELS"                  nohup node dist/node.js >/tmp/ec-on.log  2>&1 & disown
PXPIPE_LOG="$LOG_OFF" PORT="$PORT_OFF" PXPIPE_MODELS="$MODELS" PXPIPE_DISABLE=1 nohup node dist/node.js >/tmp/ec-off.log 2>&1 & disown
sleep 2

echo "[5/5] seed two read-only working copies (context/ only)"
rm -rf /tmp/pp-ec-left /tmp/pp-ec-right
mkdir -p /tmp/pp-ec-left /tmp/pp-ec-right
cp -R "$EC/context" /tmp/pp-ec-left/context
cp -R "$EC/context" /tmp/pp-ec-right/context

cat <<EOF

Ready. Proxies up: pxpipe :$PORT_ON  ·  passthrough :$PORT_OFF
GROUND-TRUTH ANSWER: ${ANSWER:-see /tmp/ec-gen.log}   <- both columns should reply with exactly this

In a browser, open the live dashboard (context/token reduction, updates as it reads):
  http://localhost:$PORT_ON     # pxpipe   -> "THIS SESSION — N% fewer tokens"
  http://localhost:$PORT_OFF    # plain    -> ~0% (the passthrough control)

Then, in TWO separate terminals:
  bash $EC/a.sh        # LEFT  = normal  (may DROWN in filler -> wrong integer)
  bash $EC/b.sh        # RIGHT = pxpipe  (images filler, keeps needle as text -> ${ANSWER:-right})

The win is CAPABILITY, not cost: watch each column's final integer. To redo, re-run
this setup (fresh context, fresh logs, fresh copies), then a.sh / b.sh.
EOF
