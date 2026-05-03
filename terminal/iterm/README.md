# iTerm2

- Dynamic profiles are linked from `terminal/iterm/profile.json` to `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles-profile.json`.
- Profiles provided:
  - **Dotfiles Guake** — Guid `EF56683E-FF62-482A-A5A4-4345EE0B3593`
  - **Dotfiles Default** — Guid `53D012C0-31AC-44CD-861A-F9D97AC559F8`
- If you see warnings like `Dynamic profile with Guid ... conflicts with non-dynamic profile with same Guid`:
  1. Ensure you have the latest dotfiles (GUIDs above).
  2. Run `./terminal/iterm/cleanup-iterm-conflicts.py` (backs up `com.googlecode.iterm2.plist`).
  3. Restart iTerm2.

`terminal/iterm/setup-iterm.sh` installs shell integration, adds a `dev-profile.json` once, and runs the cleanup script automatically when available.
