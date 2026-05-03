#!/bin/bash

# Source the nvm script
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# Handle Codespaces where nvm installs to /usr/local/share/nvm
if [[ ! -s "$NVM_DIR/nvm.sh" && -s "/usr/local/share/nvm/nvm.sh" ]]; then
  export NVM_DIR="/usr/local/share/nvm"
fi
# The following line loads nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 

# Now you can use nvm as a command
if ! nvm install 24 2>/dev/null; then
  # If nvm is not available, try to use system node or fall back gracefully
  if command -v node >/dev/null 2>&1; then
    echo "node already installed: $(node -v)"
  else
    echo "Warning: Could not install node via nvm"
    exit 1
  fi
else
  nvm alias default 24
  nvm use 24
fi

# Verify node is available
node -v
