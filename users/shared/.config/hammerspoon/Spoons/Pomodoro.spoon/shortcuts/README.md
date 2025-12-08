# Pomodoro Focus Mode Shortcuts

이 디렉토리에는 macOS Focus Mode 'Pomodoro'를 제어하기 위한 단축어 파일들이 포함되어 있습니다.

## 포함된 단축어

1. **EnablePomodoroFocus.shortcut** - Pomodoro Focus Mode 활성화
2. **DisablePomodoroFocus.shortcut** - Pomodoro Focus Mode 비활성화

## 가져오는 방법

### 방법 1: 직접 가져오기

1. macOS 단축어 앱 열기
2. 메뉴에서 '파일' > '가져오기' 선택
3. 이 디렉토리에서 `.shortcut` 파일 선택
4. 단축어 정보 확인 후 '가져오기' 클릭

### 방법 2: AirDrop 사용

1. Mac에서 .shortcut 파일 선택
2. 마우스 오른쪽 클릭 > '공유' > 'AirDrop'
3. 대상 Mac 선택하여 전송

### 방법 3: URL로 접속

터미널에서 다음 명령어를 실행하여 단축어를 직접 열 수 있습니다:

```bash
# Enable Pomodoro Focus
open shortcuts://import-shortcut?url=file:///Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/shortcuts/EnablePomodoroFocus.shortcut

# Disable Pomodoro Focus
open shortcuts://import-shortcut?url=file:///Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/shortcuts/DisablePomodoroFocus.shortcut
```

## 가져온 후 확인사항

1. **Focus Mode 존재 확인**
   - 시스템 설정 > 집중 모드에서 'Pomodoro'가 있는지 확인
   - 없다면 [macOS-Shortcuts-Setup-Guide.md](../docs/macOS-Shortcuts-Setup-Guide.md)를 참고하여 생성

2. **URL Scheme 확인**
   - 단축어 앱에서 각 단축어의 '세부정보' > 'URL 스킴' 활성화
   - URL 스킴 이름이 올바른지 확인

3. **권한 확인**
   - 시스템 설정 > 개인정보 보호 및 보안 > 자동화
   - Hammerspoon에 필요한 권한이 있는지 확인

## 테스트

```bash
# Hammerspoon 콘솔에서 테스트
hs.urlevent.openURL("shortcuts://run-shortcut?name=EnablePomodoroFocus")
hs.urlevent.openURL("shortcuts://run-shortcut?name=DisablePomodoroFocus")
```

## 문제 해결

- 단축어가 실행되지 않으면 이름이 정확히 일치하는지 확인
- Focus Mode 이름을 변경했다면 단축어 내에서도 수정 필요
- 자동화 권한이 필요할 수 있음

## 자동화 통합

이 단축어들은 Hammerspoon의 `focus_integration.lua` 모듈에서 자동으로 호출됩니다:

- `EnablePomodoroFocus`: Pomodoro 세션 시작 시 자동 호출
- `DisablePomodoroFocus`: Pomodoro 세션 종료 시 자동 호출