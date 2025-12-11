--- === Pomodoro ===
---
--- A Pomodoro timer Spoon that integrates with macOS Focus modes.
--- Automatically starts when Focus mode changes to "Pomodoro" and
--- provides a 25-minute work session followed by a 5-minute break.
---
--- Features:
--- - Event-based Focus mode integration using NSDistributedNotificationCenter
--- - JXA-based Focus mode detection for macOS Sequoia compatibility
--- - Menubar countdown display
--- - Daily statistics tracking
--- - One-cycle-per-session approach
---
--- Requirements:
--- - macOS Sequoia (15.x) or later
--- - Full Disk Access permission for Hammerspoon

local obj = {}
obj.__index = obj

-- Spoon Metadata
obj.name = "FocusTracker"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT"
obj.homepage = "https://github.com/jito-hwang/dotfiles"
obj.description = "Focus Mode tracker with real-time duration display"

-- Default Configuration
obj.config = {
  -- Callbacks
  onFocusStart = nil,  -- Called when Focus Mode starts: function(focusModeName)
  onFocusEnd = nil     -- Called when Focus Mode ends: function(focusModeName, durationInSeconds)
}

-- Application State
local State = {
  isTracking = false,
  elapsedTime = 0,
  currentFocusMode = nil,
  startTime = nil,
}

-- UI Components
local UI = {
  countdownTimer = nil,
  menubarItem = nil,
  focusWatcherEnabled = nil,
  focusWatcherDisabled = nil,
  lastKnownFocus = nil,
}


-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================


local function formatTime(seconds)
  local minutes = math.floor(seconds / 60)
  local secs = seconds % 60
  return string.format("%02d:%02d", minutes, secs)
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
      State.sessionsCompleted = 0
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

function TimerManager.stopTracking()
  local duration = State.elapsedTime
  local focusName = State.currentFocusMode

  TimerManager.cleanup()

  State.isTracking = false
  State.elapsedTime = 0
  State.currentFocusMode = nil
  State.startTime = nil

  -- Callback: onFocusEnd
  if obj.config.onFocusEnd then
    obj.config.onFocusEnd(focusName, duration)
  end
end


function TimerManager.startTracking()
  TimerManager.cleanup()

  State.isTracking = true
  State.elapsedTime = 0
  State.startTime = os.time()
  State.currentFocusMode = FocusManager.getCurrentFocusMode()

  if not State.currentFocusMode then
    State.currentFocusMode = "Focus Mode"
  end

  -- Callback: onFocusStart
  if obj.config.onFocusStart then
    obj.config.onFocusStart(State.currentFocusMode)
  end

  UI.countdownTimer = hs.timer.new(1, function()
    State.elapsedTime = State.elapsedTime + 1
    updateMenubarDisplay()
  end)
  UI.countdownTimer:start()
end


-- ============================================================================
-- FOCUS MODE DETECTION
-- ============================================================================

local FocusManager = {}

function FocusManager.getCurrentFocusMode()
  local script = [[
    (function() {
      const app = Application.currentApplication();
      app.includeStandardAdditions = true;

      function getJSON(path) {
        const fullPath = path.replace(/^~/, app.pathTo('home folder'));
        const contents = app.read(fullPath);
        return JSON.parse(contents);
      }

      try {
        const assert = getJSON("~/Library/DoNotDisturb/DB/Assertions.json").data[0].storeAssertionRecords;
        const config = getJSON("~/Library/DoNotDisturb/DB/ModeConfigurations.json").data[0].modeConfigurations;

        if (assert && assert.length > 0) {
          const modeid = assert[0].assertionDetails.assertionDetailsModeIdentifier;
          return config[modeid].mode.name;
        }

        return null;
      } catch (e) {
        return null;
      }
    })();
  ]]

  local ok, result = hs.osascript.javascript(script)
  if ok and result then
    return result
  end
  return nil
end

function FocusManager.isPomodoroActive()
  local currentMode = FocusManager.getCurrentFocusMode()
  return currentMode == "Pomodoro"
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
      TimerManager.stopTracking()
    end
  end
end

function FocusManager.startMonitoring()
  -- Watch for Focus mode enabled
  UI.focusWatcherEnabled = hs.distributednotifications.new(function(name, object, userInfo)
    if FocusManager.isPomodoroActive() then
      if not State.timerRunning then
        TimerManager.startWorkSession()
      end
    end
  end, "_NSDoNotDisturbEnabledNotification")
  UI.focusWatcherEnabled:start()

  -- Watch for Focus mode disabled
  UI.focusWatcherDisabled = hs.distributednotifications.new(function(name, object, userInfo)
    if State.timerRunning then
      showNotification("Pomodoro Stopped", "Focus mode changed")
      TimerManager.stopTracking()
    end
  end, "_NSDoNotDisturbDisabledNotification")
  UI.focusWatcherDisabled:start()

  UI.lastKnownFocus = FocusManager.isPomodoroActive()
end

function FocusManager.stopMonitoring()
  if UI.focusWatcherEnabled then
    UI.focusWatcherEnabled:stop()
    UI.focusWatcherEnabled = nil
  end
  if UI.focusWatcherDisabled then
    UI.focusWatcherDisabled:stop()
    UI.focusWatcherDisabled = nil
  end
end

-- ============================================================================
-- SPOON INTERFACE METHODS
-- ============================================================================

--- Pomodoro:init(config) -> Pomodoro
--- Method
--- Initializes the Pomodoro Spoon with custom configuration
---
--- Parameters:
---  * config - Optional table containing configuration options:
---    * focusMode - String name of the Focus mode to monitor (default: "Pomodoro")
---    * workDuration - Work session duration in seconds (default: 25 * 60)
---    * breakDuration - Break duration in seconds (default: 5 * 60)
---    * onWorkStart - Function called when work session starts (optional)
---    * onBreakStart - Function called when break starts (work completed) (optional)
---    * onComplete - Function called when session completes (break ends) (optional)
---    * onStopped - Function called when session is stopped prematurely (optional)
---
--- Returns:
---  * The Pomodoro object
---
--- Notes:
---  * This method is optional. If not called, default configuration will be used
---  * Can be chained with start(): `spoon.Pomodoro:init({focusMode = "Deep Work"}):start()`
---  * Callbacks allow custom notifications or actions at key moments
---  * Example: `spoon.Pomodoro:init({
---    onStopped = function()
---      hs.alert.show("Session stopped!", {duration = 2})
---    end
---  })`
function obj:init(config)
  if config then
    for k, v in pairs(config) do
      if self.config[k] ~= nil then
        self.config[k] = v
      end
    end
  end
  return self
end

--- Pomodoro:start() -> Pomodoro
--- Method
--- Starts the Pomodoro Spoon and initializes all watchers and timers
---
--- Returns:
---  * The Pomodoro object
function obj:start()
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
  TimerManager.stopTracking()

  -- Stop focus monitoring
  FocusManager.stopMonitoring()

  -- Remove menubar item
  if UI.menubarItem then
    UI.menubarItem:delete()
    UI.menubarItem = nil
  end

  -- Clear state
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
        TimerManager.stopTracking()
      end
    end
  }

  hs.spoons.bindHotkeysToSpec(specs, mapping)
  return self
end


--- Pomodoro:toggleSession() -> boolean
--- Method
--- Toggle between starting and stopping a Pomodoro session
---
--- Returns:
---  * boolean - true if session was started, false if stopped
function obj:toggleSession()
  if State.timerRunning then
    TimerManager.stopTracking()
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
