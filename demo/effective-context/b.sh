#!/usr/bin/env bash
# RIGHT column = pxpipe (through the proxy on 47824). Reads the SAME huge context.
# pxpipe images the bulky filler but keeps the small needle as text, so it carries
# a smaller active context and should read the needle perfectly. Run
# `bash demo/effective-context/setup.sh` first.
set -uo pipefail

DIR=/tmp/pp-ec-right
[ -d "$DIR/context" ] || { echo "no $DIR — run: bash demo/effective-context/setup.sh"; exit 1; }

# `claude` is usually a shell alias (not on PATH); resolve the real binary.
CB="${CLAUDE_BIN:-}"
if [ -z "$CB" ]; then
  if command -v claude >/dev/null 2>&1; then CB="$(command -v claude)"
  elif [ -x "$HOME/.claude/local/claude" ]; then CB="$HOME/.claude/local/claude"
  else echo "claude not found — set CLAUDE_BIN=/path/to/claude"; exit 1; fi
fi

PROMPT='context/ has needle.txt plus filler-NNN.txt files. Using the Read tool on each file individually (do NOT use grep, bash, find, or any search tool — I need every file actually read into your context): FIRST read needle.txt, THEN read every filler-NNN.txt in numerical order. As you read, COUNT the lines that contain the exact token "AUDIT-ZX9". Only after reading ALL files, answer using only what you read: (1) the final ledger balance of account ZX-9 from needle.txt, (2) how many lines contained "AUDIT-ZX9", and (3) their sum. Reply as: balance=<n>, count=<m>, final=<n+m>.'

# Model: defaults to Fable 5; override with the first arg (friendly name or full id):
#   ./b.sh        → claude-fable-5       ./b.sh opus → claude-opus-4-8
#   ./b.sh sonnet → claude-sonnet-4-6    ./b.sh claude-... → used verbatim
# NOTE: for pxpipe to actually compress, the :47824 proxy must allow this model
# (Fable-only by default — see PXPIPE_MODELS or the dashboard "compress models"
# chips). A model the proxy doesn't cover just passes through uncompressed.
case "${1:-fable}" in
  fable)  MODEL=claude-fable-5 ;;
  opus)   MODEL=claude-opus-4-8 ;;
  sonnet) MODEL=claude-sonnet-4-6 ;;
  haiku)  MODEL=claude-haiku-4-5 ;;
  *)      MODEL="$1" ;;
esac

echo "RIGHT = pxpipe (:47824), model=$MODEL. Launching interactive Claude with the needle task..."
# Run in $DIR via a subshell so your terminal stays in the original dir afterward.
( cd "$DIR" && exec env ANTHROPIC_BASE_URL=http://localhost:47824 \
  "$CB" "$PROMPT" --model "$MODEL" --setting-sources project --strict-mcp-config --dangerously-skip-permissions )
