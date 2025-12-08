--- Focus Integration Test Suite
--- Tests for focus_integration.lua module

local FocusIntegration = require("../focus_integration")

-- Test helpers
local TestFramework = {}
TestFramework.tests = {}
TestFramework.passed = 0
TestFramework.failed = 0
TestFramework.currentBeforeEach = nil
TestFramework.currentAfterEach = nil

function TestFramework.describe(name, fn)
  print("\n--- " .. name .. " ---")
  local oldBeforeEach = TestFramework.currentBeforeEach
  local oldAfterEach = TestFramework.currentAfterEach
  TestFramework.currentBeforeEach = nil
  TestFramework.currentAfterEach = nil
  fn()
  TestFramework.currentBeforeEach = oldBeforeEach
  TestFramework.currentAfterEach = oldAfterEach
end

function TestFramework.it(name, fn)
  if TestFramework.currentBeforeEach then
    TestFramework.currentBeforeEach()
  end

  local ok, err = pcall(fn)

  if TestFramework.currentAfterEach then
    TestFramework.currentAfterEach()
  end

  if ok then
    print("✓ " .. name)
    TestFramework.passed = TestFramework.passed + 1
  else
    print("✗ " .. name)
    print("  Error: " .. err)
    TestFramework.failed = TestFramework.failed + 1
  end
end

function TestFramework.beforeEach(fn)
  TestFramework.currentBeforeEach = fn
end

function TestFramework.afterEach(fn)
  TestFramework.currentAfterEach = fn
end

function TestFramework.expect(actual)
  return {
    to_be = function(expected)
      if actual ~= expected then
        error(string.format("Expected %s, but got %s", tostring(expected), tostring(actual)))
      end
    end,
    to_be_true = function()
      if actual ~= true then
        error("Expected true, but got " .. tostring(actual))
      end
    end,
    to_be_false = function()
      if actual ~= false then
        error("Expected false, but got " .. tostring(actual))
      end
    end,
    to_be_nil = function()
      if actual ~= nil then
        error("Expected nil, but got " .. tostring(actual))
      end
    end,
    to_equal = function(expected)
      if type(actual) ~= type(expected) then
        error("Types don't match: " .. type(actual) .. " vs " .. type(expected))
      end
      if type(actual) == "table" then
        for k, v in pairs(expected) do
          if actual[k] ~= v then
            error(string.format("Table values differ at key %s: %s vs %s", k, tostring(actual[k]), tostring(v)))
          end
        end
      else
        if actual ~= expected then
          error(string.format("Expected %s, but got %s", tostring(expected), tostring(actual)))
        end
      end
    end
  }
end

function TestFramework.run()
  print("\nTest Results:")
  print("Passed: " .. TestFramework.passed)
  print("Failed: " .. TestFramework.failed)
  return TestFramework.failed == 0
end

-- Mock hs module for testing
local mock_hs = {
  focus = {
    getFocusModes = function()
      return {
        { name = "Pomodoro", active = true },
        { name = "Do Not Disturb", active = false },
        { name = "Sleep", active = false }
      }
    end,
    new = function(callback)
      return {
        stop = function() end
      }
    end
  },
  osascript = {
    applescript = function(script)
      return true, false  -- Simulate AppleScript returning false for Focus state
    end
  },
  urlevent = {
    openURL = function(url)
      return true
    end
  },
  timer = {
    delayed = function(delay, fn)
      fn()
    end,
    doAfter = function(delay, fn)
      fn()
    end,
    doEvery = function(interval, fn)
      fn()
      return {
        stop = function() end
      }
    end
  }
}

-- Replace global hs with mock
_G.hs = mock_hs

-- Test variables
local pomodoroMock = {
  isRunning = function() return false end,
  startSession = function() end,
  stopSession = function() end
}

-- Tests
TestFramework.describe("Focus Integration Module", function()

  TestFramework.describe("Initialization", function()
    TestFramework.it("should initialize successfully", function()
      local result = FocusIntegration.init(pomodoroMock)
      TestFramework.expect(result).to_be(FocusIntegration)
    end)

    TestFramework.it("should detect initial Focus state", function()
      FocusIntegration.init(pomodoroMock)
      local isActive = FocusIntegration.isPomodoroFocusActive()
      TestFramework.expect(isActive).to_be(true)  -- Based on mock data
    end)
  end)

  TestFramework.describe("Focus Mode Control", function()
    TestFramework.it("should enable Focus Mode", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)
      local result = FocusIntegration.enablePomodoroFocus()
      TestFramework.expect(result).to_be_true()
    end)

    TestFramework.it("should disable Focus Mode", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)
      local result = FocusIntegration.disablePomodoroFocus()
      TestFramework.expect(result).to_be_true()
    end)

    TestFramework.it("should toggle Focus Mode", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)
      local initialState = FocusIntegration.isPomodoroFocusActive()
      local result = FocusIntegration.togglePomodoroFocus()
      TestFramework.expect(result).to_be_true()
      local newState = FocusIntegration.isPomodoroFocusActive()
      TestFramework.expect(newState).to_be(not initialState)
    end)
  end)

  TestFramework.describe("State Management", function()
    TestFramework.it("should track Focus state correctly", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)
      local debugInfo = FocusIntegration.getDebugInfo()
      TestFramework.expect(debugInfo.isActive).to_be(true)
      TestFramework.expect(debugInfo.hasFocusModule).to_be(true)
      TestFramework.expect(debugInfo.callbackCount).to_be(0)
    end)

    TestFramework.it("should handle callback registration", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)
      local callbackCalled = false
      local callback = function(isActive)
        callbackCalled = isActive
      end

      FocusIntegration.onFocusModeChanged(callback)
      local debugInfo = FocusIntegration.getDebugInfo()
      TestFramework.expect(debugInfo.callbackCount).to_be(1)
    end)

    TestFramework.it("should handle callback removal", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)
      local callback = function() end

      FocusIntegration.onFocusModeChanged(callback)
      local debugInfo = FocusIntegration.getDebugInfo()
      TestFramework.expect(debugInfo.callbackCount).to_be(1)

      local removed = FocusIntegration.removeFocusModeCallback(callback)
      TestFramework.expect(removed).to_be_true()

      debugInfo = FocusIntegration.getDebugInfo()
      TestFramework.expect(debugInfo.callbackCount).to_be(0)
    end)
  end)

  TestFramework.describe("Focus Mode Detection", function()
    TestFramework.it("should correctly identify Pomodoro in Focus modes", function()
      local focusModes = {
        { name = "Pomodoro", active = true },
        { name = "Do Not Disturb", active = false }
      }
      local isActive = FocusIntegration.isPomodoroActive(focusModes)
      TestFramework.expect(isActive).to_be_true()
    end)

    TestFramework.it("should handle missing Pomodoro mode", function()
      local focusModes = {
        { name = "Do Not Disturb", active = true },
        { name = "Sleep", active = false }
      }
      local isActive = FocusIntegration.isPomodoroActive(focusModes)
      TestFramework.expect(isActive).to_be_false()
    end)

    TestFramework.it("should handle nil focus modes", function()
      local isActive = FocusIntegration.isPomodoroActive(nil)
      TestFramework.expect(isActive).to_be_false()
    end)
  end)

  TestFramework.describe("Debouncing", function()
    TestFramework.it("should handle state changes", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)

      -- Enable Focus
      local result1 = FocusIntegration.enablePomodoroFocus()
      TestFramework.expect(result1).to_be_true()

      -- Verify state changed
      local isActive = FocusIntegration.isPomodoroFocusActive()
      TestFramework.expect(isActive).to_be_true()

      -- Disable Focus with cleanup to reset debounce timer
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)

      -- Now disable should succeed
      local result2 = FocusIntegration.disablePomodoroFocus()
      TestFramework.expect(result2).to_be_true()

      -- Verify state changed
      isActive = FocusIntegration.isPomodoroFocusActive()
      TestFramework.expect(isActive).to_be_false()
    end)
  end)

  TestFramework.describe("Cleanup", function()
    TestFramework.it("should clean up properly", function()
      FocusIntegration.init(pomodoroMock)
      FocusIntegration.cleanup()
      local debugInfo = FocusIntegration.getDebugInfo()
      TestFramework.expect(debugInfo.hasWatcher).to_be_false()
      TestFramework.expect(debugInfo.callbackCount).to_be(0)
    end)
  end)
end)

-- Edge case tests
TestFramework.describe("Edge Cases", function()
  TestFramework.describe("When hs.focus is not available", function()
    local originalFocus

    TestFramework.beforeEach(function()
      -- Temporarily remove hs.focus
      originalFocus = mock_hs.focus
      mock_hs.focus = nil
      _G.hs = mock_hs
    end)

    TestFramework.afterEach(function()
      -- Restore hs.focus
      mock_hs.focus = originalFocus or {
        getFocusModes = function()
          return {
            { name = "Pomodoro", active = true },
            { name = "Do Not Disturb", active = false }
          }
        end,
        new = function(callback)
          return {
            stop = function() end
          }
        end
      }
      _G.hs = mock_hs
    end)

    TestFramework.it("should use fallback detection", function()
      FocusIntegration.init(pomodoroMock)
      local debugInfo = FocusIntegration.getDebugInfo()
      TestFramework.expect(debugInfo.hasFocusModule).to_be_false()
    end)

    TestFramework.it("should still allow Focus control", function()
      FocusIntegration.cleanup()
      FocusIntegration.init(pomodoroMock)
      -- Even with fallback detection, we should still be able to control Focus
      -- The initial state will be false since AppleScript returns false
      local initialState = FocusIntegration.isPomodoroFocusActive()
      TestFramework.expect(initialState).to_be_false()

      local result = FocusIntegration.enablePomodoroFocus()
      TestFramework.expect(result).to_be_true()
    end)
  end)

  TestFramework.describe("Invalid inputs", function()
    TestFramework.it("should handle non-function callbacks", function()
      FocusIntegration.init(pomodoroMock)
      local result = FocusIntegration.onFocusModeChanged("not a function")
      TestFramework.expect(result).to_be_false()
    end)

    TestFramework.it("should handle removing non-existent callbacks", function()
      FocusIntegration.init(pomodoroMock)
      local result = FocusIntegration.removeFocusModeCallback(function() end)
      TestFramework.expect(result).to_be_false()
    end)
  end)
end)

-- Integration tests (simplified)
TestFramework.describe("Integration", function()
  TestFramework.it("should sync with Pomodoro spoon", function()
    FocusIntegration.cleanup()
    local callbackTriggered = false
    local callbackState = nil

    local mockPomodoro = {
      isRunning = function() return false end,
      startSession = function() end,
      stopSession = function() end
    }

    -- Simulate Focus activation
    FocusIntegration.init(mockPomodoro)

    -- Register callback to verify it's triggered
    FocusIntegration.onFocusModeChanged(function(isActive)
      callbackTriggered = true
      callbackState = isActive
    end)

    -- Enable Focus (should trigger callback)
    local result = FocusIntegration.enablePomodoroFocus()
    TestFramework.expect(result).to_be_true()
    TestFramework.expect(callbackTriggered).to_be_true()
    TestFramework.expect(callbackState).to_be_true()
  end)
end)

-- Run all tests
print("Running Focus Integration Tests...")
local allPassed = TestFramework.run()

if allPassed then
  print("\n✅ All tests passed!")
  os.exit(0)
else
  print("\n❌ Some tests failed!")
  os.exit(1)
end