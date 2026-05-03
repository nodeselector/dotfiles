. "$HOME/.local/bin/env"

for file in $HOME/.zshrc.d/*; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
