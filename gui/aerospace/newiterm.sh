#!/bin/bash
# Open a new iTerm window (works whether iTerm is running or not)

if ! pgrep -q "iTerm2"; then
    # iTerm not running - just open it (it will create a window automatically)
    open -a iTerm
else
    # iTerm is running - create a new window
    osascript -e 'tell application "iTerm2" to create window with default profile'
fi
