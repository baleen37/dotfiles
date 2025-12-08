#!/usr/bin/env lua

-- Test script for Focus Mode integration
-- This script can be run in Hammerspoon console to test the implementation

print("=== Testing Pomodoro Focus Mode Integration ===\n")

-- Test 1: Check if Pomodoro spoon is loaded
if spoon and spoon.Pomodoro then
  print("✓ Pomodoro spoon is loaded")

  -- Test 2: Check if Focus Integration is available
  local debugInfo = spoon.Pomodoro:getFocusDebugInfo()
  print("\nFocus Integration Debug Info:")
  for key, value in pairs(debugInfo) do
    print(string.format("  %s: %s", key, tostring(value)))
  end

  -- Test 3: Check hs.focus availability
  if hs.focus then
    print("\n✓ hs.focus module is available")

    -- Get current focus modes
    local modes = hs.focus.getFocusModes()
    print("\nCurrent Focus Modes:")
    if modes and #modes > 0 then
      for _, mode in ipairs(modes) do
        print(string.format("  - %s: %s", mode.name, mode.active and "active" or "inactive"))
      end
    else
      print("  No focus modes found")
    end
  else
    print("\n✗ hs.focus module is not available")
    print("  Note: hs.focus requires macOS 14+")
  end

  -- Test 4: Test callback registration
  print("\nTesting callback registration...")
  local testCallback = function(isActive)
    print(string.format("Focus Mode callback triggered: %s", isActive and "active" or "inactive"))
  end

  local success = spoon.Pomodoro:onFocusModeChanged(testCallback)
  if success then
    print("✓ Callback registered successfully")

    -- Test callback removal
    local removed = spoon.Pomodoro:removeFocusModeCallback(testCallback)
    if removed then
      print("✓ Callback removed successfully")
    else
      print("✗ Failed to remove callback")
    end
  else
    print("✗ Failed to register callback")
  end

  -- Test 5: Check permissions
  print("\nChecking permissions...")
  local hasAccessibility = hs.accessibility and hs.accessibility.isEnabled()
  local hasAutomation = hs.osascript and hs.osascript.applescript('tell application "System Events" to get name of processes') and true or false

  print(string.format("  Accessibility: %s", hasAccessibility and "✓" or "✗ (required)"))
  print(string.format("  Automation: %s", hasAutomation and "✓" or "✗ (may be required)"))

  print("\n=== Test Complete ===")
  print("\nManual testing steps:")
  print("1. Open Control Center and enable 'Pomodoro' Focus Mode")
  print("2. Check if Pomodoro timer starts automatically")
  print("3. Disable 'Pomodoro' Focus Mode")
  print("4. Check if Pomodoro timer stops automatically")
  print("5. Start Pomodoro timer manually")
  print("6. Check if 'Pomodoro' Focus Mode is enabled")
  print("7. Stop Pomodoro timer manually")
  print("8. Check if 'Pomodoro' Focus Mode is disabled")

else
  print("✗ Pomodoro spoon is not loaded")
  print("  Make sure spoon.Pomodoro is loaded in init.lua")
end

print("\nTo run this test, copy and paste into Hammerspoon console")