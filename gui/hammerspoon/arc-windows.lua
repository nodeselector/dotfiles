--- Keep Little Arc previews floating and phone-sized while regular Arc windows tile.

local M = {}
local axuielement = require("hs.axuielement")

hs.window.animationDuration = 0

local AEROSPACE = "/opt/homebrew/bin/aerospace"
local ARC_BUNDLE_ID = "company.thebrowser.Browser"
local BIG_ARC_IDENTIFIER_PREFIX = "bigBrowserWindow-"
local LITTLE_ARC_IDENTIFIER_PREFIX = "littleBrowserWindow-"
local LITTLE_ARC_WIDTH = 540
local LITTLE_ARC_HEIGHT = 860

local arcWindowFilter = nil
local arcWindowTimers = {}

local function aerospaceFloat(w, onComplete)
    if not w then return end
    local wid = w:id()
    if wid then
        print(string.format("[arc-windows] float wid=%s", tostring(wid)))
        hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
            print(string.format("[arc-windows] float exit=%d stderr=%s", exitCode, stderr or ""))
            if onComplete then onComplete(exitCode) end
        end, {"layout", "floating", "--window-id", tostring(wid)}):start()
    end
end

local function aerospaceTile(w, onComplete)
    if not w then return end
    local wid = w:id()
    if wid then
        print(string.format("[arc-windows] tile wid=%s", tostring(wid)))
        hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
            print(string.format("[arc-windows] tile exit=%d stderr=%s", exitCode, stderr or ""))
            if onComplete then onComplete(exitCode) end
        end, {"layout", "tiling", "--window-id", tostring(wid)}):start()
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
        print(string.format("[arc-windows] floating Little Arc wid=%s", tostring(w:id())))
        aerospaceFloat(w, function()
            hs.timer.doAfter(0.05, function()
                resizeLittleArcWindow(w)
            end)
        end)
    end
end

local function restoreBigArcTiling(w)
    if isBigArcWindow(w) then
        print(string.format("[arc-windows] tiling big Arc wid=%s", tostring(w:id())))
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

function M.start()
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
        for _, app in ipairs(hs.application.applicationsForBundleID(ARC_BUNDLE_ID) or {}) do
            for _, w in ipairs(app:allWindows()) do
                queueArcLayout(w)
            end
        end
    end)
end

M.isLittleArcWindow = isLittleArcWindow
M.isBigArcWindow = isBigArcWindow
M.floatLittleArcWindow = floatLittleArcWindow
M.resizeLittleArcWindow = resizeLittleArcWindow
M.restoreBigArcTiling = restoreBigArcTiling

return M
