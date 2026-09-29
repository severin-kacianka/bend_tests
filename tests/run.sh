#!/usr/bin/env bash
# Runs the snake test suite: one bare compile check plus a series of
# tmux-driven end-to-end tests that launch the real game in a real pty,
# send it real keystrokes, and inspect the rendered terminal output.
# The same gameplay tests validate either implementation -- only which
# command they launch (via $GAME_LANG in lib.sh) changes.
#
# Usage: tests/run.sh [--python] [pattern]
#   --python  test snake.py instead of the default snake.bend
#   pattern   optional glob to select a subset, e.g. tests/run.sh quit
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if [ "${1:-}" = "--python" ]; then
  export GAME_LANG=python
  shift
fi

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
