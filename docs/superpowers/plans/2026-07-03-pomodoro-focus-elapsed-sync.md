# Pomodoro Focus 시작시각 보정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** macOS Focus가 켜진 실제 시각을 기준으로 Pomodoro 타이머의 남은 시간·단계를 보정한다.

**Architecture:** `Assertions.json`(FDA 필요)에서 현재 Focus 이름과 `assertionStartDateTimestamp`를 읽어, 경과 시간으로 작업/휴식/완료 단계를 계산한다(`computeSyncPlan`). Focus 감지 워쳐와 부팅 경로는 모두 `handleFocusChange()`로 통일되어, focus가 이미 켜져 있던 경우에도 시작시각 기준으로 재동기화한다. 사용자 시작 경로(`startWorkSession`)는 Focus를 직접 켜고 지금부터 25분으로 시작하는 기존 동작을 유지한다.

**Tech Stack:** Lua (Hammerspoon Spoon), JXA(osascript), Nix(content-assertion 통합 테스트).

## Global Constraints

- 대상 파일: `users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua`, `tests/integration/hammerspoon-test.nix`.
- Cocoa→Unix 변환 오프셋: `978307200` (초, 1970↔2001).
- `workDuration = 25*60`, `breakDuration = 5*60` (obj.config에서 참조; 하드코딩 금지).
- 완료(`elapsed ≥ workDuration+breakDuration`) 처리 = 타이머 idle + `saveCurrentStatistics()`, **완료 카운트 증가 없음**.
- Focus 감지 경로(syncFromFocus)는 **`activatePomodoroFocus()`를 호출하지 않는다**(focus 이미 켜짐).
- 런타임 검증은 `hs` CLI(IPC)로 수행. HS가 실행 중이어야 하며 각 코드 변경 후 `hs -c 'hs.reload()'`로 재적재한다.
- 코드 스타일은 기존 파일 관례(2-space 들여쓰기, `TimerManager.`/`FocusManager.`/`obj:` 네임스페이스)를 따른다.
- 계획서의 줄 번호는 **수정 전 기준**이다. 앞 태스크가 함수를 삽입하면 이후 줄 번호가 밀리므로,
  위치는 반드시 각 스텝에 명시된 **함수명/원본 코드 블록**을 앵커로 찾는다.

---

## File Structure

- `Spoons/Pomodoro.spoon/init.lua`
  - `computeSyncPlan(elapsed, workDuration, breakDuration)` — 순수 함수, 단계/남은시간 계산 (신규, 유틸 영역).
  - `TimerManager.completeSession/runWork/runBreak` — 타이머 구동 저수준 헬퍼 (신규, 기존 로직 추출).
  - `TimerManager.syncFromFocus(startTime)` — 보정 진입점 (신규).
  - `TimerManager.startWorkSession/startBreakSession` — 헬퍼 위로 재작성 (수정).
  - `FocusManager.getCurrentFocusInfo()` — 이름+시작시각 (신규); `getCurrentFocusMode()`는 래퍼 (수정).
  - `FocusManager.handleFocusChange/startMonitoring` — 보정 배선 + 워쳐 통일 (수정).
  - `obj:syncFromFocus/obj:currentFocusInfo` — 공개 test seam/introspection (신규).
- `tests/integration/hammerspoon-test.nix` — 신규 함수/배선 content assertion 추가 (수정).

---

## Task 1: 타이머 구동 로직을 재사용 헬퍼로 추출 (동작 변경 없음)

**Files:**
- Modify: `users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua:535-589`
- Test: `tests/integration/hammerspoon-test.nix`

**Interfaces:**
- Produces:
  - `TimerManager.completeSession()` — 세션 완료 처리(카운트++, stop, 통계저장, 모달, onComplete).
  - `TimerManager.runWork(timeLeft, sessionStartTime)` — 작업 카운트다운 시작(완료 시 startBreakSession).
  - `TimerManager.runBreak(timeLeft)` — 휴식 카운트다운 시작(완료 시 completeSession).
  - `TimerManager.startWorkSession()` — 사용자 시작(Focus 켜기 + 지금부터 workDuration).
  - `TimerManager.startBreakSession()` — 휴식 세션 시작.

- [ ] **Step 1: 기존 `startWorkSession`/`startBreakSession`(535-589)을 헬퍼 기반으로 교체**

`init.lua`의 535–589행(아래 원본)을 통째로 교체한다.

원본(참고):
```lua
function TimerManager.startWorkSession()
  TimerManager.cleanup()

  State.isBreak = false
  State.timeLeft = obj.config.workDuration
  State.timerRunning = true
  State.sessionStartTime = os.time()

  activatePomodoroFocus()
  updateMenubarDisplay()

  -- Create overlay if not exists
  if not UI.overlayCanvas then
    OverlayManager.create()
  end

  ModalManager.show("Work session begins!", "🍅", 2)

  -- Callback: onWorkStart
  if obj.config.onWorkStart then
    obj.config.onWorkStart()
  end

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(TimerManager.startBreakSession))
  UI.countdownTimer:start()
end

function TimerManager.startBreakSession()
  TimerManager.cleanup()

  State.isBreak = true
  State.timeLeft = obj.config.breakDuration
  State.timerRunning = true

  updateMenubarDisplay()
  ModalManager.show("25 minutes complete! Take a break", "🍅", 2)

  -- Callback: onBreakStart
  if obj.config.onBreakStart then
    obj.config.onBreakStart()
  end

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(function()
    State.sessionsCompleted = State.sessionsCompleted + 1
    TimerManager.stop()
    saveCurrentStatistics()
    ModalManager.show("Session complete! Great job", "✅", 2)

    -- Callback: onComplete
    if obj.config.onComplete then
      obj.config.onComplete()
    end
  end))
  UI.countdownTimer:start()
end
```

교체 후:
```lua
function TimerManager.completeSession()
  State.sessionsCompleted = State.sessionsCompleted + 1
  TimerManager.stop()
  saveCurrentStatistics()
  ModalManager.show("Session complete! Great job", "✅", 2)

  -- Callback: onComplete
  if obj.config.onComplete then
    obj.config.onComplete()
  end
end

function TimerManager.runWork(timeLeft, sessionStartTime)
  TimerManager.cleanup()

  State.isBreak = false
  State.timeLeft = timeLeft
  State.timerRunning = true
  State.sessionStartTime = sessionStartTime

  updateMenubarDisplay()

  -- Create overlay if not exists
  if not UI.overlayCanvas then
    OverlayManager.create()
  end

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(TimerManager.startBreakSession))
  UI.countdownTimer:start()
end

function TimerManager.runBreak(timeLeft)
  TimerManager.cleanup()

  State.isBreak = true
  State.timeLeft = timeLeft
  State.timerRunning = true

  updateMenubarDisplay()

  UI.countdownTimer = hs.timer.new(1, TimerManager.createCallback(TimerManager.completeSession))
  UI.countdownTimer:start()
end

function TimerManager.startWorkSession()
  activatePomodoroFocus()
  TimerManager.runWork(obj.config.workDuration, os.time())

  ModalManager.show("Work session begins!", "🍅", 2)

  -- Callback: onWorkStart
  if obj.config.onWorkStart then
    obj.config.onWorkStart()
  end
end

function TimerManager.startBreakSession()
  TimerManager.runBreak(obj.config.breakDuration)

  ModalManager.show("25 minutes complete! Take a break", "🍅", 2)

  -- Callback: onBreakStart
  if obj.config.onBreakStart then
    obj.config.onBreakStart()
  end
end
```

- [ ] **Step 2: 런타임 재적재 후 사용자 시작 경로 동작 확인 (회귀 없음)**

Run:
```bash
hs -c 'hs.reload()' && sleep 1
hs -c 'spoon.Pomodoro:toggleSession(); return string.format("run=%s break=%s left=%d", tostring(spoon.Pomodoro:isRunning()), tostring(spoon.Pomodoro:isBreak()), spoon.Pomodoro:getTimeLeft())'
```
Expected: `run=true break=false left=1500` (± 1). 이후 정리:
```bash
hs -c 'spoon.Pomodoro:toggleSession(); return tostring(spoon.Pomodoro:isRunning())'
```
Expected: `false`

> 주의: `toggleSession()`은 `startWorkSession`→`activatePomodoroFocus()`로 실제 Focus 단축키를 실행한다. 테스트 후 Focus가 켜졌으면 수동으로 꺼둔다.

- [ ] **Step 3: content assertion 추가**

`tests/integration/hammerspoon-test.nix`의 Section 3 마지막 assertion(163-165행의 `hyper-spoon-structure`) **앞**에 다음을 추가:
```nix
    (helpers.assertTest "pomodoro-timer-helpers-extracted" (
      lib.hasInfix "function TimerManager.completeSession()" pomodoroInitContent
      && lib.hasInfix "function TimerManager.runWork(" pomodoroInitContent
      && lib.hasInfix "function TimerManager.runBreak(" pomodoroInitContent
    ) "Pomodoro Spoon should expose reusable timer helpers")

```

- [ ] **Step 4: 테스트 실행**

Run: `USER=$(whoami) make test`
Expected: PASS (hammerspoon 통합 테스트 포함, 실패 assertion 없음)

- [ ] **Step 5: 커밋**

```bash
git add users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua tests/integration/hammerspoon-test.nix
git commit -m "refactor(pomodoro): extract reusable timer helpers"
```

---

## Task 2: 순수 보정 계산 + `syncFromFocus` 진입점

**Files:**
- Modify: `users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua` (유틸 영역 ~94행, TimerManager 영역, obj 메서드 영역)
- Test: `tests/integration/hammerspoon-test.nix`

**Interfaces:**
- Consumes: `TimerManager.runWork`, `TimerManager.runBreak`, `TimerManager.stop`, `saveCurrentStatistics`, `obj.config.workDuration/breakDuration` (Task 1).
- Produces:
  - `computeSyncPlan(elapsed, workDuration, breakDuration) -> { stage = "work"|"break"|"complete", timeLeft = number }` (파일 로컬 순수 함수).
  - `TimerManager.syncFromFocus(startTime)` — startTime(Unix초) 기준 보정. Focus 재점화 없음.
  - `obj:syncFromFocus(startTime) -> obj` — 공개 test seam.

- [ ] **Step 1: 순수 함수 `computeSyncPlan` 추가**

`init.lua`의 `formatTime` 함수(90-94행) **바로 뒤**, `shellQuote`(96행) **앞**에 추가:
```lua
-- Decide the pomodoro phase from elapsed seconds since Focus started.
-- Returns { stage = "work" | "break" | "complete", timeLeft = <seconds> }.
local function computeSyncPlan(elapsed, workDuration, breakDuration)
  if elapsed < 0 then
    elapsed = 0
  end
  if elapsed < workDuration then
    return { stage = "work", timeLeft = workDuration - elapsed }
  elseif elapsed < workDuration + breakDuration then
    return { stage = "break", timeLeft = workDuration + breakDuration - elapsed }
  end
  return { stage = "complete", timeLeft = 0 }
end
```

- [ ] **Step 2: `TimerManager.syncFromFocus` 추가**

Task 1에서 만든 `TimerManager.startBreakSession` 함수 정의 **바로 뒤**에 추가:
```lua
function TimerManager.syncFromFocus(startTime)
  local elapsed = os.time() - (startTime or os.time())
  local plan = computeSyncPlan(elapsed, obj.config.workDuration, obj.config.breakDuration)

  if plan.stage == "work" then
    TimerManager.runWork(plan.timeLeft, startTime)
  elseif plan.stage == "break" then
    TimerManager.runBreak(plan.timeLeft)
  else
    -- 사이클이 이미 끝남: 러닝 상태 해제 + 통계 저장(완료 카운트는 올리지 않음)
    TimerManager.stop()
    saveCurrentStatistics()
  end
end
```

- [ ] **Step 3: 공개 메서드 `obj:syncFromFocus` 추가**

`obj:toggleSession()` 함수 정의(868-876행) **바로 뒤**에 추가:
```lua
--- Pomodoro:syncFromFocus(startTime) -> Pomodoro
--- Method
--- Reconcile the timer to a Focus mode start time (Unix seconds).
--- Picks work/break/complete from elapsed time. Does NOT enable Focus.
---
--- Parameters:
---  * startTime - Unix timestamp (seconds) when the Focus mode started
---
--- Returns:
---  * The Pomodoro object
function obj:syncFromFocus(startTime)
  TimerManager.syncFromFocus(startTime)
  return self
end
```

- [ ] **Step 4: 런타임 경계 검증**

Run:
```bash
hs -c 'hs.reload()' && sleep 1
hs -c 'spoon.Pomodoro:syncFromFocus(os.time() - 60); return string.format("run=%s break=%s left=%d", tostring(spoon.Pomodoro:isRunning()), tostring(spoon.Pomodoro:isBreak()), spoon.Pomodoro:getTimeLeft())'
```
Expected: `run=true break=false left=1440` (±2)
```bash
hs -c 'spoon.Pomodoro:syncFromFocus(os.time() - 26*60); return string.format("run=%s break=%s left=%d", tostring(spoon.Pomodoro:isRunning()), tostring(spoon.Pomodoro:isBreak()), spoon.Pomodoro:getTimeLeft())'
```
Expected: `run=true break=true left=240` (±2)
```bash
hs -c 'spoon.Pomodoro:syncFromFocus(os.time() - 31*60); return string.format("run=%s left=%d", tostring(spoon.Pomodoro:isRunning()), spoon.Pomodoro:getTimeLeft())'
```
Expected: `run=false left=0`

- [ ] **Step 5: content assertion 추가**

Task 1에서 추가한 `pomodoro-timer-helpers-extracted` assertion **뒤**에 추가:
```nix
    (helpers.assertTest "pomodoro-sync-from-focus" (
      lib.hasInfix "local function computeSyncPlan(" pomodoroInitContent
      && lib.hasInfix "function TimerManager.syncFromFocus(" pomodoroInitContent
      && lib.hasInfix "function obj:syncFromFocus(" pomodoroInitContent
    ) "Pomodoro Spoon should reconcile timer state from Focus start time")

```

- [ ] **Step 6: 테스트 실행**

Run: `USER=$(whoami) make test`
Expected: PASS

- [ ] **Step 7: 커밋**

```bash
git add users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua tests/integration/hammerspoon-test.nix
git commit -m "feat(pomodoro): reconcile timer from focus start time"
```

---

## Task 3: Focus 시작시각을 포함한 감지 (`getCurrentFocusInfo`)

**Files:**
- Modify: `users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua:597-630` (getCurrentFocusMode), obj 메서드 영역
- Test: `tests/integration/hammerspoon-test.nix`

**Interfaces:**
- Produces:
  - `FocusManager.getCurrentFocusInfo() -> { name = string, startTime = number|nil } | nil` — 현재 활성 Focus의 이름과 Unix 시작시각.
  - `FocusManager.getCurrentFocusMode() -> string|nil` — `getCurrentFocusInfo().name` 래퍼(기존 인터페이스 유지).
  - `obj:currentFocusInfo() -> table|nil` — 공개 introspection/test seam.

- [ ] **Step 1: `getCurrentFocusMode`(597-630)를 `getCurrentFocusInfo` + 래퍼로 교체**

`init.lua` 597–630행(원본 `function FocusManager.getCurrentFocusMode() ... end`)을 아래로 교체:
```lua
local FOCUS_COCOA_EPOCH_OFFSET = 978307200 -- seconds between 1970-01-01 and 2001-01-01

function FocusManager.getCurrentFocusInfo()
  local script = [[
    (function() {
      const app = Application.currentApplication();
      app.includeStandardAdditions = true;

      function getJSON(path) {
        const fullPath = path.replace(/^~/, app.pathTo('home folder'));
        return JSON.parse(app.read(fullPath));
      }

      try {
        const assertions = getJSON("~/Library/DoNotDisturb/DB/Assertions.json").data[0].storeAssertionRecords;
        const config = getJSON("~/Library/DoNotDisturb/DB/ModeConfigurations.json").data[0].modeConfigurations;

        if (!assertions || assertions.length === 0) {
          return null;
        }

        const record = assertions[0];
        const modeid = record.assertionDetails.assertionDetailsModeIdentifier;
        const name = config[modeid] ? config[modeid].mode.name : null;
        if (!name) {
          return null;
        }
        return JSON.stringify({ name: name, startTimestamp: record.assertionStartDateTimestamp });
      } catch (e) {
        return null;
      }
    })();
  ]]

  local ok, result = hs.osascript.javascript(script)
  if not ok or not result then
    return nil
  end

  local decoded = hs.json.decode(result)
  if not decoded or not decoded.name then
    return nil
  end

  local startTime = nil
  if decoded.startTimestamp then
    startTime = math.floor(decoded.startTimestamp + FOCUS_COCOA_EPOCH_OFFSET)
  end

  return { name = decoded.name, startTime = startTime }
end

function FocusManager.getCurrentFocusMode()
  local info = FocusManager.getCurrentFocusInfo()
  return info and info.name or nil
end
```

> 참고: 활성 레코드는 `storeAssertionRecords[0]`을 사용한다(현재 동작과 동일). `startTime`은 pomodoro 활성이 확인된 뒤(`handleFocusChange`)에만 소비되므로 [0]이 pomodoro임이 보장된다.

- [ ] **Step 2: 공개 introspection 메서드 `obj:currentFocusInfo` 추가**

Task 2에서 추가한 `obj:syncFromFocus` 정의 **바로 뒤**에 추가:
```lua
--- Pomodoro:currentFocusInfo() -> table or nil
--- Method
--- Returns the current macOS Focus mode info, or nil if none is active.
---
--- Returns:
---  * A table `{ name = <string>, startTime = <unix seconds or nil> }`, or nil
function obj:currentFocusInfo()
  return FocusManager.getCurrentFocusInfo()
end
```

- [ ] **Step 3: 런타임 검증 (실제 Focus 필요)**

먼저 Pomodoro Focus를 켠다(예: `hs -c 'hs.execute("/usr/bin/shortcuts run Pomodoro", true)'` 또는 수동). 그런 다음:
```bash
hs -c 'hs.reload()' && sleep 1
hs -c 'local i = spoon.Pomodoro:currentFocusInfo(); if not i then return "nil" end; return string.format("name=%s startAgo=%ds", tostring(i.name), i.startTime and (os.time() - i.startTime) or -1)'
```
Expected: `name=Pomodoro startAgo=<0 이상 초, 방금 켰다면 한 자리~두 자리 초>`

Focus를 끈 상태에서:
```bash
hs -c 'return spoon.Pomodoro:currentFocusInfo() == nil and "nil-ok" or "unexpected"'
```
Expected: `nil-ok`

- [ ] **Step 4: content assertion 추가**

Task 2의 `pomodoro-sync-from-focus` assertion **뒤**에 추가:
```nix
    (helpers.assertTest "pomodoro-focus-info-with-start-time" (
      lib.hasInfix "function FocusManager.getCurrentFocusInfo()" pomodoroInitContent
      && lib.hasInfix "assertionStartDateTimestamp" pomodoroInitContent
      && lib.hasInfix "978307200" pomodoroInitContent
    ) "Pomodoro Spoon should read the Focus start timestamp")

```

- [ ] **Step 5: 테스트 실행**

Run: `USER=$(whoami) make test`
Expected: PASS

- [ ] **Step 6: 커밋**

```bash
git add users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua tests/integration/hammerspoon-test.nix
git commit -m "feat(pomodoro): read focus start timestamp for reconciliation"
```

---

## Task 4: 감지→보정 배선 + 워쳐 통일

**Files:**
- Modify: `users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua:637-675` (handleFocusChange, startMonitoring)
- Test: `tests/integration/hammerspoon-test.nix`

**Interfaces:**
- Consumes: `FocusManager.getCurrentFocusInfo` (Task 3), `TimerManager.syncFromFocus` (Task 2), `obj.config.focusMode`.

- [ ] **Step 1: `handleFocusChange`(637-651)를 보정 기반으로 교체**

`init.lua` 637–651행(원본 `function FocusManager.handleFocusChange() ... end`)을 아래로 교체:
```lua
function FocusManager.handleFocusChange()
  local info = FocusManager.getCurrentFocusInfo()
  local hasPomodoro = info ~= nil and info.name == obj.config.focusMode

  if hasPomodoro then
    if not State.timerRunning then
      TimerManager.syncFromFocus(info.startTime)
    end
  else
    if State.timerRunning then
      ModalManager.show("Pomodoro session stopped", "⏹️", 2)
      saveCurrentStatistics()
      TimerManager.stop()
    end
  end
end
```

- [ ] **Step 2: `startMonitoring`(653-675)의 두 워쳐를 `handleFocusChange` 호출로 통일**

`init.lua` 653–675행(원본 `function FocusManager.startMonitoring() ... end`)을 아래로 교체:
```lua
function FocusManager.startMonitoring()
  -- Focus mode enabled/disabled 모두 현재 focus를 다시 읽어 상태를 재조정한다.
  UI.focusWatcherEnabled = hs.distributednotifications.new(function()
    FocusManager.handleFocusChange()
  end, "_NSDoNotDisturbEnabledNotification")
  UI.focusWatcherEnabled:start()

  UI.focusWatcherDisabled = hs.distributednotifications.new(function()
    FocusManager.handleFocusChange()
  end, "_NSDoNotDisturbDisabledNotification")
  UI.focusWatcherDisabled:start()

  UI.lastKnownFocus = FocusManager.isPomodoroActive()
end
```

- [ ] **Step 3: 통합 런타임 검증 (실제 Focus 토글)**

Pomodoro Focus를 켜고 잠깐(예: 30초 이상) 둔 뒤:
```bash
hs -c 'hs.reload()' && sleep 1
hs -c 'return string.format("run=%s break=%s left=%d", tostring(spoon.Pomodoro:isRunning()), tostring(spoon.Pomodoro:isBreak()), spoon.Pomodoro:getTimeLeft())'
```
Expected: `run=true break=false left=<1500에서 경과초를 뺀 값>` (부팅 경로 `start()`가 자동 보정)

Focus를 끈다(수동 또는 `hs -c 'hs.execute("/usr/bin/shortcuts run Pomodoro", true)'`로 토글 off). 몇 초 후:
```bash
hs -c 'return tostring(spoon.Pomodoro:isRunning())'
```
Expected: `false`

- [ ] **Step 4: content assertion 추가**

Task 3의 `pomodoro-focus-info-with-start-time` assertion **뒤**에 추가:
```nix
    (helpers.assertTest "pomodoro-focus-change-reconciles" (
      lib.hasInfix "TimerManager.syncFromFocus(info.startTime)" pomodoroInitContent
      && lib.hasInfix "FocusManager.handleFocusChange()" pomodoroInitContent
    ) "Focus change should reconcile timer via handleFocusChange")

```

- [ ] **Step 5: 테스트 실행**

Run: `USER=$(whoami) make test`
Expected: PASS

- [ ] **Step 6: 커밋**

```bash
git add users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua tests/integration/hammerspoon-test.nix
git commit -m "feat(pomodoro): sync timer on focus change from start time"
```

---

## 검증 요약 (전체 완료 후)

- `USER=$(whoami) make test` — 통합 테스트 통과.
- 실제 Pomodoro Focus를 N분 전에 켠 상태에서 `hs -c 'hs.reload()'` 후
  `Pomodoro:getTimeLeft()` ≈ `1500 - N*60`인지 확인.
- Focus를 끄면 `Pomodoro:isRunning()`이 `false`가 되는지 확인.
- Hyper+P로 시작하면 Focus가 켜지고 25:00부터 시작하는지 확인(회귀 없음).

## 비고 (테스트 한계)

- 이 저장소에는 Lua 유닛 테스트 러너가 없다. `hammerspoon-test.nix`의 content assertion은
  함수/배선의 존재만 정적으로 확인하며, 실제 동작 검증은 `hs` CLI 런타임 스텝이 담당한다.
- `obj:syncFromFocus`/`obj:currentFocusInfo`는 런타임 검증을 위한 공개 seam이며,
  기존 introspection 메서드(`getStatistics`/`isRunning`/`getTimeLeft`/`isBreak`)와 같은 스타일이다.
