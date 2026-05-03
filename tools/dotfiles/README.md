# dotfiles console

Provides a friendly CLI `dotfiles` (symlinked to `script/console`).

## Usage
```bash
dotfiles            # interactive menu
dotfiles bootstrap  # run script/bootstrap
dotfiles setup      # run script/setup (link only)
dotfiles install    # run script/setup --install
dotfiles plugins    # run script/clone-plugins
dotfiles update     # git pull --rebase origin main
dotfiles status     # git status -sb
dotfiles path       # print repo root
```

- On macOS, `gum` is installed via Homebrew for a richer menu if available.
- The symlink is created at `~/.local/bin/dotfiles`.
