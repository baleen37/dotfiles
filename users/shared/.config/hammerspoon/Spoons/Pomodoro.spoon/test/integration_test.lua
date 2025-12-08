-- test/integration_test.lua
-- Set up test environment first
package.path = package.path .. ";../?.lua"

-- Load test helper BEFORE any other modules
dofile("test_helper.lua")
testHelper.resetMocks()

-- Now load the pomodoro module
local pomodoro = require("init")

-- Initialize state if needed
if not pomodoro.state then
    local StateManager = require("state_manager")
    pomodoro.state = StateManager:new()
end

if not pomodoro.ui then
    local UIManager = require("ui_manager")
    pomodoro.ui = UIManager:new()
end

function testFullSession()
    -- Setup
    pomodoro.state:reset()

    -- Test initial state
    assert(pomodoro.state:isRunning() == false, "Initial state should not be running")
    assert(pomodoro.state:getTimeLeft() == 0, "Initial time left should be 0")

    -- Start session with custom duration to avoid waiting
    local startResult = pomodoro:startSessionWithDuration(2)  -- 2 seconds
    assert(startResult == true, "Should start session successfully")

    -- Verify state
    assert(pomodoro.state:isRunning(), "State should show running")
    assert(pomodoro.state:getTimeLeft() > 0, "Should have time left")
    assert(pomodoro.state:isBreak() == false, "Should be work session")

    -- Test duplicate start
    local duplicateStart = pomodoro:startSessionWithDuration(5)
    assert(duplicateStart == false, "Should reject duplicate start")

    -- Stop session
    local stopResult = pomodoro:stopSession()
    assert(stopResult, "Should stop session")

    -- Verify final state
    assert(not pomodoro.state:isRunning(), "State should show not running")

    print("✓ Full session test passed")
end

function testErrorHandling()
    -- Test invalid duration
    local result = pomodoro:startSessionWithDuration(-1)
    assert(result == false, "Should reject negative duration")

    result = pomodoro:startSessionWithDuration(0)
    assert(result == false, "Should reject zero duration")

    result = pomodoro:startSessionWithDuration("invalid")
    assert(result == false, "Should reject string duration")

    result = pomodoro:startSessionWithDuration(nil)
    assert(result == false, "Should reject nil duration")

    print("✓ Error handling test passed")
end

function testValidateSettings()
    -- Test settings validation
    local isValid = pomodoro:validateSettings()
    assert(isValid == true, "Should validate default settings")

    print("✓ Settings validation test passed")
end

function testStatistics()
    -- Test statistics
    local stats = pomodoro:getStatistics()
    assert(type(stats) == "table", "Should return table")
    assert(type(stats.today) == "number", "Should have today count")
    assert(type(stats.all) == "table", "Should have all stats")

    print("✓ Statistics test passed")
end

function testToggleSession()
    -- Reset first
    pomodoro:stopSession()

    -- Toggle to start
    pomodoro:toggleSession()
    assert(pomodoro.state:isRunning(), "Should start session on toggle")

    -- Toggle to stop
    pomodoro:toggleSession()
    assert(not pomodoro.state:isRunning(), "Should stop session on toggle")

    print("✓ Toggle session test passed")
end

function testManagers()
    -- Test that managers exist
    assert(pomodoro.state ~= nil, "Should have state manager")
    assert(pomodoro.ui ~= nil, "Should have UI manager")

    -- Test state manager methods
    assert(type(pomodoro.state.isRunning) == "function", "Should have isRunning method")
    assert(type(pomodoro.state.isBreak) == "function", "Should have isBreak method")
    assert(type(pomodoro.state.getTimeLeft) == "function", "Should have getTimeLeft method")

    -- Test UI manager methods
    assert(type(pomodoro.ui.updateMenuBarText) == "function", "Should have updateMenuBarText method")
    assert(type(pomodoro.ui.updateMenu) == "function", "Should have updateMenu method")

    print("✓ Managers test passed")
end

function testAPICompatibility()
    -- Test that all expected methods exist
    local expectedMethods = {
        "start",
        "stop",
        "bindHotkeys",
        "getStatistics",
        "startSession",
        "stopSession",
        "toggleSession",
        "startSessionWithDuration",
        "validateSettings"
    }

    for _, method in ipairs(expectedMethods) do
        assert(type(pomodoro[method]) == "function", "Should have method: " .. method)
    end

    print("✓ API compatibility test passed")
end

function testStatePersistence()
    -- Test that state persists correctly
    pomodoro.state:reset()

    -- Set some state
    pomodoro.state:setSessionsCompleted(5)
    assert(pomodoro.state:getSessionsCompleted() == 5, "Should persist session count")

    -- Reset should clear timer state but not necessarily session count
    pomodoro.state:reset()
    assert(not pomodoro.state:isRunning(), "Reset should clear running state")
    assert(pomodoro.state:getTimeLeft() == 0, "Reset should clear time left")

    print("✓ State persistence test passed")
end

-- Run all tests
testFullSession()
testErrorHandling()
testValidateSettings()
testStatistics()
testToggleSession()
testManagers()
testAPICompatibility()
testStatePersistence()

print("\n🎉 All integration tests passed!")
print("✅ Pomodoro.spoon is working correctly with:")
print("   - Encapsulated state management")
print("   - Robust error handling")
print("   - UI management")
print("   - Input validation")
print("   - Full API compatibility")