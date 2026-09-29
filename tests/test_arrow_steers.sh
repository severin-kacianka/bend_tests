#!/usr/bin/env bash
# Pressing Down turns the snake, which starts moving Right, downward.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name arrow_steers)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

frame1=$(capture "$SESSION")
pos1=$(pos_of "$frame1" "@")
[ -n "$pos1" ] || fail "could not locate head in initial frame:
$frame1"
read -r row1 _ <<< "$pos1"

send_keys "$SESSION" Down
sleep 1.5

frame2=$(capture "$SESSION")
pos2=$(pos_of "$frame2" "@")
[ -n "$pos2" ] || fail "could not locate head after steering:
$frame2"
read -r row2 _ <<< "$pos2"

[ "$row2" -gt "$row1" ] || fail "expected head row to increase after Down ($row1 -> $row2):
$frame2"
