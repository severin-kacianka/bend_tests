#!/usr/bin/env bash
# snake.bend type-checks and passes Bend's termination/proof checker.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
[ "$GAME_LANG" = "python" ] && { echo "SKIP: testing the Python implementation"; exit 77; }

out=$(bend "$SNAKE_FILE" --check-only 2>&1)
status=$?
[ "$status" -eq 0 ] || fail "bend --check-only exited $status:
$out"
echo "$out" | grep -q "ALL PROOFS CHECK" || fail "expected ALL PROOFS CHECK, got:
$out"
