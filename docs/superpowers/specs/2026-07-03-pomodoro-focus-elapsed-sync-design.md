# Pomodoro Focus 시작시각 보정 설계

## 배경 / 문제

`Pomodoro.spoon`은 macOS Focus 모드 변경을 감지해 타이머 상태를 바꾼다.
현재 두 가지 문제가 있다.

1. **감지 자체가 동작하지 않음 (근본 원인, 이미 해결).**
   `FocusManager.getCurrentFocusMode()`는 `~/Library/DoNotDisturb/DB/Assertions.json`을
   JXA로 읽어 현재 Focus 모드를 판별한다. 이 경로는 macOS TCC가 보호하며
   **Full Disk Access(FDA)** 가 필요하다. Hammerspoon에 FDA가 부여되지 않아 읽기가
   항상 "File permission error"로 실패 → `getCurrentFocusMode()`가 항상 `nil` →
   `isPomodoroActive()`가 항상 `false` → focus가 바뀌어도 상태가 전혀 바뀌지 않았다.
   **해결:** Hammerspoon에 FDA 부여 (라이브 검증 완료: 읽기 성공).

2. **시작 시각 보정 부재 (이번 작업 대상).**
   `TimerManager.startWorkSession()`은 감지 시점을 세션 시작으로 보고 무조건 25분으로
   리셋한다. focus가 이미 10분 전에 켜져 있었다면 15분 남아야 하지만 25분으로 초기화된다.

## 실측으로 확정된 사실

- 활성 focus는 `Assertions.json`의 `data[0].storeAssertionRecords`에 있다.
- 각 레코드는 `assertionDetails.assertionDetailsModeIdentifier`(모드 id)와
  `assertionStartDateTimestamp`(시작 시각)를 가진다.
- 모드 id → 표시 이름은 `ModeConfigurations.json`의
  `data[0].modeConfigurations[id].mode.name`으로 해석한다.
- `assertionStartDateTimestamp`는 **Cocoa 기준일(2001-01-01)** epoch이다.
  Unix 변환: `unixStart = assertionStartDateTimestamp + 978307200`.
  (경과 시간이 실제와 일치함을 라이브 검증: 8.0분 예시.)

## 보정 규칙

`elapsed = os.time() - unixStart` (nil/음수면 0으로 방어)

| 조건                                                            | 동작      | timeLeft                                                   |
| --------------------------------------------------------------- | --------- | ---------------------------------------------------------- |
| `elapsed < workDuration` (25분)                                 | 작업 세션 | `workDuration - elapsed`                                   |
| `workDuration ≤ elapsed < workDuration+breakDuration` (25~30분) | 휴식 세션 | `(workDuration+breakDuration) - elapsed`                   |
| `elapsed ≥ workDuration+breakDuration` (≥30분)                  | 완료 처리 | 타이머 미가동(idle) + 통계 저장, **완료 카운트 증가 없음** |

> 완료 카운트를 올리지 않는 이유: 이 경로는 주로 부팅/리로드 시 재동기화 상황이라,
> 카운트를 올리면 리로드마다 통계가 부풀 수 있다. 기존 통계만 저장한다.

## 설계

### 1. 감지 소스 확장 — `FocusManager`

- 신규 `getCurrentFocusInfo()` → `{ name = <string>, startTime = <unix seconds> }` 또는 `nil`.
  - `storeAssertionRecords`에서 **해석된 이름이 `config.focusMode`와 일치하는 레코드**를
    찾아 그 `assertionStartDateTimestamp`를 사용 (기존 `[0]` 고정보다 견고).
  - `startTime = assertionStartDateTimestamp + 978307200`.
- `getCurrentFocusMode()`는 `getCurrentFocusInfo()`의 `name`을 반환하는 얇은 래퍼로 유지.
  `isPomodoroActive()`는 변경 없음.

### 2. 보정 로직 — `TimerManager.syncFromFocus(startTime)`

- 위 보정 규칙에 따라 stage(work/break/complete)와 `timeLeft`를 계산.
- 작업/휴식이면 `sessionStartTime = startTime`으로 두고 해당 카운트다운 타이머를 시작.
- 완료면 러닝 상태 해제 + `saveCurrentStatistics()`.
- **`activatePomodoroFocus()`를 호출하지 않는다** (focus가 이미 켜져 있음).
- 기존 `startWorkSession()`/`startBreakSession()`의 타이머 구동 부분을 재사용하도록
  낮은 수준 헬퍼(예: 초기 `timeLeft`/`isBreak`/`sessionStartTime`을 받는 함수)로 정리.

### 3. 감지→보정 배선 + 워쳐 단순화 — `FocusManager`

- `handleFocusChange()`:
  - pomodoro 활성 & `!State.timerRunning` → `getCurrentFocusInfo()`로 startTime을 얻어
    `TimerManager.syncFromFocus(startTime)`.
  - 비활성 & `State.timerRunning` → 기존대로 stop + 통계 저장.
- `startMonitoring()`의 enabled/disabled 두 워쳐를 **각각 `handleFocusChange()` 한 번 호출**로
  교체한다. 중복·부분 로직을 제거하며, "focus 모드를 직접 갈아탈 때 상태가 안 바뀌던"
  잠재 버그도 함께 해소된다.

### 4. 사용자 시작 경로 유지

- `TimerManager.startWorkSession()`은 **사용자 시작 전용**으로 남긴다:
  `activatePomodoroFocus()` 호출 + 지금부터 `workDuration`.
- 진입점: `toggleSession()`(Hyper+P), `bindHotkeys`의 start, 메뉴바 Start.

## 영향 파일

- `users/shared/programs/.config/hammerspoon/Spoons/Pomodoro.spoon/init.lua`
  - `TimerManager` (start 로직 헬퍼화, `syncFromFocus` 추가)
  - `FocusManager` (`getCurrentFocusInfo`, `getCurrentFocusMode` 래퍼, `handleFocusChange`,
    `startMonitoring`)
- `tests/integration/hammerspoon-test.nix` — 신규 함수 존재/배선을 검증하는 content assertion 추가.

## 테스트 / 검증

- **정적 테스트:** hammerspoon-test.nix에 `getCurrentFocusInfo`, `syncFromFocus`,
  워쳐가 `handleFocusChange`를 호출하는지 등 content assertion 추가.
- **런타임 검증(수동, `hs` CLI):**
  - focus를 켠 뒤 N분 경과 → HS 리로드 → `Pomodoro:getTimeLeft()`가 `workDuration - N분`에
    근사하는지 확인.
  - 25~30분 경과 상태에서 리로드 → 휴식 단계로 진입하는지.
  - 30분 초과 상태에서 리로드 → 러닝 아님(idle)인지.
  - focus를 끄면 타이머가 정지하는지.

## 범위 밖 (YAGNI)

- FDA-불필요 감지(Shortcuts 등) 대안: 시작 시각을 못 얻어 이 요구사항과 상충하므로 채택하지 않음.
- 여러 사이클 wrap-around(30분 초과를 2번째 사이클로 환산): "현재 사이클 내에서만 보정"으로 합의됨.
- FDA 부여 자동화: TCC는 SIP로 스크립트 불가. 머신마다 수동 1회 부여 필요.
