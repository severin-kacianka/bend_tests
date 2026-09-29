#!/usr/bin/env bash
# Pressing Left while moving Right is an instant 180 reversal and must be
# ignored (Snake.turn) -- the snake keeps moving right, not into itself.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name ignores_reversal)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

frame1=$(capture "$SESSION")
pos1=$(pos_of "$frame1" "@")
[ -n "$pos1" ] || fail "could not locate head in initial frame"
read -r _ col1 <<< "$pos1"

send_keys "$SESSION" Left
sleep 1.5

frame2=$(capture "$SESSION")
# A live game over screen (from a bogus self-crash) would fail this too.
echo "$frame2" | grep -q "Game over" && fail "snake reversed into itself and crashed:
$frame2"

pos2=$(pos_of "$frame2" "@")
[ -n "$pos2" ] || fail "could not locate head after reversal attempt:
$frame2"
read -r _ col2 <<< "$pos2"

[ "$col2" -ge "$col1" ] || fail "expected head column to keep increasing (ignored reversal), $col1 -> $col2:
$frame2"
