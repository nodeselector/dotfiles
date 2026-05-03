export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# Handle Codespaces where nvm installs to /usr/local/share/nvm
if [[ ! -s "$NVM_DIR/nvm.sh" && -s "/usr/local/share/nvm/nvm.sh" ]]; then
  export NVM_DIR="/usr/local/share/nvm"
fi

# Lazy-load nvm: stub functions that source nvm.sh on first use (~2s saved)
# Add default node to PATH immediately so node/npm/npx work without loading nvm
_nvm_alias=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
if [[ -n "$_nvm_alias" ]]; then
  # Resolve alias (e.g. "16" → "v16.20.2", "lts/*" → latest lts)
  _nvm_default_dir=$(ls -d "$NVM_DIR/versions/node/v${_nvm_alias}"* 2>/dev/null | sort -V | tail -1)
  if [[ -d "$_nvm_default_dir/bin" ]]; then
    export PATH="$_nvm_default_dir/bin:$PATH"
  fi
fi
unset _nvm_alias _nvm_default_dir

_load_nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

nvm()  { _load_nvm; nvm "$@" }
node() { _load_nvm; node "$@" }
npm()  { _load_nvm; npm "$@" }
npx()  { _load_nvm; npx "$@" }