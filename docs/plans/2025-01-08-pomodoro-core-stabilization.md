# Pomodoro.spoon Core Stabilization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stabilize the Pomodoro.spoon codebase by eliminating global state, improving error handling, reducing code duplication, and adding proper testing.

**Architecture:** Refactor the existing code from global variables to encapsulated object-oriented design while maintaining backward compatibility and all existing functionality.

**Tech Stack:** Lua, Hammerspoon APIs, hs.settings, hs.timer, hs.menubar

---

## Phase 1: Foundation and Testing Infrastructure

### Task 1: Create Test Framework

**Files:**
- Create: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/test/init.lua`
- Modify: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua`

**Step 1: Write the failing test**

```lua
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
```

**Step 2: Run test to verify it fails**

Run: `lua -e "dofile('test/init.lua').testFrameworkSetup()"`
Expected: May fail due to missing spoon loading context

**Step 3: Write minimal test runner in init.lua**

Add to end of `init.lua`:
```lua
-- Test helper
if _G.POMODORO_TEST_MODE then
    return obj  -- Return the spoon object for testing
end
```

**Step 4: Run test to verify it passes**

Run test with Hammerspoon context or create test harness
Expected: PASS

**Step 5: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/test/init.lua
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua
git commit -m "test: add basic test framework for Pomodoro.spoon"
```

### Task 2: Add Error Handling Utilities

**Files:**
- Create: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/utils.lua`

**Step 1: Write the failing test**

```lua
-- test/utils_test.lua
local utils = require("utils")

function testErrorHandler()
    local result = utils.safeCall(function() error("Test error") end)
    assert(result.success == false, "Should catch error")
    assert(result.error:match("Test error"), "Should preserve error message")
end
```

**Step 2: Run test to verify it fails**

Expected: FAIL - "utils not found"

**Step 3: Write minimal implementation**

```lua
-- utils.lua
local utils = {}

function utils.safeCall(fn, ...)
    local success, result = pcall(fn, ...)
    if success then
        return { success = true, result = result }
    else
        return { success = false, error = result }
    end
end

function utils.validateSettings(settings)
    if type(settings) ~= "table" then
        return false, "Settings must be a table"
    end

    -- Validate work duration
    if settings.workDuration and (type(settings.workDuration) ~= "number" or settings.workDuration <= 0) then
        return false, "workDuration must be a positive number"
    end

    -- Validate break duration
    if settings.breakDuration and (type(settings.breakDuration) ~= "number" or settings.breakDuration <= 0) then
        return false, "breakDuration must be a positive number"
    end

    return true, "Settings valid"
end

return utils
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/utils.lua
git commit -m "feat: add error handling utilities"
```

## Phase 2: Encapsulate Global State

### Task 3: Create State Manager

**Files:**
- Create: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/state_manager.lua`

**Step 1: Write the failing test**

```lua
-- test/state_manager_test.lua
local StateManager = require("state_manager")

function testStateManagerCreation()
    local state = StateManager:new()
    assert(state:isRunning() == false, "Initial state should not be running")
    assert(state:getTimeLeft() == 0, "Initial time left should be 0")
end
```

**Step 2: Run test to verify it fails**

Expected: FAIL - "state_manager not found"

**Step 3: Write minimal implementation**

```lua
-- state_manager.lua
local StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local self = setmetatable({}, StateManager)
    self.timerRunning = false
    self.isBreak = false
    self.sessionsCompleted = 0
    self.timeLeft = 0
    self.sessionStartTime = nil
    self.timer = nil
    self.menuBarItem = nil
    return self
end

function StateManager:isRunning()
    return self.timerRunning
end

function StateManager:isBreak()
    return self.isBreak
end

function StateManager:getTimeLeft()
    return self.timeLeft
end

function StateManager:getSessionsCompleted()
    return self.sessionsCompleted
end

function StateManager:setRunning(running)
    self.timerRunning = running
end

function StateManager:setBreak(isBreak)
    self.isBreak = isBreak
end

function StateManager:setTimeLeft(time)
    self.timeLeft = time
end

function StateManager:setTimer(timer)
    if self.timer then
        self.timer:stop()
    end
    self.timer = timer
end

function StateManager:setMenuBarItem(item)
    self.menuBarItem = item
end

function StateManager:reset()
    self.timerRunning = false
    self.isBreak = false
    self.timeLeft = 0
    self.sessionStartTime = nil
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
end

function StateManager:saveSession()
    self.sessionsCompleted = self.sessionsCompleted + 1
    -- Save to hs.settings
    local today = os.date("%Y-%m-%d")
    local stats = hs.settings.get("pomodoro.dailyStats") or {}
    stats[today] = self.sessionsCompleted
    hs.settings.set("pomodoro.dailyStats", stats)
end

return StateManager
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/state_manager.lua
git commit -m "feat: add encapsulated state manager"
```

### Task 4: Refactor Global Variables in init.lua

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua`

**Step 1: Write the failing test**

```lua
-- test/init_refactor_test.lua
-- Test that refactored init maintains same behavior
local pomodoro = require("init")

function testRefactoredInit()
    -- Test that we can start/stop without errors
    local success = pomodoro:start()
    assert(success, "Should start successfully")

    local success = pomodoro:stop()
    assert(success, "Should stop successfully")
end
```

**Step 2: Run test to verify it fails**

Expected: May fail due to missing state manager integration

**Step 3: Refactor init.lua to use StateManager**

Replace global variables with state manager:
```lua
-- At the top of init.lua, after spoon declaration
local StateManager = require("pomodoro.state_manager")
local utils = require("pomodoro.utils")

-- Remove these global variables:
-- local timerRunning = false
-- local isBreak = false
-- local sessionsCompleted = 0
-- local timeLeft = 0
-- local sessionStartTime = nil
-- local timer = nil
-- local menuBarItem = nil

-- Add state instance to obj:
obj.state = StateManager:new()

-- Update all references from global variables to obj.state
-- Example: timerRunning becomes obj.state:isRunning()
-- Example: sessionsCompleted becomes obj.state:getSessionsCompleted()
```

**Step 4: Update all function references**

Update functions to use state manager:
```lua
function obj:startSession()
    if obj.state:isRunning() then
        return
    end

    obj.state:setRunning(true)
    obj.state:setBreak(false)
    obj.state:setTimeLeft(workDuration)
    obj.state.sessionStartTime = os.time()

    -- ... rest of the function
end

function obj:stopSession()
    if not obj.state:isRunning() then
        return
    end

    obj.state:setRunning(false)
    obj.state:setTimer(nil)

    -- ... rest of the function
end
```

**Step 5: Run test to verify it passes**

Expected: PASS

**Step 6: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua
git commit -m "refactor: replace global state with StateManager"
```

## Phase 3: Improve Error Handling

### Task 5: Add Validation to Timer Operations

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua`

**Step 1: Write the failing test**

```lua
-- test/timer_validation_test.lua
local pomodoro = require("init")

function testInvalidWorkDuration()
    local result = pomodoro:startSessionWithDuration(-5)
    assert(result == false, "Should reject negative duration")
end

function testZeroDuration()
    local result = pomodoro:startSessionWithDuration(0)
    assert(result == false, "Should reject zero duration")
end
```

**Step 2: Run test to verify it fails**

Expected: FAIL - Methods don't exist or don't validate

**Step 3: Add validation methods**

```lua
-- In init.lua
function obj:startSessionWithDuration(duration)
    -- Validate input
    if not duration or type(duration) ~= "number" or duration <= 0 then
        utils.showError("Invalid duration: must be a positive number")
        return false
    end

    if obj.state:isRunning() then
        utils.showInfo("Session already running")
        return false
    end

    -- ... rest of implementation
end

function obj:validateSettings()
    local isValid, message = utils.validateSettings({
        workDuration = workDuration,
        breakDuration = breakDuration
    })

    if not isValid then
        utils.showError("Invalid settings: " .. message)
        return false
    end

    return true
end
```

**Step 4: Add error display utilities to utils.lua**

```lua
-- In utils.lua
function utils.showError(message)
    hs.notify.new({
        title = "Pomodoro Error",
        informativeText = message
    }):send()
    print("[Pomodoro Error] " .. message)
end

function utils.showInfo(message)
    hs.notify.new({
        title = "Pomodoro",
        informativeText = message
    }):send()
    print("[Pomodoro] " .. message)
end
```

**Step 5: Run test to verify it passes**

Expected: PASS

**Step 6: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/utils.lua
git commit -m "feat: add validation and error handling to timer operations"
```

### Task 6: Handle Timer Failures Gracefully

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua`

**Step 1: Write the failing test**

```lua
-- test/timer_failure_test.lua
function testTimerCreationFailure()
    -- Mock hs.timer.new to fail
    local originalTimerNew = hs.timer.new
    hs.timer.new = function() error("Timer creation failed") end

    local pomodoro = require("init")
    local result = pomodoro:startSession()

    -- Restore
    hs.timer.new = originalTimerNew

    assert(result == false, "Should handle timer creation failure")
end
```

**Step 2: Run test to verify it fails**

Expected: FAIL - No error handling

**Step 3: Add timer error handling**

```lua
-- In startSession function
function obj:startSession()
    -- ... existing validation ...

    local success, timer = utils.safeCall(function()
        return hs.timer.new(1, obj.updateTimer)
    end)

    if not success then
        utils.showError("Failed to create timer: " .. timer.error)
        obj.state:setRunning(false)
        return false
    end

    obj.state:setTimer(timer)
    timer:start()

    -- ... rest of function
end
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua
git commit -m "feat: add graceful timer failure handling"
```

## Phase 4: Reduce Code Duplication

### Task 7: Extract Common UI Update Logic

**Files:**
- Create: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/ui_manager.lua`

**Step 1: Write the failing test**

```lua
-- test/ui_manager_test.lua
local UIManager = require("ui_manager")

function testUIManagerCreation()
    local ui = UIManager:new()
    assert(ui ~= nil, "UIManager should be created")
end

function testUpdateMenuBarText()
    local ui = UIManager:new()
    local mockItem = { setTitle = function() end }
    ui:setMenuBarItem(mockItem)

    -- Should not error
    ui:updateMenuBarText("Work", 1500)
end
```

**Step 2: Run test to verify it fails**

Expected: FAIL - "ui_manager not found"

**Step 3: Write minimal implementation**

```lua
-- ui_manager.lua
local UIManager = {}
UIManager.__index = UIManager

function UIManager:new()
    local self = setmetatable({}, UIManager)
    self.menuBarItem = nil
    return self
end

function UIManager:setMenuBarItem(item)
    self.menuBarItem = item
end

function UIManager:updateMenuBarText(sessionType, timeLeft)
    if not self.menuBarItem then
        return
    end

    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    local title = string.format("%s: %02d:%02d", sessionType, minutes, seconds)

    utils.safeCall(function()
        self.menuBarItem:setTitle(title)
    end)
end

function UIManager:updateMenu(state)
    if not self.menuBarItem then
        return
    end

    local menuItems = {}

    if state:isRunning() then
        table.insert(menuItems, {
            title = "Stop Session",
            fn = function() obj:stopSession() end
        })
    else
        table.insert(menuItems, {
            title = "Start Session",
            fn = function() obj:startSession() end
        })
    end

    table.insert(menuItems, { title = "-" })
    table.insert(menuItems, {
        title = "Reset",
        fn = function() obj:reset() end
    })

    utils.safeCall(function()
        self.menuBarItem:setMenu(menuItems)
    end)
end

return UIManager
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Refactor init.lua to use UIManager**

Update init.lua:
```lua
local UIManager = require("pomodoro.ui_manager")

-- Add UI manager to obj
obj.ui = UIManager:new()

-- Update menu bar creation
obj.menuBarItem = hs.menubar.new()
obj.ui:setMenuBarItem(obj.menuBarItem)

-- Update timer callback
function obj.updateTimer()
    -- ... calculate timeLeft ...

    local sessionType = obj.state:isBreak() and "Break" or "Work"
    obj.ui:updateMenuBarText(sessionType, obj.state:getTimeLeft())
    obj.ui:updateMenu(obj.state)
end
```

**Step 6: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/ui_manager.lua
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua
git commit -m "refactor: extract UI management to reduce duplication"
```

## Phase 5: Documentation and Cleanup

### Task 8: Update API Documentation

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/docs.json`

**Step 1: Write the failing test**

```lua
-- test/docs_test.lua
local docs = require("docs")

function testDocsCompleteness()
    assert(docs.functions, "Should document functions")
    assert(docs.functions.startSession, "Should document startSession")
    assert(docs.functions.stopSession, "Should document stopSession")
end
```

**Step 2: Run test to verify it fails**

Expected: May fail due to missing documentation

**Step 3: Update docs.json**

```json
{
  "name": "Pomodoro.spoon",
  "version": "1.0.0",
  "description": "A Pomodoro timer with error handling and encapsulated state",
  "author": "Jiho",
  "license": "MIT",
  "functions": {
    "startSession": {
      "description": "Start a new Pomodoro work session",
      "returns": "boolean - success status",
      "errors": "Returns false if timer creation fails or session already running"
    },
    "stopSession": {
      "description": "Stop the current session",
      "returns": "boolean - success status"
    },
    "reset": {
      "description": "Reset the timer and clear all state",
      "returns": "nil"
    },
    "validateSettings": {
      "description": "Validate current timer settings",
      "returns": "boolean - true if settings are valid"
    }
  },
  "dependencies": [
    "hs.timer",
    "hs.menubar",
    "hs.notify",
    "hs.settings"
  ]
}
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/docs.json
git commit -m "docs: update API documentation for refactored code"
```

### Task 9: Final Integration Test

**Files:**
- Create: `users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/test/integration_test.lua`

**Step 1: Write the comprehensive test**

```lua
-- test/integration_test.lua
local pomodoro = require("init")

function testFullSession()
    -- Setup
    pomodoro:reset()

    -- Start session
    local startResult = pomodoro:startSession()
    assert(startResult, "Should start session")

    -- Verify state
    assert(pomodoro.state:isRunning(), "State should show running")
    assert(pomodoro.state:getTimeLeft() > 0, "Should have time left")

    -- Stop session
    local stopResult = pomodoro:stopSession()
    assert(stopResult, "Should stop session")

    -- Verify final state
    assert(not pomodoro.state:isRunning(), "State should show not running")
end

function testErrorHandling()
    -- Test invalid input
    local result = pomodoro:startSessionWithDuration(-1)
    assert(result == false, "Should reject invalid duration")
end

print("All integration tests passed!")
```

**Step 2: Run test to verify it passes**

Expected: PASS

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/test/integration_test.lua
git commit -m "test: add comprehensive integration tests"
```

## Phase 6: Cleanup and Final Review

### Task 10: Remove Unused Code and Final Review

**Files:**
- Modify: Multiple files for cleanup

**Step 1: Review and remove unused imports**

**Step 2: Remove commented-out code**

**Step 3: Ensure consistent formatting**

**Step 4: Add TODO comments for future improvements**

**Step 5: Final commit**

```bash
git add -A
git commit -m "cleanup: remove unused code and final polish"
```

## Summary

This plan stabilizes the Pomodoro.spoon by:

1. **Adding comprehensive tests** - Ensures reliability and prevents regressions
2. **Encapsulating state** - Eliminates global variables and improves maintainability
3. **Improving error handling** - Makes the timer robust against failures
4. **Reducing duplication** - Extracts common UI logic for better DRY
5. **Updating documentation** - Keeps docs in sync with code changes

All changes maintain backward compatibility while significantly improving code quality and reliability.