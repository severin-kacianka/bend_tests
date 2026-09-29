#!/usr/bin/env bash
# snake.py is at least syntactically valid Python.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
[ "$GAME_LANG" = "python" ] || { echo "SKIP: testing the Bend implementation"; exit 77; }

out=$(python3 -m py_compile "$PY_FILE" 2>&1)
status=$?
[ "$status" -eq 0 ] || fail "python3 -m py_compile exited $status:
$out"
