--- window-toggle.lua
--- Global hotkeys to toggle app windows with centered positioning.
---
--- Each "slot" captures a specific window and toggles it via AeroSpace
--- scratch workspace Z. Windows appear centered and floating.
---
--- ALT-S: toggle slot "slack" (auto-captures Slack's main window)
--- ALT-B: toggle slot "browser" (captures whatever window is focused)
--- ALT-SHIFT-B: clear browser capture so next ALT-B grabs a new window

local M = {}

-- ─── Configuration ───────────────────────────────────────────────────────────

hs.window.animationDuration = 0

local CENTER_WIDTH_RATIO = 0.65
local CENTER_HEIGHT_RATIO = 0.80
local SCRATCH_WORKSPACE = "Z"
local AEROSPACE = "/opt/homebrew/bin/aerospace"

-- ─── Slot state ──────────────────────────────────────────────────────────────

-- Each slot: { windowId, appName, isHidden }
local slots = {}

local function getSlot(name)
    if not slots[name] then
        slots[name] = { windowId = nil, appName = nil, isHidden = false }
    end
    return slots[name]
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function aerospaceFloat(w)
    if not w then return end
    local wid = w:id()
    if wid then
        print(string.format("[window-toggle] float wid=%s", tostring(wid)))
        hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
            print(string.format("[window-toggle] float exit=%d stderr=%s", exitCode, stderr or ""))
        end, {"layout", "floating", "--window-id", tostring(wid)}):start()
    end
end

local function centerWindow(w)
    local screen = w:screen()
    if not screen then return end
    local sf = screen:frame()
    local width = sf.w * CENTER_WIDTH_RATIO
    local height = sf.h * CENTER_HEIGHT_RATIO
    local x = sf.x + (sf.w - width) / 2
    local y = sf.y + (sf.h - height) / 2
    w:setFrame(hs.geometry.rect(x, y, width, height))
end

local function findWindowById(wid)
    if not wid then return nil end
    for _, w in ipairs(hs.window.allWindows()) do
        if w:id() == wid then return w end
    end
    return nil
end

local function focusNextVisible(excludeId)
    for _, w in ipairs(hs.window.orderedWindows()) do
        if w:id() ~= excludeId and w:isVisible() then
            w:focus()
            return
        end
    end
end

local function hideToScratch(w, slot)
    print(string.format("[window-toggle] hide %s -> workspace %s", slot.appName or "?", SCRATCH_WORKSPACE))
    slot.isHidden = true
    hs.task.new(AEROSPACE, function(exitCode, _, stderr)
        print(string.format("[window-toggle] move-to-scratch exit=%d stderr=%s", exitCode, stderr or ""))
    end, {"move-node-to-workspace", SCRATCH_WORKSPACE, "--window-id", tostring(w:id())}):start()
    focusNextVisible(w:id())
end

local function showFromScratch(w, slot)
    print(string.format("[window-toggle] show %s from workspace %s", slot.appName or "?", SCRATCH_WORKSPACE))
    slot.isHidden = false
    hs.task.new(AEROSPACE, function(_, stdout, _)
        local ws = (stdout or ""):match("^%s*(.-)%s*$")
        hs.task.new(AEROSPACE, function(e2, _, s2)
            print(string.format("[window-toggle] move-from-scratch exit=%d stderr=%s", e2, s2 or ""))
            hs.timer.doAfter(0.05, function()
                aerospaceFloat(w)
                hs.timer.doAfter(0.05, function()
                    centerWindow(w)
                    w:focus()
                end)
            end)
        end, {"move-node-to-workspace", ws or "1", "--window-id", tostring(w:id())}):start()
    end, {"list-workspaces", "--focused"}):start()
end

-- ─── Capture / clear ─────────────────────────────────────────────────────────

local function captureForSlot(slotName, w)
    local slot = getSlot(slotName)
    slot.windowId = w:id()
    slot.appName = w:application() and w:application():name() or "unknown"
    slot.isHidden = false
    local title = w:title() or "untitled"
    print(string.format("[window-toggle] captured [%s]: wid=%s app=%s title=%s",
        slotName, tostring(slot.windowId), slot.appName, title))
    hs.alert.show(string.format("[%s] Captured: %s -- %s", slotName, slot.appName, title))
end

local function clearSlot(slotName)
    local slot = getSlot(slotName)
    if slot.windowId then
        hs.alert.show(string.format("[%s] Cleared (%s). Press hotkey on new window.", slotName, slot.appName or "?"))
        slot.windowId = nil
        slot.appName = nil
        slot.isHidden = false
    else
        hs.alert.show(string.format("[%s] Nothing captured", slotName))
    end
end

-- ─── Generic slot toggle ────────────────────────────────────────────────────

--- Toggle a named slot.
local function toggleSlot(slotName)
    local slot = getSlot(slotName)
    local w = findWindowById(slot.windowId)

    if not w then
        -- Window is gone or never captured
        slot.windowId = nil

        -- Capture whatever is focused
        local focused = hs.window.focusedWindow()
        if focused then
            captureForSlot(slotName, focused)
        else
            hs.alert.show(string.format("[%s] No window to capture", slotName))
        end
        return
    end

    -- We have a live captured window -- toggle it
    local focused = hs.window.focusedWindow()
    local isFocused = focused and focused:id() == w:id()

    if not slot.isHidden and isFocused then
        hideToScratch(w, slot)
    else
        showFromScratch(w, slot)
    end
end

-- ─── Hotkey binding ──────────────────────────────────────────────────────────

function M.start()
    -- All slots are manual capture -- press hotkey on a window to capture, press again to toggle
    hs.hotkey.bind({"alt"}, "S", function() toggleSlot("slack") end)
    hs.hotkey.bind({"alt", "shift"}, "S", function() clearSlot("slack") end)

    hs.hotkey.bind({"alt"}, "B", function() toggleSlot("browser") end)
    hs.hotkey.bind({"alt", "shift"}, "B", function() clearSlot("browser") end)

    print("[window-toggle] hotkeys bound: Alt+S (slack), Alt+B (browser), Alt+Shift+[key] (clear)")
end

-- Expose for adding custom slots from init.lua
M.toggleSlot = toggleSlot
M.clearSlot = clearSlot
M.captureForSlot = captureForSlot

return M
