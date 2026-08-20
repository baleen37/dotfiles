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

- Firefox의 새 selectable profile 기능을 우선 지원한다. `profiles.ini`의
  `StoreID`로 `Profile Groups/<StoreID>.sqlite`를 찾고, macOS 기본
  `/usr/bin/sqlite3`로 `Profiles` 테이블을 한 번 read-only 조회한다.
- SQLite profile group을 사용할 수 없는 구형 Firefox에서는 `profiles.ini`의
  `Profile0`, `Profile1`, ... 섹션으로 fallback한다.
- Script Filter의 `title`에는 프로필 이름을 표시하고, `arg`에는 실제 프로필
  경로를 전달한다. 이름에 공백이 있어도 argv 경계가 유지된다.
- 선택된 경로는 `--no-remote --profile <path>`로 Firefox에 전달한다.
- 실행 가능한 프로필이 없으면 Profile Manager를 여는 하나의 fallback 항목을 출력한다.
- `profiles.ini`와 SQLite를 쓰지 않으며, 프로필 디렉터리도 수정·삭제하지 않는다.

새 Firefox profile management는 표시 이름과 profile path를 `Profile Groups/<StoreID>.sqlite`의
`Profiles` 테이블에서 관리한다. Firefox 자체도 selectable profile을 새 인스턴스로
열 때 이름보다 실제 경로를 `--profile` 인자로 넘긴다. 구형 형식에서는
`Profile0`, `Profile1`처럼 Firefox가 읽는 연속 번호를 따르며, `Name` 또는 `Path`가
없는 섹션은 표시하지 않는다.

## 검증 기준

- `info.plist`가 XML plist이며 Script Filter와 Run Script의 UID 연결을 포함한다.
- 두 external zsh script가 문법 검사되고 실행 가능하다.
- SQLite profile group의 `work`, `personal` 이름과 공백이 있는 경로, 구형
  `profiles.ini` fallback을 fixture로 검증한다.
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
- [Mozilla Firefox profile group datastore](https://searchfox.org/firefox-main/source/toolkit/profile/ProfilesDatastoreService.sys.mjs)
- [Mozilla Firefox selectable profile launcher](https://searchfox.org/firefox-main/source/browser/components/profiles/SelectableProfileService.sys.mjs)
- [Mozilla Profile Manager guide](https://support.mozilla.org/en-US/kb/profile-manager-create-remove-switch-firefox-profiles)
