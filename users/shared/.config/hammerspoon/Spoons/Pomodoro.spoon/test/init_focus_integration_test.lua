--- === Init Focus Integration Test ===
---
--- Tests for the Focus Mode integration in init.lua
---

local obj = {}

-- Test configuration
local testResult = {
  passed = 0,
  failed = 0,
  errors = {}
}

-- Helper functions
local function assert(condition, message)
  if condition then
    testResult.passed = testResult.passed + 1
    print(string.format("✓ PASS: %s", message))
  else
    testResult.failed = testResult.failed + 1
    local errorMsg = string.format("✗ FAIL: %s", message)
    print(errorMsg)
    table.insert(testResult.errors, errorMsg)
  end
end

-- Mock Focus Integration for testing
local function createMockFocusIntegration()
  local mock = {}

  -- State variables (use different names to avoid conflicts)
  mock.state = {
    isPomodoroFocusActive = false,
    callbacks = {},
    initCalled = false,
    cleanupCalled = false,
    enableCalled = false,
    disableCalled = false
  }

  -- Methods
  mock.init = function(pomodoroSpoon)
    mock.state.initCalled = true
    assert(pomodoroSpoon ~= nil, "init should receive pomodoroSpoon reference")
    return mock
  end

  mock.cleanup = function()
    mock.state.cleanupCalled = true
    mock.state.callbacks = {}
    mock.state.isPomodoroFocusActive = false
    return mock
  end

  mock.enablePomodoroFocus = function()
    mock.state.enableCalled = true
    mock.state.isPomodoroFocusActive = true
    -- Trigger callbacks
    for _, callback in ipairs(mock.state.callbacks) do
      pcall(callback, true)
    end
    return true
  end

  mock.disablePomodoroFocus = function()
    mock.state.disableCalled = true
    mock.state.isPomodoroFocusActive = false
    -- Trigger callbacks
    for _, callback in ipairs(mock.state.callbacks) do
      pcall(callback, false)
    end
    return true
  end

  mock.togglePomodoroFocus = function()
    mock.state.isPomodoroFocusActive = not mock.state.isPomodoroFocusActive
    return true
  end

  mock.isPomodoroFocusActive = function()
    return mock.state.isPomodoroFocusActive
  end

  mock.onFocusModeChanged = function(callback)
    if type(callback) == "function" then
      table.insert(mock.state.callbacks, callback)
      return true
    end
    return false
  end

  mock.removeFocusModeCallback = function(callback)
    for i, cb in ipairs(mock.state.callbacks) do
      if cb == callback then
        table.remove(mock.state.callbacks, i)
        return true
      end
    end
    return false
  end

  mock.getDebugInfo = function()
    return {
      isActive = mock.state.isPomodoroFocusActive,
      callbackCount = #mock.state.callbacks,
      initCalled = mock.state.initCalled,
      cleanupCalled = mock.state.cleanupCalled
    }
  end

  return mock
end

-- Mock hs module
local mock_hs = {
  menubar = {
    new = function()
      return {
        setTitle = function() end,
        setMenu = function() end,
        setClickCallback = function() end,
        delete = function() end
      }
    end
  },
  timer = {
    doEvery = function(interval, fn)
      return {
        stop = function() end
      }
    end
  },
  notify = {
    new = function(config)
      return {
        send = function() end
      }
    end
  },
  settings = {
    get = function(key)
      if key == "pomodoro.stats" then
        return {}
      end
      return nil
    end,
    set = function(key, value) end
  },
  spoons = {
    scriptPath = function()
      return "/Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon"
    end
  },
  -- Add require to hs namespace to avoid module loading issues
  require = function(module)
    if module == "hs.spoons" then
      return mock_hs.spoons
    end
    return _G.require(module)
  end
}

-- Replace global hs with mock
_G.hs = mock_hs

-- Test functions
local function testInitializationAndCleanup()
  print("\n=== Testing Initialization and Cleanup ===")

  -- Load Pomodoro spoon with mocked focus integration
  local mockFocus = createMockFocusIntegration()

  -- Mock dofile to return our mock
  local originalDofile = dofile
  _G.dofile = function(path)
    if path:match("focus_integration") then
      return mockFocus
    end
    return originalDofile(path)
  end

  -- Load the pomodoro spoon
  local Pomodoro = dofile("/Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua")
  local pomodoro = Pomodoro:new()

  -- Test initialization
  pomodoro:start()
  assert(mockFocus.state.initCalled == true, "Focus integration should be initialized when spoon starts")

  -- Test cleanup
  pomodoro:stop()
  assert(mockFocus.state.cleanupCalled == true, "Focus integration should be cleaned up when spoon stops")

  -- Restore original dofile
  _G.dofile = originalDofile
end

local function testSessionFocusSync()
  print("\n=== Testing Session-Focus Synchronization ===")

  -- Create fresh mock
  local mockFocus = createMockFocusIntegration()

  -- Mock dofile
  local originalDofile = dofile
  _G.dofile = function(path)
    if path:match("focus_integration") then
      return mockFocus
    end
    return originalDofile(path)
  end

  -- Load pomodoro
  local Pomodoro = dofile("/Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua")
  local pomodoro = Pomodoro:new()
  pomodoro:start()

  -- Test starting session enables focus
  pomodoro:startSession()
  assert(mockFocus.state.enableCalled == true, "enablePomodoroFocus should be called when starting session")
  assert(pomodoro:isFocusModeActive() == true, "Focus mode should be active after starting session")

  -- Test stopping session disables focus
  mockFocus.state.enableCalled = false  -- Reset flag
  pomodoro:stopSession()
  assert(mockFocus.state.disableCalled == true, "disablePomodoroFocus should be called when stopping session")
  assert(pomodoro:isFocusModeActive() == false, "Focus mode should be inactive after stopping session")

  -- Clean up
  pomodoro:stop()
  _G.dofile = originalDofile
end

local function testFocusModeAPI()
  print("\n=== Testing Focus Mode API ===")

  -- Create fresh mock
  local mockFocus = createMockFocusIntegration()

  -- Mock dofile
  local originalDofile = dofile
  _G.dofile = function(path)
    if path:match("focus_integration") then
      return mockFocus
    end
    return originalDofile(path)
  end

  -- Load pomodoro
  local Pomodoro = dofile("/Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua")
  local pomodoro = Pomodoro:new()
  pomodoro:start()

  -- Test callback registration
  local callbackCalled = false
  local testCallback = function(isActive)
    callbackCalled = true
  end

  local result = pomodoro:onFocusModeChanged(testCallback)
  assert(result == true, "Should successfully register focus mode callback")
  assert(#mockFocus.state.callbacks == 1, "Should have one callback registered")

  -- Test callback removal
  result = pomodoro:removeFocusModeCallback(testCallback)
  assert(result == true, "Should successfully remove focus mode callback")
  assert(#mockFocus.state.callbacks == 0, "Should have no callbacks after removal")

  -- Test manual focus control
  result = pomodoro:enableFocusMode()
  assert(result == true, "Should successfully enable focus mode")
  assert(pomodoro:isFocusModeActive() == true, "Focus mode should be active")

  result = pomodoro:disableFocusMode()
  assert(result == true, "Should successfully disable focus mode")
  assert(pomodoro:isFocusModeActive() == false, "Focus mode should be inactive")

  -- Test toggle
  result = pomodoro:toggleFocusMode()
  assert(result == true, "Should successfully toggle focus mode")
  assert(pomodoro:isFocusModeActive() == true, "Focus mode should be active after toggle")

  result = pomodoro:toggleFocusMode()
  assert(result == true, "Should successfully toggle focus mode again")
  assert(pomodoro:isFocusModeActive() == false, "Focus mode should be inactive after second toggle")

  -- Test debug info
  local debugInfo = pomodoro:getFocusDebugInfo()
  assert(type(debugInfo) == "table", "Debug info should be a table")
  assert(type(debugInfo.isActive) == "boolean", "Debug info should include isActive field")

  -- Clean up
  pomodoro:stop()
  _G.dofile = originalDofile
end

local function testFocusModeCallbacks()
  print("\n=== Testing Focus Mode Callbacks ===")

  -- Create fresh mock
  local mockFocus = createMockFocusIntegration()

  -- Mock dofile
  local originalDofile = dofile
  _G.dofile = function(path)
    if path:match("focus_integration") then
      return mockFocus
    end
    return originalDofile(path)
  end

  -- Load pomodoro
  local Pomodoro = dofile("/Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua")
  local pomodoro = Pomodoro:new()
  pomodoro:start()

  local callback1Called = false
  local callback2Called = false

  local callback1 = function(isActive)
    callback1Called = true
  end

  local callback2 = function(isActive)
    callback2Called = true
  end

  -- Register callbacks
  pomodoro:onFocusModeChanged(callback1)
  pomodoro:onFocusModeChanged(callback2)
  assert(#mockFocus.state.callbacks == 2, "Should have two callbacks registered")

  -- Trigger focus change manually
  mockFocus.enablePomodoroFocus()
  assert(callback1Called == true, "First callback should be called")
  assert(callback2Called == true, "Second callback should be called")

  -- Clean up
  pomodoro:stop()
  _G.dofile = originalDofile
end

-- Main test runner
function obj.runTests()
  print("Starting Init Focus Integration Tests...")
  print("=====================================")

  -- Run all tests
  local success, err = pcall(function()
    testInitializationAndCleanup()
    testSessionFocusSync()
    testFocusModeAPI()
    testFocusModeCallbacks()
  end)

  if not success then
    print("\n✗ ERROR: " .. err)
    testResult.failed = testResult.failed + 1
    table.insert(testResult.errors, err)
  end

  -- Print summary
  print("\n=====================================")
  print("Test Summary:")
  print(string.format("  Passed: %d", testResult.passed))
  print(string.format("  Failed: %d", testResult.failed))

  if #testResult.errors > 0 then
    print("\nErrors:")
    for _, error in ipairs(testResult.errors) do
      print("  - " .. error)
    end
  end

  print(string.format("\nResult: %s", testResult.failed == 0 and "ALL TESTS PASSED ✓" or "SOME TESTS FAILED ✗"))

  return testResult
end

-- Auto-run tests when executed directly
if ... == nil then
  obj.runTests()
end

return obj