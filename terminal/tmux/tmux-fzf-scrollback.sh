#!/usr/bin/env bash
# tmux-fzf-scrollback: fzf search through tmux scrollback history
# Captures the full pane history, pipes to fzf, copies selection to clipboard.
# Designed for prefix+/ binding in tmux.conf.
set -euo pipefail

LINES="${TMUX_FZF_SCROLLBACK_LINES:-50000}"

# Capture scrollback (deduplicate empty lines, strip trailing whitespace)
tmux capture-pane -pS "-${LINES}" 2>/dev/null \
  | sed 's/[[:space:]]*$//' \
  | awk 'NF || !blank { print; blank=!NF }' \
  | fzf --no-sort --reverse --multi --exact \
        --header="scrollback search (tab=multi, enter=copy)" \
        --bind='ctrl-a:select-all' \
  | pbcopy

# Brief flash so you know it copied
tmux display-message "Copied to clipboard"
