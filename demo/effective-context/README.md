# Demo 2 — effective context (recall at scale)

**What it measures:** does pxpipe stay *sharp* in a context big enough to overload
the plain column? This is the **capability** story, not cost — and it's the one that
matters, because the cost A/B ([`../cost-ab/`](../cost-ab/README.md)) came out
~break-even.

The idea: a context too large for the plain column to track reliably (a "dumb
zone"). pxpipe images the bulky filler (compressing it) but keeps the small
**needle** as *text* — so it reads the needle perfectly while carrying a much
smaller active context. The plain column carries everything as text and may lose
the needle in the noise. `setup.sh` floods ≈200k tokens of inert logs around a
`needle.txt` with a deterministic integer answer.

---

## Run it — 3 scripts, 3 terminals

```bash
# Terminal 1 — set up: generates the context, builds, starts BOTH proxies, seeds
#              two read-only copies, and PRINTS the ground-truth answer.
bash demo/effective-context/setup.sh

# Terminal 2 — LEFT  = normal   (interactive Claude — may drown and answer wrong)
bash demo/effective-context/a.sh   # defaults to Fable; `a.sh opus` to use Opus

# Terminal 3 — RIGHT = pxpipe   (interactive Claude — should answer correctly)
bash demo/effective-context/b.sh   # use the SAME model as a.sh
```

`a.sh` / `b.sh` launch a **real interactive Claude session** with the needle prompt
already submitted — you watch the CLI read the files. They run from isolated `/tmp`
copies inside a subshell, so your terminal stays in the repo afterward. `claude` is
usually a shell alias; the scripts resolve the real binary, or set
`CLAUDE_BIN=/path/to/claude`. To redo, re-run `setup.sh`.

**Model:** both scripts default to **Fable 5**. Pass a model as the first arg to
override — `bash demo/effective-context/a.sh opus` (also `sonnet`, `haiku`, or a
full `claude-…` id); run both columns on the same model. For `b.sh`, pxpipe only
compresses models the `:47824` proxy allows (Fable-only by default — see
`PXPIPE_MODELS` or the dashboard "compress models" chips).

## See the result — compare the two integers

`setup.sh` prints the **ground-truth answer**. Each column replies with one integer:

| column | expectation |
|---|---|
| **RIGHT — pxpipe** (`b.sh`) | matches the ground truth (needle stays text) |
| LEFT — plain (`a.sh`) | **may be wrong** at this size (drowns in filler) |

**pxpipe correct + plain wrong = the effective-context win.** Each proxy also serves
a live dashboard ([:47824](http://localhost:47824/) pxpipe, [:47823](http://localhost:47823/)
plain) showing the context/token reduction — the same number `/context` reports.

---

## Read it honestly

- **The premise is UNVALIDATED.** "Plain drowns at this size and answers wrong" is an
  assumption — modern Claude has strong long-context retrieval, so plain may **also**
  get it right. If it does, this demo shows **no pxpipe advantage**. Run it and report
  *both* integers; don't assume the outcome.
- **The needle stays text on purpose.** pxpipe is lossy on imaged content (it misreads
  exact strings), so this demo only works because the needle is small enough to stay
  text. It does **not** show pxpipe recalling imaged exact values.

## What IS already validated (from the cost A/B)

In the Rust-rewrite run, **both** columns ported the whole pricing library to Rust and
**both passed all 5 tests with the exact expected integers** (`2468 / 8316 / 216 /
9975 / 45181`) preserved — pxpipe through imaged spec + source. So *"compression
doesn't corrupt precision work"* is supported. This demo tests the complementary
claim: *"compression keeps you sharp where raw context overloads."*

## The other demo
This is the **capability** demo. The **cost** demo ("does pxpipe cost less on a real
task?", ~break-even) is in [`../cost-ab/`](../cost-ab/README.md).
