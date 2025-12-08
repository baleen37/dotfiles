#!/usr/bin/env lua

-- Standalone test for Focus integration
-- Tests the integration logic without requiring full Hammerspoon environment

-- Mock hs module for testing
local mock_hs = {
    settings = {
        data = {},
        get = function(key)
            return mock_hs.settings.data[key]
        end,
        set = function(key, value)
            mock_hs.settings.data[key] = value
        end
    },
    timer = {
        new = function(delay, fn)
            return {
                start = function() end,
                stop = function() end
            }
        end
    },
    notify = {
        new = function(params)
            return {
                send = function() end
            }
        end
    },
    fs = {
        path = {
            tildeexpand = function(path)
                return path
            end
        }
    },
    inspect = function(obj)
        return tostring(obj)
    end,
    menuitem = {
        separator = { title = "-" }
    }
}

-- Set global hs
_G.hs = mock_hs

-- Mock dofile for focus_detector
local original_dofile = dofile
dofile = function(path)
    if path:match("focus_detector%.lua$") then
        return mock_focusDetector
    elseif path:match("%.lua$") and not path:match("^/") then
        -- Try to load from current directory
        local fullPath = "./" .. path
        local file = io.open(fullPath, "r")
        if file then
            file:close()
            return original_dofile(fullPath)
        end
    end
    return original_dofile(path)
end

-- Load focus detector mock
local mock_focusDetector = {
    callbacks = {},
    started = false,
    setDebugMode = function(self, enabled)
        self.debug = enabled
    end,
    start = function(self)
        self.started = true
    end,
    stop = function(self)
        self.started = false
    end,
    addCallback = function(self, fn)
        table.insert(self.callbacks, fn)
    end,
    removeCallback = function(self, fn)
        for i, callback in ipairs(self.callbacks) do
            if callback == fn then
                table.remove(self.callbacks, i)
                break
            end
        end
    end,
    isFocusModeActive = function()
        return false
    end,
    setManualFocus = function(self, isActive)
        for _, callback in ipairs(self.callbacks) do
            callback(isActive, not isActive, "manual")
        end
    end,
    getDetectionMethods = function()
        return {
            notifications = { active = true },
            controlCenter = { active = false },
            shortcuts = { active = false }
        }
    end,
    checkAllDetectionMethods = function()
        print("Checking detection methods...")
    end
}

-- Mock focus_detector module
package.loaded["focus_detector"] = mock_focusDetector

-- Load modules
local focusIntegration = dofile("focus_integration.lua")

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

print("=== Focus Integration Standalone Test Suite ===\n")

-- Test 1: Module loading
print("Test 1: Module loading")
assert(focusIntegration ~= nil, "Focus integration module loaded")
assert(type(focusIntegration.start) == "function", "start method exists")
assert(type(focusIntegration.stop) == "function", "stop method exists")
assert(type(focusIntegration.configure) == "function", "configure method exists")

-- Test 2: Configuration
print("\nTest 2: Configuration")
local config = focusIntegration:getConfiguration()
assert(type(config) == "table", "Configuration is a table")
assertEqual(config.autoStartOnFocus, true, "Auto-start on focus enabled by default")
assertEqual(config.autoPauseOnUnfocus, true, "Auto-pause on unfocus enabled by default")
assertEqual(config.focusSessionDuration, 1500, "Default focus session is 25 minutes")

-- Test 3: Configuration changes
print("\nTest 3: Configuration changes")
focusIntegration:configure({
    autoStartOnFocus = false,
    focusSessionDuration = 1800
})
local newConfig = focusIntegration:getConfiguration()
assertEqual(newConfig.autoStartOnFocus, false, "Auto-start disabled")
assertEqual(newConfig.focusSessionDuration, 1800, "Session duration updated")

-- Test 4: Status
print("\nTest 4: Status tracking")
local status = focusIntegration:getStatus()
assert(type(status) == "table", "Status is a table")
assert(type(status.focusActive) == "boolean", "FocusActive is boolean")
assert(type(status.integrationEnabled) == "boolean", "IntegrationEnabled is boolean")

-- Test 5: Integration menu
print("\nTest 5: Integration menu")
local menu = focusIntegration.createIntegrationMenu()
assert(type(menu) == "table", "Integration menu is a table")
assert(#menu > 0, "Integration menu has items")

-- Test 6: Start/Stop integration
print("\nTest 6: Integration lifecycle")
focusIntegration:start()
status = focusIntegration:getStatus()
assertEqual(status.integrationEnabled, true, "Integration enabled after start")

focusIntegration:stop()
status = focusIntegration:getStatus()
assertEqual(status.integrationEnabled, false, "Integration disabled after stop")

-- Test 7: Manual focus trigger
print("\nTest 7: Manual focus trigger")
focusIntegration:start()
focusIntegration:manuallyTriggerFocus(true)
status = focusIntegration:getStatus()
assertEqual(status.focusActive, true, "Focus mode activated")

focusIntegration:manuallyTriggerFocus(false)
status = focusIntegration:getStatus()
assertEqual(status.focusActive, false, "Focus mode deactivated")

focusIntegration:stop()

-- Test 8: Pomodoro reference
print("\nTest 8: Pomodoro reference handling")
local mockPomodoro = {
    isRunning = function() return false end,
    startSession = function() print("Mock: Start session") end,
    stopSession = function() print("Mock: Stop session") end,
    startSessionWithDuration = function(duration, isRestore)
        print("Mock: Start session with duration " .. duration .. (isRestore and " (restore)" or ""))
    end,
    setBreak = function(isBreak)
        print("Mock: Set break to " .. tostring(isBreak))
    end,
    getStatistics = function() return { today = 2 } end
}

focusIntegration:setPomodoroReference(mockPomodoro)
focusIntegration:start()

-- Test 9: Unknown configuration option
print("\nTest 9: Error handling")
focusIntegration:configure({ invalidOption = true })
-- Should not crash

-- Test 10: State preservation
print("\nTest 10: State preservation")
-- Initialize some test state
mock_hs.settings.set("pomodoro.focusState", {
    timerRunning = true,
    isBreak = false,
    timeLeft = 1200
})

-- Clean up
focusIntegration:stop()
mock_hs.settings.data = {}

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

print("\n=== Focus Integration Standalone Test Suite Complete ===")

-- Return test results
return {
    passed = testPassed,
    failed = testFailed,
    total = testPassed + testFailed,
    results = testResults
}