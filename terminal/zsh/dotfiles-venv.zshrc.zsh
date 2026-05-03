#!/usr/bin/env zsh

# Dotfiles Python virtual environment setup
# This ensures Python scripts in dotfiles can find their dependencies
#
# WHY: Homebrew Python is externally managed (PEP 668), so we can't install
# packages directly. This venv provides a clean isolated environment for
# dotfiles Python tools like rssh, mc-* scripts, etc.
#
# TODO: LATER - Extract this into ./dev/python for better organization
# and consistency with other dev tools

# Path to the dotfiles venv
DOTFILES_VENV="$HOME/.dotfiles-venv"

# Simply add the dotfiles venv to PATH so Python scripts can find packages
# This is much simpler and more reliable than preexec hooks
if [[ -d "$DOTFILES_VENV" ]]; then
    export PATH="$DOTFILES_VENV/bin:$PATH"
fi

# Convenience function to manually activate dotfiles venv
dotfiles-venv() {
    if [[ -d "$DOTFILES_VENV" ]]; then
        source "$DOTFILES_VENV/bin/activate"
        echo "🐍 Activated dotfiles Python venv"
    else
        echo "❌ Dotfiles venv not found at $DOTFILES_VENV"
        echo "Create it with: python3 -m venv $DOTFILES_VENV"
    fi
}

# Alias for convenience
alias dvenv='dotfiles-venv'
# dvenv