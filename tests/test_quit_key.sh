#!/usr/bin/env bash
# Pressing 'q' prints "Bye!" and exits cleanly with status 0.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name quit_key)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

send_keys "$SESSION" q
wait_for "$SESSION" "Bye!" 3 || fail "'Bye!' not shown after pressing q:
$(capture "$SESSION")"
wait_for "$SESSION" "GAME_EXIT_CODE:0" 3 || fail "game did not exit with status 0 after quitting:
$(capture "$SESSION")"
