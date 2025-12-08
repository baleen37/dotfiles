-- test/init.lua
local obj = {}
obj.__index = obj

-- Test framework setup
function obj.testFrameworkSetup()
    -- Test that we can load the spoon
    local pomodoro = hs.loadSpoon("Pomodoro")
    assert(pomodoro, "Pomodoro spoon should load successfully")
    print("✓ Spoon loads successfully")
end

return obj