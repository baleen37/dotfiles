--- === Simple Focus Mode Detector ===
---
--- A simple Focus Mode detection system for Hammerspoon
--- Uses AppleScript to check Do Not Disturb status
---

local obj = {}
obj.__index = obj

-- Module metadata
obj.name = "SimpleFocus"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT"

-- State tracking
local currentFocusState = false
local callbacks = {}

-- Configuration
local config = {
  pollInterval = 2.0,  -- Check Focus status every 2 seconds
  debug = false
}

-- Helper functions
local function log(...)
  if config.debug then
    print("[SimpleFocus]", ...)
  end
end

-- Check if Focus Mode is active using AppleScript
function obj.isFocusModeActive()
  local script = 'tell application "System Events" to get do not disturb value of appearance preferences'
  local success, result = hs.osascript.applescript(script)

  if success then
    log("Focus Mode status:", result)
    return result
  else
    log("Error checking Focus Mode:", result)
    return false
  end
end

-- Start monitoring Focus Mode changes
function obj.startMonitoring()
  if obj.timer then
    obj.stopMonitoring()
  end

  local function checkFocus()
    local newState = obj.isFocusModeActive()

    if newState ~= currentFocusState then
      log(string.format("Focus Mode changed: %s -> %s",
                       tostring(currentFocusState), tostring(newState)))

      -- Notify all callbacks
      for _, callback in ipairs(callbacks) do
        callback(newState, currentFocusState, "SimpleFocus")
      end

      currentFocusState = newState
    end
  end

  obj.timer = hs.timer.new(config.pollInterval, checkFocus)
  obj.timer:start()

  -- Check initial state
  currentFocusState = obj.isFocusModeActive()

  log("Started monitoring Focus Mode")
end

-- Stop monitoring Focus Mode changes
function obj.stopMonitoring()
  if obj.timer then
    obj.timer:stop()
    obj.timer = nil
    log("Stopped monitoring Focus Mode")
  end
end

-- Add callback for Focus Mode changes
function obj.onFocusModeChanged(callback)
  table.insert(callbacks, callback)
  log("Added Focus Mode change callback")
end

-- Remove callback for Focus Mode changes
function obj.removeFocusModeCallback(callback)
  for i, cb in ipairs(callbacks) do
    if cb == callback then
      table.remove(callbacks, i)
      break
    end
  end
  log("Removed Focus Mode change callback")
end

-- Get current Focus Mode state
function obj.getCurrentState()
  return currentFocusState
end

-- Set debug mode
function obj.setDebugMode(enabled)
  config.debug = enabled
  log("Debug mode", enabled and "enabled" or "disabled")
end

-- Initialize the module
function obj.init(options)
  options = options or {}
  config.pollInterval = options.pollInterval or config.pollInterval
  config.debug = options.debug or config.debug

  log("Simple Focus initialized with poll interval:", config.pollInterval)
  return obj
end

return obj