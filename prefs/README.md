# macOS Preferences Management

Tooling for backing up, restoring, and version-controlling macOS system settings (`defaults` plists).

## Quick Reference

| Command | What it does |
|---------|-------------|
| `make backup-prefs` | Export curated defaults + mackup backup |
| `make backup-defaults` | Export curated defaults only |
| `make restore-prefs` | Restore tracked defaults + mackup (**destructive**) |
| `make restore-prefs-dry` | Preview what restore would do |
| `make promote-default PLIST=... REASON="..."` | Track a plist in version control |
| `make validate-prefs` | Check defaults-safe matches lockfile |
| `make test-prefs` | Run bats tests for prefs tooling |

## How It Works

### Directory Layout

```
prefs/
├── defaults/              # Raw exports (gitignored, may contain secrets)
├── defaults-safe/         # Promoted plists safe for version control
├── defaults.lock.yaml     # Lockfile: allowlist + reasons for each tracked plist
├── domains.txt            # Curated list of safe domains to export
├── macos-defaults/        # Low-level export/import scripts (all domains)
│   ├── export_defaults.sh
│   └── import_defaults.sh
└── test/                  # bats tests for promote + validate logic
    ├── fixtures/
    ├── test-promote.bats
    └── test-validate.bats
```

### Two-Tier Export System

**Tier 1 — Curated export** (`make backup-defaults` / `make backup-prefs`):
- Exports only domains listed in `prefs/domains.txt`
- These are pre-vetted to not trigger TCC permission popups
- Output goes to `prefs/defaults/` (gitignored)

**Tier 2 — Full export** (`script/prefs-backup --defaults-all`):
- Exports ALL macOS defaults domains
- May trigger permission prompts (grant Full Disk Access to iTerm)
- Also goes to `prefs/defaults/` (gitignored)

### Promoting a Plist to Version Control

Not everything in `defaults/` is safe to commit. The promote workflow gates what gets tracked:

```bash
# 1. Back up current defaults
make backup-defaults

# 2. Review the exported plist (never commit blindly)
plutil -p prefs/defaults/com.apple.dock.plist

# 3. Promote it with a reason
make promote-default PLIST=com.apple.dock REASON="Dock layout, autohide, icon size - no secrets"
```

This copies the plist to `prefs/defaults-safe/` and adds an entry to `prefs/defaults.lock.yaml`.

### Lockfile (`defaults.lock.yaml`)

The lockfile serves as:
1. **Allowlist** — only plists listed here may exist in `defaults-safe/`
2. **Documentation** — each entry explains what the plist controls and why it's safe
3. **Validation source** — the pre-commit hook checks that `defaults-safe/` matches the lockfile

### Restoring Settings

```bash
# Preview what would be restored
make restore-prefs-dry

# Actually restore (overwrites current settings!)
make restore-prefs
```

Restore imports all plists from `defaults-safe/` via `defaults import`. Some changes require
restarting apps or running `killall Dock Finder SystemUIServer`.

## Safety Rules

### Never Commit from `defaults/`
The `prefs/defaults/` directory is gitignored because raw exports may contain auth tokens,
keychain references, browsing data, email accounts, or other sensitive system state.

### Never Promote These Domains
- `com.apple.accountsd` — auth tokens
- `com.apple.security*` — keychain references
- `com.apple.mail` — email account details
- `com.apple.Safari` — browsing data
- Anything with `tokens`, `credentials`, or `secrets` in the domain name

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) and require `yq`:

```bash
brew install bats-core yq
make test-prefs
```
