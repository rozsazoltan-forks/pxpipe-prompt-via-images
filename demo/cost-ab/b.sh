#!/usr/bin/env bash
# RIGHT column = pxpipe (through the proxy on 47824). Launches an INTERACTIVE
# Claude session with the task prompt already submitted — you watch it work in
# the real CLI. Run `bash demo/cost-ab/setup.sh` first.
set -uo pipefail

DIR=/tmp/pp-demo-right
[ -d "$DIR" ] || { echo "no $DIR — run: bash demo/cost-ab/setup.sh"; exit 1; }

# `claude` is usually a shell alias (not on PATH); resolve the real binary.
CB="${CLAUDE_BIN:-}"
if [ -z "$CB" ]; then
  if command -v claude >/dev/null 2>&1; then CB="$(command -v claude)"
  elif [ -x "$HOME/.claude/local/claude" ]; then CB="$HOME/.claude/local/claude"
  else echo "claude not found — set CLAUDE_BIN=/path/to/claude"; exit 1; fi
fi

PROMPT='This project has a failing test suite. Read SPEC.md and the source, then fix src/pricing.js so it follows SPEC.md exactly and the test suite (node --test) passes. Run the tests to confirm.'

# Model: defaults to Fable 5; override with the first arg (friendly name or full id):
#   ./b.sh        → claude-fable-5[1m]     ./b.sh opus → claude-opus-4-8[1m]
#   ./b.sh sonnet → claude-sonnet-5[1m]    ./b.sh claude-... → used verbatim
# NOTE: for pxpipe to actually compress, the :47824 proxy must allow this model
# (Fable-only by default — see PXPIPE_MODELS or the dashboard "compress models"
# chips). A model the proxy doesn't cover just passes through uncompressed.
case "${1:-fable}" in
  fable)  MODEL=claude-fable-5[1m] ;;
  opus)   MODEL=claude-opus-4-8[1m] ;;
  sonnet) MODEL=claude-sonnet-5[1m] ;;
  haiku)  MODEL=claude-haiku-4-5 ;;
  *)      MODEL="$1" ;;
esac

echo "RIGHT = pxpipe (:47824), model=$MODEL. Launching interactive Claude with the task..."
# Run in $DIR via a subshell so your terminal stays in the original dir afterward.
( cd "$DIR" && exec env ANTHROPIC_BASE_URL=http://localhost:47824 \
  "$CB" "$PROMPT" --model "$MODEL" --setting-sources project --strict-mcp-config --no-chrome --dangerously-skip-permissions )
