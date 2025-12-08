# Focus Mode 통합 테스트 가이드

이 가이드는 macOS Focus Mode 'Pomodoro'와 Hammerspoon Pomodoro.spoon 간의 양방향 동기화 기능을 테스트하는 방법을 설명합니다.

## 목차

1. [사전 준비 사항](#사전-준비-사항)
2. [권한 설정](#권한-설정)
3. [기본 테스트](#기본-테스트)
4. [고급 테스트](#고급-테스트)
5. [문제 해결](#문제-해결)
6. [검증 단계](#검증-단계)

## 사전 준비 사항

### 시스템 요구사항

- macOS 14 (Sonoma) 이상
- Hammerspoon 0.9.100 이상
- Shortcuts 앱 (기본 설치됨)

### Pomodoro Focus Mode 생성

1. **Settings 앱 열기**
   - `Apple 메뉴` → `System Settings`

2. **Focus Mode 설정**
   - `Focus` 메뉴 선택
   - `Add Focus` 버튼 클릭
   - `Custom` 선택
   - 이름으로 `Pomodoro` 입력 (정확히 이 이름으로)

3. **Focus Mode 구성 (선택사항)**
   - 알림 비활성화 설정
   - 특정 앱 허용/차단 설정
   - 홈 화면 커스터마이징

### Shortcuts 생성

두 개의 간단한 Shortcut을 생성해야 합니다:

#### 1. EnablePomodoroFocus Shortcut

1. **Shortcuts 앱 열기**
2. `+` 버튼으로 새 Shortcut 생성
3. 이름을 `EnablePomodoroFocus`로 설정
4. 다음 액션 추가:
   - `Apps` → `Focus` → `Turn Focus On`
   - Focus 모드로 `Pomodoro` 선택

#### 2. DisablePomodoroFocus Shortcut

1. 새 Shortcut 생성
2. 이름을 `DisablePomodoroFocus`로 설정
3. 다음 액션 추가:
   - `Apps` → `Focus` → `Turn Focus Off`
   - 또는 `Turn Focus On`에서 `Pomodoro` 선택 후 `Turn Off` 옵션

## 권한 설정

Focus Mode 통합을 위해 다음 권한이 필요합니다:

### 1. Accessibility 권한

**목적**: Hammerspoon이 시스템 이벤트를 감지하고 UI 요소에 접근하기 위해 필요

**설정 방법**:

1. **System Settings 열기**
   ```
   Apple 메뉴 → System Settings → Privacy & Security → Accessibility
   ```

2. **Hammerspoon 추가**
   - `+` 버튼 클릭
   - `/Applications/Hammerspoon.app` 선택
   - 또는 드래그 앤 드롭

3. **권한 활성화**
   - Hammerspoon 항목의 토글 ON

### 2. Automation 권한

**목적**: Hammerspoon이 Shortcuts를 실행하기 위해 필요

**설정 방법**:

1. **System Settings 열기**
   ```
   Apple 메뉴 → System Settings → Privacy & Security → Automation
   ```

2. **Hammerspoon에 권한 추가**
   - `+` 버튼 클릭
   - `Hammerspoon.app` 선택
   - `Shortcuts.app` 체크박스 ON

### 3. Focus 권한 (필요시)

**목적**: Focus Mode 상태를 직접 읽기 위해 필요

**설정 방법**:

1. **System Settings 열기**
   ```
   Apple 메뉴 → System Settings → Privacy & Security → Focus
   ```

2. **앱 권한 확인**
   - 필요한 경우 Hammerspoon에 Focus 접근 권한 부여

### 권한 확인 스크립트

Hammerspoon Console에서 다음 코드로 권한 확인:

```lua
-- Accessibility 권한 확인
print("Accessibility:", hs.accessibilityIsTrusted())

-- Shortcuts 접근 테스트
local testResult = hs.urlevent.openURL("shortcuts://")
print("Shortcuts access:", testResult)

-- Focus 모듈 사용 가능 여부
print("Focus module:", hs.focus ~= nil)
```

## 기본 테스트

### 테스트 1: Focus Mode → Pomodoro 자동 시작

**목표**: Focus Mode 'Pomodoro'가 활성화될 때 Pomodoro 타이머가 자동으로 시작되는지 확인

**절차**:

1. **Hammerspoon 재시작**
   - Hammerspoon 메뉴 → `Reload Config`

2. **콘솔 열기**
   - Hammerspoon 메뉴 → `Open Console`

3. **상태 확인**
   ```lua
   -- Pomodoro 상태 확인
   print("Pomodoro running:", spoon.Pomodoro:isRunning())

   -- Focus 통합 상태 확인
   local debugInfo = spoon.Pomodoro.focusIntegration.getDebugInfo()
   print("Debug info:", hs.inspect(debugInfo))
   ```

4. **Focus Mode 활성화**
   - Control Center 클릭
   - `Focus` → `Pomodoro` 선택

5. **결과 확인**
   - 메뉴바에 🍅 아이콘이 나타나는지 확인
   - 콘솔에 로그 메시지 확인
   - 25분 카운트다운 시작 여부 확인

**예상 결과**:
```
[FocusIntegration] Focus Mode state changed: active
[Pomodoro] Starting work session
```

### 테스트 2: Pomodoro → Focus Mode 자동 활성화

**목표**: Pomodoro 타이머를 시작할 때 Focus Mode 'Pomodoro'가 자동으로 활성화되는지 확인

**절차**:

1. **상태 초기화**
   - Focus Mode가 비활성화 상태인지 확인
   - Pomodoro가 실행 중이 아닌지 확인

2. **Pomodoro 시작**
   - 메뉴바의 🍅 아이콘 클릭
   - 또는 설정된 단축키 사용 (예: Ctrl+Cmd+P)

3. **결과 확인**
   - Control Center에서 Focus Mode 'Pomodoro'가 활성화되는지 확인
   - 메뉴바에 Focus 아이콘이 나타나는지 확인

**예상 결과**:
```
[Pomodoro] Starting work session
[FocusIntegration] Enabling Focus Mode
```

### 테스트 3: 무한 루프 방지 확인

**목표**: Focus Mode와 Pomodoro 간의 변경이 무한 루프를 일으키지 않는지 확인

**절차**:

1. **빠른 전환 테스트**
   - Focus Mode 빠르게 켜고 끄기 (3-5회)
   - 각 전환 사이에 2초 간격 유지

2. **상태 모니터링**
   ```lua
   -- 상태 변경 모니터링
   local monitorCount = 0
   spoon.Pomodoro.focusIntegration.onFocusModeChanged(function(isActive)
     monitorCount = monitorCount + 1
     print(string.format("State change #%d: %s", monitorCount, tostring(isActive)))
   end)
   ```

3. **결과 분석**
   - 상태 변경 횟수가 사용자 액션 횟수와 일치하는지 확인
   - 불필요한 중복 변경이 없는지 확인

**예상 결과**:
- 각 사용자 액션에 대해 정확히 한 번의 상태 변경 발생
- 1초 내의 중복 변경 무시됨

## 고급 테스트

### 테스트 4: 메뉴 트리거 테스트

**목표**: 메뉴바를 통한 세션 제어가 올바르게 동작하는지 확인

**절차**:

1. **메뉴 테스트**
   - 메뉴바 아이콘 우클릭
   - 각 메뉴 항목 클릭:
     - `Start Session`
     - `Stop Session`
     - `Show Statistics`

2. **동기화 확인**
   - 각 액션 후 Focus Mode 상태 확인
   - 일관된 동기화 동작 확인

### 테스트 5: 단축키 트리거 테스트

**목표**: 단축키를 통한 세션 제어가 올바르게 동작하는지 확인

**절차**:

1. **단축키 테스트**
   - 시작 단축키 (예: Ctrl+Cmd+P)
   - 정지 단축키 (예: Ctrl+Cmd+S)
   - 토글 단축키 (예: Ctrl+Cmd+T)

2. **결과 확인**
   - 각 단축키 실행 후 상태 변화 확인
   - Focus Mode 동기화 확인

### 테스트 6: API 트리거 테스트

**목표**: 프로그래매틱 API 호출이 올바르게 동작하는지 확인

**절차**:

1. **Hammerspoon Console에서 테스트**
   ```lua
   -- API를 통한 시작
   spoon.Pomodoro:startSession()
   hs.timer.doAfter(2, function()
     -- API를 통한 정지
     spoon.Pomodoro:stopSession()
   end)
   ```

2. **결과 확인**
   - API 호출 즉시 상태 변화
   - Focus Mode 동기화 확인

### 테스트 7: Fallback 모드 테스트

**목표**: hs.focus 모듈이 없을 때 fallback 동작이 올바르게 동작하는지 확인

**절차**:

1. **hs.focus 모듈 일시 비활성화**
   ```lua
   local originalFocus = hs.focus
   hs.focus = nil

   -- 테스트
   spoon.Pomodoro.focusIntegration.cleanup()
   spoon.Pomodoro.focusIntegration.init(spoon.Pomodoro)

   -- 복원
   hs.focus = originalFocus
   ```

2. **폴백 동작 확인**
   - 2초 간격으로 상태 확인
   - AppleScript를 통한 감지 동작 확인

## 문제 해결

### 일반적인 문제

#### 1. Focus Mode가 감지되지 않음

**원인**: Accessibility 권한 없음

**해결책**:
```
System Settings → Privacy & Security → Accessibility → Hammerspoon ON
```

**확인 스크립트**:
```lua
if not hs.accessibilityIsTrusted() then
  print("ERROR: Accessibility permissions not granted")
  hs.alert.show("Grant Accessibility permissions in System Settings")
end
```

#### 2. Shortcuts가 실행되지 않음

**원인**: Automation 권한 없음 또는 Shortcut 이름 불일치

**해결책**:
1. 권한 확인:
   ```
   System Settings → Privacy & Security → Automation
   → Hammerspoon → Shortcuts ON
   ```

2. Shortcut 이름 확인:
   - `EnablePomodoroFocus` (정확한 대소문자)
   - `DisablePomodoroFocus`

**테스트 스크립트**:
```lua
-- Shortcuts 테스트
local testURL = "shortcuts://run-shortcut?name=EnablePomodoroFocus"
local success = hs.urlevent.openURL(testURL)
print("Shortcut test:", success)
```

#### 3. 무한 루프 발생

**원인**: 디바운싱 설정 문제

**해결책**:
```lua
-- 현재 설정 확인
local debugInfo = spoon.Pomodoro.focusIntegration.getDebugInfo()
print("Last change time:", debugInfo.lastChangeTime)
print("Is internal change:", debugInfo.isInternalChange)

-- 강제 리셋
spoon.Pomodoro.focusIntegration.cleanup()
spoon.Pomodoro.focusIntegration.init(spoon.Pomodoro)
```

#### 4. 동기화 지연

**원인**: 시스템 부하 또는 디바운스 타이머

**해결책**:
```lua
-- 디버깅 모드 활성화
spoon.Pomodoro.focusIntegration.onFocusModeChanged(function(isActive)
  print(string.format("[DEBUG] Focus changed: %s at %d",
    tostring(isActive), os.time()))
end)
```

### 로그 수집

문제 발생 시 다음 정보를 수집하세요:

```lua
-- 상세 디버그 정보
local debugInfo = spoon.Pomodoro.focusIntegration.getDebugInfo()
print("=== Focus Integration Debug Info ===")
print("Active:", debugInfo.isActive)
print("Last change:", debugInfo.lastChangeTime)
print("Internal change:", debugInfo.isInternalChange)
print("Has watcher:", debugInfo.hasWatcher)
print("Has fallback timer:", debugInfo.hasFallbackTimer)
print("Active timers:", debugInfo.activeTimerCount)
print("Callbacks:", debugInfo.callbackCount)
print("Has focus module:", debugInfo.hasFocusModule)

-- 현재 Focus 모드 목록
if hs.focus then
  print("=== Current Focus Modes ===")
  local modes = hs.focus.getFocusModes()
  for _, mode in ipairs(modes) do
    print(string.format("%s: %s", mode.name, tostring(mode.active)))
  end
end
```

## 검증 단계

### 최종 검증 체크리스트

1. **권한 확인**
   - [ ] Accessibility 권한 부여됨
   - [ ] Automation 권한 부여됨
   - [ ] Focus 권한 (필요시) 부여됨

2. **기능 확인**
   - [ ] Focus Mode → Pomodoro 동기화
   - [ ] Pomodoro → Focus Mode 동기화
   - [ ] 무한 루프 방지
   - [ ] 메뉴 동작
   - [ ] 단축키 동작
   - [ ] API 호출 동작

3. **안정성 확인**
   - [ ] 빠른 전환 시 안정성
   - [ ] 시스템 재시작 후 동작
   - [ ] 메모리 누수 없음

4. **에러 핸들링**
   - [ ] 권한 없을 때 에러 처리
   - [ ] Shortcuts 실패 시 처리
   - [ ] 모듈 없을 때 fallback 동작

### 성공 기준

모든 테스트가 통과되고 다음 조건이 만족되면 성공으로 간주합니다:

1. 양방향 동기화가 100% 일관되게 동작
2. 사용자 액션에 1초 내로 반응
3. 불필요한 상태 변경 없음 (무한 루프 없음)
4. 모든 트리거 방법(메뉴, 단축키, API)이 정상 동작
5. 권한 문제가 명확하게 보고됨

### 자동화된 테스트 실행

Unit 테스트 실행:

```bash
cd /Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/test
lua focus_integration_test.lua
```

예상 결과:
```
Running Focus Integration Tests...
✅ All tests passed!
```

---

## 문제 보고

테스트 중 문제가 발생하면 다음 정보를 포함하여 보고하세요:

1. macOS 버전
2. Hammerspoon 버전
3. 전체 콘솔 로그
4. Debug info 출력
5. 재현 단계
6. 기대 결과
7. 실제 결과

이 정보는 문제를 빠르게 진단하고 해결하는 데 도움이 됩니다.