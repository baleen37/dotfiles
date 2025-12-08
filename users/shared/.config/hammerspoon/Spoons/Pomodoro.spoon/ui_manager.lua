-- ui_manager.lua
local utils = require("utils")

local UIManager = {}
UIManager.__index = UIManager

function UIManager:new()
    local self = setmetatable({}, UIManager)
    self.menuBarItem = nil
    return self
end

function UIManager:getMenuBarItem()
    return self.menuBarItem
end

function UIManager:setMenuBarItem(item)
    self.menuBarItem = item
end

function UIManager:updateMenuBarText(sessionType, timeLeft)
    if not self.menuBarItem then
        return
    end

    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    local emoji = sessionType == "Break" and "☕" or "🍅"
    local title = emoji .. " " .. string.format("%02d:%02d", minutes, seconds)

    if not utils.safeCall(function()
        self.menuBarItem:setTitle(title)
    end).success then
        print("[Pomodoro Error] Failed to update menubar title")
    end
end

function UIManager:updateMenuBarReady()
    if not self.menuBarItem then
        return
    end

    if not utils.safeCall(function()
        self.menuBarItem:setTitle("🍅 Ready")
    end).success then
        print("[Pomodoro Error] Failed to update menubar to ready state")
    end
end

function UIManager:updateMenu(state, pomodoroObj)
    if not self.menuBarItem then
        return
    end

    local menuItems = {}

    if state:isRunning() then
        local status = state:isBreak() and "Break" or "Work"
        local formatTime = function(seconds)
            local minutes = math.floor(seconds / 60)
            local secs = seconds % 60
            return string.format("%02d:%02d", minutes, secs)
        end

        table.insert(menuItems, {
            title = string.format("Status: %s (%s)", status, formatTime(state:getTimeLeft())),
            disabled = true
        })

        table.insert(menuItems, {
            title = "Stop Session",
            fn = function()
                if pomodoroObj then
                    pomodoroObj:stopSession()
                end
            end
        })
    else
        table.insert(menuItems, {
            title = "Start Session",
            fn = function()
                if pomodoroObj then
                    pomodoroObj:startSession()
                end
            end
        })
    end

    table.insert(menuItems, { title = "-" })

    -- Statistics
    local today = os.date("%Y-%m-%d")
    local stats = hs.settings.get("pomodoro.stats") or {}
    local todaySessions = stats[today] or 0

    table.insert(menuItems, {
        title = string.format("Today: %d sessions", todaySessions),
        disabled = true
    })

    table.insert(menuItems, {
        title = "Reset Stats",
        fn = function()
            local today = os.date("%Y-%m-%d")
            local stats = hs.settings.get("pomodoro.stats") or {}
            stats[today] = 0
            hs.settings.set("pomodoro.stats", stats)
            if pomodoroObj then
                pomodoroObj.state:setSessionsCompleted(0)
            end
        end
    })

    table.insert(menuItems, { title = "-" })

    table.insert(menuItems, {
        title = "Quit",
        fn = function()
            if pomodoroObj then
                pomodoroObj:stop()
            end
        end
    })

    if not utils.safeCall(function()
        self.menuBarItem:setMenu(menuItems)
    end).success then
        print("[Pomodoro Error] Failed to update menubar menu")
    end
end

return UIManager