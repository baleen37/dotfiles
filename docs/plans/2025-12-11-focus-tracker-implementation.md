# FocusTracker.spoon Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** FocusTracker.spoon을 구현하여 macOS의 모든 Focus Mode를 추적하고 집중 시간을 실시간으로 표시합니다.

**Architecture:** Pomodoro.spoon의 코드를 복사하여 수정합니다. 통계 추적을 제거하고, 카운트다운을 카운트업으로 변경하며, 특정 Focus Mode가 아닌 모든 Focus Mode를 추적합니다. UI는 콜백 기반으로 완전히 위임합니다.

**Tech Stack:** Lua, Hammerspoon API, JXA (JavaScript for Automation), NSDistributedNotificationCenter

---

### Task 1: 디렉토리 및 기본 파일 생성

**Files:**
- Create: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
- Create: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/docs.json`

**Step 1: Pomodoro.spoon 복사**

```bash
cp -r users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon
```

**Step 2: 복사 확인**

Run: `ls -la users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/`
Expected: `init.lua`와 `docs.json` 파일이 존재함

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/
git commit -m "feat: copy Pomodoro.spoon as FocusTracker.spoon base"
```

---

### Task 2: Metadata 업데이트

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua:18-27`

**Step 1: Metadata 변경**

`init.lua`의 18-27줄을 다음과 같이 수정:

```lua
local obj = {}
obj.__index = obj

-- Spoon Metadata
obj.name = "FocusTracker"
obj.version = "1.0"
obj.author = "Jiho Hwang <jito.hello@gmail.com>"
obj.license = "MIT"
obj.homepage = "https://github.com/jito-hwang/dotfiles"
obj.description = "Focus Mode tracker with real-time duration display"
```

**Step 2: 변경 확인**

Run: `grep -n "obj.name\|obj.description" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: FocusTracker 이름과 새로운 description 확인

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: update FocusTracker metadata"
```

---

### Task 3: Config 구조 변경

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua:29-40`

**Step 1: Config 수정**

29-40줄의 `obj.config`를 다음과 같이 수정:

```lua
-- Default Configuration
obj.config = {
  -- Callbacks
  onFocusStart = nil,  -- Called when Focus Mode starts: function(focusModeName)
  onFocusEnd = nil     -- Called when Focus Mode ends: function(focusModeName, durationInSeconds)
}
```

**Step 2: 변경 확인**

Run: `grep -A 5 "obj.config = {" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua | head -7`
Expected: onFocusStart와 onFocusEnd만 존재

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: simplify config to callback-only structure"
```

---

### Task 4: State 구조 변경

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua:42-50`

**Step 1: State 수정**

42-50줄의 `State` 테이블을 다음과 같이 수정:

```lua
-- Application State
local State = {
  isTracking = false,
  elapsedTime = 0,
  currentFocusMode = nil,
  startTime = nil,
}
```

**Step 2: 변경 확인**

Run: `grep -A 6 "local State = {" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua | head -7`
Expected: isTracking, elapsedTime, currentFocusMode, startTime만 존재

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: update State structure for tracking focus mode"
```

---

### Task 5: Cache 및 통계 관련 코드 완전 제거

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: Cache 테이블 제거**

59-65줄의 `Cache` 테이블을 완전히 삭제

**Step 2: 통계 관련 함수 제거**

다음 함수들을 완전히 삭제:
- `getCurrentDateString()` (71-78줄)
- `getCachedStatistics()` (99-106줄)
- `invalidateStatisticsCache()` (108-111줄)
- `saveCurrentStatistics()` (113-119줄)
- `loadCurrentStatistics()` (121-126줄)

**Step 3: 변경 확인**

Run: `grep -n "Cache\|Statistics\|getCurrentDateString" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: 출력 없음 (모두 제거됨)

**Step 4: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: remove cache and statistics tracking"
```

---

### Task 6: Utility 함수 정리

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: showNotification 함수 제거**

`showNotification()` 함수를 완전히 삭제 (더 이상 사용하지 않음)

**Step 2: formatTime 함수는 유지**

`formatTime()` 함수는 menubar 표시에 사용하므로 그대로 유지

**Step 3: 변경 확인**

Run: `grep -n "function showNotification\|function formatTime" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: formatTime만 존재, showNotification은 없음

**Step 4: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: remove showNotification, keep formatTime"
```

---

### Task 7: TimerManager - startTracking 구현

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: startWorkSession을 startTracking으로 교체**

기존 `TimerManager.startWorkSession()` 함수를 다음으로 교체:

```lua
function TimerManager.startTracking()
  TimerManager.cleanup()

  State.isTracking = true
  State.elapsedTime = 0
  State.startTime = os.time()
  State.currentFocusMode = FocusManager.getCurrentFocusMode()

  if not State.currentFocusMode then
    State.currentFocusMode = "Focus Mode"
  end

  -- Callback: onFocusStart
  if obj.config.onFocusStart then
    obj.config.onFocusStart(State.currentFocusMode)
  end

  UI.countdownTimer = hs.timer.new(1, function()
    State.elapsedTime = State.elapsedTime + 1
    updateMenubarDisplay()
  end)
  UI.countdownTimer:start()
end
```

**Step 2: 변경 확인**

Run: `grep -n "function TimerManager.startTracking" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: startTracking 함수가 존재함

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: implement TimerManager.startTracking with count-up timer"
```

---

### Task 8: TimerManager - stopTracking 구현

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: stop을 stopTracking으로 교체**

기존 `TimerManager.stop()` 함수를 다음으로 교체:

```lua
function TimerManager.stopTracking()
  local duration = State.elapsedTime
  local focusName = State.currentFocusMode

  TimerManager.cleanup()

  State.isTracking = false
  State.elapsedTime = 0
  State.currentFocusMode = nil
  State.startTime = nil

  -- Callback: onFocusEnd
  if obj.config.onFocusEnd then
    obj.config.onFocusEnd(focusName, duration)
  end
end
```

**Step 2: 변경 확인**

Run: `grep -n "function TimerManager.stopTracking" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: stopTracking 함수가 존재함

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: implement TimerManager.stopTracking with callback"
```

---

### Task 9: TimerManager - 불필요한 함수 제거

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: startBreakSession 함수 제거**

`TimerManager.startBreakSession()` 함수 전체 삭제

**Step 2: createCallback 함수 제거**

`TimerManager.createCallback()` 함수 전체 삭제 (더 이상 사용하지 않음)

**Step 3: 변경 확인**

Run: `grep -n "startBreakSession\|createCallback" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: 출력 없음

**Step 4: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: remove unused TimerManager functions"
```

---

### Task 10: FocusManager - handleFocusChange 수정

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: handleFocusChange 함수 교체**

기존 `FocusManager.handleFocusChange()` 함수를 다음으로 교체:

```lua
function FocusManager.handleFocusChange()
  local currentMode = FocusManager.getCurrentFocusMode()

  if currentMode then
    if not State.isTracking then
      TimerManager.startTracking()
      updateMenubarDisplay()
    end
  else
    if State.isTracking then
      TimerManager.stopTracking()
      updateMenubarDisplay()
    end
  end
end
```

**Step 2: 변경 확인**

Run: `grep -A 15 "function FocusManager.handleFocusChange" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua | head -16`
Expected: currentMode 체크만 하고 특정 Focus Mode 필터링 없음

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: update handleFocusChange to track all focus modes"
```

---

### Task 11: FocusManager - isPomodoroActive 제거 및 모니터링 단순화

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: isPomodoroActive 함수 제거**

`FocusManager.isPomodoroActive()` 함수 전체 삭제

**Step 2: startMonitoring 함수 수정**

기존 `FocusManager.startMonitoring()` 함수를 다음으로 교체:

```lua
function FocusManager.startMonitoring()
  -- Watch for Focus mode enabled
  UI.focusWatcherEnabled = hs.distributednotifications.new(function(name, object, userInfo)
    if FocusManager.getCurrentFocusMode() then
      if not State.isTracking then
        TimerManager.startTracking()
        updateMenubarDisplay()
      end
    end
  end, "_NSDoNotDisturbEnabledNotification")
  UI.focusWatcherEnabled:start()

  -- Watch for Focus mode disabled
  UI.focusWatcherDisabled = hs.distributednotifications.new(function(name, object, userInfo)
    if State.isTracking then
      TimerManager.stopTracking()
      updateMenubarDisplay()
    end
  end, "_NSDoNotDisturbDisabledNotification")
  UI.focusWatcherDisabled:start()

  UI.lastKnownFocus = FocusManager.getCurrentFocusMode()
end
```

**Step 3: 변경 확인**

Run: `grep -n "isPomodoroActive" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: 출력 없음

**Step 4: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: remove isPomodoroActive and simplify focus monitoring"
```

---

### Task 12: UI - updateMenubarDisplay 단순화

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: updateMenubarDisplay 함수 교체**

기존 함수를 다음으로 교체:

```lua
local function updateMenubarDisplay()
  if not UI.menubarItem then return end

  if not State.isTracking then
    UI.menubarItem:setTitle("🔵 Ready")
  else
    UI.menubarItem:setTitle("🔵 " .. formatTime(State.elapsedTime))
  end
end
```

**Step 2: 변경 확인**

Run: `grep -A 8 "function updateMenubarDisplay" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua | head -9`
Expected: isBreak 체크 없이 단순한 Ready/시간 표시만

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: simplify menubar display to show tracking status"
```

---

### Task 13: UI - buildMenuTable 제거

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: buildMenuTable 함수 제거**

`buildMenuTable()` 함수 전체 삭제

**Step 2: 변경 확인**

Run: `grep -n "buildMenuTable" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: 출력 없음

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: remove buildMenuTable (no menu needed)"
```

---

### Task 14: obj:init() 함수 단순화

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: init() 함수의 doc comment 수정**

```lua
--- FocusTracker:init(config) -> FocusTracker
--- Method
--- Initializes the FocusTracker Spoon with custom configuration
---
--- Parameters:
---  * config - Optional table containing configuration options:
---    * onFocusStart - Function called when Focus Mode starts: function(focusModeName) (optional)
---    * onFocusEnd - Function called when Focus Mode ends: function(focusModeName, durationInSeconds) (optional)
---
--- Returns:
---  * The FocusTracker object
---
--- Notes:
---  * This method is optional. If not called, no callbacks will be triggered
---  * Can be chained with start(): `spoon.FocusTracker:init({onFocusStart = ...}):start()`
---  * Callbacks allow custom notifications or actions when Focus Mode changes
function obj:init(config)
  if config then
    for k, v in pairs(config) do
      if self.config[k] ~= nil then
        self.config[k] = v
      end
    end
  end
  return self
end
```

**Step 2: 변경 확인**

Run: `grep -A 5 "FocusTracker:init" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua | head -6`
Expected: FocusTracker 관련 doc comment

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "docs: update init() documentation"
```

---

### Task 15: obj:start() 함수 수정

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: start() 함수 교체**

기존 함수를 다음으로 교체:

```lua
--- FocusTracker:start() -> FocusTracker
--- Method
--- Starts the FocusTracker Spoon and initializes all watchers and timers
---
--- Returns:
---  * The FocusTracker object
function obj:start()
  -- Initialize menubar with error handling
  local success, menubar = pcall(function()
    return hs.menubar.new()
  end)
  if not success or not menubar then
    hs.alert.show("Failed to create menubar item for FocusTracker")
    return self
  end
  UI.menubarItem = menubar

  -- No menu callback (clicking does nothing)

  -- Start focus mode monitoring
  FocusManager.startMonitoring()

  -- Initialize UI state
  updateMenubarDisplay()

  -- Handle current focus mode if already active
  if FocusManager.getCurrentFocusMode() then
    TimerManager.startTracking()
    updateMenubarDisplay()
  end

  return self
end
```

**Step 2: 변경 확인**

Run: `grep -n "setClickCallback\|loadCurrentStatistics\|invalidateStatisticsCache" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: 출력 없음 (모두 제거됨)

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: simplify start() to remove menu and statistics"
```

---

### Task 16: obj:stop() 함수 수정

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: stop() 함수 교체**

기존 함수를 다음으로 교체:

```lua
--- FocusTracker:stop() -> FocusTracker
--- Method
--- Stops the FocusTracker Spoon and cleans up resources
---
--- Returns:
---  * The FocusTracker object
function obj:stop()
  -- Stop active timer
  TimerManager.stopTracking()

  -- Stop focus monitoring
  FocusManager.stopMonitoring()

  -- Remove menubar item
  if UI.menubarItem then
    UI.menubarItem:delete()
    UI.menubarItem = nil
  end

  -- Clear state
  UI.lastKnownFocus = nil

  return self
end
```

**Step 2: 변경 확인**

Run: `grep -n "saveCurrentStatistics\|invalidateStatisticsCache" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: 출력 없음

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: simplify stop() to remove statistics handling"
```

---

### Task 17: 불필요한 공개 API 제거

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`

**Step 1: 다음 함수들 제거**

- `obj:bindHotkeys()`
- `obj:getStatistics()`
- `obj:toggleSession()`
- `obj:isRunning()`
- `obj:getTimeLeft()`
- `obj:isBreak()`

모두 완전히 삭제

**Step 2: 변경 확인**

Run: `grep -n "bindHotkeys\|getStatistics\|toggleSession\|isRunning\|getTimeLeft\|isBreak" users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua`
Expected: 출력 없음

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/init.lua
git commit -m "feat: remove unnecessary public APIs"
```

---

### Task 18: docs.json 생성

**Files:**
- Modify: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/docs.json`

**Step 1: docs.json 내용 작성**

```json
[
  {
    "Constant": [],
    "Variable": [],
    "Method": [
      {
        "def": "FocusTracker:init(config)",
        "desc": "Initializes the FocusTracker Spoon with custom configuration",
        "doc": "Initializes the FocusTracker Spoon with custom configuration\n\nParameters:\n * config - Optional table containing configuration options:\n   * onFocusStart - Function called when Focus Mode starts: function(focusModeName) (optional)\n   * onFocusEnd - Function called when Focus Mode ends: function(focusModeName, durationInSeconds) (optional)\n\nReturns:\n * The FocusTracker object\n\nNotes:\n * This method is optional. If not called, no callbacks will be triggered\n * Can be chained with start(): `spoon.FocusTracker:init({onFocusStart = ...}):start()`\n * Callbacks allow custom notifications or actions when Focus Mode changes",
        "name": "init",
        "parameters": [
          " * config - Optional table containing configuration options:",
          "   * onFocusStart - Function called when Focus Mode starts: function(focusModeName) (optional)",
          "   * onFocusEnd - Function called when Focus Mode ends: function(focusModeName, durationInSeconds) (optional)"
        ],
        "returns": [
          " * The FocusTracker object"
        ],
        "signature": "FocusTracker:init(config)",
        "stripped_doc": "Initializes the FocusTracker Spoon with custom configuration\nParameters:\nReturns:\nNotes:",
        "type": "Method"
      },
      {
        "def": "FocusTracker:start()",
        "desc": "Starts the FocusTracker Spoon and initializes all watchers and timers",
        "doc": "Starts the FocusTracker Spoon and initializes all watchers and timers\n\nReturns:\n * The FocusTracker object",
        "name": "start",
        "parameters": [],
        "returns": [
          " * The FocusTracker object"
        ],
        "signature": "FocusTracker:start()",
        "stripped_doc": "Starts the FocusTracker Spoon and initializes all watchers and timers\nReturns:",
        "type": "Method"
      },
      {
        "def": "FocusTracker:stop()",
        "desc": "Stops the FocusTracker Spoon and cleans up resources",
        "doc": "Stops the FocusTracker Spoon and cleans up resources\n\nReturns:\n * The FocusTracker object",
        "name": "stop",
        "parameters": [],
        "returns": [
          " * The FocusTracker object"
        ],
        "signature": "FocusTracker:stop()",
        "stripped_doc": "Stops the FocusTracker Spoon and cleans up resources\nReturns:",
        "type": "Method"
      }
    ],
    "Command": [],
    "Constructor": [],
    "Field": [],
    "Function": [],
    "name": "FocusTracker"
  }
]
```

**Step 2: 변경 확인**

Run: `cat users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/docs.json | grep -o '"name": "FocusTracker"'`
Expected: "name": "FocusTracker"

**Step 3: Commit**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/docs.json
git commit -m "docs: create FocusTracker API documentation"
```

---

### Task 19: 수동 테스트 - Hammerspoon 설정

**Files:**
- Read: `users/shared/.config/hammerspoon/init.lua`

**Step 1: init.lua 확인**

현재 Hammerspoon init.lua에 Pomodoro 설정이 있는지 확인

Run: `grep -n "Pomodoro\|FocusTracker" users/shared/.config/hammerspoon/init.lua`

**Step 2: FocusTracker 테스트 설정 추가 계획**

init.lua에 다음 설정을 추가할 위치를 파악:

```lua
hs.loadSpoon("FocusTracker")

spoon.FocusTracker:init({
  onFocusStart = function(focusModeName)
    hs.alert.show("🔵 " .. focusModeName, 2)
  end,

  onFocusEnd = function(focusModeName, durationInSeconds)
    local minutes = math.floor(durationInSeconds / 60)
    local seconds = durationInSeconds % 60
    local timeStr
    if minutes == 0 then
      timeStr = string.format("%d초", seconds)
    else
      timeStr = string.format("%d분 %d초", minutes, seconds)
    end

    hs.alert.show(focusModeName .. "\n" .. timeStr, 3)
  end
}):start()
```

**Step 3: 테스트 계획 문서화**

다음 테스트 시나리오 준비:
1. Hammerspoon 재로드
2. Focus Mode 켜기 → "🔵 Deep Work" 알림 확인
3. Menubar에 "🔵 0:05" 같은 카운터 확인
4. Focus Mode 끄기 → "Deep Work\n5분 30초" 알림 확인
5. Menubar "🔵 Ready"로 돌아옴 확인

**Step 4: Commit (테스트 설정은 아직 추가하지 않음)**

```bash
git add -A
git commit -m "docs: prepare manual testing procedure"
```

---

### Task 20: 최종 검증 및 README 업데이트 (선택사항)

**Files:**
- Create: `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/README.md` (선택사항)

**Step 1: README 작성 (선택사항)**

```markdown
# FocusTracker.spoon

FocusTracker는 macOS의 모든 Focus Mode를 추적하고 집중 시간을 실시간으로 표시하는 Hammerspoon Spoon입니다.

## Features

- 모든 Focus Mode 자동 추적
- 실시간 카운트업 타이머
- Menubar 경과 시간 표시 (🔵 25:30)
- 콜백 기반 알림 시스템

## Requirements

- macOS Sequoia (15.x) or later
- Hammerspoon
- Full Disk Access permission (권장)

## Installation

1. Copy `FocusTracker.spoon` to `~/.hammerspoon/Spoons/`
2. Add configuration to `~/.hammerspoon/init.lua`

## Usage

```lua
hs.loadSpoon("FocusTracker")

spoon.FocusTracker:init({
  onFocusStart = function(focusModeName)
    hs.alert.show("🔵 " .. focusModeName, 2)
  end,

  onFocusEnd = function(focusModeName, durationInSeconds)
    local minutes = math.floor(durationInSeconds / 60)
    local seconds = durationInSeconds % 60
    local timeStr = minutes == 0
      and string.format("%d초", seconds)
      or string.format("%d분 %d초", minutes, seconds)

    hs.alert.show(focusModeName .. "\n" .. timeStr, 3)
  end
}):start()
```

## API

- `FocusTracker:init(config)` - Configure callbacks
- `FocusTracker:start()` - Start tracking
- `FocusTracker:stop()` - Stop tracking

## License

MIT
```

**Step 2: Commit (선택사항)**

```bash
git add users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/README.md
git commit -m "docs: add FocusTracker README"
```

---

## Testing Checklist

수동 테스트 체크리스트:

- [ ] Hammerspoon 재로드 후 에러 없이 시작
- [ ] Menubar에 "🔵 Ready" 표시
- [ ] Focus Mode 켜기 → 시작 알림 표시
- [ ] Menubar 카운터 실시간 업데이트 (1초마다)
- [ ] Focus Mode 끄기 → 종료 알림 (시간 포함)
- [ ] Menubar "🔵 Ready"로 복구
- [ ] 다른 Focus Mode로 전환 → 올바른 이름 표시
- [ ] Hammerspoon 재시작 후에도 정상 작동

## Notes

- Pomodoro.spoon과 동시에 사용 가능 (충돌하지 않음)
- 통계는 추적하지 않으므로 과거 데이터는 저장되지 않음
- Full Disk Access 권한이 없으면 Focus Mode 이름이 "Focus Mode"로 표시됨
