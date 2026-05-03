# dotfiles

Personal development environment for macOS and Linux. Managed by [punch](https://github.com/nodeselector/punch), a copy-based dotfile manager with provenance tracking.

## Quick Start

```bash
git clone https://github.com/nodeselector/dotfiles ~/ghq/github.com/nodeselector/dotfiles
cd ~/ghq/github.com/nodeselector/dotfiles
make bootstrap
```

## What's Here

| Category | What | Key Tools |
|----------|------|-----------|
| `terminal/` | Shell, editor, multiplexer | zsh, neovim (LazyVim), tmux, starship, ghostty, iTerm2 |
| `dev/` | Language runtimes, package managers | brew, nvm, gvm, rust, uv, fzf, lazygit, lazydocker |
| `gui/` | Window management, automation | AeroSpace, Hammerspoon |
| `services/` | Self-hosted Docker services | Dozzle |
| `tools/` | CLI utilities | wk (which-key), dotfiles console |
| `script/` | Bootstrap and setup | bootstrap, setup, clone-plugins |

## How It Works

Each tool lives in its own directory with a `dot.yaml` that declares what to link and install:

```yaml
darwin:
  installs: brew install neovim
global:
  links:
    init.lua: ~/.config/nvim/init.lua
```

Punch walks the directory tree, resolves platform sections (`darwin`, `linux`, `global`), and copies configs to their targets.

## Setup

| Command | What it does |
|---------|-------------|
| `make bootstrap` | First-time setup -- installs punch, clones plugins, links + installs everything |
| `make setup` | Re-link and re-install (idempotent) |
| `make setup-link` | Link only, skip installs |

## Plugins

Private configs live in a separate repo, declared in `plugin.yaml`:

```yaml
plugins:
  - github.com/nodeselector/dotfiles.private
```

`script/clone-plugins` clones them into `plugins/`. Punch discovers their `dot.yaml` files automatically.

## Highlights

**Terminal** -- Tokyo Night everywhere. Ctrl-A prefix for tmux. Vim-style pane navigation with `christoomey/vim-tmux-navigator`. FZF scrollback search, keybinding cheatsheet, and a persistent scratch popup.

**Editor** -- LazyVim with Telescope, neo-tree, octo.nvim, and auto-updating Mason packages. Symlink-aware file pickers.

**Shell** -- Modular `~/.zshrc.d/*.zsh` pattern. Lazy-loaded nvm, gvm, and bun. Starship prompt with vim mode indicator.

**Window Management** -- AeroSpace tiling with vim-style alt-hjkl focus/move. Hammerspoon for ControlEscape (tap Ctrl = Esc, hold = Ctrl) and app window toggles.
