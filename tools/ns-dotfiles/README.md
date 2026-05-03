# ns-dotfiles console

Provides a friendly CLI `ns-dotfiles` (symlinked to `script/console`).

## Usage
```bash
ns-dotfiles            # interactive menu
ns-dotfiles bootstrap  # run script/bootstrap
ns-dotfiles setup      # run script/setup (link only)
ns-dotfiles install    # run script/setup --install
ns-dotfiles plugins    # run script/clone-plugins
ns-dotfiles update     # git pull --rebase origin main
ns-dotfiles status     # git status -sb
ns-dotfiles path       # print repo root
```

- On macOS, `gum` is installed via Homebrew for a richer menu if available.
- The symlink is created at `~/.local/bin/ns-dotfiles`.
