-- test/init_refactor_test.lua
-- Set test mode to avoid executing initialization code
_G.POMODORO_TEST_MODE = true

-- Load the refactored init
local pomodoro = require("init")

function testRefactoredInit()
    -- Test that state manager exists
    assert(pomodoro.state, "Should have state manager")

    -- Test initial state
    assert(pomodoro.state:isRunning() == false, "Initial state should not be running")
    assert(pomodoro.state:getTimeLeft() == 0, "Initial time left should be 0")
    assert(pomodoro.state:getSessionsCompleted() == 0, "Initial sessions should be 0")

    print("✓ Refactored init test passed")
end

function testManualControlMethods()
    -- Test that methods exist
    assert(type(pomodoro.startSession) == "function", "Should have startSession method")
    assert(type(pomodoro.stopSession) == "function", "Should have stopSession method")
    assert(type(pomodoro.toggleSession) == "function", "Should have toggleSession method")

    print("✓ Manual control methods test passed")
end

-- Run tests
testRefactoredInit()
testManualControlMethods()
print("All refactored init tests passed!")