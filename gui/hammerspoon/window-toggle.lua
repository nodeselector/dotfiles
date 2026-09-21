--- window-toggle.lua
--- Global hotkeys for floating app toggles and captured scratch windows.
---
--- App toggles use native hide/show while AeroSpace keeps their windows floating.
--- Captured slots use AeroSpace scratch workspace Z and centered positioning.
---
--- ALT-N: toggle Obsidian (launches it when it is not running)
--- ALT-S: group-toggle already-running Discord and Slack apps
--- ALT-B: toggle slot "browser" (captures whatever window is focused)
--- ALT-SHIFT-B: clear browser capture so next ALT-B grabs a new window

local M = {}

-- ─── Configuration ───────────────────────────────────────────────────────────

hs.window.animationDuration = 0

local CENTER_WIDTH_RATIO = 0.65
local CENTER_HEIGHT_RATIO = 0.80
local SCRATCH_WORKSPACE = "Z"
local AEROSPACE = "/opt/homebrew/bin/aerospace"
local OBSIDIAN_BUNDLE_ID = "md.obsidian"
local SOCIAL_BUNDLE_IDS = {
    "com.hnc.Discord",
    "com.tinyspeck.slackmacgap",
    "com.tinyspeck.chatlyio",
}

-- ─── Slot state ──────────────────────────────────────────────────────────────

-- Each slot: { windowId, appName, isHidden }
local slots = {}
local lastSocialBundleId = nil

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

local function runningApplications(bundleIds)
    local apps = {}
    for _, bundleId in ipairs(bundleIds) do
        for _, app in ipairs(hs.application.applicationsForBundleID(bundleId) or {}) do
            table.insert(apps, app)
        end
    end
    return apps
end

local function floatApplicationWindows(app)
    for _, w in ipairs(app:allWindows()) do
        aerospaceFloat(w)
    end
end

local function toggleObsidian()
    local apps = runningApplications({OBSIDIAN_BUNDLE_ID})
    local app = apps[1]

    if not app then
        hs.application.launchOrFocusByBundleID(OBSIDIAN_BUNDLE_ID)
        return
    end

    if app:isFrontmost() and not app:isHidden() then
        app:hide()
        return
    end

    app:unhide()
    app:activate(true)
    hs.timer.doAfter(0.05, function()
        floatApplicationWindows(app)
    end)
end

local function toggleSocialGroup()
    local apps = runningApplications(SOCIAL_BUNDLE_IDS)
    if #apps == 0 then
        print("[window-toggle] social group: no running apps")
        return
    end

    local anyShown = false
    for _, app in ipairs(apps) do
        if app:isFrontmost() then
            lastSocialBundleId = app:bundleID()
        end
        if not app:isHidden() then
            anyShown = true
            lastSocialBundleId = lastSocialBundleId or app:bundleID()
        end
    end

    if anyShown then
        print(string.format("[window-toggle] hiding %d running social app(s)", #apps))
        for _, app in ipairs(apps) do
            app:hide()
        end
        return
    end

    print(string.format("[window-toggle] showing %d running social app(s)", #apps))
    local focusApp = apps[1]
    for _, app in ipairs(apps) do
        app:unhide()
        if app:bundleID() == lastSocialBundleId then
            focusApp = app
        end
    end

    hs.timer.doAfter(0.05, function()
        for _, app in ipairs(apps) do
            floatApplicationWindows(app)
        end
        focusApp:activate(true)
    end)
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
    hs.hotkey.bind({"alt"}, "N", toggleObsidian)
    hs.hotkey.bind({"alt"}, "S", toggleSocialGroup)

    -- Browser remains a manual capture slot: press on a window to capture it.
    hs.hotkey.bind({"alt"}, "B", function() toggleSlot("browser") end)
    hs.hotkey.bind({"alt", "shift"}, "B", function() clearSlot("browser") end)

    -- Alt+; handled natively by iTerm's Guake-style hotkey window

    print("[window-toggle] hotkeys bound: Alt+N (Obsidian), Alt+S (Discord/Slack group), Alt+B (browser)")
end

-- Expose helpers for console testing and extension from init.lua.
M.toggleObsidian = toggleObsidian
M.toggleSocialGroup = toggleSocialGroup
M.toggleSlot = toggleSlot
M.clearSlot = clearSlot
M.captureForSlot = captureForSlot

return M
