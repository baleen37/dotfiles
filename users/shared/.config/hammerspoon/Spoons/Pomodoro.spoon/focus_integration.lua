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
  timers = {},  -- 활성 타이머들을 추적하기 위한 배열
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

-- 타이머 정리 함수
local function cleanupTimers()
  for _, timer in ipairs(internalState.timers) do
    if timer then
      timer:stop()
    end
  end
  internalState.timers = {}
end

-- 타이머를 생성하고 추적하는 헬퍼 함수
local function scheduleDelayedCall(delay, fn)
  local timer = hs.timer.doAfter(delay, function()
    -- 타이머 완료 후 목록에서 제거
    for i, t in ipairs(internalState.timers) do
      if t == timer then
        table.remove(internalState.timers, i)
        break
      end
    end
    fn()
  end)

  table.insert(internalState.timers, timer)
  return timer
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

  -- Focus Mode 모듈이 있는지 확인 (macOS 14+와 Hammerspoon 0.9.90+ 필요)
  -- 참고: hs.focus는 포어그라운드 함수이므로 Focus Mode API와는 다름
  if false then -- Focus Mode API가 현재 설치되지 않았으므로 일단 비활성화
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
  -- Focus Mode 모듈 사용 가능 여부 확인
  -- 참고: 현재 Hammerspoon 버전에서는 Focus Mode API를 사용할 수 없음
  if false then -- Focus Mode API가 현재 설치되지 않았으므로 일단 비활성화
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

  -- timer를 internalState에 저장하여 추적
  local fallbackTimer = hs.timer.doEvery(2.0, function()
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

  internalState.fallbackTimer = fallbackTimer
end

--- 현재 Focus 상태 확인 (fallback용)
function obj.getCurrentFocusState()
  -- AppleScript를 사용한 Focus 상태 확인
  -- ControlCenter가 메뉴 막대에 없는 경우를 대비한 여러 방법 시도
  local scripts = {
    -- 방법 1: ControlCenter 메뉴 막대 아이템 확인
    string.format([[
      tell application "System Events"
        tell process "ControlCenter"
          try
            return value of menu bar item "%s" of menu bar 1
          on error errMsg
            log "ControlCenter error: " & errMsg
            return "not_found"
          end try
        end tell
      end tell
    ]], POMODORO_FOCUS_NAME),

    -- 방법 2: System Preferences.app를 통한 확인
    [[
      tell application "System Events"
        try
          tell application "System Preferences"
            activate
            set the pane to pane id "com.apple.preference.dock"
            tell window "Dock \\& Menu Bar"
              try
                return selected of row 1 of table 1 of scroll area 1 of group "Focus Modes"
              on error errMsg
                log "Could not find Focus Modes: " & errMsg
                return "not_found"
              end try
            end tell
          end tell
          quit application "System Preferences"
        on error errMsg
          try
            quit application "System Preferences"
          end try
          log "System Preferences error: " & errMsg
          return "not_found"
        end try
      end tell
    ]],

    -- 방법 3: NSWorkspace를 통한 확인 (macOS 12+)
    [[
      tell application "System Events"
        try
          do shell script "defaults read com.apple.controlcenter FocusModePomodoro"
          return "active"
        on error errMsg
          log "Defaults read error: " & errMsg
          return "not_found"
        end try
      end tell
    ]]
  }

  -- hs.osascript 모듈이 있는지 확인
  if hs.osascript then
    -- 각 스크립트 방법 시도
    for i, script in ipairs(scripts) do
      log("Executing script #" .. i .. ", length: " .. string.len(script))
      local success, result = hs.osascript.applescript(script)
      if not success then
        log("Script #" .. i .. " failed: " .. tostring(result))
      else
        if result == 1 or result == true or result == "active" then
          return true
        elseif result == 0 or result == false then
          return false
        end
      end
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
  -- Watcher 정리
  if internalState.watcher then
    internalState.watcher:stop()
    internalState.watcher = nil
  end

  -- Fallback timer 정리
  if internalState.fallbackTimer then
    internalState.fallbackTimer:stop()
    internalState.fallbackTimer = nil
  end

  -- 모든 지연된 타이머 정리
  cleanupTimers()

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
  scheduleDelayedCall(DEBOUNCE_DELAY, function()
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
  scheduleDelayedCall(DEBOUNCE_DELAY, function()
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
    hasFallbackTimer = internalState.fallbackTimer ~= nil,
    activeTimerCount = #internalState.timers,
    callbackCount = #internalState.callbacks,
    hasFocusModule = hs.focus ~= nil
  }
end

--- 현재 Focus Mode 목록 반환 (디버그용)
function obj.getCurrentFocusModes()
  -- 참고: hs.focus는 포어그라운드 함수이므로 Focus Mode API를 제공하지 않음
  return {}
end

return obj