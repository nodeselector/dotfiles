# wk (which-key) initialization -- cached with content-hash invalidation
_wk_cache="$HOME/.cache/wk-init.zsh"
_wk_hash_file="$HOME/.cache/wk-init.hash"

if command -v wk &>/dev/null; then
  # Build a hash from wk binary path + config content to detect any change
  _wk_current_hash=$(cat ~/.config/wk/config.yaml ~/.config/wk/bindings.yaml 2>/dev/null | shasum -a 256 | cut -d' ' -f1)
  _wk_cached_hash=$(cat "$_wk_hash_file" 2>/dev/null)

  if [[ ! -f "$_wk_cache" ]] || [[ "$_wk_current_hash" != "$_wk_cached_hash" ]] \
     || [[ "$(command -v wk)" -nt "$_wk_cache" ]]; then
    mkdir -p "${_wk_cache:h}"
    wk init --leader '^G' > "$_wk_cache"
    echo "$_wk_current_hash" > "$_wk_hash_file"
  fi
  source "$_wk_cache"

  unset _wk_current_hash _wk_cached_hash
fi
unset _wk_cache _wk_hash_file

reload() {
  exec zsh -l
}
