--- === Focus Mode Detector ===
---
--- A comprehensive Focus Mode detection system for Hammerspoon
--- Combines multiple detection methods for reliable Focus Mode monitoring
---
--- Detection Methods:
--- 1. SystemUIServer application monitoring
--- 2. Control Center window watching
--- 3. File system monitoring for preference changes
--- 4. AppleScript-based Focus Mode queries
--- 5. Network and system state inference
--- 6. URL scheme triggers for external integration

local obj = {}
obj.__index = obj

-- Module metadata
obj.name = "FocusModeDetector"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT"

-- State tracking
local currentFocusState = false
local lastFocusChange = 0
local detectionMethods = {}
local callbacks = {}

-- Configuration
local config = {
  -- Detection method priorities (higher = more reliable)
  methodPriorities = {
    applescript = 10,
    filewatcher = 8,
    uiwatcher = 6,
    network = 3
  },

  -- File paths to monitor
  watchPaths = {
    "~/Library/DoNotDisturb/",
    "~/Library/FocusStatus/",
    "~/Library/Preferences/com.apple.controlcenter.plist",
    "~/Library/Preferences/com.apple.notificationcenterui.plist"
  },

  -- Polling intervals (in seconds)
  pollIntervals = {
    focus = 2.0,      -- Focus status polling
    network = 5.0,    -- Network state polling
    debounce = 0.5    -- Debounce rapid changes
  },

  -- Debug mode
  debug = false
}

-- Helper functions
local function log(...)
  if config.debug then
    print("[FocusModeDetector]", ...)
  end
end

local function getCurrentTimestamp()
  return os.time()
end

local function debounce(func, delay)
  local lastCall = 0
  return function(...)
    local now = getCurrentTimestamp()
    if now - lastCall >= delay then
      lastCall = now
      return func(...)
    end
  end
end

-- Method 1: AppleScript-based Focus Mode detection (most reliable)
local function createAppleScriptDetector()
  local detector = {
    name = "AppleScript",
    active = false,
    timer = nil
  }

  -- AppleScript to get Focus Mode status
  local focusScript = [[
    tell application "System Events"
      try
        -- Get Focus Mode status from Control Center
        set focusStatus to do shell script "defaults read com.apple.controlcenter 'NSStatusItem Visible FocusModes' 2>/dev/null || echo 'false'"

        -- Alternative method: Check Do Not Disturb status
        if focusStatus contains "false" then
          set dndStatus to do shell script "defaults read com.apple.notificationcenterui 'doNotDisturb' 2>/dev/null || echo '0'"
          if dndStatus contains "1" then
            return "true"
          end
        end

        return focusStatus
      on error
        return "false"
      end try
    end tell
  ]]

  function detector:check()
    local success, result = hs.applescript.applescript(focusScript)
    if success then
      local isActive = result:match("true") and true or false
      log("AppleScript detection:", isActive)
      return isActive, "applescript"
    end
    return nil, "applescript"
  end

  function detector:start()
    if not self.active then
      self.active = true
      self.timer = hs.timer.new(config.pollIntervals.focus, function()
        local isActive, method = detector:check()
        if isActive ~= nil then
          obj.processFocusStateChange(isActive, method)
        end
      end)
      self.timer:start()
      log("AppleScript detector started")
    end
  end

  function detector:stop()
    if self.active and self.timer then
      self.timer:stop()
      self.timer = nil
      self.active = false
      log("AppleScript detector stopped")
    end
  end

  return detector
end

-- Method 2: File system watcher for preference changes
local function createFileWatcher()
  local detector = {
    name = "FileWatcher",
    active = false,
    watchers = {},
    lastModified = {}
  }

  local function handleFileChange(files)
    log("File change detected in:", table.concat(files, ", "))

    -- Debounce rapid file changes
    hs.timer.doAfter(config.pollIntervals.debounce, function()
      for _, file in ipairs(files) do
        local modified = hs.fs.attributes(file, "modification")
        if modified and modified ~= (detector.lastModified[file] or 0) then
          detector.lastModified[file] = modified

          -- Trigger Focus check with slight delay
          hs.timer.doAfter(0.2, function()
            obj.checkAllDetectionMethods()
          end)
        end
      end
    end)
  end

  function detector:start()
    if not self.active then
      self.active = true

      -- Start file watchers
      for _, path in ipairs(config.watchPaths) do
        local expandedPath = hs.fs.path.tildeexpand(path)
        if hs.fs.attributes(expandedPath) then
          local watcher = hs.pathwatcher.new(expandedPath, handleFileChange)
          if watcher then
            watcher:start()
            table.insert(self.watchers, watcher)
            log("Watching file:", expandedPath)
          end
        else
          log("Path does not exist:", expandedPath)
        end
      end
    end
  end

  function detector:stop()
    if self.active then
      for _, watcher in ipairs(self.watchers) do
        watcher:stop()
      end
      self.watchers = {}
      self.lastModified = {}
      self.active = false
      log("File watcher stopped")
    end
  end

  return detector
end

-- Method 3: SystemUIServer and Control Center monitoring
local function createUIWatcher()
  local detector = {
    name = "UIWatcher",
    active = false,
    appWatcher = nil,
    windowFilter = nil
  }

  -- Monitor SystemUIServer for Focus Mode changes
  local function onAppEvent(appName, eventType, app)
    if appName == "SystemUIServer" then
      log("SystemUIServer event:", eventType)

      if eventType == hs.application.watcher.launched or
         eventType == hs.application.watcher.activated then
        -- Trigger Focus check after a short delay
        hs.timer.doAfter(0.5, function()
          obj.checkAllDetectionMethods()
        end)
      end
    end
  end

  -- Monitor Control Center windows
  local function onWindowEvent(window, appName, event)
    if appName == "Control Center" then
      log("Control Center window event:", event)

      -- When Control Center closes, check for Focus Mode changes
      if event == hs.window.filter.windowDestroyed then
        hs.timer.doAfter(0.3, function()
          obj.checkAllDetectionMethods()
        end)
      end
    end
  end

  function detector:start()
    if not self.active then
      self.active = true

      -- Start application watcher
      self.appWatcher = hs.application.watcher.new(onAppEvent)
      self.appWatcher:start()

      -- Start window filter for Control Center
      self.windowFilter = hs.window.filter.new(function(w)
        return w:application():name() == "Control Center"
      end)

      self.windowFilter:subscribe(hs.window.filter.windowCreated, onWindowEvent)
      self.windowFilter:subscribe(hs.window.filter.windowDestroyed, onWindowEvent)

      log("UI watcher started")
    end
  end

  function detector:stop()
    if self.active then
      if self.appWatcher then
        self.appWatcher:stop()
        self.appWatcher = nil
      end

      if self.windowFilter then
        self.windowFilter:unsubscribeAll()
        self.windowFilter = nil
      end

      self.active = false
      log("UI watcher stopped")
    end
  end

  return detector
end

-- Method 4: Network and system state inference
local function createNetworkDetector()
  local detector = {
    name = "NetworkDetector",
    active = false,
    timer = nil,
    lastNetworkState = nil
  }

  -- Check if system state suggests Focus Mode
  function detector:check()
    local wifi = hs.wifi.currentNetwork()
    local screens = hs.screen.allScreens()
    local caffeinated = hs.caffeinate.get("displayIdle") or false

    -- Create a state signature
    local state = {
      network = wifi or "disconnected",
      screens = #screens,
      caffeinated = caffeinated,
      timestamp = getCurrentTimestamp()
    }

    -- Compare with last state
    local hasChanged = false
    if self.lastNetworkState then
      hasChanged = (state.network ~= self.lastNetworkState.network or
                   state.screens ~= self.lastNetworkState.screens or
                   state.caffeinated ~= self.lastNetworkState.caffeinated)
    end

    self.lastNetworkState = state

    if hasChanged then
      log("Network state changed:", state.network, state.screens, "screens",
          state.caffeinated and "caffeinated" or "normal")

      -- Infer potential Focus Mode changes
      -- Example: Disconnecting from WiFi might indicate starting Focus Mode
      local inferredFocus = (state.network == "disconnected" and state.screens == 1)

      return inferredFocus, "network"
    end

    return nil, "network"
  end

  function detector:start()
    if not self.active then
      self.active = true
      self.timer = hs.timer.new(config.pollIntervals.network, function()
        local inferred, method = detector:check()
        if inferred ~= nil then
          -- Network detection is less reliable, so use it as a hint only
          log("Network inference:", inferred)
          obj.checkAllDetectionMethods()
        end
      end)
      self.timer:start()
      log("Network detector started")
    end
  end

  function detector:stop()
    if self.active and self.timer then
      self.timer:stop()
      self.timer = nil
      self.active = false
      log("Network detector stopped")
    end
  end

  return detector
end

-- URL scheme handler for external triggers
local function setupURLHandler()
  local urlHandler = function(scheme, host, params)
    if scheme == "hammerspoon-focus" then
      log("URL trigger received:", host, params)

      if host == "toggle" then
        obj.toggleManualFocus()
      elseif host == "on" then
        obj.setManualFocus(true)
      elseif host == "off" then
        obj.setManualFocus(false)
      elseif host == "check" then
        obj.checkAllDetectionMethods()
      end

      return true
    end
    return false
  end

  hs.urlevent.registerCallback("hammerspoon-focus", urlHandler)
  log("URL handler registered: hammerspoon-focus://")
end

-- Core functionality
local function processStateChange(newState, source, priority)
  local now = getCurrentTimestamp()

  -- Debounce rapid changes
  if now - lastFocusChange < config.pollIntervals.debounce then
    return
  end

  -- Update state if this is higher priority or current state is uncertain
  if newState ~= currentFocusState then
    local oldState = currentFocusState
    currentFocusState = newState
    lastFocusChange = now

    log(string.format("Focus Mode changed: %s -> %s (source: %s, priority: %d)",
                     tostring(oldState), tostring(newState), source, priority))

    -- Trigger callbacks
    for _, callback in ipairs(callbacks) do
      pcall(callback, newState, oldState, source)
    end
  end
end

-- Public API

--- FocusModeDetector:start() -> FocusModeDetector
--- Method
--- Starts the Focus Mode detection system
---
--- Returns:
---  * The FocusModeDetector object
function obj:start()
  if not detectionMethods.applescript then
    -- Initialize detection methods
    detectionMethods.applescript = createAppleScriptDetector()
    detectionMethods.filewatcher = createFileWatcher()
    detectionMethods.uiwatcher = createUIWatcher()
    detectionMethods.network = createNetworkDetector()

    -- Setup URL handler
    setupURLHandler()

    -- Start all detection methods
    for name, detector in pairs(detectionMethods) do
      detector:start()
    end

    -- Perform initial check
    hs.timer.doAfter(1.0, function()
      obj.checkAllDetectionMethods()
    end)

    log("Focus Mode Detector started")
  end

  return self
end

--- FocusModeDetector:stop() -> FocusModeDetector
--- Method
--- Stops the Focus Mode detection system
---
--- Returns:
---  * The FocusModeDetector object
function obj:stop()
  for name, detector in pairs(detectionMethods) do
    detector:stop()
  end
  detectionMethods = {}

  hs.urlevent.unregisterCallback("hammerspoon-focus")

  log("Focus Mode Detector stopped")
  return self
end

--- FocusModeDetector.checkAllDetectionMethods()
--- Function
--- Checks all detection methods and updates Focus state based on highest priority result
function obj.checkAllDetectionMethods()
  local bestResult = nil
  local bestPriority = -1
  local bestSource = nil

  for name, detector in pairs(detectionMethods) do
    if detector.check then
      local result, source = detector:check()
      if result ~= nil then
        local priority = config.methodPriorities[name] or 0
        if priority > bestPriority then
          bestResult = result
          bestPriority = priority
          bestSource = source or name
        end
      end
    end
  end

  if bestResult ~= nil then
    processStateChange(bestResult, bestSource, bestPriority)
  end
end

--- FocusModeDetector.processFocusStateChange(newState, source)
--- Function
--- Internal function to process Focus Mode state changes
function obj.processFocusStateChange(newState, source)
  local priority = config.methodPriorities[source] or 0
  processStateChange(newState, source, priority)
end

--- FocusModeDetector:addCallback(callback)
--- Method
--- Adds a callback function to be called when Focus Mode changes
---
--- Parameters:
---  * callback - Function that receives (newState, oldState, source)
function obj:addCallback(callback)
  table.insert(callbacks, callback)
end

--- FocusModeDetector:removeCallback(callback)
--- Method
--- Removes a callback function
---
--- Parameters:
---  * callback - The callback function to remove
function obj:removeCallback(callback)
  for i, cb in ipairs(callbacks) do
    if cb == callback then
      table.remove(callbacks, i)
      break
    end
  end
end

--- FocusModeDetector:isFocusModeActive() -> boolean
--- Method
--- Returns the current Focus Mode state
---
--- Returns:
---  * true if Focus Mode is active, false otherwise
function obj:isFocusModeActive()
  return currentFocusState
end

--- FocusModeDetector:toggleManualFocus()
--- Method
--- Manually toggles Focus Mode state
function obj:toggleManualFocus()
  currentFocusState = not currentFocusState
  lastFocusChange = getCurrentTimestamp()

  log("Manual Focus Mode toggle:", currentFocusState)

  for _, callback in ipairs(callbacks) do
    pcall(callback, currentFocusState, not currentFocusState, "manual")
  end
end

--- FocusModeDetector:setManualFocus(state)
--- Method
--- Manually sets Focus Mode state
---
--- Parameters:
---  * state - Boolean value for Focus Mode state
function obj:setManualFocus(state)
  if state ~= currentFocusState then
    local oldState = currentFocusState
    currentFocusState = state
    lastFocusChange = getCurrentTimestamp()

    log("Manual Focus Mode set:", state)

    for _, callback in ipairs(callbacks) do
      pcall(callback, state, oldState, "manual")
    end
  end
end

--- FocusModeDetector:setDebugMode(enabled)
--- Method
--- Enables or disables debug logging
---
--- Parameters:
---  * enabled - Boolean to enable/disable debug mode
function obj:setDebugMode(enabled)
  config.debug = enabled
  log("Debug mode:", enabled and "enabled" or "disabled")
end

--- FocusModeDetector:getDetectionMethods() -> table
--- Method
--- Returns information about active detection methods
---
--- Returns:
---  * Table with detection method information
function obj:getDetectionMethods()
  local info = {}
  for name, detector in pairs(detectionMethods) do
    info[name] = {
      active = detector.active,
      priority = config.methodPriorities[name] or 0
    }
  end
  return info
end

return obj