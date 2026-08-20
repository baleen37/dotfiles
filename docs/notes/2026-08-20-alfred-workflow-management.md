# Alfred workflow 관리 설계

## 결정

Alfred의 workflow 코드만 Home Manager로 관리한다. `users/shared/programs/.config/alfred/workflows/` 아래의 각 디렉터리를 자동 발견해 다음 경로에 재귀적으로 링크한다.

```text
~/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/<workflow-directory>
```

`modules.programs.alfred.enable`은 Darwin에서 기본 활성화하고, `preferencesPath`로 Alfred 동기화 경로를 바꿀 수 있게 한다. 기존 Alfred preferences, Powerpack 상태, hotkey, 다른 workflow, runtime `prefs.plist`는 Home Manager 관리 범위에 넣지 않는다.

워크플로우 source 디렉터리에 `prefs.plist`를 추가하지 않는 이유는 Alfred가 workflow 기본값을 `info.plist`에 두고 사용자가 바꾼 설정을 `prefs.plist`에 저장하기 때문이다. 이 분리는 개인 설정을 dotfiles에 저장하거나 기존 Alfred 상태를 덮어쓰는 일을 막는다.

## Firefox workflow

`firefox-profiles`는 `ff` Script Filter와 Run Script를 연결한다.

- Script Filter는 Firefox `profiles.ini`에서 등록된 프로필을 읽어 JSON `items`를 출력한다.
- 프로필 이름은 표시와 단일 argv 값에 그대로 사용해 공백을 보존한다.
- 선택된 이름은 `--no-remote -P <profile>`로 Firefox에 전달한다.
- 실행 가능한 프로필이 없으면 Profile Manager를 여는 하나의 fallback 항목을 출력한다.
- `profiles.ini`를 쓰거나 프로필 디렉터리를 수정·삭제하지 않는다.

Firefox 프로필 열거는 `Profile0`, `Profile1`처럼 Firefox가 읽는 연속 번호를 따른다. `Name` 또는 `Path`가 없는 섹션은 표시하지 않고, 번호 사이의 빈틈은 임의로 보정하지 않는다.

## 검증 기준

- `info.plist`가 XML plist이며 Script Filter와 Run Script의 UID 연결을 포함한다.
- 두 external zsh script가 문법 검사되고 실행 가능하다.
- 공백이 있는 이름과 섹션 순서, 빈 `profiles.ini` fallback을 fixture로 검증한다.
- Home Manager가 Darwin에서 모듈을 활성화하고 `preferencesPath` override를 지원한다.
- source tree에 `prefs.plist`가 없다.

## 근거

- [Alfred Script Filter](https://www.alfredapp.com/help/workflows/inputs/script-filter/)
- [Alfred Script Filter JSON](https://www.alfredapp.com/help/workflows/inputs/script-filter/json/)
- [Alfred Run Script](https://www.alfredapp.com/help/workflows/actions/run-script/)
- [Alfred workflow configuration](https://www.alfredapp.com/help/workflows/workflow-configuration/)
- [Alfred script environment variables](https://www.alfredapp.com/help/workflows/script-environment-variables/)
- [Alfred preferences sync](https://www.alfredapp.com/help/advanced/sync/)
- [Home Manager dotfiles](https://home-manager.dev/manual/unstable/usage/dotfiles.html)
- [Home Manager `home.file` options](https://home-manager.dev/manual/unstable/options/home-manager/home.html)
- [Mozilla Firefox command-line parameters](https://firefox-source-docs.mozilla.org/browser/CommandLineParameters.html)
- [Mozilla Firefox profile service](https://searchfox.org/firefox-main/source/toolkit/profile/nsToolkitProfileService.cpp)
- [Mozilla Profile Manager guide](https://support.mozilla.org/en-US/kb/profile-manager-create-remove-switch-firefox-profiles)
