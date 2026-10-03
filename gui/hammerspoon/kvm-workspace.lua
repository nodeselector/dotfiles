--- Keep workspace 10 on the display that is actually showing this Mac.
---
--- The TESmart KVM emulates the Odyssey and Moonlander on inactive inputs, so
--- normal display and USB presence checks cannot reveal the selected computer.
--- The helper sends a read-only Oryx protocol query to the physical Moonlander;
--- only the selected KVM input receives a response.

local M = {}

local AEROSPACE = "/opt/homebrew/bin/aerospace"
local DETECTOR = os.getenv("HOME") .. "/.local/bin/moonlander-active"
local WORKSPACE = "10"
local ODYSSEY = "^Odyssey G95SC$"
local ODYSSEY_NAME = "Odyssey G95SC"
local BUILT_IN = "built-in retina display$"
local BUILT_IN_NAME = "Built-in Retina Display"
local POLL_INTERVAL_SECONDS = 2
local INACTIVE_CONFIRMATIONS = 2

local pollTimer = nil
local mouseGuard = nil
local detectorTask = nil
local reconcileTask = nil
local currentState = nil
local pendingState = nil
local pendingCount = 0

local function screenNamed(name)
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() == name then return screen end
    end
    return nil
end

local function keepMouseOnBuiltInDisplay()
    local builtIn = screenNamed(BUILT_IN_NAME)
    if not builtIn then return end

    local point = hs.mouse.absolutePosition()
    local frame = builtIn:fullFrame()
    local inset = 2
    local clamped = {
        x = math.max(frame.x + inset, math.min(point.x, frame.x + frame.w - inset)),
        y = math.max(frame.y + inset, math.min(point.y, frame.y + frame.h - inset)),
    }

    if clamped.x ~= point.x or clamped.y ~= point.y then
        hs.mouse.absolutePosition(clamped)
    end
end

local function moveWorkspace(active)
    local monitor = active and ODYSSEY or BUILT_IN
    hs.task.new(AEROSPACE, function(exitCode, _, stderr)
        if exitCode == 0 then
            print(string.format("[kvm-workspace] workspace %s -> %s", WORKSPACE, monitor))
        else
            print(string.format(
                "[kvm-workspace] move failed exit=%d monitor=%s stderr=%s",
                exitCode,
                monitor,
                stderr or ""
            ))
        end
    end, {"move-workspace-to-monitor", "--workspace", WORKSPACE, monitor}):start()
end

local function reconcileWorkspace(active)
    if reconcileTask and reconcileTask:isRunning() then return end

    local expectedMonitor = active and ODYSSEY_NAME or BUILT_IN_NAME
    reconcileTask = hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        reconcileTask = nil
        if exitCode ~= 0 then
            print(string.format(
                "[kvm-workspace] workspace query failed exit=%d stderr=%s",
                exitCode,
                stderr or ""
            ))
            return
        end

        local workspaceLine = WORKSPACE .. "\t([^\n]+)"
        local currentMonitor = stdout:match("^" .. workspaceLine)
            or stdout:match("\n" .. workspaceLine)
        if currentMonitor and currentMonitor ~= expectedMonitor then
            moveWorkspace(active)
        end
    end, {"list-workspaces", "--all", "--format", "%{workspace}\t%{monitor-name}"})
    reconcileTask:start()
end

local function observe(active)
    if active == currentState then
        pendingState = nil
        pendingCount = 0
        reconcileWorkspace(active)
        return
    end

    if active ~= pendingState then
        pendingState = active
        pendingCount = 1
    else
        pendingCount = pendingCount + 1
    end

    -- Switching to the Odyssey is confirmed by a real keyboard response. Give
    -- timeouts two polls so one dropped HID packet does not move the workspace.
    local confirmations = active and 1 or INACTIVE_CONFIRMATIONS
    if pendingCount >= confirmations then
        currentState = active
        pendingState = nil
        pendingCount = 0
        if not active then keepMouseOnBuiltInDisplay() end
        reconcileWorkspace(active)
    end
end

local function poll()
    if detectorTask and detectorTask:isRunning() then return end

    detectorTask = hs.task.new(DETECTOR, function(exitCode, _, stderr)
        detectorTask = nil
        if exitCode == 0 then
            observe(true)
        elseif exitCode == 1 then
            observe(false)
        else
            print(string.format(
                "[kvm-workspace] detector failed exit=%d stderr=%s",
                exitCode,
                stderr or ""
            ))
        end
    end, {})

    if not detectorTask:start() then
        detectorTask = nil
        print("[kvm-workspace] could not start " .. DETECTOR)
    end
end

function M.start()
    -- Hammerspoon can retain required modules across hs.reload(). Restart any
    -- existing watchers instead of leaving stopped timers behind.
    if pollTimer then M.stop() end

    if not hs.fs.attributes(DETECTOR) then
        print("[kvm-workspace] detector missing: " .. DETECTOR)
        return
    end

    -- Hammerspoon's event tap does not see every synthetic/high-resolution
    -- mouse event, so use a lightweight positional guard while the KVM is away.
    mouseGuard = hs.timer.doEvery(0.1, function()
        if currentState ~= false then return end

        local screen = hs.mouse.getCurrentScreen()
        if screen and screen:name() == ODYSSEY_NAME then
            keepMouseOnBuiltInDisplay()
        end
    end)

    poll()
    pollTimer = hs.timer.doEvery(POLL_INTERVAL_SECONDS, poll)
end

function M.isPersonalInputActive()
    return currentState
end

function M.stop()
    if pollTimer then
        pollTimer:stop()
        pollTimer = nil
    end
    if mouseGuard then
        mouseGuard:stop()
        mouseGuard = nil
    end
    if detectorTask and detectorTask:isRunning() then
        detectorTask:terminate()
    end
    if reconcileTask and reconcileTask:isRunning() then
        reconcileTask:terminate()
    end
    detectorTask = nil
    reconcileTask = nil
end

return M
