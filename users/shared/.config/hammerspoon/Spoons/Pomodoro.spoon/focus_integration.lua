--- === Pomodoro Focus Integration ===
---
--- Integration module for Pomodoro Spoon with Focus Mode Detector
--- Provides automatic Pomodoro session management based on Focus Mode state
---
--- Features:
--- - Auto-start Pomodoro when Focus Mode activates
--- - Auto-pause when Focus Mode deactivates
--- - Configurable behavior preferences
--- - Focus-aware notifications

local obj = {}
obj.__index = obj

-- Import Simple Focus Detector
local simpleFocus = require("simple_focus")

-- Configuration
local config = {
  -- Auto-management settings
  autoStartOnFocus = true,        -- Start Pomodoro when Focus Mode activates
  autoPauseOnUnfocus = true,      -- Pause when Focus Mode deactivates
  resumeOnRefocus = true,         -- Resume paused session when Focus returns
  requireManualStart = false,     -- Require manual start for first session

  -- Session settings
  focusSessionDuration = 25 * 60, -- Focus session duration (25 min)
  focusBreakDuration = 5 * 60,    -- Focus break duration (5 min)

  -- Notification settings
  enableNotifications = true,
  notificationSound = "Glass",

  -- State preservation
  preserveState = true,           -- Remember session state across Focus changes
  maxPauseDuration = 10 * 60      -- Max pause time before session auto-cancels
}

-- State tracking
local focusState = {
  active = false,
  sessionActive = false,
  wasRunning = false,
  pauseTime = nil,
  originalDuration = 0,
  timeRemaining = 0
}

-- Pomodoro reference (will be set externally)
local pomodoroRef = nil

-- Helper functions
local function log(...)
  if simpleFocus then
    simpleFocus.setDebugMode(config.debug or false)
  end
  print("[PomodoroFocus]", ...)
end

local function showNotification(title, subtitle)
  if config.enableNotifications then
    hs.notify.new({
      title = title,
      subtitle = subtitle,
      informativeText = "",
      soundName = config.notificationSound
    }):send()
  end
end

local function saveCurrentState()
  if not pomodoroRef then return end

  local stats = pomodoroRef:getStatistics()
  local currentState = {
    timerRunning = pomodoroRef:isRunning(),
    isBreak = pomodoroRef:isBreak(),
    sessionsCompleted = stats.today,
    timeLeft = pomodoroRef:getTimeLeft()
  }

  hs.settings.set("pomodoro.focusState", currentState)
  log("Saved state:", hs.inspect(currentState))
end

local function loadSavedState()
  return hs.settings.get("pomodoro.focusState")
end

local function clearSavedState()
  hs.settings.set("pomodoro.focusState", nil)
end

-- Focus Mode change handler
local function onFocusModeChanged(isActive, wasActive, source)
  log(string.format("Focus Mode changed: %s -> %s (source: %s)",
                   tostring(wasActive), tostring(isActive), source))

  focusState.active = isActive

  if not pomodoroRef then
    log("Warning: No Pomodoro reference available")
    return
  end

  if isActive then
    -- Focus Mode activated
    handleFocusActivation(source)
  else
    -- Focus Mode deactivated
    handleFocusDeactivation(source)
  end
end

local function handleFocusActivation(source)
  log("Handling Focus activation from:", source)

  if config.autoStartOnFocus then
    if pomodoroRef and not pomodoroRef:isRunning() then
      -- Check if there's a saved state to resume
      local savedState = loadSavedState()
      if savedState and config.preserveState then
        log("Resuming from saved state")
        -- Restore session with remaining time
        if savedState.timeLeft and savedState.timeLeft > 0 then
          -- Use startSessionWithDuration with isRestore flag
          if pomodoroRef.startSessionWithDuration and type(pomodoroRef.startSessionWithDuration) == "function" then
            pomodoroRef:startSessionWithDuration(savedState.timeLeft, true)
          else
            pomodoroRef:startSession()
          end
          if savedState.isBreak then
            pomodoroRef:setBreak(savedState.isBreak)
          end
          showNotification("Pomodoro Resumed", "Session restored from Focus Mode")
        else
          pomodoroRef:startSession()
          showNotification("Pomodoro Started", "Auto-started with Focus Mode")
        end
      else
        -- Start fresh session
        pomodoroRef:startSession()
        showNotification("Pomodoro Started", "Auto-started with Focus Mode")
      end

      focusState.sessionActive = true
      focusState.wasRunning = true
    elseif config.resumeOnRefocus and focusState.pauseTime then
      -- Resume paused session
      local pauseDuration = os.time() - focusState.pauseTime
      if pauseDuration < config.maxPauseDuration then
        pomodoroRef:startSession()
        showNotification("Pomodoro Resumed", "Session continued with Focus Mode")
        focusState.pauseTime = nil
      else
        showNotification("Session Expired", "Start a new Pomodoro session")
        clearSavedState()
      end
    end
  end
end

local function handleFocusDeactivation(source)
  log("Handling Focus deactivation from:", source)

  if config.autoPauseOnUnfocus then
    if pomodoroRef and pomodoroRef:isRunning() then
      -- Save current state
      focusState.wasRunning = true
      focusState.pauseTime = os.time()

      if config.preserveState then
        saveCurrentState()
      end

      -- Pause the session
      pomodoroRef:stopSession()
      showNotification("Pomodoro Paused", "Session paused (Focus Mode off)")
    end
  end
end

-- Public API

--- PomodoroFocus:setPomodoroReference(pomodoroObject)
--- Method
--- Sets a reference to the main Pomodoro object
---
--- Parameters:
---  * pomodoroObject - The main Pomodoro Spoon object
function obj:setPomodoroReference(pomodoroObject)
  pomodoroRef = pomodoroObject
  log("Pomodoro reference set")
end

--- PomodoroFocus:start() -> PomodoroFocus
--- Method
--- Starts the Focus Mode integration
---
--- Returns:
---  * The PomodoroFocus object
function obj:start()
  if not simpleFocus then
    log("Error: Simple Focus not loaded")
    return self
  end

  -- Initialize simple focus
  simpleFocus.init({
    pollInterval = 2.0,
    debug = config.debug or false
  })

  -- Register callback for Focus Mode changes
  simpleFocus.onFocusModeChanged(onFocusModeChanged)

  -- Start monitoring
  simpleFocus.startMonitoring()

  -- Get current Focus state
  local currentFocus = simpleFocus.getCurrentState()
  focusState.active = currentFocus

  log("Focus Integration started, current Focus state:", currentFocus)

  return self
end

--- PomodoroFocus:stop() -> PomodoroFocus
--- Method
--- Stops the Focus Mode integration
---
--- Returns:
---  * The PomodoroFocus object
function obj:stop()
  if simpleFocus then
    simpleFocus.removeFocusModeCallback(onFocusModeChanged)
    simpleFocus.stopMonitoring()
  end

  -- Clean up any saved state
  clearSavedState()

  log("Focus Integration stopped")
  return self
end

--- PomodoroFocus:configure(settings) -> PomodoroFocus
--- Method
--- Configures the Focus integration behavior
---
--- Parameters:
---  * settings - Table with configuration options
---
--- Returns:
---  * The PomodoroFocus object
function obj:configure(settings)
  for key, value in pairs(settings) do
    if config[key] ~= nil then
      config[key] = value
      log("Configuration updated:", key, "=", tostring(value))
    else
      log("Warning: Unknown configuration option:", key)
    end
  end
  return self
end

--- PomodoroFocus:getConfiguration() -> table
--- Method
--- Returns current configuration
---
--- Returns:
---  * Table with current configuration settings
function obj:getConfiguration()
  -- Return a copy to prevent external modification
  local copy = {}
  for k, v in pairs(config) do
    copy[k] = v
  end
  return copy
end

--- PomodoroFocus:isFocusModeActive() -> boolean
--- Method
--- Returns the current Focus Mode state
---
--- Returns:
---  * true if Focus Mode is active, false otherwise
function obj:isFocusModeActive()
  return focusState.active
end

--- PomodoroFocus:manuallyTriggerFocus(isActive)
--- Method
--- Manually triggers Focus Mode state change
---
--- Parameters:
---  * isActive - Boolean indicating desired Focus Mode state
function obj:manuallyTriggerFocus(isActive)
  -- Manual triggering is not supported in Simple Focus
  log("Manual focus triggering not supported in Simple Focus")
end

--- PomodoroFocus:getStatus() -> table
--- Method
--- Returns current status information
---
--- Returns:
---  * Table with status information
function obj:getStatus()
  return {
    focusActive = focusState.active,
    sessionActive = focusState.sessionActive,
    wasRunning = focusState.wasRunning,
    pausedAt = focusState.pauseTime,
    integrationEnabled = simpleFocus ~= nil
  }
end

-- Integration helper for Pomodoro Spoon
local function createIntegrationMenu(pomodoro)
  local menu = {}

  -- Focus Mode status
  local focusActive = obj:isFocusModeActive()
  table.insert(menu, {
    title = string.format("Focus Mode: %s", focusActive and "On" or "Off"),
    disabled = true
  })

  table.insert(menu, hs.menuitem.separator)

  -- Focus integration toggle
  local integrationEnabled = config.autoStartOnFocus
  table.insert(menu, {
    title = string.format("Auto-Start: %s", integrationEnabled and "On" or "Off"),
    fn = function()
      obj:configure({ autoStartOnFocus = not integrationEnabled })
      -- Note: This would require menu refresh to show updated state
    end
  })

  table.insert(menu, {
    title = string.format("Auto-Pause: %s", config.autoPauseOnUnfocus and "On" or "Off"),
    fn = function()
      obj:configure({ autoPauseOnUnfocus = not config.autoPauseOnUnfocus })
    end
  })

  table.insert(menu, hs.menuitem.separator)

  -- Manual Focus trigger
  table.insert(menu, {
    title = "Trigger Focus Mode",
    fn = function()
      obj:manuallyTriggerFocus(not focusActive)
    end
  })

  table.insert(menu, {
    title = "Check Focus Status",
    fn = function()
      if simpleFocus then
        local isActive = simpleFocus.isFocusModeActive()
        hs.alert.show(string.format("Focus Mode: %s", isActive and "Active" or "Inactive"))
      end
    end
  })

  table.insert(menu, hs.menuitem.separator)

  -- Integration info
  table.insert(menu, {
    title = "Detection Method: AppleScript",
    disabled = true
  })

  return menu
end

-- Export the integration menu helper
obj.createIntegrationMenu = createIntegrationMenu

return obj