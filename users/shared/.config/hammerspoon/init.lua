hs.loadSpoon('Hyper')
-- hs.loadSpoon('Headspace'):start()
hs.loadSpoon('HyperModal')
hs.loadSpoon('Pomodoro')  -- FIXED: hs.focus dependency removed


Config = {}
Config.applications = require('configApplications')
print('Config.applications = require("configApplications")')
print('Config.applications = ', Config.applications)

Hyper = spoon.Hyper

Hyper:bindHotKeys({hyperKey = {{}, 'F19'}})

-- provide the ability to override config per computer
if (hs.fs.displayName('./localConfig.lua')) then
    require('localConfig')
end


hs.fnutils.each(Config.applications, function(appConfig)
  if appConfig.hyperKey then
    Hyper:bind({}, appConfig.hyperKey, function()
        if hs.application.get(appConfig.bundleID) and hs.application.get(appConfig.bundleID):isFrontmost() then
            hs.application.get(appConfig.bundleID):hide()
        else
            hs.application.launchOrFocusByBundleID(appConfig.bundleID)
        end
    end)
  end
  if appConfig.localBindings then
    hs.fnutils.each(appConfig.localBindings, function(key)
      Hyper:bindPassThrough(key, appConfig.bundleID)
    end)
  end
end)

HyperModal = spoon.HyperModal
Hyper:bind({}, 'm', function() HyperModal:toggle() end)

-- HyperModal with basic bindings
HyperModal
 :start()
 :bind('', ";", function() hs.urlevent.openURL("raycast://extensions/raycast/system/toggle-system-appearance") end)

-- Initialize Pomodoro Spoon
Pomodoro = spoon.Pomodoro
Pomodoro:start()  -- FIXED: hs.focus dependency removed

-- Bind hotkey for Pomodoro toggle using Hyper key
Pomodoro:bindHotkeys({
  toggle = {{"shift", "ctrl", "alt", "cmd"}, "p"}   -- Hyper+P
})

-- Initialize Focus Mode integration
-- Check if hs.focus module is available (macOS 14+)
if hs.focus then
  print("Pomodoro: Focus Mode integration available (hs.focus detected)")

  -- Check required permissions
  local function checkPermissions()
    local hasAccessibility = hs.accessibility and hs.accessibility.isEnabled()
    local hasAutomation = hs.osascript and hs.osascript.applescript('tell application "System Events" to get name of processes') and true or false

    print("Pomodoro: Permissions check:")
    print("  - Accessibility: " .. (hasAccessibility and "✓" or "✗ (required)"))
    print("  - Automation: " .. (hasAutomation and "✓" or "✗ (may be required)"))

    if not hasAccessibility then
      print("WARNING: Accessibility permission is required for Focus Mode integration")
      print("Please grant Accessibility permission to Hammerspoon in System Preferences > Security & Privacy > Privacy")
    end

    return hasAccessibility
  end

  -- Initialize Focus Mode integration if permissions are ok
  if checkPermissions() then
    -- Register callback for Focus Mode changes with error handling
    local success, err = pcall(function()
      Pomodoro:onFocusModeChanged(function(isActive)
        if isActive then
          -- Focus Mode 'Pomodoro' was activated
          if not Pomodoro:isRunning() then
            print("Focus Mode activated: Starting Pomodoro session")
            Pomodoro:startSession()
          end
        else
          -- Focus Mode 'Pomodoro' was deactivated
          if Pomodoro:isRunning() and not Pomodoro:isBreak() then
            print("Focus Mode deactivated: Stopping Pomodoro session")
            Pomodoro:stopSession()
          end
        end
      end)
    end)

    if not success then
      print("ERROR: Failed to register Focus Mode callback: " .. tostring(err))
    else
      -- Check initial Focus Mode state with error handling
      local success2, err2 = pcall(function()
        local currentFocusModes = hs.focus.getFocusModes() or {}
        local pomodoroFocusActive = false

        for _, mode in ipairs(currentFocusModes) do
          if mode.name == "Pomodoro" and mode.active then
            pomodoroFocusActive = true
            break
          end
        end

        if pomodoroFocusActive then
          print("Pomodoro Focus Mode is already active at startup")
          if not Pomodoro:isRunning() then
            Pomodoro:startSession()
          end
        end
      end)

      if not success2 then
        print("WARNING: Could not check initial Focus Mode state: " .. tostring(err2))
      end
    end
  end
else
  print("Pomodoro: Focus Mode integration not available (hs.focus not found)")
  print("Note: Focus Mode integration requires macOS 14+ with Hammerspoon 0.9.90+")
end
