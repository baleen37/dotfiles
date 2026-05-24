# FocusTracker.spoon Design

**Date**: 2025-12-11
**Author**: Jiho Hwang

## Overview

FocusTracker.spoon은 macOS의 모든 Focus Mode를 추적하고 집중 시간을 실시간으로 표시하는 Hammerspoon Spoon입니다. Pomodoro.spoon의 코드를 기반으로 하되, 특정 Focus Mode가 아닌 모든 Focus Mode를 추적하고 통계 대신 실시간 추적에 집중합니다.

## Requirements

### Core Features

- **모든 Focus Mode 추적**: 특정 모드가 아닌 macOS의 모든 Focus Mode 추적
- **실시간 카운트업**: 0초부터 시작하여 1초마다 증가하는 타이머
- **Menubar 표시**: 고정 아이콘 "🔵 25:30" 형식으로 현재 경과 시간 표시
- **알림**:
  - 시작 시: "🔵 {Focus Mode 이름}"
  - 종료 시: "{Focus Mode 이름}\n{시간}" (예: "Deep Work\n25분 30초")
- **중단 처리**: 정상 종료든 중간에 Focus Mode를 끄든 동일하게 처리

### Non-Features

- 통계 추적 없음 (과거 데이터 저장 안 함)
- Menubar 클릭 시 메뉴 없음
- 수동 시작/중지 없음 (Focus Mode에만 반응)
- 핫키 바인딩 없음

## Architecture

### State Management

```lua
State = {
  isTracking = false,      -- 현재 추적 중인지
  elapsedTime = 0,         -- 경과 시간 (초)
  currentFocusMode = nil,  -- 현재 Focus Mode 이름
  startTime = nil          -- 시작 시각 (os.time())
}
```

### Configuration

```lua
obj.config = {
  onFocusStart = nil,  -- function(focusModeName)
  onFocusEnd = nil     -- function(focusModeName, durationInSeconds)
}
```

### Component Overview

Pomodoro.spoon의 구조를 유지하되 핵심 동작 방식을 변경:

**유지되는 컴포넌트:**

- `FocusManager`: JXA 기반 Focus Mode 감지 및 DistributedNotificationCenter 이벤트 모니터링
- `UI.menubarItem`: 상태 표시용 menubar item
- `formatTime()`: 시간 포맷팅 함수

**제거되는 컴포넌트:**

- 통계 관련 모든 코드 (`State.sessionsCompleted`, `Cache`, `saveCurrentStatistics()`, etc.)
- `buildMenuTable()` 및 menubar 클릭 콜백
- `config.workDuration`, `config.breakDuration`, `config.focusMode`
- Pomodoro 전용 콜백 (`onWorkStart`, `onBreakStart`, `onComplete`, `onStopped`)
- `showNotification()` - 콜백으로 대체

**변경되는 컴포넌트:**

- `TimerManager`: 카운트다운 → 카운트업으로 변경
- `FocusManager`: 특정 모드 필터링 제거

## Implementation Details

### TimerManager

순수하게 타이머 로직만 담당. UI 처리는 하지 않고 콜백만 호출.

```lua
function TimerManager.startTracking()
  State.isTracking = true
  State.elapsedTime = 0
  State.startTime = os.time()
  State.currentFocusMode = FocusManager.getCurrentFocusMode()

  if not State.currentFocusMode then
    State.currentFocusMode = "Focus Mode"
  end

  -- 콜백만 호출
  if obj.config.onFocusStart then
    obj.config.onFocusStart(State.currentFocusMode)
  end

  UI.countdownTimer = hs.timer.new(1, function()
    State.elapsedTime = State.elapsedTime + 1
    updateMenubarDisplay()
  end)
  UI.countdownTimer:start()
end

function TimerManager.stopTracking()
  local duration = State.elapsedTime
  local focusName = State.currentFocusMode

  TimerManager.cleanup()

  State.isTracking = false
  State.elapsedTime = 0
  State.currentFocusMode = nil
  State.startTime = nil

  -- 콜백만 호출
  if obj.config.onFocusEnd then
    obj.config.onFocusEnd(focusName, duration)
  end
end
```

### FocusManager

특정 Focus Mode 필터링을 제거하고 모든 Focus Mode에 반응:

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

### UI Management

Menubar 표시는 단순화하고, 메뉴는 완전히 제거:

```lua
function updateMenubarDisplay()
  if not UI.menubarItem then return end

  if not State.isTracking then
    UI.menubarItem:setTitle("🔵 Ready")
  else
    UI.menubarItem:setTitle("🔵 " .. formatTime(State.elapsedTime))
  end
end
```

Menubar 초기화 시 클릭 콜백 설정하지 않음:

```lua
function obj:start()
  local success, menubar = pcall(function()
    return hs.menubar.new()
  end)
  if not success or not menubar then
    hs.alert.show("Failed to create menubar item for FocusTracker")
    return self
  end
  UI.menubarItem = menubar

  -- 메뉴 콜백 없음 (클릭해도 반응 없음)

  FocusManager.startMonitoring()
  updateMenubarDisplay()

  -- 현재 Focus Mode가 이미 활성화되어 있으면 추적 시작
  if FocusManager.getCurrentFocusMode() then
    TimerManager.startTracking()
    updateMenubarDisplay()
  end

  return self
end
```

### Public API

```lua
-- 설정 (콜백 등)
FocusTracker:init(config)

-- Spoon 시작
FocusTracker:start()

-- Spoon 중지
FocusTracker:stop()
```

제거되는 API:

- `bindHotkeys()` - 수동 제어 없음
- `getStatistics()` - 통계 추적 안 함
- `toggleSession()` - 수동 제어 없음
- `isRunning()`, `getTimeLeft()`, `isBreak()` - 필요 시 추가 가능

## Edge Cases & Error Handling

### Focus Mode 빠른 전환

사용자가 Focus Mode를 빠르게 껐다 켰다 하는 경우, 각각 별도 세션으로 처리. `handleFocusChange()`에서 현재 상태를 확인하여 중복 방지.

### Focus Mode 이름 nil 처리

JXA가 실패하거나 권한 문제로 Focus Mode 이름을 가져오지 못할 경우 "Focus Mode"로 폴백.

### macOS 권한 문제

Full Disk Access 권한이 필요하지만, 권한이 없어도 작동 (DistributedNotificationCenter는 권한 불필요). 다만 Focus Mode 이름을 알 수 없어서 "Focus Mode"로 표시.

### Spoon 재시작

`obj:stop()` 호출 시 또는 Hammerspoon 재시작 시 추적 중이던 세션은 저장되지 않고 사라짐 (통계 추적 안 하므로 문제없음).

## Usage Example

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

## Comparison with Pomodoro.spoon

| 기능         | Pomodoro                        | FocusTracker                 |
| ------------ | ------------------------------- | ---------------------------- |
| Focus Mode   | 특정 모드만 ("Pomodoro")        | 모든 모드                    |
| 타이머       | 고정 시간 카운트다운 (25분/5분) | 실시간 카운트업              |
| 통계         | 일일 세션 수 추적               | 추적 안 함                   |
| Menubar 메뉴 | 있음 (상태, 통계, 리셋 등)      | 없음                         |
| 알림         | 내장 (`showNotification()`)     | 콜백으로만                   |
| 수동 제어    | 가능 (핫키, 메뉴)               | 불가능 (Focus Mode에만 반응) |

## Requirements

- macOS Sequoia (15.x) or later
- Full Disk Access permission for Hammerspoon (권장)
- Hammerspoon

## Implementation Approach

Pomodoro.spoon의 `init.lua`를 복사하여 다음 순서로 수정:

1. Metadata 업데이트 (name, description, etc.)
2. Config 및 State 구조 변경
3. 통계 관련 코드 제거
4. TimerManager 로직 변경 (카운트다운 → 카운트업)
5. FocusManager 로직 변경 (특정 모드 → 모든 모드)
6. UI 로직 단순화 (메뉴 제거)
7. 공개 API 정리
8. docs.json 업데이트
