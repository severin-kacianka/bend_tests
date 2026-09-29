#!/usr/bin/env bash
# After quitting, the terminal must be back in normal (cooked, echoing)
# mode -- not left raw, which would break the user's shell.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name terminal_restored)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

send_keys "$SESSION" q
wait_for "$SESSION" "GAME_EXIT_CODE:0" 3 || fail "game did not exit"

send_keys "$SESSION" "stty -F /dev/tty -a; echo STTY_DONE" Enter
wait_for "$SESSION" "STTY_DONE" 3 || fail "stty command never completed"
out=$(capture "$SESSION")

if echo "$out" | grep -q -- '-icanon'; then
  fail "terminal still in raw mode (-icanon present):
$out"
fi
if echo "$out" | grep -q -- '-echo'; then
  fail "terminal still has echo disabled (-echo present):
$out"
fi
exit 0
