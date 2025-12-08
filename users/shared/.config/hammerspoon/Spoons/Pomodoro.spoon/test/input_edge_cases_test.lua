-- test/input_edge_cases_test.lua
-- Test user input-related edge cases for Pomodoro.spoon

local pomodoro = require("init")
local testHelper = require("test_helper")

local InputEdgeCaseTests = {}

-- Test getStatistics with date edge cases
function InputEdgeCaseTests.test_statistics_date_edge_cases()
    testHelper.resetMocks()

    -- Test with empty statistics
    mockSettings["pomodoro.stats"] = {}

    local spoon = pomodoro
    spoon:start()

    local stats = spoon:getStatistics()
    assert(stats.today == 0, "Should return 0 for empty stats")
    assert(next(stats.all) == nil, "Should return empty all table")

    -- Test with malformed dates
    mockSettings["pomodoro.stats"] = {
        ["invalid-date"] = 5,
        ["2024-13-45"] = 3,  -- Invalid month and day
        [""] = 2,
        [nil] = 1
    }

    stats = spoon:getStatistics()
    assert(stats.today == 0, "Should ignore invalid dates")
    assert(type(stats.all) == "table", "Should still return table with invalid entries")

    -- Test with very old and future dates
    mockSettings["pomodoro.stats"] = {
        ["1900-01-01"] = 100,  -- Very old date
        ["2100-12-31"] = 200   -- Future date
    }

    stats = spoon:getStatistics()
    assert(type(stats.all["1900-01-01"]) == "number", "Should preserve old dates")
    assert(type(stats.all["2100-12-31"]) == "number", "Should preserve future dates")

    spoon:stop()
    print("✓ Statistics date edge cases test passed")
end

-- Test nil and invalid arguments
function InputEdgeCaseTests.test_nil_invalid_arguments()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Test bindHotkeys with various invalid inputs
    local testCases = {
        nil,
        {},
        { invalid = function() end },
        { start = "not_a_function" },
        { start = nil, stop = nil, toggle = nil }
    }

    for _, mapping in ipairs(testCases) do
        local success, err = pcall(function()
            spoon:bindHotkeys(mapping)
        end)
        -- Should not crash with any input
        assert(success == true, string.format("Should handle input: %s", tostring(mapping)))
    end

    -- Test API methods with invalid states
    spoon:stop()  -- Stop when already stopped
    spoon:startSession()  -- Start when not initialized
    assert(spoon:isRunning() == false, "Should handle calls without proper init")

    spoon:stop()
    print("✓ Nil and invalid arguments test passed")
end

-- Test hotkey binding edge cases
function InputEdgeCaseTests.test_hotkey_binding_edge_cases()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Test binding with empty mapping
    spoon:bindHotkeys({})
    -- Should not crash

    -- Test binding with partial mapping
    spoon:bindHotkeys({
        start = { { "ctrl", "cmd" }, "p" },
        -- stop and toggle missing
    })
    -- Should bind what's available

    -- Test rebinding
    spoon:bindHotkeys({
        start = { { "ctrl", "cmd" }, "p" },
        stop = { { "ctrl", "cmd" }, "s" },
        toggle = { { "ctrl", "cmd" }, "t" }
    })

    -- Then rebind with different keys
    spoon:bindHotkeys({
        start = { { "alt", "cmd" }, "p" }
    })

    spoon:stop()
    print("✓ Hotkey binding edge cases test passed")
end

-- Test session management edge cases
function InputEdgeCaseTests.test_session_management_edge_cases()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Test rapid start/stop sequence
    local rapidSequence = {
        "start", "stop", "start", "start", "stop", "stop",
        "toggle", "toggle", "toggle", "toggle"
    }

    for _, action in ipairs(rapidSequence) do
        if action == "start" then
            spoon:startSession()
        elseif action == "stop" then
            spoon:stopSession()
        elseif action == "toggle" then
            spoon:toggleSession()
        end
    end

    -- Should end in consistent state
    assert(spoon:isRunning() == false, "Should end stopped after rapid sequence")

    -- Test session during break
    spoon:startSession()
    local isRunningAfterStart = spoon:isRunning()

    -- Manually set break state to simulate transition
    -- (Note: This requires internal access which isn't available in public API)
    -- In real scenario, this would happen automatically

    spoon:stopSession()
    assert(spoon:isRunning() == false, "Should stop cleanly")

    spoon:stop()
    print("✓ Session management edge cases test passed")
end

-- Test statistics corruption scenarios
function InputEdgeCaseTests.test_statistics_corruption()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Test with corrupted statistics data
    local corruptData = {
        [os.date("%Y-%m-%d")] = "not_a_number",
        ["2024-01-01"] = function() end,
        ["2024-01-02"] = {},
        ["2024-01-03"] = nil
    }
    mockSettings["pomodoro.stats"] = corruptData

    local stats = spoon:getStatistics()
    assert(type(stats) == "table", "Should return table despite corruption")
    assert(stats.today == 0, "Should default to 0 for corrupted today's data")

    -- Test with partially corrupted data
    mockSettings["pomodoro.stats"] = {
        [os.date("%Y-%m-%d")] = 5,
        ["2024-01-01"] = "corrupted",
        ["2024-01-02"] = 3,
        invalidKey = "should_be_ignored"
    }

    stats = spoon:getStatistics()
    assert(stats.today == 5, "Should preserve valid data")
    assert(stats.all["2024-01-02"] == 3, "Should preserve other valid entries")

    spoon:stop()
    print("✓ Statistics corruption test passed")
end

-- Test concurrent user interactions
function InputEdgeCaseTests.test_concurrent_interactions()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Simulate concurrent calls from different sources
    local function simulateConcurrentCalls()
        spoon:startSession()
        spoon:toggleSession()
        spoon:stopSession()
        spoon:getStatistics()
        spoon:isRunning()
        spoon:getTimeLeft()
    end

    -- Run multiple "concurrent" operations
    for i = 1, 10 do
        simulateConcurrentCalls()
    end

    -- Should maintain consistent state
    assert(spoon:isRunning() == false, "Should maintain consistent state")

    spoon:stop()
    print("✓ Concurrent interactions test passed")
end

-- Test boundary conditions
function InputEdgeCaseTests.test_boundary_conditions()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Test with maximum session count
    local maxSessions = 999999
    mockSettings["pomodoro.stats"] = {
        [os.date("%Y-%m-%d")] = maxSessions
    }

    spoon:startSession()  -- Should increment beyond max
    assert(spoon:getSessionsCompleted() > maxSessions, "Should handle large numbers")

    -- Test with negative session counts (corruption)
    mockSettings["pomodoro.stats"] = {
        [os.date("%Y-%m-%d")] = -5
    }

    spoon = pomodoro  -- Fresh instance
    spoon:start()
    assert(spoon:getSessionsCompleted() == 0, "Should handle negative counts gracefully")

    spoon:startSession()
    assert(spoon:getSessionsCompleted() == 1, "Should start from 0 with negative base")

    spoon:stop()
    print("✓ Boundary conditions test passed")
end

-- Test method chaining edge cases
function InputEdgeCaseTests.test_method_chaining_edge_cases()
    testHelper.resetMocks()

    local spoon = pomodoro

    -- Test method chaining with invalid states
    local result = spoon:start():stop()
    assert(result == spoon, "Should return self for chaining")

    -- Test chaining after errors
    local success = pcall(function()
        spoon:bindHotkeys(nil):startSession():stopSession()
    end)
    assert(success == true, "Should handle chaining after invalid operations")

    -- Test chaining with undefined methods
    local undefinedResult = spoon.nonExistentMethod
    assert(undefinedResult == nil, "Should return nil for non-existent methods")

    print("✓ Method chaining edge cases test passed")
end

-- Test multiple instance scenarios
function InputEdgeCaseTests.test_multiple_instances()
    testHelper.resetMocks()

    -- Create multiple instances
    local spoon1 = pomodoro
    local spoon2 = require("init")

    spoon1:start()
    spoon2:start()

    -- Both should start independently
    assert(spoon1:isRunning() == false, "Instance 1 should not be running")
    assert(spoon2:isRunning() == false, "Instance 2 should not be running")

    -- Start sessions on both
    spoon1:startSession()
    assert(spoon1:isRunning() == true, "Instance 1 should be running")

    spoon2:startSession()
    assert(spoon2:isRunning() == true, "Instance 2 should be running")

    -- They should operate independently
    spoon1:stopSession()
    assert(spoon1:isRunning() == false, "Instance 1 should be stopped")
    assert(spoon2:isRunning() == true, "Instance 2 should still be running")

    spoon2:stop()

    print("✓ Multiple instances test passed")
end

return InputEdgeCaseTests