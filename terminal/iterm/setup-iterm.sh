#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up iTerm2..."

# Install vendored shell integration
ITERM_INTEGRATION="$HOME/.iterm2_shell_integration.zsh"
if [[ -f "$SCRIPT_DIR/iterm2_shell_integration.zsh" ]]; then
    cp "$SCRIPT_DIR/iterm2_shell_integration.zsh" "$ITERM_INTEGRATION"
    echo "✓ iTerm2 shell integration installed (vendored)"
fi

# Set up dynamic profiles directory
ITERM_PROFILES_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
mkdir -p "$ITERM_PROFILES_DIR"

# Cleanup conflicting static profiles
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup-iterm-conflicts.py"
if command -v python3 &>/dev/null && [[ -x "$CLEANUP_SCRIPT" ]]; then
    python3 "$CLEANUP_SCRIPT" || true
fi

# Disable iTerm2 hotkey on dotfiles profiles
HOTKEY_SCRIPT="$SCRIPT_DIR/disable-iterm-hotkey.py"
if command -v python3 &>/dev/null && [[ -f "$HOTKEY_SCRIPT" ]]; then
    python3 "$HOTKEY_SCRIPT" || true
fi

echo "✓ iTerm2 setup complete"
