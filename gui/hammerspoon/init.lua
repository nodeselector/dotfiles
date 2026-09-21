-- Hammerspoon configuration

-- ControlEscape: tap Ctrl for Escape, hold for Ctrl
hs.loadSpoon('ControlEscape'):start()

-- CLI tool for Hammerspoon
hs.ipc.cliInstall()

-- Window toggles and floating automation (Obsidian, Discord/Slack, Little Arc, browser)
local windowToggle = require("window-toggle")
windowToggle.start()
