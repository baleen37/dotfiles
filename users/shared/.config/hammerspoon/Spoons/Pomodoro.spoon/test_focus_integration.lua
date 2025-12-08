#!/usr/bin/env lua

-- Focus integration test for Pomodoro.spoon
-- Tests the integration between Pomodoro and Focus Mode Detector

-- Set test mode
_G.POMODORO_TEST_MODE = true

-- Load modules
local pomodoro = dofile(hs.fs.path.tildeexpand("~/.hammerspoon/Spoons/Pomodoro.spoon/init.lua"))
local focusIntegration = dofile(hs.fs.path.tildeexpand("~/.hammerspoon/Spoons/Pomodoro.spoon/focus_integration.lua"))

-- Test utilities
local testPassed = 0
local testFailed = 0
local testResults = {}

local function assert(condition, message)
    if condition then
        testPassed = testPassed + 1
        table.insert(testResults, {status = "PASS", message = message})
        print("✓ PASS: " .. message)
    else
        testFailed = testFailed + 1
        table.insert(testResults, {status = "FAIL", message = message})
        print("✗ FAIL: " .. message)
    end
end

local function assertEqual(actual, expected, message)
    local actualStr = tostring(actual)
    local expectedStr = tostring(expected)

    if actual == expected then
        testPassed = testPassed + 1
        table.insert(testResults, {status = "PASS", message = message})
        print("✓ PASS: " .. message)
    else
        testFailed = testFailed + 1
        table.insert(testResults, {status = "FAIL", message = message .. " (Expected: " .. expectedStr .. ", Got: " .. actualStr .. ")"})
        print("✗ FAIL: " .. message .. " (Expected: " .. expectedStr .. ", Got: " .. actualStr .. ")")
    end
end

print("=== Focus Integration Test Suite ===\n")

-- Test 1: API methods exist
print("Test 1: Checking API methods existence")
assert(type(pomodoro.isRunning) == "function", "Pomodoro:isRunning() method exists")
assert(type(pomodoro.isBreak) == "function", "Pomodoro:isBreak() method exists")
assert(type(pomodoro.getTimeLeft) == "function", "Pomodoro:getTimeLeft() method exists")
assert(type(pomodoro.setBreak) == "function", "Pomodoro:setBreak() method exists")
assert(type(pomodoro.startSessionWithDuration) == "function", "Pomodoro:startSessionWithDuration() method exists")

-- Test 2: Initial state
print("\nTest 2: Checking initial state")
assertEqual(pomodoro:isRunning(), false, "Initial state: not running")
assertEqual(pomodoro:isBreak(), false, "Initial state: not on break")
assertEqual(pomodoro:getTimeLeft(), 0, "Initial state: no time left")

-- Test 3: Focus integration setup
print("\nTest 3: Focus integration setup")
focusIntegration:setPomodoroReference(pomodoro)
local config = focusIntegration:getConfiguration()
assert(type(config) == "table", "Configuration is a table")
assertEqual(config.autoStartOnFocus, true, "Auto-start on focus is enabled by default")
assertEqual(config.autoPauseOnUnfocus, true, "Auto-pause on unfocus is enabled by default")

-- Test 4: State preservation
print("\nTest 4: State preservation")
-- Start a session
pomodoro:startSessionWithDuration(300)  -- 5 minutes
assertEqual(pomodoro:isRunning(), true, "Session started")
assertEqual(pomodoro:getTimeLeft(), 300, "Time left is 300 seconds")

-- Set break state
pomodoro:setBreak(true)
assertEqual(pomodoro:isBreak(), true, "Break state set to true")

-- Stop the session
pomodoro:stopSession()
assertEqual(pomodoro:isRunning(), false, "Session stopped")

-- Test 5: Session restore with isRestore flag
print("\nTest 5: Session restore behavior")
local sessionsBefore = pomodoro:getStatistics().today
pomodoro:startSessionWithDuration(150, true)  -- Restore with 2.5 minutes left
assertEqual(pomodoro:isRunning(), true, "Session restored")
assertEqual(pomodoro:getTimeLeft(), 150, "Time left is 150 seconds")

-- Sessions should not increment for restore
local sessionsAfter = pomodoro:getStatistics().today
assertEqual(sessionsBefore, sessionsAfter, "Session count not incremented on restore")

-- Test 6: Configuration changes
print("\nTest 6: Configuration changes")
local newConfig = {
    autoStartOnFocus = false,
    autoPauseOnUnfocus = false,
    focusSessionDuration = 1800  -- 30 minutes
}
focusIntegration:configure(newConfig)
local updatedConfig = focusIntegration:getConfiguration()
assertEqual(updatedConfig.autoStartOnFocus, false, "Auto-start on focus disabled")
assertEqual(updatedConfig.autoPauseOnUnfocus, false, "Auto-pause on unfocus disabled")
assertEqual(updatedConfig.focusSessionDuration, 1800, "Focus session duration updated")

-- Test 7: Status reporting
print("\nTest 7: Status reporting")
local status = focusIntegration:getStatus()
assert(type(status) == "table", "Status is a table")
assert(type(status.focusActive) == "boolean", "Status includes focusActive")
assert(type(status.sessionActive) == "boolean", "Status includes sessionActive")
assert(type(status.integrationEnabled) == "boolean", "Status includes integrationEnabled")

-- Test 8: Integration menu creation
print("\nTest 8: Integration menu creation")
local menu = focusIntegration.createIntegrationMenu(pomodoro)
assert(type(menu) == "table", "Integration menu is a table")
assert(#menu > 0, "Integration menu has items")

-- Check for essential menu items
local hasFocusStatus = false
local hasAutoStart = false
for _, item in ipairs(menu) do
    if item.title and string.find(item.title, "Focus Mode:") then
        hasFocusStatus = true
    end
    if item.title and string.find(item.title, "Auto-Start:") then
        hasAutoStart = true
    end
end
assert(hasFocusStatus, "Menu includes Focus Mode status")
assert(hasAutoStart, "Menu includes Auto-Start toggle")

-- Test 9: Error handling
print("\nTest 9: Error handling")
-- Test invalid duration
local result = pomodoro:startSessionWithDuration(-10)
assertEqual(result, false, "Rejects negative duration")
local result = pomodoro:startSessionWithDuration(0)
assertEqual(result, false, "Rejects zero duration")
local result = pomodoro:startSessionWithDuration("invalid")
assertEqual(result, false, "Rejects non-numeric duration")

-- Test 10: Manual focus trigger
print("\nTest 10: Manual focus trigger")
-- Test that manual trigger doesn't crash
focusIntegration:manuallyTriggerFocus(true)
focusIntegration:manuallyTriggerFocus(false)

-- Clean up
pomodoro:stopSession()
focusIntegration:stop()

-- Test Results Summary
print("\n" .. string.rep("=", 50))
print("Test Results Summary")
print(string.rep("=", 50))
print("Total tests: " .. (testPassed + testFailed))
print("Passed: " .. testPassed)
print("Failed: " .. testFailed)
print("Success rate: " .. string.format("%.1f%%", (testPassed / (testPassed + testFailed)) * 100))

if testFailed > 0 then
    print("\nFailed Tests:")
    for _, result in ipairs(testResults) do
        if result.status == "FAIL" then
            print("  - " .. result.message)
        end
    end
end

print("\n=== Focus Integration Test Suite Complete ===")

-- Return test results for programmatic access
return {
    passed = testPassed,
    failed = testFailed,
    total = testPassed + testFailed,
    results = testResults
}