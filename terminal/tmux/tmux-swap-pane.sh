#!/usr/bin/env bash
# tmux-swap-pane: fzf picker to swap current pane with a sibling
set -euo pipefail

panes=$(tmux list-panes -F '#{pane_index}: #{pane_current_command} [#{pane_width}x#{pane_height}] #{?pane_active,◀ active,}' \
  | grep -v '◀ active')

if [ -z "$panes" ]; then
  echo "Only one pane."
  sleep 1
  exit 0
fi

target=$(echo "$panes" | fzf --reverse --header='Swap with:')
[ -z "$target" ] && exit 0

idx=$(echo "$target" | cut -d: -f1)
tmux swap-pane -t "$idx"
