-- Hammerspoon configuration

-- ControlEscape: tap Ctrl for Escape, hold for Ctrl
hs.loadSpoon('ControlEscape'):start()

-- CLI tool for Hammerspoon
hs.ipc.cliInstall()

-- Keep Little Arc floating and restore regular Arc windows to tiling.
local arcWindows = require("arc-windows")
arcWindows.start()

-- Follow the TESmart KVM's active input when placing workspace 10.
package.loaded["kvm-workspace"] = nil
local kvmWorkspace = require("kvm-workspace")
kvmWorkspace.start()
