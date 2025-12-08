-- state_manager.lua
local StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local self = setmetatable({}, StateManager)
    self.timerRunning = false
    self.isBreakTime = false  -- Renamed to avoid conflict with method
    self.sessionsCompleted = 0
    self.timeLeft = 0
    self.sessionStartTime = nil
    self.timer = nil
    self.menuBarItem = nil
    self.observers = {}  -- List of observer callbacks
    return self
end

function StateManager:isRunning()
    return self.timerRunning
end

function StateManager:isBreak()
    return self.isBreakTime
end

function StateManager:getTimeLeft()
    return self.timeLeft
end

function StateManager:getSessionsCompleted()
    return self.sessionsCompleted
end

function StateManager:getSessionStartTime()
    return self.sessionStartTime
end

function StateManager:getTimer()
    return self.timer
end

function StateManager:getMenuBarItem()
    return self.menuBarItem
end

-- Observer pattern methods
function StateManager:addObserver(callback)
    table.insert(self.observers, callback)
end

function StateManager:removeObserver(callback)
    for i, observer in ipairs(self.observers) do
        if observer == callback then
            table.remove(self.observers, i)
            break
        end
    end
end

function StateManager:notifyObservers(changedProperty, newValue)
    for _, callback in ipairs(self.observers) do
        callback(changedProperty, newValue, self)
    end
end

function StateManager:setRunning(running)
    self.timerRunning = running
    self:notifyObservers("timerRunning", running)
end

function StateManager:setBreak(isBreak)
    self.isBreakTime = isBreak
    self:notifyObservers("isBreakTime", isBreak)
end

function StateManager:setTimeLeft(time)
    self.timeLeft = time
    self:notifyObservers("timeLeft", time)
end

function StateManager:setSessionStartTime(time)
    self.sessionStartTime = time
end

function StateManager:setSessionsCompleted(count)
    self.sessionsCompleted = count
    self:notifyObservers("sessionsCompleted", count)
end

function StateManager:setTimer(timer)
    if self.timer then
        self.timer:stop()
    end
    self.timer = timer
end

function StateManager:setMenuBarItem(item)
    self.menuBarItem = item
end

function StateManager:reset()
    self.timerRunning = false
    self.isBreakTime = false
    self.timeLeft = 0
    self.sessionStartTime = nil
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
    -- Notify observers about all state changes
    self:notifyObservers("timerRunning", false)
    self:notifyObservers("isBreakTime", false)
    self:notifyObservers("timeLeft", 0)
end

function StateManager:saveSession()
    -- Save current sessionsCompleted to hs.settings
    -- Don't increment here - it's already incremented in init.lua
    local today = os.date("%Y-%m-%d")
    local stats = hs.settings.get("pomodoro.stats") or {}
    stats[today] = self.sessionsCompleted
    hs.settings.set("pomodoro.stats", stats)
end

function StateManager:loadStatistics()
    local today = os.date("%Y-%m-%d")
    local stats = hs.settings.get("pomodoro.stats") or {}
    return stats[today] or 0
end

return StateManager