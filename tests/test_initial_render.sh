#!/usr/bin/env bash
# The game renders a clean 20x20 grid with exactly one head and Score: 0.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name initial_render)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score: 0" 5 || fail "game did not render within 5s"

frame=$(capture "$SESSION")

grid_lines=$(echo "$frame" | grep -cE '^[.@o*]{20}$')
[ "$grid_lines" -eq 20 ] || fail "expected 20 grid rows of 20 cells, got $grid_lines:
$frame"

heads=$(echo "$frame" | grep -o '@' | wc -l)
[ "$heads" -eq 1 ] || fail "expected exactly one head '@', got $heads"

echo "$frame" | grep -q "Score: 0" || fail "missing 'Score: 0'"
