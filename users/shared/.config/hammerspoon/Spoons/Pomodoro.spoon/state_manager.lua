-- state_manager.lua
local StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local self = setmetatable({}, StateManager)
    self.timerRunning = false
    self.isBreak = false
    self.sessionsCompleted = 0
    self.timeLeft = 0
    self.sessionStartTime = nil
    self.timer = nil
    self.menuBarItem = nil
    return self
end

function StateManager:isRunning()
    return self.timerRunning
end

function StateManager:isBreak()
    return self.isBreak
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

function StateManager:setRunning(running)
    self.timerRunning = running
end

function StateManager:setBreak(isBreak)
    self.isBreak = isBreak
end

function StateManager:setTimeLeft(time)
    self.timeLeft = time
end

function StateManager:setSessionStartTime(time)
    self.sessionStartTime = time
end

function StateManager:setSessionsCompleted(count)
    self.sessionsCompleted = count
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
    self.isBreak = false
    self.timeLeft = 0
    self.sessionStartTime = nil
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
end

function StateManager:saveSession()
    self.sessionsCompleted = self.sessionsCompleted + 1
    -- Save to hs.settings
    local today = os.date("%Y-%m-%d")
    local stats = hs.settings.get("pomodoro.dailyStats") or {}
    stats[today] = self.sessionsCompleted
    hs.settings.set("pomodoro.dailyStats", stats)
end

return StateManager