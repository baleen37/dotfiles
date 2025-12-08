-- test/timer_validation_test.lua
-- Set test mode to avoid executing initialization code
_G.POMODORO_TEST_MODE = true

local pomodoro = require("init")

function testInvalidWorkDuration()
    -- This will fail until we implement startSessionWithDuration
    -- For now, just test that validateSettings works
    local utils = require("utils")

    local isValid, message = utils.validateSettings({
        workDuration = -5,
        breakDuration = 5 * 60
    })

    assert(isValid == false, "Should reject negative work duration")
    assert(message:match("workDuration must be a positive number"), "Should return error message")
    print("✓ Invalid work duration test passed")
end

function testZeroDuration()
    local utils = require("utils")

    local isValid, message = utils.validateSettings({
        workDuration = 0,
        breakDuration = 5 * 60
    })

    assert(isValid == false, "Should reject zero duration")
    assert(message:match("workDuration must be a positive number"), "Should return error message")
    print("✓ Zero duration test passed")
end

function testValidSettings()
    local utils = require("utils")

    local isValid, message = utils.validateSettings({
        workDuration = 25 * 60,
        breakDuration = 5 * 60
    })

    assert(isValid == true, "Should accept valid settings")
    assert(message == "Settings valid", "Should return success message")
    print("✓ Valid settings test passed")
end

function testStringDuration()
    local utils = require("utils")

    local isValid, message = utils.validateSettings({
        workDuration = "25 minutes",
        breakDuration = 5 * 60
    })

    assert(isValid == false, "Should reject string duration")
    assert(message:match("workDuration must be a positive number"), "Should return error message")
    print("✓ String duration test passed")
end

-- Run tests
testInvalidWorkDuration()
testZeroDuration()
testValidSettings()
testStringDuration()
print("All timer validation tests passed!")