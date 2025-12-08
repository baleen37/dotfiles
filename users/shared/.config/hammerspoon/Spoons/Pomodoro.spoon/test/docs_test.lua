-- test/docs_test.lua
local docs = require("docs")

function testDocsCompleteness()
    assert(docs.name == "Pomodoro.spoon", "Should have correct name")
    assert(docs.version, "Should have version")
    assert(docs.description, "Should have description")
    assert(docs.functions, "Should document functions")
    assert(docs.functions.startSession, "Should document startSession")
    assert(docs.functions.stopSession, "Should document stopSession")
    assert(docs.functions.startSessionWithDuration, "Should document startSessionWithDuration")
    assert(docs.functions.validateSettings, "Should document validateSettings")
    assert(docs.functions.getStatistics, "Should document getStatistics")
    print("✓ Docs completeness test passed")
end

function testNewFunctionsDocumented()
    -- Check that new functions are documented
    assert(docs.functions.startSessionWithDuration, "Should document startSessionWithDuration")
    assert(docs.functions.startSessionWithDuration.description, "Should have description")
    assert(docs.functions.startSessionWithDuration.returns, "Should document return value")
    assert(docs.functions.startSessionWithDuration.parameters, "Should document parameters")

    assert(docs.functions.validateSettings, "Should document validateSettings")
    assert(docs.functions.validateSettings.description, "Should have description")
    assert(docs.functions.validateSettings.returns, "Should document return value")

    print("✓ New functions documented test passed")
end

function testErrorHandlingDocumented()
    -- Check that error handling is documented
    local startSessionFn = docs.functions.startSessionWithDuration
    assert(startSessionFn.errors, "Should document possible errors")

    print("✓ Error handling documented test passed")
end

-- Run tests
testDocsCompleteness()
testNewFunctionsDocumented()
testErrorHandlingDocumented()
print("All docs tests passed!")