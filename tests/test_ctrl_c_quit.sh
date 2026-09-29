#!/usr/bin/env bash
# Raw mode disables SIGINT generation, so Ctrl-C arrives as byte 3 and must
# be treated as a clean quit (same as 'q'), not ignored or left hanging.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tmux

SESSION=$(new_session_name ctrl_c_quit)
trap 'stop_game "$SESSION"' EXIT

start_game "$SESSION"
wait_for "$SESSION" "Score:" 5 || fail "game did not start"

send_keys "$SESSION" C-c
wait_for "$SESSION" "Bye!" 3 || fail "'Bye!' not shown after Ctrl-C:
$(capture "$SESSION")"
wait_for "$SESSION" "GAME_EXIT_CODE:0" 3 || fail "game did not exit with status 0 after Ctrl-C:
$(capture "$SESSION")"
