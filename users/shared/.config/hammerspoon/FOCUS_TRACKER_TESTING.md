# FocusTracker Spoon Testing Guide

이 가이드는 Hammerspoon FocusTracker Spoon의 수동 테스트 방법을 안내합니다.

## 전제 조건

1. FocusTracker.spoon이 `users/shared/.config/hammerspoon/Spoons/FocusTracker.spoon/`에 설치되어 있어야 합니다
2. Hammerspoon 설정을 다시 로드해야 합니다 (`hs.reload()`)

## 테스트 환경 설정

### 1. Focus Mode 준비

macOS 설정에서 여러 Focus Mode를 생성합니다:
- **Work** - 업무용 Focus Mode
- **Deep Work** - 깊은 집중용 Focus Mode
- **Reading** - 독서용 Focus Mode
- **Meeting** - 회의용 Focus Mode

### 2. init.lua에 테스트 설정 추가

아래 코드를 init.lua의 기존 Pomodoro 설정 아래에 추가합니다:

```lua
-- Initialize FocusTracker Spoon for testing
FocusTracker = spoon.FocusTracker
FocusTracker:init({
  onFocusStart = function(focusMode)
    hs.alert.show("🎯 " .. focusMode .. " 시작!\n집중 시간을 추적합니다", 1.5)
  end,
  onFocusEnd = function(focusMode, duration)
    local minutes = math.floor(duration / 60)
    local seconds = duration % 60
    hs.alert.show(string.format("⏹️ %s 종료!\n집중 시간: %d분 %d초", focusMode, minutes, seconds), 2)
  end
}):start()
```

## 테스트 시나리오

### 테스트 1: Hammerspoon 리로드

**목표**: FocusTracker가 올바르게 로드되는지 확인

**절차**:
1. Hammerspoon 콘솔 열기 (`⌘ + ⌥ + 0`)
2. `hs.reload()` 실행
3. 콘솔 출력 확인
   - "FocusTracker loaded successfully" 메시지 확인
   - 에러 메시지 없는지 확인
4. 메뉴바에 "🔵 Ready" 아이콘이 표시되는지 확인

**예상 결과**:
- 메뉴바에 파란색 원 아이콘 표시
- 아이콘에 마우스를 올리면 "Focus Tracker: Ready" 툴팁 표시

### 테스트 2: Focus Mode 시작 감지

**목표**: Focus Mode 활성화시 카운트다운 시작 확인

**절차**:
1. macOS Control Center 열기
2. Focus Mode 중 하나 선택 (예: "Work")
3. 다음 사항들 확인:
   - "🎯 Work 시작!" 알림이 표시됨
   - 메뉴바 아이콘이 즉시 "🔵 0m 0s"로 변경됨
   - 1초 후 "🔵 0m 1s"로 업데이트됨

**예상 결과**:
- 시작 알림 표시
- 메뉴바에 실시간 카운트업 표시
- 초 단위로 정확한 업데이트

### 테스트 3: 실시간 업데이트 확인

**목표**: 메뉴바 표시가 정확하게 업데이트되는지 확인

**절차**:
1. Focus Mode 활성화된 상태에서 30초 이상 대기
2. 메뉴바 표시 확인:
   - 30초 후: "🔵 0m 30s"
   - 1분 후: "🔵 1m 0s"
   - 1분 30초 후: "🔵 1m 30s"
   - 2분 후: "🔵 2m 0s"

**예상 결과**:
- 초 단위로 부드러운 업데이트
- 분/초 형식이 올바르게 표시
- 아이콘이 일관되게 유지됨

### 테스트 4: Focus Mode 전환

**목표**: 다른 Focus Mode로 전환 시 동작 확인

**절차**:
1. "Work" Focus Mode에서 1분 이상 실행
2. "Deep Work" Focus Mode로 전환
3. 확인 사항:
   - "🎯 Deep Work 시작!" 알림 표시
   - 이전 시간(1분 이상)이 유지됨
   - 새 Focus Mode 이름이 표시됨
   - 카운트업이 계속됨

**예상 결과**:
- 전환 알림 표시
- 시간 리셋되지 않고 계속 추적

### 테스트 5: Focus Mode 종료

**목표**: Focus Mode 비활성화시 종료 알림 확인

**절차**:
1. Focus Mode를 2분 이상 실행
2. Control Center에서 Focus Mode 끄기
3. 확인 사항:
   - 종료 알림 표시 (예: "⏹️ Work 종료!\n집중 시간: 2분 15초")
   - 메뉴바가 "🔵 Ready"로 복귀
   - 정확한 시간이 표시됨

**예상 결과**:
- 정확한 집중 시간 알림
- 메뉴바 초기 상태 복귀

### 테스트 6: 여러 Focus Mode 순차적 사용

**목표**: 여러 Focus Mode를 순차적으로 사용할 때의 동작 확인

**절차**:
1. "Work" Focus Mode: 1분 실행
2. "Reading" Focus Mode로 전환: 1분 실행
3. "Meeting" Focus Mode로 전환: 30초 실행
4. Focus Mode 끄기
5. 확인 사항:
   - 각 전환 시 시작 알림 표시
   - 시간이 누적되지 않고 각 세션별로 추적
   - 종료 시 마지막 Focus Mode의 총 시간 표시

**예상 결과**:
- 각 Focus Mode 독립 추적
- 올바른 전환 동작

### 테스트 7: Pomodoro와 동시 실행

**목표**: Pomodoro.spoon과 충돌 없이 동시 실행 확인

**절차**:
1. Hyper+P로 Pomodoro 세션 시작
2. 1분 후 Focus Mode 활성화
3. 확인 사항:
   - 두 Spoon 모두 정상 실행
   - 메뉴바에 각각 다른 아이콘 표시
   - 알림이 서로 겹치지 않음

**예상 결과**:
- 두 Spoon 독립적으로 동작
- 리소스 충돌 없음

## 디버깅 명령어

Hammerspoon 콘솔에서 사용할 수 있는 유용한 명령어들:

```lua
-- FocusTracker 상태 확인
print("Timer running:", spoon.FocusTracker.timerRunning)
print("Current focus:", spoon.FocusTracker.currentFocus)
print("Elapsed time:", spoon.FocusTracker.elapsedTime)
print("Menubar title:", spoon.FocusTracker.menubar:title())

-- 수동으로 테스트
spoon.FocusTracker:_startFocus("TestMode")
spoon.FocusTracker:_endFocus()

-- 통계 정보 확인
print("Stats:", hs.inspect(hs.settings.get("focustracker.stats")))
```

## 문제 해결

### 일반적인 문제

1. **아이콘이 표시되지 않음**
   - Hammerspoon 재시작
   - `hs.reload()` 실행
   - 메뉴바 아이콘 숨김 설정 확인

2. **알림이 표시되지 않음**
   - macOS 알림 설정 확인
   - Hammerspoon 알림 권한 확인

3. **시간이 업데이트되지 않음**
   - 타이머 상태 확인: `spoon.FocusTracker.timerRunning`
   - Focus Mode 변경 감지 확인

### 로그 확인

Hammerspoon 콘솔에서 다음을 실행하여 자세한 로그 확인:

```lua
-- 디버그 모드 활성화
spoon.FocusTracker.debug = true

-- 핵심 함수 직접 테스트
spoon.FocusTracker:_updateUI()
```

## 테스트 완료 후

테스트가 완료되면 테스트 설정 코드를 init.lua에서 제거하거나 주석 처리하세요:

```lua
--[[
-- Initialize FocusTracker Spoon for testing
FocusTracker = spoon.FocusTracker
-- ... 테스트 설정 코드 ...
--]]
```
