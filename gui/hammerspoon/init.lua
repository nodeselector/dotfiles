-- Hammerspoon configuration

-- ControlEscape: tap Ctrl for Escape, hold for Ctrl
hs.loadSpoon('ControlEscape'):start()

-- CLI tool for Hammerspoon
hs.ipc.cliInstall()

-- Window toggles (Alt+N for Obsidian, Alt+S for Discord/Slack, Alt+B for browser)
local windowToggle = require("window-toggle")
windowToggle.start()
