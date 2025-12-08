--- === Pomodoro ===
---
--- A simplified Pomodoro timer Spoon.
--- Provides 25-minute work sessions followed by 5-minute breaks.
---
--- Features:
--- - Manual start/stop control via menubar or hotkeys
--- - Menubar countdown display with emoji indicators
--- - Daily statistics tracking
--- - Session completion notifications
--- - Focus Mode synchronization (macOS)

local obj = {}
obj.__index = obj

-- Import Focus Integration module
local focusIntegration
if hs and hs.spoons and hs.spoons.scriptPath then
  -- Running in Hammerspoon environment
  local scriptPath = hs.spoons.scriptPath()
  focusIntegration = dofile(scriptPath .. "/focus_integration.lua")
else
  -- Running in test environment
  focusIntegration = dofile("focus_integration.lua")
end

-- Metadata
obj.name = "Pomodoro"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT <https://opensource.org/licenses/MIT>"

-- Constants
local WORK_DURATION = 25 * 60  -- 25 minutes in seconds
local BREAK_DURATION = 5 * 60  -- 5 minutes in seconds

-- Local state variables
local menubarItem = nil
local timer = nil
local isRunning = false
local isBreak = false
local timeLeft = 0
local sessionsCompleted = 0

-- Constructor
function obj:new()
  local instance = {}
  setmetatable(instance, self)
  self.__index = self
  return instance
end

-- Helper functions

local function formatTime(seconds)
  local minutes = math.floor(seconds / 60)
  local secs = seconds % 60
  return string.format("%d:%02d", minutes, secs)
end

local function updateMenuBar()
  if not menubarItem then return end

  if not isRunning then
    local emoji = "🍅"
    local title = string.format("%s %d", emoji, sessionsCompleted)
    menubarItem:setTitle(title)
  else
    local emoji = isBreak and "☕" or "🍅"
    local timeStr = formatTime(timeLeft)
    local title = string.format("%s %s", emoji, timeStr)
    menubarItem:setTitle(title)
  end
end

local function showNotification(title, subtitle)
  hs.notify.new({
    title = title,
    subtitle = subtitle,
    informativeText = "",
    soundName = "Glass"
  }):send()
end

local function saveStatistics()
  local today = os.date("%Y-%m-%d")
  local stats = hs.settings.get("pomodoro.stats") or {}
  stats[today] = sessionsCompleted
  hs.settings.set("pomodoro.stats", stats)
end

local function loadStatistics()
  local today = os.date("%Y-%m-%d")
  local stats = hs.settings.get("pomodoro.stats") or {}
  return stats[today] or 0
end

local function updateMenu()
  if not menubarItem then return end

  local menuTable = {}

  if isRunning then
    table.insert(menuTable, {
      title = isBreak and "Break in Progress" or "Work Session",
      disabled = true
    })
    table.insert(menuTable, {
      title = "Stop Session",
      fn = function()
        stopTimer()
      end
    })
  else
    table.insert(menuTable, {
      title = "Start Work Session",
      fn = function()
        startWorkSession()
      end
    })
  end

  table.insert(menuTable, { title = "-" })

  -- Statistics
  table.insert(menuTable, {
    title = string.format("Today: %d sessions", sessionsCompleted),
    disabled = true
  })

  table.insert(menuTable, { title = "-" })

  -- Configuration info
  table.insert(menuTable, {
    title = string.format("Work: %d min", WORK_DURATION / 60),
    disabled = true
  })
  table.insert(menuTable, {
    title = string.format("Break: %d min", BREAK_DURATION / 60),
    disabled = true
  })

  menubarItem:setMenu(menuTable)
end

local function stopTimer()
  if timer then
    timer:stop()
    timer = nil
  end
  isRunning = false
  isBreak = false
  timeLeft = 0

  -- Sync with Focus Mode - disable when stopping any session
  focusIntegration.disablePomodoroFocus()

  updateMenuBar()
  updateMenu()
end

local function startWorkSession()
  if isRunning then return end

  isRunning = true
  isBreak = false
  timeLeft = WORK_DURATION

  -- Update statistics
  sessionsCompleted = loadStatistics() + 1
  saveStatistics()

  showNotification("Pomodoro Started", "Work session begins!")

  -- Sync with Focus Mode - enable when starting a work session
  focusIntegration.enablePomodoroFocus()

  timer = hs.timer.doEvery(1, function()
    timeLeft = timeLeft - 1
    updateMenuBar()

    if timeLeft <= 0 then
      stopTimer()
      startBreakSession()
    end
  end)

  updateMenuBar()
  updateMenu()
end

local function startBreakSession()
  isRunning = true
  isBreak = true
  timeLeft = BREAK_DURATION

  showNotification("Break Time!", "Take a 5-minute break")

  -- Sync with Focus Mode - disable during breaks
  focusIntegration.disablePomodoroFocus()

  timer = hs.timer.doEvery(1, function()
    timeLeft = timeLeft - 1
    updateMenuBar()

    if timeLeft <= 0 then
      stopTimer()
      showNotification("Session Complete!", "Great job! Ready for another?")
    end
  end)

  updateMenuBar()
  updateMenu()
end

-- Public API

function obj:start()
  -- Initialize menubar
  menubarItem = hs.menubar.new()
  menubarItem:setClickCallback(function()
    updateMenu()
  end)

  -- Load initial statistics
  sessionsCompleted = loadStatistics()

  -- Initialize Focus Integration
  focusIntegration.init(self)

  -- Initial UI update
  updateMenuBar()

  return self
end

function obj:stop()
  stopTimer()

  -- Cleanup Focus Integration
  focusIntegration.cleanup()

  if menubarItem then
    menubarItem:delete()
    menubarItem = nil
  end

  return self
end

function obj:bindHotkeys(mapping)
  local specs = {
    start = function()
      if not isRunning then
        startWorkSession()
      end
    end,
    stop = function()
      stopTimer()
    end,
    toggle = function()
      if isRunning then
        stopTimer()
      else
        startWorkSession()
      end
    end
  }

  hs.spoons.bindHotkeysToSpec(specs, mapping)
  return self
end

function obj:getStatistics()
  local today = os.date("%Y-%m-%d")
  local stats = hs.settings.get("pomodoro.stats") or {}

  return {
    today = stats[today] or 0,
    all = stats
  }
end

function obj:startSession()
  if not isRunning then
    startWorkSession()
  end
  return self
end

function obj:stopSession()
  stopTimer()
  return self
end

function obj:toggleSession()
  if isRunning then
    stopTimer()
  else
    startWorkSession()
  end
  return self
end

-- State API for external integrations
function obj:isRunning()
  return isRunning
end

function obj:isBreak()
  return isBreak
end

function obj:getTimeLeft()
  return timeLeft
end

function obj:getSessionsCompleted()
  return sessionsCompleted
end

-- Focus Mode API for external integrations

--- Register a callback for Focus Mode state changes
--- @param callback function The callback function that receives a boolean (isActive) parameter
--- @return boolean true if callback was registered successfully, false otherwise
function obj:onFocusModeChanged(callback)
  return focusIntegration.onFocusModeChanged(callback)
end

--- Remove a previously registered Focus Mode callback
--- @param callback function The callback function to remove
--- @return boolean true if callback was removed successfully, false otherwise
function obj:removeFocusModeCallback(callback)
  return focusIntegration.removeFocusModeCallback(callback)
end

--- Check if Pomodoro Focus Mode is currently active
--- @return boolean true if Focus Mode is active, false otherwise
function obj:isFocusModeActive()
  return focusIntegration.isPomodoroFocusActive()
end

--- Manually enable Pomodoro Focus Mode
--- @return boolean true if Focus Mode was enabled successfully, false otherwise
function obj:enableFocusMode()
  return focusIntegration.enablePomodoroFocus()
end

--- Manually disable Pomodoro Focus Mode
--- @return boolean true if Focus Mode was disabled successfully, false otherwise
function obj:disableFocusMode()
  return focusIntegration.disablePomodoroFocus()
end

--- Toggle Pomodoro Focus Mode state
--- @return boolean true if operation was successful, false otherwise
function obj:toggleFocusMode()
  return focusIntegration.togglePomodoroFocus()
end

--- Get debug information about Focus Integration
--- @return table Debug information including state, timers, callbacks, etc.
function obj:getFocusDebugInfo()
  return focusIntegration.getDebugInfo()
end

return obj
