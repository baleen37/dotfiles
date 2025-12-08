#!/usr/bin/env lua

-- Test Simple Focus module
-- Tests the simplified focus detection functionality

-- Mock Hammerspoon functions for testing
local hs = {
  fs = {
    path = {
      tildeexpand = function(path)
        return path:gsub("^~", os.getenv("HOME"))
      end
    }
  },
  osascript = {
    applescript = function(script)
      -- Mock successful Focus Mode check
      if script:match("do not disturb value") then
        return true, false -- Focus Mode is off
      end
      return true, true
    end
  },
  timer = {
    new = function(interval, fn)
      return {
        start = function() print("Timer started") end,
        stop = function() print("Timer stopped") end
      }
    end
  },
  settings = {
    get = function(key) return nil end,
    set = function(key, value) print("Settings set:", key) end
  },
  notify = {
    new = function(notification)
      return {
        send = function() print("Notification sent:", notification.title) end
      }
    end
  },
  inspect = function(obj)
    if type(obj) == "table" then
      return "{table}"
    end
    return tostring(obj)
  end
}

-- Set global hs
_G.hs = hs

-- Load the simple focus module
package.path = package.path .. ";./?.lua;../?.lua"
local simpleFocus = require("simple_focus")

print("=== Simple Focus Module Test ===\n")

-- Test 1: Module loading
print("Test 1: Module loading")
assert(simpleFocus ~= nil, "Simple Focus module loaded successfully")
print("✓ PASS: Simple Focus module loaded\n")

-- Test 2: Check module metadata
print("Test 2: Module metadata")
assert(simpleFocus.name == "SimpleFocus", "Module name is correct")
assert(simpleFocus.version == "1.0", "Module version is correct")
print("✓ PASS: Module metadata is correct\n")

-- Test 3: Focus Mode detection
print("Test 3: Focus Mode detection")
local isActive = simpleFocus.isFocusModeActive()
assert(type(isActive) == "boolean", "isFocusModeActive returns boolean")
print("✓ PASS: isFocusModeActive returns boolean, current state:", isActive, "\n")

-- Test 4: Callback registration
print("Test 4: Callback registration")
local callbackTriggered = false
local testCallback = function(isActive, wasActive, source)
  callbackTriggered = true
  print("Callback triggered: ", isActive, wasActive, source)
end

simpleFocus.onFocusModeChanged(testCallback)
-- Note: callbacks is a local variable in the module, so we can't directly access it
-- The callback registration test just verifies the function doesn't error
print("✓ PASS: Callback registered (no error)\n")

-- Test 5: State tracking
print("Test 5: State tracking")
local currentState = simpleFocus.getCurrentState()
assert(type(currentState) == "boolean", "Current state is boolean")
print("✓ PASS: Current state tracked, value:", currentState, "\n")

-- Test 6: Debug mode
print("Test 6: Debug mode")
simpleFocus.setDebugMode(true)
print("✓ PASS: Debug mode enabled\n")

-- Test 7: Module initialization
print("Test 7: Module initialization")
simpleFocus.init({
  pollInterval = 1.0,
  debug = false
})
print("✓ PASS: Module initialized with custom options\n")

-- Test 8: Start/stop monitoring
print("Test 8: Start/stop monitoring")
simpleFocus.startMonitoring()
print("✓ PASS: Monitoring started")
simpleFocus.stopMonitoring()
print("✓ PASS: Monitoring stopped\n")

print("=== All Tests Passed! ===")
print("\nSimple Focus module is working correctly.")
print("The module provides:")
print("- AppleScript-based Focus Mode detection")
print("- Callback system for state changes")
print("- Configurable polling interval")
print("- Debug mode support")
print("- State tracking")