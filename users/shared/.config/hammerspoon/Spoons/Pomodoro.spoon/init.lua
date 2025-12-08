--- === Pomodoro ===
---
--- A Pomodoro timer Spoon with manual control.
--- Provides 25-minute work sessions followed by 5-minute breaks.
---
--- Features:
--- - Manual start/stop control via menubar or hotkeys
--- - Menubar countdown display
--- - Daily statistics tracking
--- - Configurable work/break durations

-- Load dependencies
local StateManager = require("state_manager")
local UIManager = require("ui_manager")
local utils = require("utils")

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Pomodoro"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT <https://opensource.org/licenses/MIT>"
obj.homepage = "https://github.com/evantravers/dotfiles"

-- Constants
local WORK_DURATION = 25 * 60  -- 25 minutes in seconds
local BREAK_DURATION = 5 * 60  -- 5 minutes in seconds

-- Initialize managers
obj.state = StateManager:new()
obj.ui = UIManager:new()

-- TODO: Consider making durations configurable
-- TODO: Add support for different notification sounds
-- TODO: Consider adding a "pause" functionality
-- TODO: Add support for custom work/break ratios

-- Helper functions
local function updateMenubar()
  if not obj.state:isRunning() then
    obj.ui:updateMenuBarReady()
  else
    local sessionType = obj.state:isBreak() and "Break" or "Work"
    obj.ui:updateMenuBarText(sessionType, obj.state:getTimeLeft())
  end

  -- Also update the menu
  obj.ui:updateMenu(obj.state)
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
  obj.state:saveSession()
end

local function loadStatistics()
  local today = os.date("%Y-%m-%d")
  local stats = hs.settings.get("pomodoro.stats") or {}
  return stats[today] or 0
end

local function stopTimer()
  obj.state:setRunning(false)
  obj.state:setBreak(false)
  obj.state:setTimeLeft(0)
  obj.state:setSessionStartTime(nil)
  obj.state:setTimer(nil)

  updateMenubar()
end

local function startWorkSession()
  obj.state:setBreak(false)
  obj.state:setTimeLeft(WORK_DURATION)
  obj.state:setRunning(true)
  obj.state:setSessionStartTime(os.time())
  obj.state:setSessionsCompleted(loadStatistics() + 1)

  updateMenubar()
  showNotification("Pomodoro Started", "Work session begins!")

  local success, timer = utils.safeCall(function()
    return hs.timer.new(1, function()
      obj.state:setTimeLeft(obj.state:getTimeLeft() - 1)

      if obj.state:getTimeLeft() <= 0 then
        stopTimer()
        startBreakSession()
      else
        updateMenubar()
      end
    end)
  end)

  if not success then
    utils.showError("Failed to create timer: " .. timer.error)
    obj.state:setRunning(false)
    return
  end

  obj.state:setTimer(timer)
  timer:start()
end

local function startBreakSession()
  obj.state:setBreak(true)
  obj.state:setTimeLeft(BREAK_DURATION)
  obj.state:setRunning(true)

  updateMenubar()
  showNotification("Break Time!", "Take a 5-minute break")

  local success, timer = utils.safeCall(function()
    return hs.timer.new(1, function()
      obj.state:setTimeLeft(obj.state:getTimeLeft() - 1)

      if obj.state:getTimeLeft() <= 0 then
        stopTimer()
        saveStatistics()
        showNotification("Session Complete!", "Great job! Ready for another?")
      else
        updateMenubar()
      end
    end)
  end)

  if not success then
    utils.showError("Failed to create break timer: " .. timer.error)
    obj.state:setRunning(false)
    return
  end

  obj.state:setTimer(timer)
  timer:start()
end

-- Spoon methods

--- Pomodoro:start() -> Pomodoro
--- Method
--- Starts the Pomodoro Spoon and initializes the menubar
---
--- Returns:
---  * The Pomodoro object
function obj:start()
  -- Initialize menubar
  local menubarItem = hs.menubar.new()
  obj.state:setMenuBarItem(menubarItem)
  obj.ui:setMenuBarItem(menubarItem)

  menubarItem:setClickCallback(function()
    -- Update menu on click
    obj.ui:updateMenu(obj.state)
  end)

  -- Load initial statistics
  obj.state:setSessionsCompleted(loadStatistics())

  -- Initial menubar update
  updateMenubar()

  return self
end

--- Pomodoro:stop() -> Pomodoro
--- Method
--- Stops the Pomodoro Spoon and cleans up resources
---
--- Returns:
---  * The Pomodoro object
function obj:stop()
  -- Stop timer if running
  stopTimer()

  -- Save statistics
  saveStatistics()

  -- Remove menubar item
  local menubarItem = obj.ui:getMenuBarItem()
  if menubarItem then
    menubarItem:delete()
    obj.state:setMenuBarItem(nil)
    obj.ui:setMenuBarItem(nil)
  end

  return self
end

--- Pomodoro:bindHotkeys(mapping) -> Pomodoro
--- Method
--- Binds hotkeys for Pomodoro control
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * start - Start a Pomodoro session
---   * stop - Stop the current session
---   * toggle - Toggle between start/stop
---
--- Returns:
---  * The Pomodoro object
function obj:bindHotkeys(mapping)
  local specs = {
    start = function()
      if not obj.state:isRunning() then
        startWorkSession()
      end
    end,
    stop = function()
      if obj.state:isRunning() then
        stopTimer()
      end
    end,
    toggle = function()
      if obj.state:isRunning() then
        stopTimer()
      else
        startWorkSession()
      end
    end
  }

  hs.spoons.bindHotkeysToSpec(specs, mapping)
  return self
end

--- Pomodoro:getStatistics() -> table
--- Method
--- Returns Pomodoro statistics
---
--- Returns:
---  * A table with keys:
---    * today - Number of sessions completed today
---    * all - Table of daily statistics
function obj:getStatistics()
  local today = os.date("%Y-%m-%d")
  local stats = hs.settings.get("pomodoro.stats") or {}

  return {
    today = stats[today] or 0,
    all = stats
  }
end

--- Pomodoro:startSession() -> Pomodoro
--- Method
--- Manually starts a Pomodoro work session
---
--- Returns:
---  * The Pomodoro object
function obj:startSession()
  if not obj.state:isRunning() then
    startWorkSession()
  end
  return self
end

--- Pomodoro:stopSession() -> Pomodoro
--- Method
--- Manually stops the current Pomodoro session
---
--- Returns:
---  * The Pomodoro object
function obj:stopSession()
  if obj.state:isRunning() then
    stopTimer()
  end
  return self
end

--- Pomodoro:toggleSession() -> Pomodoro
--- Method
--- Toggles between starting and stopping a Pomodoro session
---
--- Returns:
---  * The Pomodoro object
function obj:toggleSession()
  if obj.state:isRunning() then
    stopTimer()
  else
    startWorkSession()
  end
  return self
end

--- Pomodoro:startSessionWithDuration(duration) -> boolean
--- Method
--- Starts a work session with custom duration
---
--- Parameters:
---  * duration - Duration in seconds (must be positive number)
---
--- Returns:
---  * Boolean - true if session started successfully, false otherwise
function obj:startSessionWithDuration(duration)
  -- Validate input
  if not duration or type(duration) ~= "number" or duration <= 0 then
    utils.showError("Invalid duration: must be a positive number")
    return false
  end

  if obj.state:isRunning() then
    utils.showInfo("Session already running")
    return false
  end

  -- Start session with custom duration
  obj.state:setBreak(false)
  obj.state:setTimeLeft(duration)
  obj.state:setRunning(true)
  obj.state:setSessionStartTime(os.time())
  obj.state:setSessionsCompleted(loadStatistics() + 1)

  updateMenubar()
  showNotification("Pomodoro Started", "Work session begins!")

  local success, timer = utils.safeCall(function()
    return hs.timer.new(1, function()
      obj.state:setTimeLeft(obj.state:getTimeLeft() - 1)

      if obj.state:getTimeLeft() <= 0 then
        stopTimer()
        startBreakSession()
      else
        updateMenubar()
      end
    end)
  end)

  if not success then
    utils.showError("Failed to create timer: " .. timer.error)
    obj.state:setRunning(false)
    return false
  end

  obj.state:setTimer(timer)
  timer:start()

  return true
end

--- Pomodoro:validateSettings() -> boolean
--- Method
--- Validates current timer settings
---
--- Returns:
---  * Boolean - true if settings are valid
function obj:validateSettings()
  local isValid, message = utils.validateSettings({
    workDuration = WORK_DURATION,
    breakDuration = BREAK_DURATION
  })

  if not isValid then
    utils.showError("Invalid settings: " .. message)
    return false
  end

  return true
end

return obj

-- Test helper
if _G.POMODORO_TEST_MODE then
    return obj  -- Return the spoon object for testing
end