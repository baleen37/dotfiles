-- test/test_helper.lua
-- Mock Hammerspoon environment for testing

-- Mock hs module
local hs = {
    settings = {
        get = function(key)
            return mockSettings and mockSettings[key] or nil
        end,
        set = function(key, value)
            if not mockSettings then
                mockSettings = {}
            end
            mockSettings[key] = value
        end
    },
    application = {
        runningApplications = function()
            return mockApplications or {}
        end
    },
    notify = {
        show = function(title, informativeText)
            print(string.format("[NOTIFY] %s: %s", title, informativeText or ""))
        end
    },
    alert = function(message)
        print(string.format("[ALERT] %s", message))
    end,
    timer = {
        new = function(interval, fn)
            return {
                start = function()
                    print(string.format("[TIMER] Started with interval: %s", interval))
                    return mockTimerId or 1
                end,
                stop = function()
                    print("[TIMER] Stopped")
                end,
                running = function()
                    return mockTimerRunning or false
                end
            }
        end,
        doAfter = function(delay, fn)
            print(string.format("[TIMER] Scheduled after %s seconds", delay))
        end
    },
    menubar = function()
        return {
            setIcon = function(icon)
                print(string.format("[MENUBAR] Icon set to: %s", icon or "nil"))
            end,
            setTitle = function(title)
                print(string.format("[MENUBAR] Title set to: %s", title or "nil"))
            end,
            setTooltip = function(tooltip)
                print(string.format("[MENUBAR] Tooltip set to: %s", tooltip or "nil"))
            end,
            delete = function()
                print("[MENUBAR] Deleted")
            end
        }
    end,
    canvas = function(canvasAttrs)
        return {
            appendElements = function(elements)
                print(string.format("[CANVAS] Appended %d elements", #elements))
            end,
            clickActivating = function(fn)
                print("[CANVAS] Click handler set")
            end,
            show = function()
                print("[CANVAS] Shown")
            end,
            hide = function()
                print("[CANVAS] Hidden")
            end,
            delete = function()
                print("[CANVAS] Deleted")
            end
        }
    end,
    geometry = {
        rect = function(x, y, w, h)
            return {x = x, y = y, w = w, h = h}
        end
    },
    drawing = {
        color = {
            white = {hex = "#FFFFFF"},
            black = {hex = "#000000"}
        },
        text = {
            sizedText = function(fontSize, text)
                return {
                    text = text,
                    size = fontSize
                }
            end
        }
    },
    fnutils = {
        contains = function(tbl, item)
            for _, v in ipairs(tbl) do
                if v == item then return true end
            end
            return false
        end,
        map = function(tbl, fn)
            local result = {}
            for i, v in ipairs(tbl) do
                result[i] = fn(v)
            end
            return result
        end
    },
    inspect = function(obj)
        if type(obj) == "table" then
            return tostring(obj)
        end
        return tostring(obj)
    end,
    loadSpoon = function(name)
        if name == "Pomodoro" then
            return mockSpoon or {
                bindHotKeys = function() end,
                start = function() end,
                stop = function() end
            }
        end
        return nil
    end,
    hotkey = {
        new = function(mods, key, fn)
            return {
                enable = function() end,
                disable = function() end
            }
        end
    },
    pathwatcher = {
        new = function(path, fn)
            return {
                start = function() end,
                stop = function() end
            }
        end
    }
}

-- Set up global hs
_G.hs = hs

-- Mock data for tests
mockSettings = {}
mockApplications = {}
mockTimerId = 1
mockTimerRunning = false
mockSpoon = nil

-- Mock modules
package.preload["state_manager"] = function()
    local StateManager = {}
    StateManager.__index = StateManager

    function StateManager:new()
        local self = setmetatable({}, StateManager)
        self._running = false
        self._isBreak = false
        self.timeLeft = 0
        self.sessionsCompleted = 0
        self.sessionStartTime = nil
        self.timer = nil
        self.observers = {}
        return self
    end

    function StateManager:isRunning()
        return self._running
    end

    function StateManager:setRunning(value)
        self._running = value
        self:_notifyObservers("running", value)
    end

    function StateManager:isBreak()
        return self._isBreak
    end

    function StateManager:setBreak(value)
        self._isBreak = value
        self:_notifyObservers("isBreak", value)
    end

    function StateManager:getTimeLeft()
        return self.timeLeft
    end

    function StateManager:setTimeLeft(value)
        self.timeLeft = value
        self:_notifyObservers("timeLeft", value)
    end

    function StateManager:getTimer()
        return self.timer
    end

    function StateManager:setTimer(value)
        self.timer = value
    end

    function StateManager:getSessionsCompleted()
        return self.sessionsCompleted
    end

    function StateManager:getSessionStartTime()
        return self.sessionStartTime
    end

    function StateManager:startSession()
        self.sessionStartTime = os.time()
    end

    function StateManager:saveSession()
        local today = os.date("%Y-%m-%d")
        local stats = mockSettings["pomodoro.stats"] or {}
        stats[today] = self.sessionsCompleted
        mockSettings["pomodoro.stats"] = stats
    end

    function StateManager:addObserver(callback)
        table.insert(self.observers, callback)
    end

    function StateManager:_notifyObservers(property, value)
        for _, observer in ipairs(self.observers) do
            -- Create a proxy table with all the methods
            local proxy = setmetatable({}, {
                __index = function(_, key)
                    if type(self[key]) == "function" then
                        return function(_, ...) return self[key](self, ...) end
                    else
                        return self[key]
                    end
                end
            })
            local success, err = pcall(observer, property, value, proxy)
            if not success then
                print("[ERROR] Observer error:", err)
            end
        end
    end

    function StateManager:reset()
        self._running = false
        self._isBreak = false
        self.timeLeft = 0
        self.timer = nil
    end

    return StateManager
end

package.preload["ui_manager"] = function()
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
        if self.menuBarItem then
            local minutes = math.floor(timeLeft / 60)
            local seconds = timeLeft % 60
            local text = string.format("%s: %02d:%02d", sessionType, minutes, seconds)
            self.menuBarItem.setTitle(text)
        end
    end

    function UIManager:updateMenuBarReady()
        if self.menuBarItem then
            self.menuBarItem.setTitle("🍅")
        end
    end

    function UIManager:updateMenu(state)
        -- Mock implementation
    end

    return UIManager
end

package.preload["utils"] = function()
    local utils = {}

    function utils.safeCall(fn)
        local success, result = pcall(fn)
        if success then
            return { success = true, result = result }
        else
            return { success = false, error = result }
        end
    end

    function utils.showError(message)
        print("[ERROR] " .. message)
    end

    function utils.validateSettings(settings)
        if not settings.workDuration or settings.workDuration <= 0 then
            return false, "Invalid work duration"
        end
        if not settings.breakDuration or settings.breakDuration <= 0 then
            return false, "Invalid break duration"
        end
        return true
    end

    return utils
end

-- Note: timer module is not mocked here to allow testing its actual functionality

-- Test utilities
testHelper = {
    resetMocks = function()
        mockSettings = {}
        mockApplications = {}
        mockTimerId = 1
        mockTimerRunning = false
        mockSpoon = nil
    end,

    setMockSetting = function(key, value)
        mockSettings[key] = value
    end,

    addMockApplication = function(app)
        table.insert(mockApplications, app)
    end,

    setMockTimerRunning = function(running)
        mockTimerRunning = running
    end,

    setMockSpoon = function(spoon)
        mockSpoon = spoon
    end
}

-- Return testHelper for require()
return testHelper