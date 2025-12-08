-- test/state_manager_test.lua
-- Set up test environment
package.path = package.path .. ";../?.lua"
local testHelper = require("test_helper")
testHelper.resetMocks()

local StateManager = require("state_manager")

function testStateManagerCreation()
    local state = StateManager:new()
    assert(state:isRunning() == false, "Initial state should not be running")
    assert(state:isBreak() == false, "Initial state should not be break")
    assert(state:getTimeLeft() == 0, "Initial time left should be 0")
    assert(state:getSessionsCompleted() == 0, "Initial sessions should be 0")
    print("✓ StateManager creation test passed")
end

function testStateManagerSetters()
    local state = StateManager:new()

    state:setRunning(true)
    assert(state:isRunning() == true, "Should update running state")

    state:setBreak(true)
    assert(state:isBreak() == true, "Should update break state")

    state:setTimeLeft(1500)
    assert(state:getTimeLeft() == 1500, "Should update time left")

    print("✓ StateManager setters test passed")
end

function testStateManagerReset()
    local state = StateManager:new()

    -- Set some state
    state:setRunning(true)
    state:setBreak(true)
    state:setTimeLeft(100)

    -- Reset
    state:reset()

    assert(state:isRunning() == false, "Should reset running state")
    assert(state:isBreak() == false, "Should reset break state")
    assert(state:getTimeLeft() == 0, "Should reset time left")
    assert(state:getTimer() == nil, "Should clear timer")

    print("✓ StateManager reset test passed")
end

function testStateManagerSaveSession()
    local state = StateManager:new()

    -- Manually increment session count to test save functionality
    state.sessionsCompleted = 5
    state:saveSession()

    -- Check that the value was saved to mock settings
    local today = os.date("%Y-%m-%d")
    local stats = mockSettings["pomodoro.stats"]
    assert(stats, "Stats should be saved")
    assert(stats[today] == 5, "Should save correct session count")

    print("✓ StateManager save session test passed")
end

-- Run tests
testStateManagerCreation()
testStateManagerSetters()
testStateManagerReset()
testStateManagerSaveSession()
print("All StateManager tests passed!")