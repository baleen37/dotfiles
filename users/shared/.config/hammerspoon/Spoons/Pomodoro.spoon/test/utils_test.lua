-- test/utils_test.lua
local utils = require("utils")

function testErrorHandler()
    local result = utils.safeCall(function() error("Test error") end)
    assert(result.success == false, "Should catch error")
    assert(result.error:match("Test error"), "Should preserve error message")
    print("✓ Error handler test passed")
end

function testValidSettings()
    local isValid, message = utils.validateSettings({
        workDuration = 25 * 60,
        breakDuration = 5 * 60
    })
    assert(isValid == true, "Should accept valid settings")
    assert(message == "Settings valid", "Should return valid message")
    print("✓ Valid settings test passed")
end

function testInvalidWorkDuration()
    local isValid, message = utils.validateSettings({
        workDuration = -100,
        breakDuration = 5 * 60
    })
    assert(isValid == false, "Should reject negative work duration")
    assert(message:match("workDuration must be a positive number"), "Should return error message")
    print("✓ Invalid work duration test passed")
end

function testInvalidBreakDuration()
    local isValid, message = utils.validateSettings({
        workDuration = 25 * 60,
        breakDuration = 0
    })
    assert(isValid == false, "Should reject zero break duration")
    assert(message:match("breakDuration must be a positive number"), "Should return error message")
    print("✓ Invalid break duration test passed")
end

function testNonTableSettings()
    local isValid, message = utils.validateSettings("not a table")
    assert(isValid == false, "Should reject non-table settings")
    assert(message:match("Settings must be a table"), "Should return error message")
    print("✓ Non-table settings test passed")
end

-- Run tests
testErrorHandler()
testValidSettings()
testInvalidWorkDuration()
testInvalidBreakDuration()
testNonTableSettings()
print("All utils tests passed!")