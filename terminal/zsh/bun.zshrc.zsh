# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# bun completions — lazy-loaded on first bun invocation (~0.1s saved)
_load_bun_completions() {
  unfunction bun 2>/dev/null
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
}
bun() { _load_bun_completions; command bun "$@" }
