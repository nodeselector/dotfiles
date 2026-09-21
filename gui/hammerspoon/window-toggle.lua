--- window-toggle.lua
--- Global hotkeys for floating app toggles.
---
--- App toggles use native hide/show while AeroSpace keeps their windows floating.
--- Topit mirrors selected app windows at NSFloatingWindowLevel so they stay visible.
---
--- ALT-N: toggle Obsidian (launches it when it is not running)
--- ALT-S: group-toggle already-running Discord and Slack apps
--- Arc windows: start floating; big windows are re-tiled and Little Arc stays phone-sized

local M = {}
local axuielement = require("hs.axuielement")

-- ─── Configuration ───────────────────────────────────────────────────────────

hs.window.animationDuration = 0

local AEROSPACE = "/opt/homebrew/bin/aerospace"
local OSASCRIPT = "/usr/bin/osascript"
local TOPIT_BUNDLE_ID = "com.lihaoyun6.Topit"
local TOPIT_APP_PATH = "/Applications/Topit.app"
local TOPIT_LAYER_PREFIX = "Topit Layer"
local OBSIDIAN_BUNDLE_ID = "md.obsidian"
local ARC_BUNDLE_ID = "company.thebrowser.Browser"
local BIG_ARC_IDENTIFIER_PREFIX = "bigBrowserWindow-"
local LITTLE_ARC_IDENTIFIER_PREFIX = "littleBrowserWindow-"
local LITTLE_ARC_WIDTH = 540
local LITTLE_ARC_HEIGHT = 860
local SOCIAL_BUNDLE_IDS = {
    "com.hnc.Discord",
    "com.tinyspeck.slackmacgap",
    "com.tinyspeck.chatlyio",
}

-- ─── State ───────────────────────────────────────────────────────────────────

local lastSocialBundleId = nil
local arcWindowFilter = nil
local arcWindowTimers = {}
local topitQueue = {}
local topitBusy = false

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function aerospaceFloat(w, onComplete)
    if not w then return end
    local wid = w:id()
    if wid then
        print(string.format("[window-toggle] float wid=%s", tostring(wid)))
        hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
            print(string.format("[window-toggle] float exit=%d stderr=%s", exitCode, stderr or ""))
            if onComplete then onComplete(exitCode) end
        end, {"layout", "floating", "--window-id", tostring(wid)}):start()
    end
end

local function aerospaceTile(w, onComplete)
    if not w then return end
    local wid = w:id()
    if wid then
        print(string.format("[window-toggle] tile wid=%s", tostring(wid)))
        hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
            print(string.format("[window-toggle] tile exit=%d stderr=%s", exitCode, stderr or ""))
            if onComplete then onComplete(exitCode) end
        end, {"layout", "tiling", "--window-id", tostring(wid)}):start()
    end
end

local function findWindowById(wid)
    if not wid then return nil end
    for _, w in ipairs(hs.window.allWindows()) do
        if w:id() == wid then return w end
    end
    return nil
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

local function standardApplicationWindows(app)
    local windows = {}
    if not app then return windows end

    for _, w in ipairs(app:allWindows()) do
        local ok, isStandard = pcall(function() return w:isStandard() end)
        if w:id() and ok and isStandard then
            table.insert(windows, w)
        end
    end
    return windows
end

local function startTopitInBackground()
    if hs.application.get(TOPIT_BUNDLE_ID) then return true end
    if not hs.fs.attributes(TOPIT_APP_PATH) then
        print(string.format("[window-toggle] Topit is not installed at %s", TOPIT_APP_PATH))
        return false
    end

    hs.task.new("/usr/bin/open", function(exitCode, _, stderr)
        if exitCode ~= 0 then
            print(string.format("[window-toggle] Topit launch failed: %s", stderr or ""))
        end
    end, {"-gj", "-b", TOPIT_BUNDLE_ID}):start()
    return true
end

local function topitOverlayForWindow(w)
    if not w or not w:id() then return nil end
    local app = hs.application.get(TOPIT_BUNDLE_ID)
    if not app then return nil end

    local title = TOPIT_LAYER_PREFIX .. tostring(w:id())
    for _, overlay in ipairs(app:allWindows()) do
        local overlayTitle = overlay:title() or ""
        if overlayTitle == title or overlayTitle == title .. "O" then
            return overlay
        end
    end
    return nil
end

local function isTopitPinned(w)
    return topitOverlayForWindow(w) ~= nil
end

local processTopitQueue

local function finishTopitQueueItem(success)
    local item = table.remove(topitQueue, 1)
    topitBusy = false
    if item and item.onComplete then
        local ok, err = pcall(item.onComplete, success)
        if not ok then
            print(string.format("[window-toggle] Topit callback failed: %s", tostring(err)))
        end
    end
    processTopitQueue()
end

local function runTopitToggle(item, attempt)
    local w = findWindowById(item.windowId)
    if not w then
        finishTopitQueueItem(false)
        return
    end

    if isTopitPinned(w) == item.shouldPin then
        finishTopitQueueItem(true)
        return
    end

    local app = w:application()
    if app and app:isHidden() then app:unhide() end
    w:focus()

    hs.timer.doAfter(0.20, function()
        w = findWindowById(item.windowId)
        if not w then
            finishTopitQueueItem(false)
            return
        end

        local focused = hs.window.focusedWindow()
        if (not focused or focused:id() ~= w:id()) and attempt < 3 then
            runTopitToggle(item, attempt + 1)
            return
        end

        local savedMouse = nil
        local scriptCommand = "toggle frontmost"
        if not item.shouldPin then
            -- Topit's frontmost toggle cannot reliably identify an already mirrored
            -- source window. Its under-mouse toggle ignores the floating mirror and
            -- finds the focused layer-0 source beneath it.
            savedMouse = hs.mouse.absolutePosition()
            local frame = w:frame()
            hs.mouse.absolutePosition({
                x = frame.x + frame.w / 2,
                y = frame.y + frame.h / 2,
            })
            scriptCommand = "toggle under mouse"
        end

        hs.timer.doAfter(savedMouse and 0.10 or 0, function()
            local script = string.format('tell application "Topit" to %s', scriptCommand)
            hs.task.new(OSASCRIPT, function(exitCode, _, stderr)
                if savedMouse then hs.mouse.absolutePosition(savedMouse) end
                if exitCode ~= 0 then
                    print(string.format("[window-toggle] Topit command failed: %s", stderr or ""))
                end

                hs.timer.doAfter(0.35, function()
                    local current = findWindowById(item.windowId)
                    local succeeded = current and isTopitPinned(current) == item.shouldPin
                    if not succeeded and attempt < 3 then
                        runTopitToggle(item, attempt + 1)
                    else
                        print(string.format("[window-toggle] Topit %s wid=%s success=%s",
                            item.shouldPin and "pin" or "unpin",
                            tostring(item.windowId), tostring(succeeded)))
                        finishTopitQueueItem(succeeded)
                    end
                end)
            end, {"-e", script}):start()
        end)
    end)
end

processTopitQueue = function()
    if topitBusy or #topitQueue == 0 then return end
    topitBusy = true

    local item = topitQueue[1]
    if not startTopitInBackground() then
        finishTopitQueueItem(false)
        return
    end

    local attempts = 0
    local function waitForTopit()
        if hs.application.get(TOPIT_BUNDLE_ID) then
            runTopitToggle(item, 1)
            return
        end
        attempts = attempts + 1
        if attempts >= 20 then
            print("[window-toggle] timed out waiting for Topit")
            finishTopitQueueItem(false)
            return
        end
        hs.timer.doAfter(0.10, waitForTopit)
    end
    waitForTopit()
end

local function setTopitPinned(w, shouldPin, onComplete)
    if not w or not w:id() then
        if onComplete then onComplete(false) end
        return
    end

    table.insert(topitQueue, {
        windowId = w:id(),
        shouldPin = shouldPin,
        onComplete = onComplete,
    })
    processTopitQueue()
end

local function setTopitPinnedForWindows(windows, shouldPin, onComplete)
    local ids = {}
    local unique = {}
    for _, w in ipairs(windows or {}) do
        if w:id() and not ids[w:id()] then
            ids[w:id()] = true
            table.insert(unique, w)
        end
    end

    local index = 1
    local allSucceeded = true
    local function nextWindow()
        local w = unique[index]
        if not w then
            if onComplete then onComplete(allSucceeded) end
            return
        end
        index = index + 1
        setTopitPinned(w, shouldPin, function(success)
            allSucceeded = allSucceeded and success
            nextWindow()
        end)
    end
    nextWindow()
end

local function floatApplicationWindows(app)
    for _, w in ipairs(app:allWindows()) do
        aerospaceFloat(w)
    end
end

local function arcWindowIdentifier(w)
    if not w then return nil end

    local ok, result = pcall(function()
        local app = w:application()
        if not app or app:bundleID() ~= ARC_BUNDLE_ID then
            return nil
        end

        local element = axuielement.windowElement(w)
        return element and element:attributeValue("AXIdentifier")
    end)

    return ok and result or nil
end

local function identifierHasPrefix(identifier, prefix)
    return type(identifier) == "string"
        and identifier:sub(1, #prefix) == prefix
end

local function isLittleArcWindow(w)
    return identifierHasPrefix(arcWindowIdentifier(w), LITTLE_ARC_IDENTIFIER_PREFIX)
end

local function isBigArcWindow(w)
    return identifierHasPrefix(arcWindowIdentifier(w), BIG_ARC_IDENTIFIER_PREFIX)
end

local function resizeLittleArcWindow(w)
    if not isLittleArcWindow(w) then return end

    local screen = w:screen()
    if not screen then return end

    local screenFrame = screen:frame()
    local currentFrame = w:frame()
    local width = math.min(LITTLE_ARC_WIDTH, screenFrame.w)
    local height = math.min(LITTLE_ARC_HEIGHT, screenFrame.h)
    local maxX = screenFrame.x + screenFrame.w - width
    local maxY = screenFrame.y + screenFrame.h - height
    local x = math.max(screenFrame.x, math.min(currentFrame.x, maxX))
    local y = math.max(screenFrame.y, math.min(currentFrame.y, maxY))

    w:setFrame({x = x, y = y, w = width, h = height}, 0)
end

local function floatLittleArcWindow(w)
    if isLittleArcWindow(w) then
        print(string.format("[window-toggle] floating Little Arc wid=%s", tostring(w:id())))
        aerospaceFloat(w, function()
            hs.timer.doAfter(0.05, function()
                resizeLittleArcWindow(w)
            end)
        end)
    end
end

local function restoreBigArcTiling(w)
    if isBigArcWindow(w) then
        print(string.format("[window-toggle] tiling big Arc wid=%s", tostring(w:id())))
        aerospaceTile(w)
    end
end

local function queueArcLayout(w)
    local ok, wid = pcall(function() return w and w:id() end)
    if not ok or not wid then return end

    if arcWindowTimers[wid] then
        arcWindowTimers[wid]:stop()
    end
    arcWindowTimers[wid] = hs.timer.doAfter(0.05, function()
        arcWindowTimers[wid] = nil
        if isLittleArcWindow(w) then
            floatLittleArcWindow(w)
        else
            restoreBigArcTiling(w)
        end
    end)
end

local function startArcWindowWatcher()
    if arcWindowFilter then return end

    arcWindowFilter = hs.window.filter.new(false)
    arcWindowFilter:setAppFilter("Arc", {})
    arcWindowFilter:subscribe({
        hs.window.filter.windowCreated,
        hs.window.filter.windowFocused,
        hs.window.filter.windowUnminimized,
    }, function(w)
        queueArcLayout(w)
    end)

    hs.timer.doAfter(0.2, function()
        for _, app in ipairs(runningApplications({ARC_BUNDLE_ID})) do
            for _, w in ipairs(app:allWindows()) do
                queueArcLayout(w)
            end
        end
    end)
end

local function showAndPinApplication(app, finalWindow)
    if not app then return end
    app:unhide()
    if finalWindow then finalWindow:focus() else app:activate(true) end

    hs.timer.doAfter(0.10, function()
        local windows = standardApplicationWindows(app)
        floatApplicationWindows(app)
        setTopitPinnedForWindows(windows, true, function()
            local target = finalWindow and findWindowById(finalWindow:id())
            if target then target:focus() elseif app then app:activate(true) end
        end)
    end)
end

local function waitForApplicationWindow(bundleId, onReady, attempt)
    attempt = attempt or 1
    local app = runningApplications({bundleId})[1]
    local windows = standardApplicationWindows(app)
    if app and #windows > 0 then
        onReady(app, windows)
        return
    end
    if attempt >= 50 then
        print(string.format("[window-toggle] timed out waiting for %s window", bundleId))
        return
    end
    hs.timer.doAfter(0.10, function()
        waitForApplicationWindow(bundleId, onReady, attempt + 1)
    end)
end

local function toggleObsidian()
    local apps = runningApplications({OBSIDIAN_BUNDLE_ID})
    local app = apps[1]

    if not app then
        hs.application.launchOrFocusByBundleID(OBSIDIAN_BUNDLE_ID)
        waitForApplicationWindow(OBSIDIAN_BUNDLE_ID, function(launchedApp, windows)
            showAndPinApplication(launchedApp, windows[1])
        end)
        return
    end

    if app:isFrontmost() and not app:isHidden() then
        setTopitPinnedForWindows(standardApplicationWindows(app), false, function()
            if app then app:hide() end
        end)
        return
    end

    local windows = standardApplicationWindows(app)
    showAndPinApplication(app, app:mainWindow() or windows[1])
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
        local windows = {}
        for _, app in ipairs(apps) do
            for _, w in ipairs(standardApplicationWindows(app)) do
                table.insert(windows, w)
            end
        end
        setTopitPinnedForWindows(windows, false, function()
            for _, runningApp in ipairs(apps) do
                if runningApp then runningApp:hide() end
            end
        end)
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

    hs.timer.doAfter(0.10, function()
        local windows = {}
        for _, runningApp in ipairs(apps) do
            floatApplicationWindows(runningApp)
            for _, w in ipairs(standardApplicationWindows(runningApp)) do
                table.insert(windows, w)
            end
        end
        setTopitPinnedForWindows(windows, true, function()
            if focusApp then focusApp:activate(true) end
        end)
    end)
end

-- ─── Hotkey binding ──────────────────────────────────────────────────────────

function M.start()
    startTopitInBackground()
    startArcWindowWatcher()

    hs.hotkey.bind({"alt"}, "N", toggleObsidian)
    hs.hotkey.bind({"alt"}, "S", toggleSocialGroup)

    -- Alt+; handled natively by iTerm's Guake-style hotkey window

    print("[window-toggle] hotkeys bound: Alt+N (Obsidian), Alt+S (Discord/Slack group)")
end

-- Expose helpers for console testing and extension from init.lua.
M.toggleObsidian = toggleObsidian
M.toggleSocialGroup = toggleSocialGroup
M.isLittleArcWindow = isLittleArcWindow
M.isBigArcWindow = isBigArcWindow
M.floatLittleArcWindow = floatLittleArcWindow
M.resizeLittleArcWindow = resizeLittleArcWindow
M.restoreBigArcTiling = restoreBigArcTiling
M.isTopitPinned = isTopitPinned
M.setTopitPinned = setTopitPinned
M.setTopitPinnedForWindows = setTopitPinnedForWindows

return M
