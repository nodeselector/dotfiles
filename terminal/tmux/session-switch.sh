#!/usr/bin/env bash

export FZF_DEFAULT_OPTS=''
export FZF_DEFAULT_OPTS+=' --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9'
export FZF_DEFAULT_OPTS+=' --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9'
export FZF_DEFAULT_OPTS+=' --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6'
export FZF_DEFAULT_OPTS+=' --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'
export FZF_DEFAULT_OPTS+=' -i --height=50% --layout=reverse --border'

session=$(tmux ls | awk -F: '
    /attached/ {print $1 "\033[32m *\033[0m"}
    !/attached/ {print $1} 
' | fzf --ansi)
session=$(echo "$session" | sed 's/ (attached)$//')
if [ -n "$session" ]; then
  tmux switch-client -t "$session"
else
  echo "No session selected."
fi
