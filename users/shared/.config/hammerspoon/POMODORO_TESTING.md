# Pomodoro Spoon Testing Guide

이 가이드는 Hammerspoon Pomodoro Spoon의 수동 테스트 방법을 안내합니다.

## 1. 사전 준비

### macOS Focus Mode 설정

1. **시스템 설정 > Focus > + 클릭**에서 새 Focus 모드를 생성합니다.
2. Focus 모드 이름을 **"Pomodoro"**로 지정합니다.
3. 필요한 경우 알림 설정을 구성합니다.

### Hammerspoon 재시작

```bash
# 터미널에서 Hammerspoon 재시작
osascript -e 'tell application "Hammerspoon" to quit'
sleep 2
open -a Hammerspoon
```

## 2. 기본 기능 테스트

### 2.1 자동 시작 테스트

1. **Focus Mode 활성화**:
   - Control Center 또는 메뉴 막대에서 Focus 선택
   - "Pomodoro" Focus 모드 선택

2. **예상 결과**:
   - 메뉴 막대에 🍅 토마토 아이콘이 표시됨
   - "🍅 25:00" 카운트다운이 시작됨
   - "Pomodoro Started" 알림이 표시됨

### 2.2 메뉴 상호작용 테스트

1. **메뉴 막대 아이콘 클릭**
2. **예상 결과**:
   - 팝업 메뉴가 표시됨
   - "Status: Work (남은 시간)" 항목이 보임
   - "Stop Session" 버튼이 활성화됨
   - "Today: 0 sessions" 통계가 표시됨

### 2.3 작업 세션 완료 테스트

1. **25분 대기** (또는 테스트를 위해 코드에서 시간 단축):
   ```lua
   -- init.lua에서 임시로 시간 변경 (테스트용)
   local WORK_DURATION = 5  -- 5초로 변경
   local BREAK_DURATION = 3  -- 3초로 변경
   ```

2. **예상 결과**:
   - 타이머가 0에 도달하면 자동으로 휴식 시간 시작
   - 메뉴 막대에 ☕ 커피 아이콘이 표시됨
   - "Break Time!" 알림이 표시됨
   - "☕ 05:00" 카운트다운 시작

### 2.4 휴식 시간 완료 테스트

1. **5분 대기** (또는 설정한 테스트 시간)

2. **예상 결과**:
   - 타이머가 0에 도달하면 메뉴 막대에 "🍅 Ready" 표시
   - "Session Complete!" 알림이 표시됨
   - 통계가 저장됨

## 3. Focus Mode 통합 테스트

### 3.1 Focus Mode 비활성화 테스트

1. Pomodoro 세션 진행 중
2. **Focus Mode 비활성화**:
   - Control Center에서 Focus 해제

3. **예상 결과**:
   - "Pomodoro Stopped" 알림이 표시됨
   - 메뉴 막대에 "🍅 Ready"로 변경
   - 타이머가 중지됨

### 3.2 Focus Mode 재활성화 테스트

1. "Pomodoro" Focus 모드를 다시 활성화
2. **예상 결과**:
   - 새로운 작업 세션이 자동으로 시작됨
   - 카운트다운이 25:00부터 시작

## 4. 통계 기능 테스트

### 4.1 통계 확인

1. Hammerspoon Console에서 통계 확인:
   ```lua
   spoon.Pomodoro:getStatistics()
   ```

2. **예상 결과**:
   ```lua
   {
     today = 1,  -- 완료된 세션 수
     all = {
       ["2025-12-08"] = 1
     }
   }
   ```

### 4.2 통계 초기화

1. 메뉴에서 "Reset Stats" 클릭
2. **예상 결과**:
   - 오늘의 세션 수가 0으로 초기화됨

## 5. 핫키 테스트 (선택 사항)

### 5.1 핫키 설정

init.lua에서 핫키 설정 주석 해제:
```lua
-- 주석 제거
Pomodoro:bindHotkeys({
  start = {{"ctrl", "alt"}, "p"},
  stop = {{"ctrl", "alt"}, "s"}
})
```

### 5.2 핫키 테스트

1. **Ctrl+Alt+P**: 수동으로 세션 시작
2. **Ctrl+Alt+S**: 진행 중인 세션 중지

## 6. 디버깅 및 문제 해결

### Hammerspoon Console 접근

1. 메뉴 막대 Hammerspoon 아이콘 클릭
2. "Console" 선택

### 유용한 디버깅 명령어

```lua
-- Spoon 상태 확인
print("Timer running:", spoon.Pomodoro.timerRunning)
print("Time left:", spoon.Pomodoro.timeLeft)
print("Is break:", spoon.Pomodoro.isBreak)

-- Focus 모드 확인
print("Current focus:", hs.focus.getFocusMode())

-- 설정된 값 확인
print("Stats:", hs.inspect(hs.settings.get("pomodoro.stats")))

-- Spoon 재시작
spoon.Pomodoro:stop()
spoon.Pomodoro:start()
```

## 7. 자동화된 테스트 스크립트

작성된 테스트 스크립트 실행:
```bash
cd ~/.hammerspoon
/opt/homebrew/bin/lua test_pomodoro.lua
```

## 8. 알려진 제한사항

1. **타이머 정확도**: Hammerspoon 타이머는 정확한 초 단위 타이밍을 보장하지 않을 수 있음
2. **Focus Mode API**: macOS Focus Mode API는 최신 버전에서만 지원됨
3. **통계 지속성**: hs.settings에 저장된 데이터는 Hammerspoon 재설치 시 초기화됨

## 9. 성공 확인 체크리스트

- [ ] Focus Mode 변경 시 자동으로 세션 시작/중지
- [ ] 메뉴 막대에 정확한 카운트다운 표시
- [ ] 알림이 적시에 표시됨
- [ ] 통계가 올바르게 기록됨
- [ ] 핫키가 설정된 경우 정상 동작
- [ ] 모든 전환 상태(준비 → 작업 → 휴식 → 준비)가 원활함

## 10. 문제 보고

문제가 발생한 경우:

1. Hammerspoon Console의 에러 메시지 수집
2. macOS 버전 및 Hammerspoon 버전 확인
3. 재현 단계 기록
4. 위 테스트 케이스 중 어떤 항목에서 실패했는지 기록
