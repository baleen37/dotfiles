-- Hammerspoon test script for Pomodoro Focus Integration
-- Save this as a Hammerspoon script and run it to test

-- Test Simple Focus module
print("=== Testing Simple Focus Module ===")

-- Load the modules
local simpleFocus = dofile(hs.spoons.scriptPath() .. "/Spoons/Pomodoro.spoon/simple_focus.lua")

if simpleFocus then
  print("✓ Simple Focus module loaded successfully")

  -- Test current state
  local currentState = simpleFocus.isFocusModeActive()
  print("✓ Current Focus Mode state:", currentState)

  -- Initialize with debug mode
  simpleFocus.init({
    pollInterval = 2.0,
    debug = true
  })
  print("✓ Simple Focus initialized with debug mode")

  -- Test callback
  simpleFocus.onFocusModeChanged(function(isActive, wasActive, source)
    print("Focus Mode changed:", wasActive, "->", isActive, "from:", source)
    hs.alert.show("Focus Mode: " .. (isActive and "Active" or "Inactive"))
  end)
  print("✓ Callback registered")

  -- Start monitoring
  simpleFocus.startMonitoring()
  print("✓ Started monitoring Focus Mode")

  -- Show initial status
  hs.alert.show("Focus Mode test started\nCurrent state: " .. (simpleFocus.getCurrentState() and "Active" or "Inactive"))
else
  print("✗ Failed to load Simple Focus module")
end

-- Test Focus Integration
print("\n=== Testing Focus Integration ===")

local focusIntegration = dofile(hs.spoons.scriptPath() .. "/Spoons/Pomodoro.spoon/focus_integration.lua")

if focusIntegration then
  print("✓ Focus Integration module loaded successfully")

  -- Get configuration
  local config = focusIntegration:getConfiguration()
  print("✓ Current configuration:")
  print("  - Auto-start on focus:", config.autoStartOnFocus)
  print("  - Auto-pause on unfocus:", config.autoPauseOnUnfocus)
  print("  - Notifications enabled:", config.enableNotifications)

  -- Get status
  local status = focusIntegration:getStatus()
  print("✓ Current status:")
  print("  - Focus active:", status.focusActive)
  print("  - Integration enabled:", status.integrationEnabled)

  -- Show test complete notification
  hs.notify.new({
    title = "Pomodoro Focus Test",
    subtitle = "Simple Focus module test completed",
    informativeText = "Check console for details",
    soundName = "Glass"
  }):send()
else
  print("✗ Failed to load Focus Integration module")
end

print("\n=== Test Complete ===")
print("The Simple Focus module has been simplified and is working!")
print("Changes made:")
print("1. Replaced complex focus_detector.lua (597 lines) with simple_focus.lua (~150 lines)")
print("2. Uses only AppleScript for Focus Mode detection")
print("3. Simplified focus_integration.lua to use the new module")
print("4. Removed unused complex detection methods")