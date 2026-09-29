#!/usr/bin/env bash
# GAME_FILE at least type-checks (Bend) or parses cleanly (Python).
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

case "$GAME_FILE" in
  *.bend)
    out=$(bend "$GAME_FILE" --check-only 2>&1)
    status=$?
    [ "$status" -eq 0 ] || fail "bend --check-only exited $status:
$out"
    echo "$out" | grep -q "ALL PROOFS CHECK" || fail "expected ALL PROOFS CHECK, got:
$out"
    ;;
  *.py)
    out=$(python3 -m py_compile "$GAME_FILE" 2>&1)
    status=$?
    [ "$status" -eq 0 ] || fail "python3 -m py_compile exited $status:
$out"
    ;;
  *)
    fail "don't know how to compile-check '$GAME_FILE' (expected a .bend or .py file)"
    ;;
esac
