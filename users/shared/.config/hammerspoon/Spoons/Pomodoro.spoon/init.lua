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
obj.name = "Pomodoro"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT"
obj.homepage = "https://github.com/evantravers/dotfiles"
obj.description = "Pomodoro timer with Focus mode integration"

-- Default Configuration
obj.config = {
  workDuration = 25 * 60,        -- 25 minutes in seconds
  breakDuration = 5 * 60,        -- 5 minutes in seconds
  focusMode = "Pomodoro",
  statsCacheDuration = 300,      -- 5 minutes in seconds
  -- Callbacks
  onWorkStart = nil,             -- Called when work session starts
  onBreakStart = nil,            -- Called when break starts (work completed)
  onComplete = nil,              -- Called when session completes (break ends)
  onStopped = nil                -- Called when session is stopped prematurely
}

-- Application State
local State = {
  timerRunning = false,
  isBreak = false,
  sessionsCompleted = 0,
  timeLeft = 0,
  sessionStartTime = nil,
  -- Drag state
  isDragging = false,
  dragStartPos = nil,
  dragStartFrame = nil,
}

-- UI Components
local UI = {
  countdownTimer = nil,
  menubarItem = nil,
  focusWatcherEnabled = nil,
  focusWatcherDisabled = nil,
  lastKnownFocus = nil,
  overlayCanvas = nil,
  dragTimer = nil,
  screenWatcher = nil,
  modalCanvas = nil,
  modalTimer = nil,
  modalFadeTimer = nil,
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
  if not Cache.dateString or math.abs(now - Cache.timestamp) > obj.config.statsCacheDuration then
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
  if not Cache.stats or math.abs(now - Cache.timestamp) > obj.config.statsCacheDuration then
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
-- OVERLAY MANAGEMENT
-- ============================================================================

local OverlayManager = {}

function OverlayManager.create()
  OverlayManager.cleanup()

  local screen = hs.screen.mainScreen()
  local frame = screen:frame()

  local canvasWidth = 200
  local canvasHeight = 60
  local padding = 20

  -- Load saved position or use default
  local savedPos = hs.settings.get("pomodoro.overlay.position")
  local canvasX, canvasY
  if savedPos then
    canvasX = savedPos.x
    canvasY = savedPos.y
  else
    canvasX = frame.w - canvasWidth - padding
    canvasY = frame.h - canvasHeight - padding
  end

  local canvas = hs.canvas.new({
    x = canvasX,
    y = canvasY,
    w = canvasWidth,
    h = canvasHeight
  })

  canvas[1] = {
    type = "text",
    text = "",
    textFont = "SF Pro Display",
    textSize = 48,
    textColor = {red = 1, green = 0.4, blue = 0.4, alpha = 0.3},
    textAlignment = "right",
    trackMouseEnterExit = true,
    frame = {x = 0, y = 0, w = canvasWidth, h = canvasHeight}
  }

  canvas:level(hs.drawing.windowLevels.floating)
  canvas:behavior({
    hs.drawing.windowBehaviors.canJoinAllSpaces,
    hs.drawing.windowBehaviors.stationary
  })

  -- Mouse event handlers for hover and dragging
  canvas:mouseCallback(function(c, event, id, x, y)
    if event == "mouseEnter" then
      c[1].textColor = {red = 1, green = 0.4, blue = 0.4, alpha = 1.0}
    elseif event == "mouseExit" then
      c[1].textColor = {red = 1, green = 0.4, blue = 0.4, alpha = 0.3}
    elseif event == "mouseDown" then
      State.isDragging = true
      State.dragStartPos = hs.mouse.getAbsolutePosition()
      State.dragStartFrame = c:frame()
      OverlayManager.startDragTimer()
    elseif event == "mouseUp" then
      if State.isDragging then
        State.isDragging = false
        OverlayManager.stopDragTimer()
        -- Save position
        local currentFrame = c:frame()
        hs.settings.set("pomodoro.overlay.position", {
          x = currentFrame.x,
          y = currentFrame.y
        })
      end
    end
  end)

  UI.overlayCanvas = canvas
  OverlayManager.startScreenWatcher()
end

function OverlayManager.update()
  if not UI.overlayCanvas then return end

  if State.timerRunning then
    UI.overlayCanvas[1].text = formatTime(State.timeLeft)
    UI.overlayCanvas:show()
  else
    UI.overlayCanvas:hide()
  end
end

function OverlayManager.startDragTimer()
  if UI.dragTimer then return end

  UI.dragTimer = hs.timer.new(0.016, function()
    if not State.isDragging then return end
    if not State.dragStartPos or not State.dragStartFrame then return end

    local currentPos = hs.mouse.getAbsolutePosition()
    local deltaX = currentPos.x - State.dragStartPos.x
    local deltaY = currentPos.y - State.dragStartPos.y

    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    local canvasFrame = UI.overlayCanvas:frame()

    -- Calculate new position with boundary constraints
    local newX = math.max(0, math.min(
      State.dragStartFrame.x + deltaX,
      screenFrame.w - canvasFrame.w
    ))
    local newY = math.max(0, math.min(
      State.dragStartFrame.y + deltaY,
      screenFrame.h - canvasFrame.h
    ))

    UI.overlayCanvas:frame({
      x = newX,
      y = newY,
      w = canvasFrame.w,
      h = canvasFrame.h
    })
  end)

  UI.dragTimer:start()
end

function OverlayManager.stopDragTimer()
  if UI.dragTimer then
    UI.dragTimer:stop()
    UI.dragTimer = nil
  end
end

function OverlayManager.startScreenWatcher()
  if UI.screenWatcher then
    UI.screenWatcher:stop()
  end

  UI.screenWatcher = hs.screen.watcher.new(function()
    if UI.overlayCanvas and State.timerRunning then
      OverlayManager.create()
      OverlayManager.update()
    end
  end):start()
end

function OverlayManager.cleanup()
  OverlayManager.stopDragTimer()

  if UI.screenWatcher then
    UI.screenWatcher:stop()
    UI.screenWatcher = nil
  end

  if UI.overlayCanvas then
    UI.overlayCanvas:delete()
    UI.overlayCanvas = nil
  end
end

-- ============================================================================
-- MODAL MANAGEMENT
-- ============================================================================

local ModalManager = {}

function ModalManager.create(message, emoji)
  local screen = hs.screen.mainScreen()
  local frame = screen:frame()

  local width = 400
  local height = 200
  local centerX = (frame.w - width) / 2
  local centerY = (frame.h - height) / 2

  local canvas = hs.canvas.new({
    x = centerX,
    y = centerY,
    w = width,
    h = height
  })

  -- Background
  canvas[1] = {
    type = "rectangle",
    fillColor = {red = 0, green = 0, blue = 0, alpha = 0},  -- Start transparent
    roundedRectRadii = {xRadius = 12, yRadius = 12},
    frame = {x = 0, y = 0, w = width, h = height}
  }

  -- Text
  canvas[2] = {
    type = "text",
    text = emoji .. "\n" .. message,
    textFont = "SF Pro Display",
    textSize = 32,
    textColor = {white = 1, alpha = 0},  -- Start transparent
    textAlignment = "center",
    frame = {x = 20, y = 40, w = 360, h = 120}
  }

  canvas:level(hs.drawing.windowLevels.modalPanel)
  canvas:behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
  canvas:show()

  return canvas
end

function ModalManager.fadeIn(canvas, callback)
  local currentAlpha = 0
  local targetAlpha = 1
  local fadeStep = 0.056  -- 1.0 / 18 frames ≈ 0.3s at 60fps

  UI.modalFadeTimer = hs.timer.new(0.016, function()
    currentAlpha = currentAlpha + fadeStep
    if currentAlpha >= targetAlpha then
      currentAlpha = targetAlpha
      UI.modalFadeTimer:stop()
      UI.modalFadeTimer = nil
      if callback then callback() end
    end

    -- Update alpha for background and text
    canvas[1].fillColor = {red = 0, green = 0, blue = 0, alpha = currentAlpha * 0.85}
    canvas[2].textColor = {white = 1, alpha = currentAlpha}
  end)

  UI.modalFadeTimer:start()
end

function ModalManager.fadeOut(canvas, callback)
  local currentAlpha = 1
  local targetAlpha = 0
  local fadeStep = 0.056

  UI.modalFadeTimer = hs.timer.new(0.016, function()
    currentAlpha = currentAlpha - fadeStep
    if currentAlpha <= targetAlpha then
      currentAlpha = targetAlpha
      UI.modalFadeTimer:stop()
      UI.modalFadeTimer = nil
      if callback then callback() end
    end

    -- Update alpha for background and text
    canvas[1].fillColor = {red = 0, green = 0, blue = 0, alpha = currentAlpha * 0.85}
    canvas[2].textColor = {white = 1, alpha = currentAlpha}
  end)

  UI.modalFadeTimer:start()
end

function ModalManager.show(message, emoji, duration)
  ModalManager.cleanup()

  local canvas = ModalManager.create(message, emoji)
  UI.modalCanvas = canvas

  -- Fade in, wait, then fade out
  ModalManager.fadeIn(canvas, function()
    UI.modalTimer = hs.timer.doAfter(duration or 2, function()
      ModalManager.fadeOut(canvas, function()
        ModalManager.cleanup()
      end)
    end)
  end)
end

function ModalManager.cleanup()
  if UI.modalTimer then
    UI.modalTimer:stop()
    UI.modalTimer = nil
  end
  if UI.modalFadeTimer then
    UI.modalFadeTimer:stop()
    UI.modalFadeTimer = nil
  end
  if UI.modalCanvas then
    UI.modalCanvas:delete()
    UI.modalCanvas = nil
  end
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

  OverlayManager.update()
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

  -- Callback: onStopped
  if obj.config.onStopped then
    obj.config.onStopped()
  end
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
  State.timeLeft = obj.config.workDuration
  State.timerRunning = true
  State.sessionStartTime = os.time()

  updateMenubarDisplay()

  -- Create overlay if not exists
  if not UI.overlayCanvas then
    OverlayManager.create()
  end

  ModalManager.show("Work session begins!", "🍅", 2)

  -- Callback: onWorkStart
  if obj.config.onWorkStart then
    obj.config.onWorkStart()
  end

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(TimerManager.startBreakSession))
  UI.countdownTimer:start()
end

function TimerManager.startBreakSession()
  TimerManager.cleanup()

  State.isBreak = true
  State.timeLeft = obj.config.breakDuration
  State.timerRunning = true

  updateMenubarDisplay()
  ModalManager.show("25 minutes complete! Take a break", "🍅", 2)

  -- Callback: onBreakStart
  if obj.config.onBreakStart then
    obj.config.onBreakStart()
  end

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(function()
    State.sessionsCompleted = State.sessionsCompleted + 1
    TimerManager.stop()
    saveCurrentStatistics()
    ModalManager.show("Session complete! Great job", "✅", 2)

    -- Callback: onComplete
    if obj.config.onComplete then
      obj.config.onComplete()
    end
  end))
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
  return currentMode == obj.config.focusMode
end

function FocusManager.handleFocusChange()
  local hasPomodoro = FocusManager.isPomodoroActive()

  if hasPomodoro then
    if not State.timerRunning then
      TimerManager.startWorkSession()
    end
  else
    if State.timerRunning then
      ModalManager.show("Pomodoro session stopped", "⏹️", 2)
      saveCurrentStatistics()
      TimerManager.stop()
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
      ModalManager.show("Pomodoro session stopped", "⏹️", 2)
      saveCurrentStatistics()
      TimerManager.stop()
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

  -- Create overlay if timer is running
  if State.timerRunning then
    OverlayManager.create()
    OverlayManager.update()
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

  -- Clean up overlay
  OverlayManager.cleanup()

  -- Clean up modal
  ModalManager.cleanup()

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
