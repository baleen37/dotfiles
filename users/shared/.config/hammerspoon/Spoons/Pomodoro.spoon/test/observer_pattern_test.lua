-- test/observer_pattern_test.lua
-- Set up test environment
package.path = package.path .. ";../?.lua"
local testHelper = require("test_helper")
testHelper.resetMocks()

local StateManager = require("state_manager")

function testObserverPattern()
    -- Create a state manager instance
    local state = StateManager:new()

    -- Track notification calls
    local notifications = {}

    -- Add an observer
    local observerId = state:addObserver(function(property, value, observedState)
        table.insert(notifications, {
            property = property,
            value = value,
            timestamp = os.time()
        })
        print(string.format("Observer notified: %s changed to %s", property, tostring(value)))
    end)

    -- Test property change notifications
    print("\nTesting property change notifications:")

    -- Change running state
    state:setRunning(true)
    assert(#notifications == 1, "Should receive 1 notification")
    assert(notifications[1].property == "running", "Should notify about running property")
    assert(notifications[1].value == true, "Should notify new value")

    -- Change break state
    state:setBreak(true)
    assert(#notifications == 2, "Should receive 2 notifications total")
    assert(notifications[2].property == "isBreak", "Should notify about isBreak property")

    -- Change time left
    state:setTimeLeft(1500)
    assert(#notifications == 3, "Should receive 3 notifications total")
    assert(notifications[3].property == "timeLeft", "Should notify about timeLeft property")

    print("✓ Observer pattern basic functionality test passed")
end

function testMultipleObservers()
    -- Create a state manager instance
    local state = StateManager:new()

    -- Track notifications for each observer
    local observer1Notifications = {}
    local observer2Notifications = {}

    -- Add first observer
    state:addObserver(function(property, value, observedState)
        table.insert(observer1Notifications, { property = property, value = value })
        print("Observer 1 notified: " .. property)
    end)

    -- Add second observer
    state:addObserver(function(property, value, observedState)
        table.insert(observer2Notifications, { property = property, value = value })
        print("Observer 2 notified: " .. property)
    end)

    -- Change state
    state:setRunning(true)

    -- Both observers should be notified
    assert(#observer1Notifications == 1, "Observer 1 should receive notification")
    assert(#observer2Notifications == 1, "Observer 2 should receive notification")
    assert(observer1Notifications[1].property == "running", "Should notify about running")
    assert(observer2Notifications[1].property == "running", "Should notify about running")

    print("✓ Multiple observers test passed")
end

function testObserverWithUIManager()
    -- Test integration between StateManager observers and UIManager
    local state = StateManager:new()

    -- Create a mock UI that tracks updates
    local uiUpdates = {}
    local mockUI = {
        updateMenuBarReady = function()
            table.insert(uiUpdates, { type = "ready" })
            print("UI update: Ready state")
        end,
        updateMenuBarText = function(sessionType, timeLeft)
            table.insert(uiUpdates, { type = "text", session = sessionType, time = timeLeft })
            print(string.format("UI update: %s - %d seconds", sessionType, timeLeft))
        end
    }

    -- Add observer that updates UI
    state:addObserver(function(property, value, observedState)
        if not observedState:isRunning() then
            mockUI.updateMenuBarReady()
        else
            local sessionType = observedState:isBreak() and "Break" or "Work"
            mockUI.updateMenuBarText(sessionType, observedState:getTimeLeft())
        end
    end)

    -- Test UI updates on state changes
    state:setRunning(true)
    state:setTimeLeft(1500)  -- 25 minutes

    assert(#uiUpdates >= 1, "UI should be updated")
    print("✓ Observer with UIManager integration test passed")
end

function testObserverErrorHandling()
    -- Test that observer errors don't break state management
    local state = StateManager:new()

    -- Add a faulty observer that throws an error
    state:addObserver(function(property, value, observedState)
        error("Intentional observer error")
    end)

    -- Add a normal observer
    local normalNotifications = {}
    state:addObserver(function(property, value, observedState)
        table.insert(normalNotifications, { property = property, value = value })
    end)

    -- Change state - should not crash despite faulty observer
    local success = pcall(function()
        state:setRunning(true)
    end)

    -- Normal observer should still receive notification
    assert(#normalNotifications == 1, "Normal observer should still work")
    print("✓ Observer error handling test passed")
end

-- Run all tests
print("=== Observer Pattern Tests ===\n")

testObserverPattern()
testMultipleObservers()
testObserverWithUIManager()
testObserverErrorHandling()

print("\n=== All Observer Pattern Tests Passed! ===")