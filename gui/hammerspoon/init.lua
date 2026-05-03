-- Hammerspoon configuration

-- ControlEscape: tap Ctrl for Escape, hold for Ctrl
hs.loadSpoon('ControlEscape'):start()

-- CLI tool for Hammerspoon
hs.ipc.cliInstall()

-- Window toggles (Alt+S for Slack, Alt+B for browser)
local windowToggle = require("window-toggle")
windowToggle.start()
