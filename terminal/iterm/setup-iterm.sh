#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# iterm2 setup script - installs shell integration

echo "Setting up iTerm2 shell integration..."

# Install iterm2 shell integration if not already installed
if ! command -v curl &> /dev/null; then
    echo "curl is required but not installed. Please install curl first."
    exit 1
fi

# Download and install iTerm2 shell integration
ITERM_INTEGRATION_DIR="$HOME/.iterm2_shell_integration"
if [[ ! -d "$ITERM_INTEGRATION_DIR" ]]; then
    echo "Installing iTerm2 shell integration..."
    curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
else
    echo "✓ iTerm2 shell integration already installed"
fi

echo "✓ iTerm2 setup completed successfully!"
echo "Note: Your profile is managed via DynamicProfiles (linked from dotfiles/terminal/iterm/profile.json)"
echo "Please restart iTerm2 to apply all changes."


# Set up iTerm2 dynamic profiles directory
ITERM_PROFILES_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
if [[ ! -d "$ITERM_PROFILES_DIR" ]]; then
    echo "Creating iTerm2 dynamic profiles directory..."
    mkdir -p "$ITERM_PROFILES_DIR"
fi

# Create a basic dynamic profile for development work
PROFILE_FILE="$ITERM_PROFILES_DIR/dev-profile.json"
if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "Creating development profile..."
    cat > "$PROFILE_FILE" << 'EOF'
{
  "Profiles": [
    {
      "Name": "Development",
      "Guid": "dev-profile-guid-001",
      "Working Directory": "~/ghq/github.com",
      "Custom Directory": "Yes",
      "Badge Text": "DEV",
      "Use Custom Window Title": true,
      "Custom Window Title": "Development Terminal",
      "Transparency": 0.1,
      "Blur": true,
      "Background Color": {
        "Red Component": 0.11764705882352941,
        "Green Component": 0.11764705882352941,
        "Blue Component": 0.11764705882352941,
        "Alpha Component": 1
      },
      "Foreground Color": {
        "Red Component": 0.8627450980392157,
        "Green Component": 0.8627450980392157,
        "Blue Component": 0.8627450980392157,
        "Alpha Component": 1
      }
    }
  ]
}
EOF
    echo "Development profile created at $PROFILE_FILE"
else
    echo "Development profile already exists"
fi

# Enable shell integration features in zshrc if not already enabled
if [[ -f "$HOME/.zshrc" ]] && ! grep -q "iterm2_shell_integration" "$HOME/.zshrc"; then
    echo "Adding iTerm2 shell integration to .zshrc..."
    echo "" >> "$HOME/.zshrc"
    echo "# iTerm2 shell integration" >> "$HOME/.zshrc"
    echo 'test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"' >> "$HOME/.zshrc"
fi

# Cleanup conflicting static profiles (if any)
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup-iterm-conflicts.py"
if command -v python3 &> /dev/null && [[ -x "$CLEANUP_SCRIPT" ]]; then
    echo "Cleaning up old conflicting iTerm2 profiles (if any)..."
    python3 "$CLEANUP_SCRIPT" || true
fi

# Disable iTerm2 hotkey on dotfiles profiles (often steals Alt+').
HOTKEY_SCRIPT="$SCRIPT_DIR/disable-iterm-hotkey.py"
if command -v python3 &> /dev/null && [[ -f "$HOTKEY_SCRIPT" ]]; then
    echo "Disabling dotfiles iTerm2 hotkey bindings..."
    python3 "$HOTKEY_SCRIPT" || true
fi

echo "iTerm2 setup completed successfully!"
echo "Please restart iTerm2 to apply all changes."
