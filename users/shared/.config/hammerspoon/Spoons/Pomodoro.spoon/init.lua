--- === Pomodoro ===
---
--- A Pomodoro timer Spoon that integrates with macOS Focus modes.
--- Automatically starts when Focus mode changes to "Pomodoro" and
--- provides a 25-minute work session followed by a 5-minute break.
---
--- Features:
--- - Automatic Focus mode integration
--- - Menubar countdown display
--- - Daily statistics tracking
--- - One-cycle-per-session approach

local obj = {}
obj.__index = obj

-- Spoon Metadata
obj.name = "Pomodoro"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT"
obj.homepage = "https://github.com/evantravers/dotfiles"
obj.description = "Pomodoro timer with Focus mode integration"

-- Configuration Constants
local CONFIG = {
  WORK_DURATION = 25 * 60,      -- 25 minutes in seconds
  BREAK_DURATION = 5 * 60,      -- 5 minutes in seconds
  FOCUS_MODE = "Pomodoro",
  STATS_CACHE_DURATION = 300,   -- 5 minutes in seconds
  FOCUS_CHECK_INTERVAL = 30     -- seconds
}

-- Application State
local State = {
  timerRunning = false,
  isBreak = false,
  sessionsCompleted = 0,
  timeLeft = 0,
  sessionStartTime = nil,
}

-- UI Components
local UI = {
  countdownTimer = nil,
  menubarItem = nil,
  focusChecker = nil,
  lastKnownFocus = nil,
}

-- Cache Management
local Cache = {
  dateString = nil,
  stats = nil,
  timestamp = 0
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function getCurrentDateString()
  local now = os.time()
  if not Cache.dateString or math.abs(now - Cache.timestamp) > CONFIG.STATS_CACHE_DURATION then
    Cache.dateString = os.date("%Y-%m-%d")
    Cache.timestamp = now
  end
  return Cache.dateString
end

local function formatTime(seconds)
  local minutes = math.floor(seconds / 60)
  local secs = seconds % 60
  return string.format("%02d:%02d", minutes, secs)
end

local function showNotification(title, subtitle)
  hs.notify.new({
    title = title,
    subtitle = subtitle,
    informativeText = "",
    soundName = "Glass"
  }):send()
end

-- ============================================================================
-- CACHE MANAGEMENT
-- ============================================================================

local function getCachedStatistics()
  local now = os.time()
  if not Cache.stats or math.abs(now - Cache.timestamp) > CONFIG.STATS_CACHE_DURATION then
    Cache.stats = hs.settings.get("pomodoro.stats") or {}
    Cache.timestamp = now
  end
  return Cache.stats
end

local function invalidateStatisticsCache()
  Cache.stats = nil
  Cache.timestamp = 0
end

local function saveCurrentStatistics()
  local todayStr = getCurrentDateString()
  local stats = getCachedStatistics()
  stats[todayStr] = State.sessionsCompleted
  hs.settings.set("pomodoro.stats", stats)
  invalidateStatisticsCache()
end

local function loadCurrentStatistics()
  local stats = getCachedStatistics()
  local todayStr = getCurrentDateString()
  State.sessionsCompleted = stats[todayStr] or 0
  return State.sessionsCompleted
end

-- ============================================================================
-- UI MANAGEMENT
-- ============================================================================

local function updateMenubarDisplay()
  if not UI.menubarItem then return end

  if not State.timerRunning then
    UI.menubarItem:setTitle("🍅 Ready")
  else
    local emoji = State.isBreak and "☕" or "🍅"
    UI.menubarItem:setTitle(emoji .. " " .. formatTime(State.timeLeft))
  end
end

local function buildMenuTable()
  local menu = {}

  if not State.timerRunning then
    table.insert(menu, {
      title = "Start Session",
      fn = TimerManager.startWorkSession
    })
  else
    local status = State.isBreak and "Break" or "Work"
    table.insert(menu, {
      title = string.format("Status: %s (%s)", status, formatTime(State.timeLeft)),
      disabled = true
    })

    table.insert(menu, {
      title = "Stop Session",
      fn = TimerManager.stop
    })
  end

  table.insert(menu, hs.menuitem.separator)

  table.insert(menu, {
    title = string.format("Today: %d sessions", State.sessionsCompleted),
    disabled = true
  })

  table.insert(menu, {
    title = "Reset Stats",
    fn = function()
      local todayStr = getCurrentDateString()
      local stats = getCachedStatistics()
      stats[todayStr] = 0
      hs.settings.set("pomodoro.stats", stats)
      State.sessionsCompleted = 0
      invalidateStatisticsCache()
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

-- ============================================================================
-- TIMER MANAGEMENT
-- ============================================================================

local TimerManager = {}

function TimerManager.cleanup()
  if UI.countdownTimer then
    UI.countdownTimer:stop()
    UI.countdownTimer = nil
  end
end

function TimerManager.stop()
  State.timerRunning = false
  State.isBreak = false
  State.timeLeft = 0
  State.sessionStartTime = nil

  TimerManager.cleanup()
  updateMenubarDisplay()
end

function TimerManager.createCallback(onComplete)
  return function()
    State.timeLeft = State.timeLeft - 1
    if State.timeLeft <= 0 then
      TimerManager.cleanup()
      onComplete()
    else
      updateMenubarDisplay()
    end
  end
end

function TimerManager.startWorkSession()
  TimerManager.cleanup()

  State.isBreak = false
  State.timeLeft = CONFIG.WORK_DURATION
  State.timerRunning = true
  State.sessionStartTime = os.time()

  updateMenubarDisplay()
  showNotification("Pomodoro Started", "Work session begins!")

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(TimerManager.startBreakSession))
  UI.countdownTimer:start()
end

function TimerManager.startBreakSession()
  TimerManager.cleanup()

  State.isBreak = true
  State.timeLeft = CONFIG.BREAK_DURATION
  State.timerRunning = true

  updateMenubarDisplay()
  showNotification("Break Time!", "Take a 5-minute break")

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(function()
    State.sessionsCompleted = State.sessionsCompleted + 1
    TimerManager.stop()
    saveCurrentStatistics()
    showNotification("Session Complete!", "Great job! Ready for another?")
  end))
  UI.countdownTimer:start()
end

-- ============================================================================
-- FOCUS MODE DETECTION
-- ============================================================================

local FocusManager = {}

function FocusManager.isPomodoroActive()
  local output, exitCode = hs.execute("defaults read com.apple.controlcenter FocusMode 2>/dev/null", true)
  return exitCode == 0 and output and output:match(CONFIG.FOCUS_MODE) ~= nil
end

function FocusManager.handleFocusChange()
  local hasPomodoro = FocusManager.isPomodoroActive()

  if hasPomodoro then
    if not State.timerRunning then
      TimerManager.startWorkSession()
    end
  else
    if State.timerRunning then
      showNotification("Pomodoro Stopped", "Focus mode changed")
      saveCurrentStatistics()
      TimerManager.stop()
    end
  end
end

function FocusManager.startMonitoring()
  UI.focusChecker = hs.timer.new(CONFIG.FOCUS_CHECK_INTERVAL, function()
    local currentFocus = FocusManager.isPomodoroActive()
    if currentFocus ~= UI.lastKnownFocus then
      FocusManager.handleFocusChange()
      UI.lastKnownFocus = currentFocus
    end
  end)
  UI.focusChecker:start()
  UI.lastKnownFocus = FocusManager.isPomodoroActive()
end

function FocusManager.stopMonitoring()
  if UI.focusChecker then
    UI.focusChecker:stop()
    UI.focusChecker = nil
  end
end

-- ============================================================================
-- SPOON INTERFACE METHODS
-- ============================================================================

--- Pomodoro:start() -> Pomodoro
--- Method
--- Starts the Pomodoro Spoon and initializes all watchers and timers
---
--- Returns:
---  * The Pomodoro object
function obj:start()
  -- Clear existing cache
  invalidateStatisticsCache()
  Cache.dateString = nil

  -- Initialize menubar with error handling
  local success, menubar = pcall(function()
    return hs.menubar.new()
  end)
  if not success or not menubar then
    hs.alert.show("Failed to create menubar item for Pomodoro")
    return self
  end
  UI.menubarItem = menubar

  -- Set up menu callback
  local menuCallback = function()
    UI.menubarItem:setMenu(buildMenuTable())
  end
  UI.menubarItem:setClickCallback(menuCallback)

  -- Load initial statistics
  loadCurrentStatistics()

  -- Start focus mode monitoring
  FocusManager.startMonitoring()

  -- Initialize UI state
  updateMenubarDisplay()

  -- Handle current focus mode if already active
  if UI.lastKnownFocus then
    FocusManager.handleFocusChange()
  end

  return self
end

--- Pomodoro:stop() -> Pomodoro
--- Method
--- Stops the Pomodoro Spoon and cleans up resources
---
--- Returns:
---  * The Pomodoro object
function obj:stop()
  -- Stop active timer
  TimerManager.stop()

  -- Save current statistics
  saveCurrentStatistics()

  -- Stop focus monitoring
  FocusManager.stopMonitoring()

  -- Remove menubar item
  if UI.menubarItem then
    UI.menubarItem:delete()
    UI.menubarItem = nil
  end

  -- Clear all caches and reset state
  invalidateStatisticsCache()
  Cache.dateString = nil
  UI.lastKnownFocus = nil

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
---
--- Returns:
---  * The Pomodoro object
function obj:bindHotkeys(mapping)
  local specs = {
    start = function()
      if not State.timerRunning then
        TimerManager.startWorkSession()
      end
    end,
    stop = function()
      if State.timerRunning then
        TimerManager.stop()
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
  local todayStr = getCurrentDateString()
  local stats = getCachedStatistics()

  return {
    today = stats[todayStr] or 0,
    all = stats
  }
end

--- Pomodoro:toggleSession() -> boolean
--- Method
--- Toggle between starting and stopping a Pomodoro session
---
--- Returns:
---  * boolean - true if session was started, false if stopped
function obj:toggleSession()
  if State.timerRunning then
    TimerManager.stop()
    return false
  else
    TimerManager.startWorkSession()
    return true
  end
end

--- Pomodoro:isRunning() -> boolean
--- Method
--- Check if a Pomodoro session is currently running
---
--- Returns:
---  * boolean - true if a session is running, false otherwise
function obj:isRunning()
  return State.timerRunning
end

--- Pomodoro:getTimeLeft() -> number
--- Method
--- Get the time remaining in the current session
---
--- Returns:
---  * number - Time remaining in seconds, 0 if no session is running
function obj:getTimeLeft()
  return State.timeLeft or 0
end

--- Pomodoro:isBreak() -> boolean
--- Method
--- Check if the current session is a break
---
--- Returns:
---  * boolean - true if it's break time, false otherwise
function obj:isBreak()
  return State.isBreak
end

return obj
