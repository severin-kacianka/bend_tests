#!/usr/bin/env bash
# Classic Nokia-style wraparound: the snake re-enters from the opposite
# edge instead of dying at the wall.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name wraps_around)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

wrapped=0
prev_col=""
for _ in $(seq 1 40); do
  sleep 0.2
  frame=$(capture "$SESSION")
  echo "$frame" | grep -q "Game over" && fail "snake crashed instead of wrapping:
$frame"
  pos=$(pos_of "$frame" "@")
  [ -n "$pos" ] || continue
  read -r _ col <<< "$pos"
  if [ -n "$prev_col" ] && [ "$col" -lt "$prev_col" ]; then
    wrapped=1
    break
  fi
  prev_col=$col
done

[ "$wrapped" -eq 1 ] || fail "head column never wrapped around within 8s"
