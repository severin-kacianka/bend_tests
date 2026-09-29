#!/usr/bin/env bash
# The snake advances on its own tick, with no key ever pressed.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name moves)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

frame1=$(capture "$SESSION")
sleep 1.5
frame2=$(capture "$SESSION")

[ "$frame1" != "$frame2" ] || fail "frame did not change after 1.5s with no input:
$frame1"
