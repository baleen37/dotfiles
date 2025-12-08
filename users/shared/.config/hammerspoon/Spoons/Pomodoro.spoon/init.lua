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

-- State variables
local timerRunning = false
local isBreak = false
local sessionsCompleted = 0
local timeLeft = 0
local sessionStartTime = nil
local countdownTimer = nil
local menubarItem = nil

-- Helper functions
local function formatTime(seconds)
  local minutes = math.floor(seconds / 60)
  local secs = seconds % 60
  return string.format("%02d:%02d", minutes, secs)
end

local function updateMenubar()
  if not menubarItem then return end

  if not timerRunning then
    menubarItem:setTitle("🍅 Ready")
  else
    local emoji = isBreak and "☕" or "🍅"
    menubarItem:setTitle(emoji .. " " .. formatTime(timeLeft))
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

local function stopTimer()
  timerRunning = false
  isBreak = false
  timeLeft = 0
  sessionStartTime = nil

  if countdownTimer then
    countdownTimer:stop()
    countdownTimer = nil
  end

  updateMenubar()
end

local function startWorkSession()
  isBreak = false
  timeLeft = WORK_DURATION
  timerRunning = true
  sessionStartTime = os.time()
  sessionsCompleted = loadStatistics() + 1

  updateMenubar()
  showNotification("Pomodoro Started", "Work session begins!")

  countdownTimer = hs.timer.new(1, function()
    timeLeft = timeLeft - 1

    if timeLeft <= 0 then
      stopTimer()
      startBreakSession()
    else
      updateMenubar()
    end
  end)

  countdownTimer:start()
end

local function startBreakSession()
  isBreak = true
  timeLeft = BREAK_DURATION
  timerRunning = true

  updateMenubar()
  showNotification("Break Time!", "Take a 5-minute break")

  countdownTimer = hs.timer.new(1, function()
    timeLeft = timeLeft - 1

    if timeLeft <= 0 then
      stopTimer()
      saveStatistics()
      showNotification("Session Complete!", "Great job! Ready for another?")
    else
      updateMenubar()
    end
  end)

  countdownTimer:start()
end

-- Manual control functions

-- Menu construction
local function buildMenu()
  local menu = {}

  if not timerRunning then
    table.insert(menu, {
      title = "Start Session",
      fn = function()
        startWorkSession()
      end
    })
  else
    local status = isBreak and "Break" or "Work"
    table.insert(menu, {
      title = string.format("Status: %s (%s)", status, formatTime(timeLeft)),
      disabled = true
    })

    table.insert(menu, {
      title = "Stop Session",
      fn = function()
        stopTimer()
      end
    })
  end

  table.insert(menu, hs.menuitem.separator)

  -- Statistics
  local todaySessions = loadStatistics()
  table.insert(menu, {
    title = string.format("Today: %d sessions", todaySessions),
    disabled = true
  })

  table.insert(menu, {
    title = "Reset Stats",
    fn = function()
      local today = os.date("%Y-%m-%d")
      local stats = hs.settings.get("pomodoro.stats") or {}
      stats[today] = 0
      hs.settings.set("pomodoro.stats", stats)
      sessionsCompleted = 0
    end
  })

  table.insert(menu, hs.menuitem.separator)

  table.insert(menu, {
    title = "Quit",
    fn = function()
      obj:stop()
    end
  })

  return menu
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
  menubarItem = hs.menubar.new()
  menubarItem:setClickCallback(function()
    menubarItem:setMenu(buildMenu())
  end)

  -- Load initial statistics
  sessionsCompleted = loadStatistics()

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
  if menubarItem then
    menubarItem:delete()
    menubarItem = nil
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
      if not timerRunning then
        startWorkSession()
      end
    end,
    stop = function()
      if timerRunning then
        stopTimer()
      end
    end,
    toggle = function()
      if timerRunning then
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
  if not timerRunning then
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
  if timerRunning then
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
  if timerRunning then
    stopTimer()
  else
    startWorkSession()
  end
  return self
end

return obj

-- Test helper
if _G.POMODORO_TEST_MODE then
    return obj  -- Return the spoon object for testing
end