-- test/edge_cases_test.lua
-- Test edge cases and error scenarios for Pomodoro.spoon

local pomodoro = require("init")
local testHelper = require("test_helper")

local EdgeCaseTests = {}

-- Timer-related edge cases
function EdgeCaseTests.test_duplicate_start_session()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Start first session
    spoon:startSession()

    -- Check if timer is running
    assert(spoon:isRunning() == true, "Timer should be running after startSession")
    local initialTimer = spoon:getTimeLeft()

    -- Try to start another session without stopping
    spoon:startSession()

    -- Should still be running with same timer (no duplicate)
    assert(spoon:isRunning() == true, "Timer should still be running")
    assert(spoon:getTimeLeft() == initialTimer, "Timer should not be reset when start is called during running")

    spoon:stop()
    print("✓ Duplicate start session test passed")
end

function EdgeCaseTests.test_rapid_toggle()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Rapidly toggle multiple times
    spoon:toggleSession()
    assert(spoon:isRunning() == true, "Should be running after first toggle")

    spoon:toggleSession()
    assert(spoon:isRunning() == false, "Should be stopped after second toggle")

    spoon:toggleSession()
    assert(spoon:isRunning() == true, "Should be running again after third toggle")

    spoon:stop()
    print("✓ Rapid toggle test passed")
end

function EdgeCaseTests.test_stop_without_running()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Try to stop when not running
    spoon:stopSession()
    assert(spoon:isRunning() == false, "Should not be running")
    assert(spoon:getTimeLeft() == 0, "Time left should be 0")

    -- Multiple stops should not cause errors
    spoon:stopSession()
    spoon:stopSession()

    spoon:stop()
    print("✓ Stop without running test passed")
end

function EdgeCaseTests.test_stop_during_timer_callback()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Start a session
    spoon:startSession()
    assert(spoon:isRunning() == true, "Should be running")

    -- Simulate stopping during timer execution
    -- This tests race condition where timer callback might fire during stop
    spoon:stopSession()

    -- Verify clean state
    assert(spoon:isRunning() == false, "Should not be running")
    assert(spoon:getTimeLeft() == 0, "Time left should be reset")
    assert(spoon:isBreak() == false, "Should not be in break state")

    spoon:stop()
    print("✓ Stop during timer callback test passed")
end

-- System-related edge cases
function EdgeCaseTests.test_settings_corruption()
    testHelper.resetMocks()

    -- Simulate corrupted settings
    testHelper.setMockSetting("pomodoro.stats", "invalid_string_data")

    local spoon = pomodoro
    spoon:start()

    -- Should handle corrupted data gracefully
    local stats = spoon:getStatistics()
    assert(type(stats) == "table", "Should return table even with corrupted settings")
    assert(stats.today == 0, "Should default to 0 sessions today")
    assert(type(stats.all) == "table", "Should return all stats as table")

    spoon:stop()
    print("✓ Settings corruption test passed")
end

function EdgeCaseTests.test_nil_settings()
    testHelper.resetMocks()

    -- Ensure settings are nil
    mockSettings["pomodoro.stats"] = nil

    local spoon = pomodoro
    spoon:start()

    -- Should handle nil settings
    local stats = spoon:getStatistics()
    assert(stats.today == 0, "Should default to 0 sessions with nil settings")
    assert(type(stats.all) == "table", "Should return empty table for all stats")

    spoon:stop()
    print("✓ Nil settings test passed")
end

-- User input edge cases
function EdgeCaseTests.test_invalid_statistics_request()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Mock os.date to return different date
    local originalDate = os.date
    os.date = function(format)
        if format == "%Y-%m-%d" then
            return "2024-01-01"
        end
        return originalDate(format)
    end

    -- Set some stats for today
    testHelper.setMockSetting("pomodoro.stats", {
        ["2024-01-01"] = 5,
        ["2024-01-02"] = 3
    })

    local stats = spoon:getStatistics()

    -- Should correctly handle date changes
    assert(stats.today == 5, "Should get correct stats for mocked date")
    assert(stats.all["2024-01-01"] == 5, "Should preserve all stats")

    -- Restore original os.date
    os.date = originalDate

    spoon:stop()
    print("✓ Invalid statistics request test passed")
end

function EdgeCaseTests.test_nil_arguments()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Test various nil argument scenarios
    local success1 = pcall(function()
        spoon:bindHotkeys(nil)
    end)
    assert(success1 == true, "Should handle nil hotkeys mapping")

    -- These should not crash
    spoon:startSession()
    spoon:stopSession()
    spoon:toggleSession()

    spoon:stop()
    print("✓ Nil arguments test passed")
end

-- Memory management edge cases
function EdgeCaseTests.test_multiple_start_stop_cycles()
    testHelper.resetMocks()

    local spoon = pomodoro

    -- Multiple start/stop cycles
    for i = 1, 10 do
        spoon:start()
        spoon:startSession()
        spoon:stopSession()
        spoon:stop()
    end

    -- Should not have memory leaks
    assert(spoon:isRunning() == false, "Should not be running after cycles")
    assert(spoon:getTimeLeft() == 0, "Time left should be reset")

    print("✓ Multiple start/stop cycles test passed")
end

function EdgeCaseTests.test_cleanup_on_stop()
    testHelper.resetMocks()

    local spoon = pomodoro
    spoon:start()

    -- Start a session
    spoon:startSession()
    assert(spoon:isRunning() == true, "Should be running")

    -- Stop and verify cleanup
    spoon:stop()

    -- All state should be reset
    assert(spoon:isRunning() == false, "Should not be running")
    assert(spoon:isBreak() == false, "Should not be in break")
    assert(spoon:getTimeLeft() == 0, "Time left should be 0")

    print("✓ Cleanup on stop test passed")
end

-- Performance edge cases
function EdgeCaseTests.test_large_statistics_data()
    testHelper.resetMocks()

    -- Create large statistics dataset
    local largeStats = {}
    for i = 1, 365 do
        local date = string.format("2024-%02d-%02d",
            math.floor((i - 1) / 31) + 1,
            ((i - 1) % 31) + 1)
        largeStats[date] = math.random(1, 10)
    end

    testHelper.setMockSetting("pomodoro.stats", largeStats)

    local spoon = pomodoro
    spoon:start()

    -- Should handle large dataset efficiently
    local startTime = os.clock()
    local stats = spoon:getStatistics()
    local endTime = os.clock()

    assert(type(stats) == "table", "Should return table")
    assert(next(stats.all) ~= nil, "Should have data")

    -- Should complete quickly (less than 0.1 seconds)
    assert((endTime - startTime) < 0.1, "Should handle large stats efficiently")

    spoon:stop()
    print("✓ Large statistics data test passed")
end

return EdgeCaseTests