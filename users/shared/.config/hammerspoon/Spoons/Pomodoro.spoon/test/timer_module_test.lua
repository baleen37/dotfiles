-- test/timer_module_test.lua
-- Set up test environment
package.path = package.path .. ";../?.lua"
local testHelper = require("test_helper")
testHelper.resetMocks()

local Timer = require("timer")

function testTimerCreation()
    -- Test successful timer creation
    local timerResult = Timer.createTimer(60,
        function(timeLeft) print("Tick: " .. timeLeft) end,
        function() print("Timer completed!") end
    )

    assert(timerResult.success == true, "Timer should be created successfully")
    assert(timerResult.timer ~= nil, "Timer object should be returned")

    print("✓ Timer creation test passed")
end

function testTimerValidation()
    -- Test invalid duration
    local result1 = Timer.createTimer(-1,
        function() end,
        function() end
    )
    assert(result1.success == false, "Should reject negative duration")
    assert(result1.error:match("Invalid duration"), "Error should mention invalid duration")

    -- Test non-number duration
    local result2 = Timer.createTimer("invalid",
        function() end,
        function() end
    )
    assert(result2.success == false, "Should reject string duration")

    -- Test zero duration
    local result3 = Timer.createTimer(0,
        function() end,
        function() end
    )
    assert(result3.success == false, "Should reject zero duration")

    -- Test nil duration
    local result4 = Timer.createTimer(nil,
        function() end,
        function() end
    )
    assert(result4.success == false, "Should reject nil duration")

    -- Test invalid onTick callback
    local result5 = Timer.createTimer(60, nil, function() end)
    assert(result5.success == false, "Should reject nil onTick callback")

    -- Test invalid onComplete callback
    local result6 = Timer.createTimer(60, function() end, nil)
    assert(result6.success == false, "Should reject nil onComplete callback")

    print("✓ Timer validation test passed")
end

function testTimerOperations()
    -- Test basic timer operations
    local tickCount = 0
    local completed = false

    local timerResult = Timer.createTimer(3,
        function(timeLeft)
            tickCount = tickCount + 1
            print("Timer tick, time left: " .. timeLeft)
        end,
        function()
            completed = true
            print("Timer completed!")
        end
    )

    assert(timerResult.success == true, "Timer should be created")

    local timer = timerResult.timer

    -- Test start
    timer.start()

    -- Test running check
    local isRunning = timer.running()
    print("Timer running state: " .. tostring(isRunning))

    -- Test stop
    timer.stop()

    -- Test running after stop
    isRunning = timer.running()
    assert(isRunning == false, "Timer should not be running after stop")

    print("✓ Timer operations test passed")
end

function testTimerWithErrorHandling()
    -- Test timer creation with error in callback
    local timerResult = Timer.createTimer(5,
        function(timeLeft)
            error("Test error in tick callback")
        end,
        function()
            print("Complete callback called")
        end
    )

    -- The timer should still be created successfully
    -- Error handling should be done by the caller of the timer
    assert(timerResult.success == true, "Timer should be created even with error in callback")

    print("✓ Timer error handling test passed")
end

-- Run all tests
print("=== Timer Module Tests ===\n")

testTimerCreation()
testTimerValidation()
testTimerOperations()
testTimerWithErrorHandling()

print("\n=== All Timer Module Tests Passed! ===")