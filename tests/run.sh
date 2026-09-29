#!/usr/bin/env bash
# Runs the test suite against any game file: one compile/syntax check
# plus a series of tmux-driven end-to-end tests that launch it in a real
# pty, send it real keystrokes, and inspect the rendered terminal output.
# Every test only ever interacts through the pty, so the same tests
# validate any implementation that speaks the same terminal protocol
# (20x20 grid of .@o*, arrow keys, q/Ctrl-C to quit) -- just point
# --file at it. How to launch a file is inferred from its extension
# (.bend -> `bend FILE`, .py -> `python3 FILE`); see tests/lib.sh.
#
# Usage: tests/run.sh [--file PATH] [pattern]
#   --file PATH  test PATH instead of the default snake.bend
#   pattern      optional glob to select a subset, e.g. tests/run.sh quit
set -uo pipefail

if [ "${1:-}" = "--file" ]; then
  [ -f "${2:-}" ] || { echo "error: no such file: ${2:-}" >&2; exit 1; }
  export GAME_FILE
  GAME_FILE="$(realpath "$2")"
  shift 2
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

pattern="${1:-}"
pass=0
fail=0
skip=0
failed_names=()

for t in test_*.sh; do
  case "$t" in
    *"$pattern"*) ;;
    *) continue ;;
  esac
  chmod +x "$t" 2>/dev/null || true
  printf '%-32s' "$t"
  out=$(./"$t" 2>&1)
  status=$?
  if [ "$status" -eq 0 ]; then
    echo "PASS"
    pass=$((pass + 1))
  elif [ "$status" -eq 77 ]; then
    echo "SKIP"
    skip=$((skip + 1))
  else
    echo "FAIL"
    echo "$out" | sed 's/^/    /'
    fail=$((fail + 1))
    failed_names+=("$t")
  fi
done

echo
echo "Results: $pass passed, $fail failed, $skip skipped"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failed_names[*]}"
  exit 1
fi
