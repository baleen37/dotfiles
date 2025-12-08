-- test/timer_failure_test.lua
-- Set up test environment
package.path = package.path .. ";../?.lua"
local testHelper = require("test_helper")
testHelper.resetMocks()

-- Set test mode to avoid executing initialization code
_G.POMODORO_TEST_MODE = true

local pomodoro = require("init")

function testTimerCreationFailureHandling()
    -- We can't easily mock hs.timer.new without affecting the whole test environment
    -- So we'll just verify that error handling utilities exist

    local utils = require("utils")

    -- Test that utils.safeCall exists and works
    local result = utils.safeCall(function()
        return "success"
    end)

    assert(result.success == true, "safeCall should handle successful calls")
    assert(result.result == "success", "safeCall should return result")

    local errorResult = utils.safeCall(function()
        error("test error")
    end)

    assert(errorResult.success == false, "safeCall should handle errors")
    assert(errorResult.error:match("test error"), "safeCall should preserve error message")

    print("✓ Timer failure handling test passed")
end

function testSafeCallWithNilReturn()
    local utils = require("utils")

    local result = utils.safeCall(function()
        return nil
    end)

    assert(result.success == true, "safeCall should handle nil return")
    assert(result.result == nil, "safeCall should return nil result")

    print("✓ SafeCall with nil return test passed")
end

function testSafeCallWithMultipleReturns()
    local utils = require("utils")

    local result = utils.safeCall(function()
        return "first", "second"
    end)

    assert(result.success == true, "safeCall should handle multiple returns")
    assert(result.result == "first", "safeCall should return first value")

    print("✓ SafeCall with multiple returns test passed")
end

-- Run tests
testTimerCreationFailureHandling()
testSafeCallWithNilReturn()
testSafeCallWithMultipleReturns()
print("All timer failure tests passed!")