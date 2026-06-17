# Demo 1 — cost A/B

**What it measures:** does pxpipe cost less on a real coding task? **Honest verdict:
~break-even on cost.** The compression is real (~55% fewer *real* tokens, verified)
but it lands in `cache_read` — cheap at `$` (0.1×), and its weight against a Pro/Max
weekly cap is unpublished. The capability story is in
[`../effective-context/`](../effective-context/README.md).

Two columns fix the **same** failing test suite in isolated working copies — one
plain, one through pxpipe — **both behind a proxy so both arms are logged.** It's a
real project (`template/`): the fix hinges on precise `SPEC.md` rules (volume tiers by
*total quantity*, loyalty applied *after* the discount, *banker's* rounding), so it
doubles as a recall test. `node --test` is built in (no install).

---

## Run it — 3 scripts, 3 terminals

```bash
# Terminal 1 — set up: kills old proxies, builds, starts BOTH proxies, seeds copies
bash demo/cost-ab/setup.sh

# Terminal 2 — LEFT  = normal   (interactive Claude — you watch the CLI)
bash demo/cost-ab/a.sh            # defaults to Fable; `a.sh opus` to use Opus

# Terminal 3 — RIGHT = pxpipe   (interactive Claude)
bash demo/cost-ab/b.sh            # use the SAME model as a.sh for a fair A/B
```

`a.sh` / `b.sh` launch a **real interactive Claude session** with the task prompt
already submitted — you see the CLI work, nothing headless. They run two real
sessions (uses plan usage). `claude` is usually a shell alias; the scripts resolve
the real binary, or set `CLAUDE_BIN=/path/to/claude`. To redo a run, re-run
`setup.sh` (it resets the working copies + fresh logs), then `a.sh` / `b.sh`.

**Model:** both scripts default to **Fable 5**. Pass a model as the first arg to
override — `bash demo/cost-ab/a.sh opus` (also `sonnet`, `haiku`, or a full
`claude-…` id). Run **both** columns on the same model for a fair A/B. For `b.sh`,
pxpipe only compresses models the `:47824` proxy allows (Fable-only by default —
see `PXPIPE_MODELS` or the dashboard "compress models" chips).

## See the result — just open the dashboard

Each proxy serves a **live dashboard** in your browser — no commands, no extra window:

| open in browser | shows |
|---|---|
| **http://localhost:47824/** (pxpipe → `b.sh`) | **`THIS SESSION — N% fewer tokens (… total)`** |
| http://localhost:47823/ (plain → `a.sh`) | ~0% — the passthrough **control** |

It updates as the run goes. The headline is the **honest, rate-free number**: real
server tokens (`input+cache_create+cache_read+output`) vs the same body as text
(`count_tokens`) — two real numbers, one division, no rate/cap assumptions. The
plain dashboard reading ~0% proves the method doesn't invent savings.

**Optional CLI** (same numbers, if you prefer a terminal):
```bash
node eval/ab/savings.mjs                                                # token compression, both arms
node eval/ab/analyze.mjs ~/.pxpipe/ab-on.jsonl ~/.pxpipe/ab-off.jsonl   # $ / cap?? (divergence-confounded)
```
The `$`/`cap??` deltas from `analyze.mjs` compare two *different* runs, so they're
muddied by divergence — trust the per-arm token % (dashboard or `savings.mjs`).
What the token cut *saves* depends on pricing (`cache_read` ×0.1 at `$`; weekly-cap
weight unknown).

## The other demo
This is the **cost** demo. The **capability** demo ("does pxpipe stay sharp where plain
drowns?") is in [`../effective-context/`](../effective-context/README.md) — the more
promising story, since cost is ~break-even.
