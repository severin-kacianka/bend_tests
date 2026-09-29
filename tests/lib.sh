#!/usr/bin/env bash
# Shared helpers for the tmux-driven snake.bend test suite.
# Every test sources this, then uses a unique tmux session it owns.

SNAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAKE_FILE="$SNAKE_DIR/snake.bend"

require_tmux() {
  command -v tmux >/dev/null 2>&1 || { echo "SKIP: tmux not installed"; exit 77; }
}

new_session_name() {
  echo "snaketest_$$_${1}_${RANDOM}"
}

# start_game SESSION [COLS] [ROWS]
# Launches the real game in a detached tmux session (a real pty, so
# stty/raw mode and /dev/tty behave exactly as in interactive use). The
# wrapper prints GAME_EXIT_CODE:<n> once bend exits, then idles so the
# pane survives long enough for the test to inspect it.
start_game() {
  local session="$1" cols="${2:-100}" rows="${3:-40}"
  tmux kill-session -t "$session" 2>/dev/null
  tmux new-session -d -s "$session" -x "$cols" -y "$rows" \
    "cd '$SNAKE_DIR' && bend snake.bend; echo GAME_EXIT_CODE:\$?; sleep 30"
}

stop_game() {
  tmux kill-session -t "$1" 2>/dev/null
  true
}

capture() {
  tmux capture-pane -t "$1" -p
}

send_keys() {
  local session="$1"; shift
  tmux send-keys -t "$session" "$@"
}

# wait_for SESSION REGEX [TIMEOUT_SECONDS=5]
# Polls the pane every 0.2s until REGEX appears, instead of a fixed sleep.
wait_for() {
  local session="$1" pattern="$2" timeout="${3:-5}"
  local max_iters=$(( timeout * 5 ))
  local i=0
  while (( i < max_iters )); do
    if capture "$session" | grep -qE "$pattern"; then
      return 0
    fi
    sleep 0.2
    i=$(( i + 1 ))
  done
  return 1
}

# head_pos_of FRAME_TEXT CHAR -> prints "row col" (0-based) or nothing
pos_of() {
  printf '%s' "$1" | python3 "$SNAKE_DIR/tests/parse_frame.py" "$2"
}

fail() {
  echo "FAIL: $*"
  exit 1
}
