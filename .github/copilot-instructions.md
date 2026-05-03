# Copilot Instructions for dotfiles

## Repository Purpose
Personal dotfiles managed via [punch](https://github.com/nodeselector/punch), a cross-platform dotfile manager. Supports macOS, Linux, and GitHub Codespaces with declarative configuration in `dot.yaml` files.

## Architecture
- **punch-based**: Each tool/config lives in a subdirectory with a `dot.yaml` defining links and installs
- **Directory structure**:
  - `dev/` — development tools (brew, git, nvm, rust, gvm, vscode, lazydocker, etc.)
  - `terminal/` — shell configs (zsh, tmux, nvim, starship, iterm, env)
  - `gui/` — macOS GUI configs (aerospace, hammerspoon)
  - `tools/` — miscellaneous utilities (wk, dotfiles)
  - `services/` — Docker Compose self-hosted services
  - `plugins/` — cloned plugin repos (gitignored, managed by `script/clone-plugins`)
- **Platform-specific configs**: `dot.yaml` supports `darwin:`, `linux:`, and `global:` sections
- **Dependency management**: Use `depends:` in `dot.yaml` to ensure tools install in correct order

## Core Workflows

### Bootstrap & Setup
1. **First-time setup**: `./script/bootstrap` → installs punch, links configs, installs all tools
2. **Reload shell**: `exec $SHELL` → pick up PATH/env changes
3. **Link only**: `./script/setup` → symlinks configs without installing
4. **Re-install**: `./script/setup --install` → re-run installations (e.g., after adding new tools)

### Makefile Shortcuts
- `make bootstrap` — first-time setup (installs punch + full setup)
- `make setup` — equivalent to `./script/setup --install`
- `make setup-link` — equivalent to `./script/setup` (link only)

### Common Operations
- **Add new tool**: Create `<category>/<tool>/dot.yaml` with links and installs
- **Platform-specific installs**: Use `darwin:` or `linux:` sections in `dot.yaml`
- **Custom install commands**: Use `installs: cmd: <command>` for non-package-manager installs

## punch Configuration Patterns

### Basic dot.yaml Structure
```yaml
installs: brew install <package>  # or apt install, or custom cmd
links:
  source-file: ~/.target-location
```

### Platform-Specific Example
```yaml
darwin:
  installs: brew install neovim
linux:
  installs: ~/.install_nvim.sh
  links:
    install_linux.sh: ~/.install_nvim.sh
global:
  links:
    .config: ~/.config/nvim
```

### Dependencies Example
```yaml
installs:
  cmd: curl -o- https://example.com/install.sh | bash
  depends:
    - ../terminal/zsh
```

### Key Files
- `config.yaml` — punch global config (link type: symbolic)
- `.defaults.yaml` — platform-specific install defaults (brew for macOS, apt for Linux)
- `script/bootstrap` — main entry point: installs punch, runs full setup
- `script/setup` — links configs and optionally installs tools with two-pass PATH refresh

## PATH Management
The setup handles PATH updates across multiple installation stages:
1. First punch install pass runs - core tools (brew, env) install successfully, others may fail
2. `refresh_path()` function sources common tool locations:
   - Homebrew: `/opt/homebrew/bin`, `/usr/local/bin`
   - Local bin: `~/.local/bin`
   - NVM: `~/.nvm/nvm.sh`
   - Rust/Cargo: `~/.cargo/env`
3. Second punch install pass runs with updated PATH - remaining tools now succeed

## Codespaces Support
- Detects `CODESPACES=true` environment variable
- Uses alternate dotfiles path: `/workspaces/.codespaces/.persistedshare/dotfiles`
- Repos being worked on live at `/workspaces/<repo-name>`
- Two-pass installation ensures tools like brew are available for dependent installs
- NVM may live at `/usr/local/share/nvm` instead of `~/.nvm` (setup handles both)
- `vscode/dot.yaml` runs `sudo chsh --shell /usr/bin/zsh` to set zsh as default shell
- `.defaults.yaml` uses `apt` on Linux, `brew` on Darwin
- `DOTFILES_DIR` env var is exported during install so `dot.yaml` commands can reference it

## Plugin System

### Overview
Plugins extend dotfiles with configs from external repos. Each plugin is cloned into the repo-local `plugins/<owner>/<repo>` directory by `script/clone-plugins`.

### Plugin Registry
Plugins are declared in `plugin.yaml` at the repo root:
```yaml
plugins:
  - github.com/nodeselector/dotfiles.private
```

### Plugin Installation Flow
1. `script/bootstrap` calls `script/clone-plugins`
2. For each plugin in `plugin.yaml`:
   - Clone to `plugins/<owner>/<repo>` using `gh repo clone` (falls back to `git clone`)
   - If already cloned, fast-forward pull to update
3. punch discovers plugin configs via the plugins directory structure

### Authentication
- Clone uses `gh` CLI auth by default
- For private repos in Codespaces, set `DOTFILES_PLUGINS_PAT` secret (or `DOTFILES` / `GH_TOKEN`)

### Constraints
- The `plugins/` directory is **gitignored** (except README.md and .gitignore)
- **Never edit files in `plugins/`** — change the source repo and re-pull
- Plugins with local changes are skipped during update (dirty-check before pull)

## CRITICAL: Never Manually Symlink
**DO NOT** run `ln -s` or create symlinks manually. **ALWAYS** use `dot.yaml` to declare links:
1. Add the link to the appropriate `dot.yaml` file under `links:`
2. Run `./script/setup` to apply

punch handles all symlinking. Manual symlinks bypass the framework and cause inconsistencies.

## CRITICAL: Never Modify the plugins/ Directory
**DO NOT** edit, create, or delete files in `plugins/`. This directory contains clones of external repositories managed by `script/clone-plugins`.

To modify plugin content:
1. Go to the source repository
2. Make changes there and push
3. Re-run `./script/bootstrap` or manually `git pull` in `plugins/<owner>/<repo>`

The `plugins/` directory is gitignored except for README.md and .gitignore.

## CRITICAL: Never Edit Target Files Directly
**DO NOT** edit files at their symlink targets (e.g., `~/.config/nvim/init.lua`, `~/.zshrc`).

**ALWAYS** edit the source file in dotfiles (e.g., `terminal/nvim/init.lua`, `terminal/zsh/.zshrc`).

Changes to source files take effect immediately since they're symlinked.

## Conventions
- **Symlinks**: All dotfiles are symlinked (not copied) via punch — never manually
- **zshrc.d pattern**: Shell configs live in `~/.zshrc.d/*.zsh` (sourced by main .zshrc)
- **Idempotent operations**: Running setup scripts multiple times is safe

## Common Patterns

### Adding a New Tool
1. Create directory: `<category>/<tool>/`
2. Add config files and `dot.yaml`
3. Define links (config file → home location)
4. Define installs (platform-specific if needed)
5. Run `./script/setup --install` to apply

### Debugging Installation Issues
- Check punch output for failed installs
- Verify PATH includes tool locations: `echo $PATH`
- For brew-dependent tools, ensure Pass 1 completed successfully
- On Codespaces, check `/workspaces/.codespaces/.persistedshare/dotfiles` exists
- On Codespaces, NVM may be at `/usr/local/share/nvm` — the setup handles both locations
- Check `DOTFILES_DIR` is exported correctly during install (used by `.defaults.yaml` brew helper)

### Updating Tool Configs
1. Edit files in `dotfiles/<category>/<tool>/`
2. Changes take effect immediately (files are symlinked)
3. If modifying `dot.yaml`, run `./script/setup --install` to re-apply

## Tips
- Run `./script/bootstrap` for first-time setup (does everything)
- Use `make bootstrap` as a shortcut (calls the script)
- First punch pass uses `|| true` to continue even if some tools fail (expected)
- After changing PATH-modifying configs, run `exec $SHELL` to reload
- Use `depends:` in `dot.yaml` for tools that require other tools to be installed first

## Commit Messages
- Format: `<type>(<scope>): summary`
- Types: `build|ci|docs|feat|fix|perf|refactor|test`
- Summary: lower-case, present tense, no period
- Make atomic commits
