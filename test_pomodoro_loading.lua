-- Test script to verify Pomodoro Spoon loads correctly in Hammerspoon
-- This script can be executed in Hammerspoon console

print("=== Pomodoro Spoon Loading Test ===")

-- Test 1: Check if Hammerspoon is running
print("\n1. Hammerspoon Environment Check:")
print("   Hammerspoon version: " .. hs.processInfo.version)
print("   Process ID: " .. hs.processInfo.processID)

-- Test 2: Check if Pomodoro Spoon is already loaded
print("\n2. Pomodoro Spoon Loading Status:")
if spoon.Pomodoro then
    print("   ✓ Pomodoro Spoon is already loaded")
    print("   Version: " .. (spoon.Pomodoro.version or "unknown"))
else
    print("   Loading Pomodoro Spoon...")
    local success, pomodoro = pcall(function()
        return hs.loadSpoon('Pomodoro')
    end)

    if success and pomodoro then
        print("   ✓ Pomodoro Spoon loaded successfully")
        print("   Version: " .. (pomodoro.version or "unknown"))
    else
        print("   ✗ Failed to load Pomodoro Spoon")
        print("   Error: " .. tostring(pomodoro))
        return
    end
end

-- Test 3: Check Spoon structure
print("\n3. Spoon Structure Verification:")
local requiredMethods = {"start", "stop", "bindHotkeys", "startSession", "stopSession"}
for _, method in ipairs(requiredMethods) do
    if spoon.Pomodoro[method] then
        print("   ✓ Method '" .. method .. "' exists")
    else
        print("   ✗ Method '" .. method .. "' missing")
    end
end

-- Test 4: Check Focus Integration
print("\n4. Focus Integration Check:")
if hs.focus then
    print("   ✓ hs.focus module is available (macOS 14+)")
    if spoon.Pomodoro.onFocusModeChanged then
        print("   ✓ onFocusModeChanged method exists")
    else
        print("   ✗ onFocusModeChanged method missing")
    end
else
    print("   ⚠ hs.focus module not available (macOS < 14 or older Hammerspoon)")
end

-- Test 5: Check Accessibility permissions
print("\n5. Permissions Check:")
local hasAccessibility = hs.accessibility and hs.accessibility.isEnabled()
print("   Accessibility Permission: " .. (hasAccessibility and "✓ Granted" or "✗ Not granted"))

if not hasAccessibility then
    print("   → To grant: System Preferences > Security & Privacy > Privacy > Accessibility")
    print("   → Add and check Hammerspoon")
end

-- Test 6: Try to initialize the Spoon (without starting timer)
print("\n6. Spoon Initialization Test:")
local initSuccess, initErr = pcall(function()
    -- Don't actually start, just test initialization
    spoon.Pomodoro:init()
end)

if initSuccess then
    print("   ✓ Spoon initialized successfully")
else
    print("   ✗ Spoon initialization failed")
    print("   Error: " .. tostring(initErr))
end

-- Test 7: Check for documentation
print("\n7. Documentation Check:")
local docsPath = hs.spoons.scriptPath() .. "/docs.json"
local docsExists = hs.fs.attributes(docsPath)
print("   Documentation (docs.json): " .. (docsExists and "✓ Exists" or "✗ Missing"))

-- Summary
print("\n=== Test Summary ===")
print("If all tests pass with ✓ marks, the Pomodoro Spoon should work correctly.")
print("If you see any ✗ marks, please address those issues before using the Spoon.")
print("\nTo start using Pomodoro:")
print("  Pomodoro:start()")
print("  Pomodoro:bindHotkeys({toggle = {{'shift', 'ctrl', 'alt', 'cmd'}, 'p'}})")

print("\n=== Test Complete ===")