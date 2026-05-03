#!/usr/bin/env bash
# tmux-fzf-keys: fzf search through tmux keybindings with friendly descriptions
set -euo pipefail

CACHE="$HOME/.local/state/tmux-keys-cache.txt"
CONF="$HOME/.tmux.conf"
mkdir -p "$(dirname "$CACHE")"

# Rebuild cache if tmux.conf is newer or cache doesn't exist
if [[ ! -f "$CACHE" ]] || [[ "$CONF" -nt "$CACHE" ]]; then
  cat > "$CACHE" << 'KEYS'
── Prefix Keys (Ctrl-a + key) ──────────────────────────────────────────
prefix + /         Search scrollback with fzf (multi-select, copies to clipboard)
prefix + ?         Search all keybindings (this screen)
prefix + h         Split pane horizontally (below)
prefix + v         Split pane vertically (right)
prefix + x         Kill current pane
prefix + !         Break pane to its own window
prefix + S         Swap pane (fzf pick from current window)
prefix + t         Toggle status bar
prefix + r         Reload tmux config
prefix + C-r       Rename current session
prefix + F         Fingers mode -- hint-based text selection and copy
prefix + J         Fingers jump mode -- move cursor to match position
prefix + Tab       Extrakto -- fuzzy extract text/paths/URLs from all panes
prefix + C-f       tmux-fzf -- fuzzy find sessions, windows, panes
prefix + Space     Quick actions menu (layouts, sync, logging, pane ops)
prefix + Y         Toggle synchronize-panes (type in all panes at once)
prefix + P         Start logging pane output to ~/tmux-logs/
prefix + M-p       Stop logging pane output
prefix + [         Enter copy mode (then v to select, y to copy, / to search)
prefix + ]         Paste from macOS clipboard
prefix + z         Toggle pane zoom (fullscreen)
prefix + ;         Jump to last active pane
prefix + L         Jump to last session
prefix + d         Detach from session
prefix + c         New window
prefix + n         Next window
prefix + p         Previous window
prefix + 1-9       Switch to window by number
prefix + ,         Rename current window
prefix + &         Kill current window (with confirm)
prefix + w         Choose window from list
prefix + s         Choose session from list
prefix + I         TPM: install plugins
prefix + U         TPM: update plugins
prefix + =         Choose paste buffer
prefix + :         Command prompt

── Root Keys (no prefix needed) ────────────────────────────────────────
C-h/j/k/l          Navigate panes (vim-style, also works in vim/fzf)
C-S-H              Reorder: swap window left
C-S-L              Reorder: swap window right
C-S-J              Swap pane down
C-S-K              Swap pane up
M-H / M-L          Resize pane left/right by 5
M-J / M-K          Resize pane down/up by 3
M-i                Toggle scratch terminal popup (persistent session)

── Copy Mode (prefix + [ to enter) ────────────────────────────────────
v                   Begin selection (visual mode)
y                   Copy selection to clipboard (stay in copy mode)
Enter               Copy selection to clipboard and exit copy mode
/                   Search forward (matches highlighted in blue, current in orange)
?                   Search backward
n                   Next search match
N                   Previous search match
h/j/k/l             Navigate (vim-style)
w/b/e               Word navigation
0 / $               Start / end of line
g / G               Top / bottom of scrollback
C-u / C-d           Half-page up / down
q / Escape          Exit copy mode

── Extrakto (prefix + Tab to enter) ────────────────────────────────────
type                Fuzzy filter text from all panes in window
Tab                 Insert selection into current pane
Enter               Copy selection to clipboard
Ctrl-f              Cycle filter: word -> path -> url -> line
Ctrl-g              Toggle grab area (current pane vs all window panes)
Ctrl-e              Open in editor
Ctrl-o              Open (URLs in browser, files in default app)

── Fingers Mode (prefix + F to enter) ──────────────────────────────────
a-z                 Copy highlighted match to clipboard
Shift + a-z         Copy match and paste it
Ctrl + a-z          Copy match and open it (URLs in browser, etc.)
Alt + a-z           Copy match with alt-action
Tab                 Toggle multi-select mode
Space               fzf filter matches
q / Escape / C-c    Exit fingers mode

── Hooks (automatic) ───────────────────────────────────────────────────
client-resized      Spreads panes evenly on terminal resize
KEYS
fi

fzf --reverse --ansi \
    --header="tmux keybindings · type to filter · esc to close" \
    --color="header:italic" \
    < "$CACHE"
