# macOS Focus Mode 'Pomodoro' 단축어 설정 가이드

이 가이드는 Pomodoro.spoon과 macOS Focus Mode를 양방향으로 동기화하기 위해 필요한 macOS Shortcuts를 설정하는 방법을 설명합니다.

## 개요

두 개의 macOS Shortcuts를 생성합니다:
- **EnablePomodoroFocus**: 'Pomodoro' Focus Mode 활성화
- **DisablePomodoroFocus**: 'Pomodoro' Focus Mode 비활성화

이 단축어들은 Hammerspoon에서 URL scheme을 통해 호출됩니다.

## 사전 요구사항

1. macOS 14 이상 (Sonoma 또는 그 이후 버전)
2. Hammerspoon 설치 및 설정 완료
3. Focus Mode 'Pomodoro' 생성 완료

## 단계 1: Focus Mode 'Pomodoro' 생성하기

단축어를 생성하기 전에 먼저 Focus Mode를 생성해야 합니다.

1. **시스템 설정 열기**
   - 메뉴 바에서 Apple 메뉴 > 시스템 설정 선택
   - 또는 단축키 `⌘ + ,` 사용

2. **Focus Mode 접근**
   - 왼쪽 메뉴에서 '집중 모드' 클릭
   - 상단의 '+' 버튼 클릭하여 새 Focus Mode 생성

3. **Focus Mode 설정**
   - 이름: 'Pomodoro' 입력
   - 아이콘: 적절한 아이콘 선택 (예: 토마토 또는 타이머 아이콘)
   - 색상: 빨간색 또는 주황색 계열 선택
   - '허용된 알림' 설정에서 필요한 앱만 허용
   - '화면 설정'에서 필요한 설정 구성

## 단계 2: EnablePomodoroFocus 단축어 생성

1. **단축어 앱 열기**
   - `응용프로그램` 폴더에서 '단축어' 앱 실행
   - 또는 Spotlight에서 '단축어' 검색

2. **새 단축어 생성**
   - 상단의 '+' 버튼 클릭하여 새 단축어 생성
   - 단축어 이름을 'EnablePomodoroFocus'로 설정

3. **단축어 구성**
   - '작업 추가' 버튼 클릭
   - '스크립팅' 카테고리 선택
   - '집중 모드 설정' 작업 찾기

4. **집중 모드 설정 작업 구성**
   - '켜기' 선택
   - 집중 모드 선택: 'Pomodoro' 선택
   - (선택사항) 확인 메시지 추가

5. **단축어 저장**
   - 완료되면 상단의 '완료' 버튼 클릭

## 단계 3: DisablePomodoroFocus 단축어 생성

1. **새 단축어 생성**
   - 단축어 앱에서 '+' 버튼 클릭
   - 단축어 이름을 'DisablePomodoroFocus'로 설정

2. **단축어 구성**
   - '작업 추가' 버튼 클릭
   - '스크립팅' 카테고리 선택
   - '집중 모드 설정' 작업 찾기

3. **집중 모드 설정 작업 구성**
   - '끄기' 선택
   - 집중 모드 선택: 'Pomodoro' 선택
   - (선택사항) 확인 메시지 추가

4. **단축어 저장**
   - 완료되면 상단의 '완료' 버튼 클릭

## 단계 4: Hammerspoon과 연동을 위한 URL Scheme 설정

Hammerspoon에서 이 단축어들을 호출하려면 URL Scheme이 필요합니다.

### 방법 1: 단축어 직접 URL 설정

1. **EnablePomodoroFocus 단축어 편집**
   - 단축어 앱에서 'EnablePomodoroFocus' 선택
   - 상단의 'i' 아이콘 클릭하여 상세 설정 열기
   - '단축어 세부정보' 활성화
   - '단축어 실행' 메뉴 선택
   - 'URL 스킴' 활성화
   - URL 스킴 이름: `enable-pomodoro-focus`

2. **DisablePomodoroFocus 단축어 편집**
   - 위와 동일한 과정 반복
   - URL 스킴 이름: `disable-pomodoro-focus`

### 방법 2: 자동화 앱 사용 (권장)

더 안정적인 연동을 위해 자동화(Automator) 앱을 사용할 수 있습니다.

1. **Automator 앱 열기**
   - `응용프로그램` 폴더에서 '자동화' 앱 실행

2. **새 문서 생성**
   - '빠른 동작' 유형 선택

3. **작업 설정**
   - '실행' 단축어 추가
   - 단축어 선택: 'EnablePomodoroFocus'

4. **URL Scheme 설정**
   - 문서를 '.app' 형식으로 저장
   - 예: 'EnablePomodoroFocus.app'
   - URL Scheme: `shortcuts://run-shortcut?name=EnablePomodoroFocus`

## 단계 5: 권한 설정

단축어들이 정상적으로 실행되려면 필요한 권한을 설정해야 합니다.

1. **시스템 설정 > 개인정보 보호 및 보안**
2. **자동화** 섹션에서 Hammerspoon 허용
3. **집중 모드** 권한 확인
4. 필요한 경우 '단축어' 앱에 대한 권한도 확인

## 테스트 방법

### 수동 테스트

1. **EnablePomodoroFocus 테스트**
   - 단축어 앱에서 'EnablePomodoroFocus' 실행
   - 제어 센터에서 'Pomodoro' Focus Mode가 활성화되는지 확인

2. **DisablePomodoroFocus 테스트**
   - 단축어 앱에서 'DisablePomodoroFocus' 실행
   - 제어 센터에서 'Pomodoro' Focus Mode가 비활성화되는지 확인

### URL Scheme 테스트

1. **Safari 또는 다른 브라우저 열기**
2. URL 주소창에 입력:
   ```
   shortcuts://run-shortcut?name=EnablePomodoroFocus
   ```
3. Enter 키 누르고 단축어 실행 확인

## 문제 해결

### 단축어가 실행되지 않을 경우

1. **권한 확인**
   - 시스템 설정 > 개인정보 보호 및 보안에서 권한 확인
   - Hammerspoon에 자동화 권한 부여

2. **단축어 이름 확인**
   - 정확히 일치하는 이름인지 확인
   - 공백이나 특수문자 없는지 확인

3. **Focus Mode 이름 확인**
   - 'Pomodoro'라는 이름의 Focus Mode가 있는지 확인
   - 대소문자 구분 확인

### Hammerspoon 연동이 안될 경우

1. **URL Scheme 확인**
   - 단축어의 URL Scheme이 올바르게 설정되었는지 확인

2. **로그 확인**
   - Hammerspoon 콘솔에서 오류 메시지 확인
   - `hs.openConsole()`으로 콘솔 열기

3. **네트워크 연결 확인**
   - 일부 경우 네트워크 연결이 필요할 수 있음

## 고급 설정

### 알림 설정

단축어에 알림 작업을 추가하여 실행 상태를 표시할 수 있습니다.

1. **알림 작업 추가**
   - '작업 추가' > '알림 보내기'
   - 제목: 'Focus Mode 변경'
   - 내용: 'Pomodoro 모드가 활성화되었습니다'

### 딜레이 설정

필요한 경우 딜레이를 추가할 수 있습니다.

1. **대기 작업 추가**
   - '작업 추가' > '대기'
   - 시간 설정 (예: 1초)

## 단축어 공유 및 백업

생성한 단축어는 다른 기기로 공유하거나 백업할 수 있습니다.

1. **단축어 내보내기**
   - 단축어 앱에서 공유할 단축어 선택
   - 공유 버튼 클릭
   - '단축어 복사' 또는 'AirDrop'으로 공유

2. **iCloud 동기화**
   - 설정 > Apple ID > iCloud > 단축어 활성화
   - 모든 기기에서 단축어 동기화

## 자동화 제안

생성한 단축어를 활용하여 추가 자동화를 구성할 수 있습니다.

### 1. 시간 기반 자동화

- 매일 특정 시간에 Pomodoro 모드 활성화
- 점심시간에는 자동으로 비활성화

### 2. 앱 기반 자동화

- 특정 앱을 실행할 때 자동으로 Pomodoro 모드 활성화
- 업무 관련 앱 목록 구성

### 3. 위치 기반 자동화

- 사무실에 도착하면 자동으로 활성화
- 집에 돌아오면 자동으로 비활성화

이 가이드를 따라 단축어를 설정하면 Pomodoro.spoon과 macOS Focus Mode가 완벽하게 연동되어 더 효율적인 집중 관리가 가능해집니다.