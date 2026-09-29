#!/usr/bin/env bash
# Steer deliberately onto the food (wherever it randomly spawned) and
# confirm the score increments -- exercises collision, growth, and
# food respawn together, deterministically rather than by luck.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name eats_food)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

frame=$(capture "$SESSION")
head_pos=$(pos_of "$frame" "@")
food_pos=$(pos_of "$frame" "*")
[ -n "$head_pos" ] && [ -n "$food_pos" ] || fail "could not locate head or food:
$frame"
read -r hr hc <<< "$head_pos"
read -r fr fc <<< "$food_pos"

# Step 1: align onto the food's row, if not already there.
if [ "$hr" -ne "$fr" ]; then
  down_dist=$(( (fr - hr + 20) % 20 ))
  up_dist=$(( (hr - fr + 20) % 20 ))
  if [ "$down_dist" -le "$up_dist" ]; then
    send_keys "$SESSION" Down
  else
    send_keys "$SESSION" Up
  fi

  aligned=0
  for _ in $(seq 1 40); do
    sleep 0.2
    f=$(capture "$SESSION")
    echo "$f" | grep -q "Game over" && fail "snake crashed while aligning to food row:
$f"
    hp=$(pos_of "$f" "@")
    [ -n "$hp" ] || continue
    read -r r _ <<< "$hp"
    if [ "$r" -eq "$fr" ]; then
      aligned=1
      break
    fi
  done
  [ "$aligned" -eq 1 ] || fail "never aligned to food row $fr within 8s"
fi

# Step 2: turn onto the food's column.
frame=$(capture "$SESSION")
head_pos=$(pos_of "$frame" "@")
read -r hr hc <<< "$head_pos"
right_dist=$(( (fc - hc + 20) % 20 ))
left_dist=$(( (hc - fc + 20) % 20 ))
if [ "$right_dist" -le "$left_dist" ]; then
  send_keys "$SESSION" Right
else
  send_keys "$SESSION" Left
fi

wait_for "$SESSION" "Score: 1" 10 || fail "score never reached 1 after guiding snake to food:
$(capture "$SESSION")"
