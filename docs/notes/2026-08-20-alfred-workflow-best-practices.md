# 선언적 Alfred Firefox 프로필 workflow 조사

## 범위와 결론

이 노트는 Alfred에서 Firefox 프로필을 나열하고 선택한 프로필을 실행하는
workflow를 선언적으로 배치하기 위한 조사 결과와 구현 후 정정 사항을 기록한다.
외부 근거는 Alfred, Home Manager, Mozilla가 소유한 문서 또는 Mozilla의 Firefox
소스만 사용했다.

권장 경계는 다음과 같다.

- Alfred에는 `Script Filter → Run Script`의 두 객체와 그 연결만 둔다.
- Script Filter는 JSON `items`를 내보내고, 선택 행의 `arg`만 Run Script에 넘긴다.
- Home Manager는 workflow 하나의 디렉터리만 재귀적으로 링크한다. Alfred 전역
  설정과 `prefs.plist`는 선언하지 않는다.
- Firefox의 새 selectable profile 데이터는 `profiles.ini`의 `StoreID`로 연결된
  `Profile Groups/<StoreID>.sqlite`에서 읽고, 구형 Firefox에서는 `profiles.ini`로
  fallback한다. 프로필이 없으면 Profile Manager를 열어 사용자가 복구할 수 있게 한다.

## 1. Script Filter에서 Run Script로의 최소 연결

Alfred가 공식적으로 문서화한 실행 계약은 객체 UI와 JSON 입출력이다. Script
Filter는 keyword로 실행되고 JSON `items` 배열을 반환한다. 각 행의 `title`은
필수이고, `arg`는 연결된 output action으로 전달되는 값이므로 선택 결과를
식별해야 하는 workflow에서는 채운다. 새 workflow에는 legacy XML 대신 JSON을
사용한다.

따라서 필요한 최소 의미 구조는 다음과 같다.

1. keyword를 가진 Script Filter 객체 하나. 프로필 목록을 `{"items": [...]}`로
   출력하고 각 item에 표시 이름 `title`과 실행에 필요한 단일 `arg`를 둔다.
2. Run Script 객체 하나. Script Filter의 기본 출력을 이 객체에 연결한다.
3. Run Script의 입력 방식은 `argv`로 둔다. Alfred는 `{query}`를 셸 문자열에
   치환하는 방식보다 인용/escaping 오류가 없으므로 `argv`를 권장한다.
4. 스크립트 파일을 workflow 안에 둘 경우 Run Script 언어를 `External Script`로
   선택한다. 상대 경로는 workflow 디렉터리 기준이고 실행 비트가 필요하다.

중요한 한계가 있다. Alfred의 공개 도움말은 `info.plist`라는 파일의 직렬화
스키마나 개별 키를 지원 계약으로 문서화하지 않는다. 그러므로 수작업으로 만든
"최소 plist"를 안정 API로 간주하면 안 된다. 안전한 선언 방식은 Alfred UI에서
위 두 객체를 만들고 연결한 뒤 export한 `info.plist`를 기준 산출물로 보관하는
것이다. 이후 저장소에서는 object UID, 연결, script 경로를 함께 유지하고,
Alfred 업그레이드 뒤에는 UI에서 다시 열어 연결과 debugger 출력을 확인한다.

Script Filter가 한 번에 전체 목록을 반환하고 Alfred가 필터링하게 할 수 있다.
목록이 작고 동기 조회가 짧은 프로필 선택에는 적합하다. 이 workflow는 실행할 때마다
profile source를 읽되, 새 Firefox 형식에서는 `/usr/bin/sqlite3`로 한 번의
read-only SELECT만 수행하고 별도의 DB 라이브러리나 Nix 패키지를 추가하지 않는다.

근거:

- [Alfred Script Filter input](https://www.alfredapp.com/help/workflows/inputs/script-filter/): keyword, JSON 권장, 실행 동작과 Run Script와 같은 scripting contract.
- [Alfred Script Filter JSON format](https://www.alfredapp.com/help/workflows/inputs/script-filter/json/): 최상위 `items`, 필수 `title`, 연결된 action으로 전달되는 `arg`.
- [Alfred Run Script action](https://www.alfredapp.com/help/workflows/actions/run-script/): `argv` 권장 및 External Script의 상대 경로/실행 권한 규칙.

## 2. `prefs.plist`를 보존하는 Home Manager 배치

`home.file`의 target은 HOME 기준 상대 경로이며 source는 파일 또는 디렉터리다.
source가 디렉터리일 때 `recursive = true`는 target 디렉터리 구조를 만들고 각
leaf 파일을 링크한다. 따라서 Alfred workflow 전체나 preferences 상위 디렉터리를
관리하지 말고, `workflows` 아래의 workflow 디렉터리 하나만 target으로 삼는 것이
안전하다.

적용 시 사용할 모양은 다음처럼 좁은 target이다. 이는 구현 지시가 아니라
선언 범위 예시다.

```nix
home.file."Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/<workflow-directory>" = {
  source = ./workflow;
  recursive = true;
};
```

이 범위에는 `prefs.plist`가 없다. 따라서 Alfred가 관리하는 전역 환경설정,
다른 workflow, 사용자가 만든 workflow가 Home Manager source로 교체되지 않는다.
특히 상위 `workflows` 디렉터리나 `Alfred.alfredpreferences` 전체를 source로
선언하면 기존의 비선언적 사용자 상태까지 관리 경계에 넣게 되므로 피한다.
기존 target과 충돌하면 먼저 사용자가 소유한 파일인지 확인하고, 무조건
`force = true`로 덮어쓰지 않는다.

`recursive = true`에서는 `onChange`가 매 activation마다 실행된다는 Home Manager
문서의 주의도 적용된다. 이 workflow에는 재시작이나 가져오기 같은 on-change
side effect를 붙이지 않고, 필요 시 별도 명시적 검증 단계로 둔다.

근거:

- [Home Manager `home.file` options](https://home-manager.dev/manual/23.05/options.html#opt-home.file._name_.recursive): HOME 상대 target, source, directory의 재귀 링크 의미, recursive일 때의 `onChange` 실행 규칙.

## 3. Firefox 프로필 source 읽기와 빈 목록 fallback

### 새 selectable profile 데이터

Firefox의 새 profile management는 표시 이름과 실제 profile 경로를
`Profile Groups/<StoreID>.sqlite`의 `Profiles` 테이블에 저장한다. `profiles.ini`의
profile section에 있는 `StoreID`가 이 database 이름을 결정한다. 따라서
`profiles.ini`의 `Name`만 읽으면 Firefox에서 사용자가 지정한 `work`, `personal` 같은
이름을 놓칠 수 있다.

workflow는 다음의 좁은 read-only 경계를 사용한다.

1. Firefox data directory의 `profiles.ini`에서 첫 `StoreID`를 찾는다.
2. `Profile Groups/<StoreID>.sqlite`가 있고 `/usr/bin/sqlite3`를 사용할 수 있으면
   `SELECT name, path FROM Profiles ...`를 한 번 실행한다.
3. DB의 `name`은 Alfred `title`, DB의 `path`는 data directory 기준 실제 경로로
   변환해 Alfred `arg`로 사용한다.
4. DB가 없거나 조회에 실패하면 구형 `profiles.ini` parser로 fallback한다.

SQLite는 읽기 전용으로 열고, DB 파일을 쓰거나 migration하지 않는다. profile path에
공백이 있어도 JSON escaping 후 argv 하나로 전달하므로 shell word splitting이
발생하지 않는다. 실행 가능한 directory가 없는 행은 표시하지 않는다.

### 구형 `profiles.ini` fallback

### Firefox와 같은 순서로 열거하기

Firefox의 현재 profile service는 `Profile0`부터 숫자를 증가시키며 각 섹션의
`IsRelative`를 읽는다. 해당 키가 없으면 즉시 반복을 끝낸다. 이어서 `Path`와
`Name`이 없는 섹션은 malformed로 보고 건너뛴다. 즉 다음 규칙이 필요하다.

- 파일에 적힌 섹션의 물리적 위치로 정렬하지 않는다. `Install…` 섹션이 중간에
  있어도 `Profile0`, `Profile1` 순서가 유효 순서다.
- 이름으로 정렬하거나 공백을 정규화하지 않는다. 선택 화면에는 읽은 `Name`을
  그대로 표시하고, 실행 식별자는 별도의 안전한 `arg`로 전달한다.
- `ProfileN` 번호에는 공백이나 누락을 보정하지 않는다. `Profile0` 뒤에
  `Profile2`만 있으면 Firefox 자체가 `Profile1`에서 열거를 멈추므로 workflow도
  목록을 꾸며서 보여주지 않는다.
- `Path` 또는 `Name`이 없는 섹션은 실행 가능한 항목으로 만들지 않는다. 이 경우
  사용자가 Profile Manager에서 복구하도록 안내하는 편이 잘못된 경로 실행보다
  안전하다.

여기서 "순서/공백 보존"은 원문 파일을 formatter나 map으로 다시 쓰지 않고,
Firefox가 의미를 부여하는 번호 순서와 표시 이름을 보존한다는 뜻이다. workflow는
읽기 전용이어야 하며 `profiles.ini`를 갱신하거나 정렬해서는 안 된다.

### 실행 인자

새 selectable profile은 이름이 legacy `profiles.ini`에 없을 수 있으므로 `-P <name>`
대신 `--profile <path>`를 사용한다. `--no-remote`와 함께 직접 Firefox binary에
전달해 별도 인스턴스를 실행한다. Firefox 자체 selectable profile launcher도
동일하게 실제 profile path를 `--profile`로 전달한다.

### 빈 목록과 Profile Manager

실행 가능한 프로필이 0개이면 Script Filter는 실패시키거나 빈 화면을 내지 말고
"Profile Manager 열기"라는 유효한 단일 item을 반환한다. 이 item의 Run Script는
macOS Firefox binary에 `--ProfileManager`를 전달해 Profile Manager를 연다.

Mozilla의 macOS 안내는 다음 명령을 제시한다.

```text
/Applications/Firefox.app/Contents/MacOS/firefox --ProfileManager
```

운영상 주의점은 다음과 같다.

- `--ProfileManager` fallback은 새 profile을 자동 생성하는 동작이 아니라 사용자가 만들고
  고치고 선택할 수 있는 UI를 여는 복구 경로여야 한다.
- Mozilla는 Profile Manager를 열기 전에 Firefox를 종료하라고 안내한다. 이미
  실행 중인 Firefox가 있으면 manager가 보이지 않을 수 있으므로, fallback의
  성공 기준은 프로세스 exit code가 아니라 Profile Manager 창이 실제로 열린
  것이다.
- Firefox binary가 기본 위치가 아닐 수 있다. 구현 전에는 실제 app path를
  확인하고, 임의의 PATH 탐색 결과를 영구 설정으로 기록하지 않는다.

근거:

- [Mozilla Firefox profile datastore source](https://searchfox.org/firefox-main/source/toolkit/profile/ProfilesDatastoreService.sys.mjs): `Profile Groups/<StoreID>.sqlite`와 `Profiles` table.
- [Mozilla Firefox selectable profile source](https://searchfox.org/firefox-main/source/browser/components/profiles/SelectableProfileService.sys.mjs): profile path를 `--profile`로 넘기는 launch 방식.
- [Mozilla Firefox profile service source](https://searchfox.org/firefox-main/source/toolkit/profile/nsToolkitProfileService.cpp): legacy `Profile0`, `Profile1`, … 연속 열거, 필수 `IsRelative`/`Path`/`Name` 처리.
- [Mozilla Firefox Profile Manager guide](https://support.mozilla.org/en-US/kb/profile-manager-create-remove-switch-firefox-profiles): 프로필 데이터가 application과 분리됨, macOS의 `firefox -P`, Firefox 종료 필요성, 실행 중인 Firefox 때문에 manager가 보이지 않을 수 있다는 주의.

## 구현 재개 전 확인 목록

1. Alfred에서 생성·export한 `info.plist`의 두 UID와 `connections`가 Script Filter에서
   Run Script로 향하는지 확인한다.
2. workflow source 디렉터리에 external script와 실행 권한이 포함되는지 확인한다.
3. Home Manager target이 정확히 workflow UUID 한 개이며 `prefs.plist`와 상위
   preferences 디렉터리를 건드리지 않는지 확인한다.
4. fixture에 SQLite `work`, `personal` profile과 공백이 있는 path를 넣어 이름과
   path argv가 보존되는지 검증한다.
5. StoreID/SQLite가 없는 구형 fixture에서 `profiles.ini` fallback이 동작하는지,
   빈 목록에서 `--ProfileManager` fallback item이 나오는지 검증한다.
