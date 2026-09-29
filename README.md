# bend

A repo for exploring the [Bend](https://bend-lang.com) programming
language — Lean-like formal proofs, C-like speed, CUDA-like
parallelism. The vehicle for exploring it is a terminal-playable Nokia-
style Snake game, built up alongside a few of Bend's formal proof
("law") features, plus a Python port for comparison.

## What's here

- **`snake.bend`** — the game itself. 20x20 grid, arrow-key steering,
  edge wraparound, growing on food, self-collision game over. Runs in
  a real terminal (raw mode via `stty`, `q`/Ctrl-C to quit).
- **`LAWS.bend`** / **`PROOF.bend`** — formal claims about `snake.bend`'s
  pure logic, and their proofs:
  - turning can never point the snake straight back into itself
    (no instant-reversal suicide)
  - the "opposite direction" relation is symmetric and irreflexive
  - a coordinate always equals itself (underlies collision/food checks)
  - eating adds exactly one segment; moving alone changes nothing
- **`snake_buggy.bend`** / **`LAWS_buggy.bend`** / **`PROOF_buggy.bend`** —
  a copy of the game with one deliberate bug (eating doesn't grow the
  snake), used to demonstrate that `bend PROOF_buggy.bend` catches the
  regression at check time even though the game still runs fine.
- **`snake.py`** — an independent Python port of `snake.bend`, written
  to be functionally equivalent and validated by the exact same test
  suite (see below), with no laws/proofs (Python has no equivalent
  toolchain for that).
- **`snake_buggy.py`** — the same deliberate bug as `snake_buggy.bend`,
  ported to Python, with no proof to catch it there either.
- **`tests/`** — a tmux-driven black-box test suite: launches a game
  file in a real pty, sends real keystrokes, inspects the rendered
  terminal output. `tests/run.sh --file PATH` points it at any `.bend`
  or `.py` file, not just the two above.
- **`AGENTS.md`** — repo conventions for working with Bend here (run
  `bend guide`, keep rules in `LAWS.bend`, gate commits on
  `bend PROOF.bend`).

## Requirements

- `bend` — tested against 2.0.34. Install: `curl -fsSL
  https://bend-lang.com/install.sh | sh`
- `python3` (standard library only) — for `snake.py` and a couple of
  test helpers.
- `tmux` — for the test suite.
- (Optional) a Lean 4 toolchain via `elan` — only needed for
  `bend PROOF.bend --verdict`'s stronger kernel-checked pass; ordinary
  `bend PROOF.bend` doesn't need it.

## Build / check

Bend has no separate build step for a program this size — `bend
<file>.bend` type-checks, termination-checks, and runs it in one go
(compiling to JS/Bun under the hood by default). `--check-only` does
the checking without running:

```sh
bend snake.bend --check-only     # type-check + termination-check the game
bend PROOF.bend                  # check the formal proofs -> ALL PROOFS CHECK
bend PROOF.bend --verdict        # stronger Lean-kernel-checked pass (needs elan/lean)
python3 -m py_compile snake.py   # syntax-check the Python port
```

## Run

```sh
bend snake.bend      # play the Bend version
python3 snake.py      # play the Python version
```

Arrow keys steer, `q` or Ctrl-C quits. The terminal is switched to raw
mode while playing and restored on exit either way.

## Test

```sh
tests/run.sh                       # black-box suite against snake.bend
tests/run.sh --file snake.py       # the same suite against snake.py
tests/run.sh --file path/to.bend   # ...or any other .bend/.py file
tests/run.sh quit                  # only run tests matching "quit"
```

`--file` accepts any `.bend` or `.py` file, not just the two shipped
here — the suite only ever talks to it through a real pty (keystrokes
in, rendered text out), so it works against any implementation that
speaks the same terminal protocol.

## The buggy-law demo

```sh
bend PROOF_buggy.bend --check-only
```

prints `SOME PROOFS FAIL`, pointing at `Laws.Snake.grown_body.length` —
the law that eating must grow the snake by exactly one segment.
`snake_buggy.bend` still compiles and plays fine (score climbs, the
snake just never gets longer); `tests/run.sh` against it would still
pass, since none of the black-box tests check body length. Only the
formal proof catches this particular regression.
