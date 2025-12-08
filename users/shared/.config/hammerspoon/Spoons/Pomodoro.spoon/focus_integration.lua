--- === Focus Integration ===
---
--- Focus Mode 통합 모듈
--- macOS Focus Mode 'Pomodoro'와 Hammerspoon Pomodoro 스푼 간의 양방향 동기화
---
--- Features:
--- - Focus Mode 상태 감지 (hs.focus 모듈 사용)
--- - Focus Mode 제어 (Shortcuts 통한 간접 제어)
--- - 무한 루프 방지를 위한 디바운싱 및 내부 상태 추적
--- - 양방향 동기화 지원

local obj = {}
obj.__index = obj

-- 상수
local POMODORO_FOCUS_NAME = "Pomodoro"
local DEBOUNCE_DELAY = 1.0  -- 1초 디바운싱
local FOCUS_CONTROL_SHORTCUT = "EnablePomodoroFocus"
local FOCUS_DISABLE_SHORTCUT = "DisablePomodoroFocus"

-- 내부 상태
local internalState = {
  isPomodoroFocusActive = false,
  lastChangeTime = 0,
  isInternalChange = false,
  watcher = nil,
  callbacks = {},
}

-- Helper functions

local function getCurrentTimestamp()
  return os.time()
end

local function shouldProcessChange()
  local now = getCurrentTimestamp()
  return (now - internalState.lastChangeTime) >= DEBOUNCE_DELAY
end

local function setInternalChangeFlag(flag)
  internalState.isInternalChange = flag
  if flag then
    internalState.lastChangeTime = getCurrentTimestamp()
  end
end

local function notifyCallbacks(isActive)
  for _, callback in ipairs(internalState.callbacks) do
    pcall(callback, isActive)
  end
end

local function log(message, debugOnly)
  if debugOnly == nil or debugOnly == false then
    print("[FocusIntegration] " .. message)
  end
end

-- Private functions

local function onFocusModeChanged(focusModes)
  if internalState.isInternalChange or not shouldProcessChange() then
    return
  end

  local wasActive = internalState.isPomodoroFocusActive
  local isActive = false

  -- hs.focus 모듈이 있는지 확인
  if hs.focus then
    -- Focus Mode 상태 확인
    for _, mode in ipairs(focusModes or {}) do
      if mode.name == POMODORO_FOCUS_NAME then
        isActive = mode.active
        break
      end
    end
  else
    -- Fallback: AppleScript를 사용한 상태 확인
    isActive = obj.getCurrentFocusState()
  end

  if wasActive ~= isActive then
    log("Focus Mode state changed: " .. (isActive and "active" or "inactive"))
    internalState.isPomodoroFocusActive = isActive
    notifyCallbacks(isActive)
  end
end

-- Public API

--- Focus Integration 초기화
function obj.init(pomodoroSpoon)
  -- hs.focus 모듈 사용 가능 여부 확인
  if hs.focus then
    log("Using hs.focus module for Focus Mode detection")

    -- Focus Mode watcher 설정
    if internalState.watcher then
      internalState.watcher:stop()
    end

    -- 현재 상태 확인
    local currentModes = hs.focus.getFocusModes()
    internalState.isPomodoroFocusActive = obj.isPomodoroActive(currentModes)

    -- watcher 설정
    internalState.watcher = hs.focus.new(onFocusModeChanged)
  else
    log("hs.focus module not available, using fallback detection")
    obj.setupFallbackDetection(pomodoroSpoon)
  end

  return obj
end

--- Fallback 감지 설정 (hs.focus가 없을 때)
function obj.setupFallbackDetection(pomodoroSpoon)
  local lastKnownState = obj.getCurrentFocusState()
  internalState.isPomodoroFocusActive = lastKnownState

  hs.timer.doEvery(2.0, function()
    local currentState = obj.getCurrentFocusState()
    if currentState ~= lastKnownState then
      log("Fallback detected state change: " .. tostring(currentState))
      lastKnownState = currentState
      internalState.isPomodoroFocusActive = currentState
      notifyCallbacks(currentState)

      -- Pomodoro 스푼과 동기화
      if pomodoroSpoon then
        if currentState and not pomodoroSpoon:isRunning() then
          pomodoroSpoon:startSession()
        elseif not currentState and pomodoroSpoon:isRunning() then
          pomodoroSpoon:stopSession()
        end
      end
    end
  end)
end

--- 현재 Focus 상태 확인 (fallback용)
function obj.getCurrentFocusState()
  -- AppleScript를 사용한 Focus 상태 확인
  local script = string.format([[
    tell application "System Events"
      tell process "ControlCenter"
        try
          return value of menu bar item "%s" of menu bar 1
        on error
          return false
        end try
      end tell
    end tell
  ]], POMODORO_FOCUS_NAME)

  -- hs.osascript 모듈이 있는지 확인
  if hs.osascript then
    local success, result = hs.osascript.applescript(script)
    if success then
      return result == 1 or result == true
    end
  end

  -- fallback: false 반환
  return false
end

--- Focus Mode 목록에서 Pomodoro 활성 상태 확인
function obj.isPomodoroActive(focusModes)
  if not focusModes then return false end

  for _, mode in ipairs(focusModes) do
    if mode.name == POMODORO_FOCUS_NAME then
      return mode.active
    end
  end
  return false
end

--- Focus Integration 정리
function obj.cleanup()
  if internalState.watcher then
    internalState.watcher:stop()
    internalState.watcher = nil
  end

  -- Reset all internal state
  internalState.isPomodoroFocusActive = false
  internalState.lastChangeTime = 0
  internalState.isInternalChange = false
  internalState.callbacks = {}
  return obj
end

--- Focus Mode 상태 확인
function obj.isPomodoroFocusActive()
  return internalState.isPomodoroFocusActive
end

--- Focus Mode 활성화 (Shortcuts 통한 간접 제어)
function obj.enablePomodoroFocus()
  if not shouldProcessChange() then
    return false
  end

  setInternalChangeFlag(true)

  -- Shortcuts 실행
  local url = "shortcuts://run-shortcut?name=" .. FOCUS_CONTROL_SHORTCUT
  local result = hs.urlevent.openURL(url)

  if result then
    internalState.isPomodoroFocusActive = true
    notifyCallbacks(true)
  end

  -- 내부 변경 플래그 나중에 해제
  hs.timer.doAfter(DEBOUNCE_DELAY, function()
    setInternalChangeFlag(false)
  end)

  return result
end

--- Focus Mode 비활성화 (Shortcuts 통한 간접 제어)
function obj.disablePomodoroFocus()
  if not shouldProcessChange() then
    return false
  end

  setInternalChangeFlag(true)

  -- Shortcuts 실행
  local url = "shortcuts://run-shortcut?name=" .. FOCUS_DISABLE_SHORTCUT
  local result = hs.urlevent.openURL(url)

  if result then
    internalState.isPomodoroFocusActive = false
    notifyCallbacks(false)
  end

  -- 내부 변경 플래그 나중에 해제
  hs.timer.doAfter(DEBOUNCE_DELAY, function()
    setInternalChangeFlag(false)
  end)

  return result
end

--- Focus Mode 토글
function obj.togglePomodoroFocus()
  if internalState.isPomodoroFocusActive then
    return obj.disablePomodoroFocus()
  else
    return obj.enablePomodoroFocus()
  end
end

--- Focus Mode 상태 변경 콜백 등록
function obj.onFocusModeChanged(callback)
  if type(callback) == "function" then
    table.insert(internalState.callbacks, callback)
    return true
  end
  return false
end

--- 콜백 제거
function obj.removeFocusModeCallback(callback)
  for i, cb in ipairs(internalState.callbacks) do
    if cb == callback then
      table.remove(internalState.callbacks, i)
      return true
    end
  end
  return false
end

--- 디버그 정보 반환
function obj.getDebugInfo()
  return {
    isActive = internalState.isPomodoroFocusActive,
    lastChangeTime = internalState.lastChangeTime,
    isInternalChange = internalState.isInternalChange,
    hasWatcher = internalState.watcher ~= nil,
    callbackCount = #internalState.callbacks,
    hasFocusModule = hs.focus ~= nil
  }
end

--- 현재 Focus Mode 목록 반환 (디버그용)
function obj.getCurrentFocusModes()
  if hs.focus then
    return hs.focus.getFocusModes()
  end
  return {}
end

return obj