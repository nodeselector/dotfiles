# Lazy-load gvm: source on first `gvm` call (~0.6s saved)
# Go itself is available via homebrew or gvm's installed versions
_load_gvm() {
  unfunction gvm 2>/dev/null
  [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
}

gvm() { _load_gvm; gvm "$@" }
