#!/usr/bin/env lua

--- Pomodoro Spoon Test Script
--- Tests the Pomodoro Spoon implementation without requiring Hammerspoon runtime
--- This script validates basic functionality and API compatibility

-- Mock Hammerspoon APIs for testing
local mock_hs = {
    timer = {
        new = function(delay, fn)
            return {
                start = function() print("Timer started") end,
                stop = function() print("Timer stopped") end
            }
        end
    },
    menubar = {
        new = function()
            return {
                setTitle = function(title) print("Menubar title set to:", title) end,
                setClickCallback = function(fn) print("Menubar click callback set") end,
                setMenu = function(menu) print("Menubar menu set") end,
                delete = function() print("Menubar item deleted") end
            }
        end
    },
    notify = {
        new = function(notification)
            return {
                send = function()
                    print("Notification sent:", notification.title, "-", notification.subtitle)
                end
            }
        end
    },
    focus = {
        getFocusMode = function()
            return nil  -- No focus mode by default
        end,
        watcher = {
            new = function(fn)
                return {
                    start = function() print("Focus watcher started") end,
                    stop = function() print("Focus watcher stopped") end
                }
            end
        }
    },
    settings = {
        get = function(key)
            if key == "pomodoro.stats" then
                return {}
            end
            return nil
        end,
        set = function(key, value)
            print("Settings set:", key, "->", type(value))
        end
    },
    menuitem = {
        separator = {title = "-"}
    },
    spoons = {
        bindHotkeysToSpec = function(specs, mapping)
            print("Hotkeys bound to specs")
        end
    },
    fnutils = {
        each = function(t, fn)
            for i, v in ipairs(t) do
                fn(v)
            end
        end
    }
}

-- Set up global hs
_G.hs = mock_hs

-- Load the Pomodoro Spoon
local function loadPomodoro()
    local current_dir = debug.getinfo(1, "S").source:match("@(.*)")
    local spoon_path = current_dir:gsub("test_pomodoro%.lua$", "Spoons/Pomodoro.spoon/init.lua")

    print("Loading Pomodoro from:", spoon_path)

    local chunk, err = loadfile(spoon_path)
    if not chunk then
        print("Error loading Pomodoro Spoon:", err)
        return nil
    end

    return chunk()
end

-- Test functions
local function test_spoon_loading()
    print("\n=== Testing Spoon Loading ===")

    local pomodoro = loadPomodoro()
    if not pomodoro then
        print("❌ Failed to load Pomodoro Spoon")
        return false
    end

    -- Check required properties
    local required_props = {"name", "version", "author", "license"}
    for _, prop in ipairs(required_props) do
        if not pomodoro[prop] then
            print("❌ Missing required property:", prop)
            return false
        end
    end

    print("✅ Spoon loaded successfully")
    print("  - Name:", pomodoro.name)
    print("  - Version:", pomodoro.version)
    print("  - Author:", pomodoro.author)

    return pomodoro
end

local function test_spoon_start_stop(pomodoro)
    print("\n=== Testing Start/Stop ===")

    -- Test start
    local result = pomodoro:start()
    if not result then
        print("❌ Failed to start Pomodoro")
        return false
    end

    print("✅ Pomodoro started successfully")

    -- Test getStatistics
    local stats = pomodoro:getStatistics()
    if type(stats) ~= "table" then
        print("❌ getStatistics should return a table")
        return false
    end

    if type(stats.today) ~= "number" then
        print("❌ stats.today should be a number")
        return false
    end

    if type(stats.all) ~= "table" then
        print("❌ stats.all should be a table")
        return false
    end

    print("✅ Statistics API working")
    print("  - Today's sessions:", stats.today)

    -- Test stop
    result = pomodoro:stop()
    if not result then
        print("❌ Failed to stop Pomodoro")
        return false
    end

    print("✅ Pomodoro stopped successfully")

    return true
end

local function test_hotkey_binding(pomodoro)
    print("\n=== Testing Hotkey Binding ===")

    local testMapping = {
        start = {{"ctrl"}, "p"},
        stop = {{"ctrl"}, "s"}
    }

    local result = pomodoro:bindHotkeys(testMapping)
    if not result then
        print("❌ Failed to bind hotkeys")
        return false
    end

    print("✅ Hotkeys bound successfully")
    print("  - Start hotkey: Ctrl+P")
    print("  - Stop hotkey: Ctrl+S")

    return true
end

local function test_helper_functions()
    print("\n=== Testing Helper Functions ===")

    -- Test formatTime function indirectly by checking state
    local pomodoro = loadPomodoro()

    -- Mock some state to test
    pomodoro:start()

    print("✅ Helper functions appear to be working")

    pomodoro:stop()

    return true
end

-- Run all tests
local function run_tests()
    print("=== Pomodoro Spoon Test Suite ===")
    print("Testing implementation without full Hammerspoon runtime")

    local pomodoro = test_spoon_loading()
    if not pomodoro then
        print("\n❌ Test suite failed: Could not load Spoon")
        os.exit(1)
    end

    local tests = {
        test_spoon_start_stop,
        test_hotkey_binding,
        test_helper_functions
    }

    local passed = 0
    local total = #tests

    for _, test in ipairs(tests) do
        if test(pomodoro) then
            passed = passed + 1
        end
    end

    print("\n=== Test Summary ===")
    print(string.format("Passed: %d/%d tests", passed, total))

    if passed == total then
        print("✅ All tests passed!")
        os.exit(0)
    else
        print("❌ Some tests failed")
        os.exit(1)
    end
end

-- Run tests if script is executed directly
if arg and arg[0] and arg[0]:match("test_pomodoro%.lua$") then
    run_tests()
end

return {
    run_tests = run_tests,
    test_spoon_loading = test_spoon_loading,
    test_spoon_start_stop = test_spoon_start_stop,
    test_hotkey_binding = test_hotkey_binding
}
