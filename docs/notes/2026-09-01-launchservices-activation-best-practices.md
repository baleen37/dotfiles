# nix-darwin root activation에서 LaunchServices와 AppleScript 다루기

- 조사일: 2026-09-01
- 대상: `users/shared/darwin/vscode-launchservices.sh`, `vscode-launchservices.nix`, `scripts.nix`
- 범위: root로 실행되는 nix-darwin system activation과 사용자 GUI 세션의 경계
- 상태: 조사 완료 및 권장 P0 변경 적용 완료. P1/P2 후속 과제는 아래에 남겼다.
- source 기준: 저장소의 `flake.lock`에 고정된 nix-darwin `4cff07de...`, Home Manager `99c9ec63...` source와 Apple Developer 문서, 대상 macOS 호스트의 `man launchctl` 및 `lsregister -h`

## 결론

조사 당시 오류의 직접 원인은 system activation이 root 컨텍스트에서 사용자별 LaunchServices 조회를 실행한 데 있다. 당시 [scripts.nix](../../users/shared/darwin/scripts.nix)가 root `postActivation`에서 `repair`를 직접 호출했고, [vscode-launchservices.sh](../../users/shared/darwin/vscode-launchservices.sh#L63-L65)는 `osascript`의 실패와 stderr를 버렸다. 그 결과 AppleScript 조회 실패가 `representative=none`으로 바뀌고, 당시 audit의 canonical 경로 invariant가 실패했다. 이 P0 원인과 실패 전파는 현재 구현에서 수정했다.

권장 결론은 다음과 같다.

1. root system activation에서는 LaunchServices 등록, `path to application id`, `osascript` 같은 사용자 GUI 상태 작업을 실행하지 않는다. 이 작업의 소유자는 target 사용자의 Home Manager activation으로 둔다.
2. system activation에서 반드시 사용자 작업을 dispatch해야 한다면, 알려진 UID에 대해 `launchctl asuser UID sudo -u USER --set-home ...`를 사용한다. `asuser`만으로는 UID, GID, `HOME`, 사용자 환경이 바뀌지 않으므로 `sudo -u ... --set-home`가 함께 필요하다. Home Manager의 공식 nix-darwin 통합도 이 형태를 사용한다.
3. GUI login domain이 없거나 AppleScript가 세션 오류를 반환하면 system activation의 결과를 `deferred`로 기록하고 성공 처리한다. canonical 앱의 Bundle ID 불일치, mutation 실패, repair 후 invariant 실패는 `error`로 남긴다. 모든 오류를 빈 문자열로 바꾸거나 광범위하게 `|| true`로 숨기지 않는다.
4. `path to application id`는 유효한 bundle-ID 조회지만, 한 개의 선택된 경로를 반환하는 health signal이다. canonical 앱 선택을 보장하는 증명으로 쓰지 않는다. 중복 앱을 정책으로 구분해야 한다면 사용자 컨텍스트에서 공개 `NSWorkspace` API로 모든 후보를 열거한다.
5. `lsregister`는 공개 Launch Services API가 아니라 macOS 호스트에 포함된 내부 command-line adapter로 취급한다. `-dump`의 사람이 읽는 출력 형식을 `awk`로 파싱하는 방식은 격리하고, database 파일 삭제나 전체 재구축은 activation에서 하지 않는다.

## 적용 결과

이번 구현에서는 장애를 직접 유발한 P0 범위를 적용했다.

- root nix-darwin `postActivation`의 직접 `vscode-launchservices.sh repair` 호출을 제거했다.
- LaunchServices repair의 단일 entrypoint를 target 사용자의 Home Manager activation으로 유지했다.
- `osascript` 조회 실패를 `representative=unavailable`로 구분하고, 이 조회 하나 때문에 audit가 실패하지 않도록 했다. canonical Bundle ID, 등록 상태, Nix store stale path 검사는 계속 hard check로 남겼다.
- root system activation에 다시 직접 호출이 생기지 않도록 user-scoped unit assertion을 추가했다.
- GUI/AppleScript 조회 불가 상태를 고정하는 integration fixture를 추가했다.

검증 결과는 다음과 같다.

- Darwin user-scoped unit: PASS
- standalone activation source unit: PASS
- VS Code LaunchServices integration: PASS
- Darwin aggregate unit: PASS
- treefmt: PASS
- 실제 GUI 로그인 상태의 `make switch`: 2회 연속 exit 0
- target user audit: canonical 등록 확인, Nix store 등록 없음, representative가 canonical 경로로 확인됨
- root audit: `representative=unavailable`이지만 exit 0. root에서 repair를 실행하지 않는 현재 설계의 보조 안전성 확인이다.

`make test` 명령 자체는 마지막 recipe가 평가 오류를 가려 exit 0을 반환했다. 출력에는 이 변경과 무관한 Raycast Nix store 경로 오류가 있었으므로 전체 테스트 PASS로 간주하지 않았다.

## 사실과 추론의 경계

Apple의 공개 문서는 Launch Services database의 물리적 파일이 사용자마다 하나씩 존재한다고 보장하지 않는다. 따라서 이 문서에서 “per-user 상태”라고 할 때는 파일 레이아웃 주장이 아니라, 사용자 로그인과 bootstrap/GUI 세션에 맞춰 조회·등록 작업을 실행해야 한다는 운영 경계를 뜻한다.

Apple은 Launch Services가 앱 bundle의 `Info.plist` 정보를 기록하고, 사용자 시스템에서 사용할 앱은 등록되어야 하며, 새 사용자가 로그인하거나 시스템이 앱 위치를 검색할 때 자동 등록될 수 있다고 설명한다. 명시적 등록에는 공개 `LSRegisterURL` API가 제공된다. [Launch Services Concepts](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts.html), [`LSRegisterURL`](https://developer.apple.com/documentation/coreservices/1446350-lsregisterurl)

따라서 실무 규칙은 다음과 같다.

- `/Applications`의 canonical 앱에 대한 LaunchServices health check는 target 사용자의 GUI login 세션에서 실행한다.
- root system activation에서 보이는 `lsregister -dump`와 `osascript` 결과를 console 사용자의 LaunchServices view로 간주하지 않는다.
- 사용자별 database 파일을 직접 찾거나 지우는 방식으로 문제를 해결하지 않는다.

## 공식 근거

### 1. nix-darwin system activation은 root 경로다

고정된 nix-darwin source는 `system.activationScripts`가 boot/rebuild마다 실행되므로 script가 빠르고 멱등적이어야 한다고 설명한다. 같은 source의 생성 script는 `set -e`, `set -o pipefail`, `USER=root`, `LOGNAME=root`, `HOME=~root`를 설정하고 activation segment를 순서대로 실행한다. 처리되지 않은 non-zero exit는 뒤의 segment와 activation 완료를 중단시킨다. [nix-darwin activation-scripts.nix: idempotence와 실행 경로](https://github.com/nix-darwin/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/system/activation-scripts.nix#L597-L618), [root 환경과 실패 전파](https://github.com/nix-darwin/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/system/activation-scripts.nix#L624-L748)

Apple의 다중 사용자 문서도 root session과 login session을 별개로 설명한다. root process는 active login process를 자동으로 알지 못하고, root session에는 WindowServer를 필요로 하는 상위 프레임워크를 사용할 수 있는 GUI 문맥이 없다. GUI console login에는 Finder와 Dock이 있지만 remote login은 shell-level process만 가진다. [Apple, System Contexts](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPMultipleUsers/Concepts/SystemContexts.html), [Apple, command-line과 GUI login의 경계](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/CommandLInePrimer/CommandLine.html)

그러므로 root에서 실행되는 `osascript`가 어떤 사용자 화면의 LaunchServices 선택을 대변한다고 가정하면 안 된다. 이번 로그의 `representative=none`과 `-600`은 이 호스트에서 발생한 관찰 결과이며, 모든 macOS 버전에 대한 AppleScript 오류 코드 계약으로 일반화하지 않는다.

### 2. LaunchServices 조회와 AppleScript `path to application id`

AppleScript의 `path to` command는 지정한 application의 위치를 반환하고, `application`은 bundle identifier로 지정할 수 있다. application class의 `id`는 bundle identifier 또는 legacy four-character signature다. `POSIX path of`로 alias 결과를 POSIX 경로로 바꾸는 현재 문법 자체는 유효하다. [AppleScript `path to`](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_cmds.html), [AppleScript application class와 `id`](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_classes.html)

AppleScript application object는 script가 실행될 때 동적으로 위치를 확인한다. 따라서 `path to application id "com.microsoft.VSCode"`는 “현재 이 사용자 문맥에서 LaunchServices가 선택한 위치”를 확인하는 데 쓸 수 있지만, `/Applications/Visual Studio Code.app`을 선택해야 한다는 정책을 강제하지는 않는다. 이 문장은 AppleScript의 동적 application lookup과 공개 `NSWorkspace`의 중복 앱 heuristic을 합친 운영적 추론이다. [AppleScript application class](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_classes.html), [`NSWorkspace.urlForApplication(withBundleIdentifier:)`](https://developer.apple.com/documentation/appkit/nsworkspace/urlforapplication%28withbundleidentifier%3A%29)

중복 bundle ID를 명시적으로 검사해야 하는 새 helper를 만들 경우 공개 AppKit API를 우선한다.

- `urlForApplication(withBundleIdentifier:)`는 하나의 URL을 반환하며 여러 앱이 있을 때 heuristic을 사용한다.
- `urlsForApplications(withBundleIdentifier:)`는 모든 후보 URL을 반환하므로 canonical 경로, Nix store 경로, 다른 사용자 설치 경로를 정책으로 분류할 수 있다.
- CoreServices의 `LSCopyApplicationURLsForBundleIdentifier`도 전체 URL을 찾는 API지만 현재 Apple 문서에서 deprecated로 표시된다. 새 helper의 기본 API로 도입하지 않는다.

[NSWorkspace](https://developer.apple.com/documentation/appkit/nsworkspace), [`urlsForApplications(withBundleIdentifier:)`](https://developer.apple.com/documentation/appkit/nsworkspace/urlsforapplications%28withbundleidentifier%3A%29), [deprecated `LSCopyApplicationURLsForBundleIdentifier`](https://developer.apple.com/documentation/coreservices/1449290-lscopyapplicationurlsforbundleid)

### 3. `launchctl asuser`는 bootstrap bridge이지 credential switch가 아니다

2026-09-01 대상 호스트의 `/usr/bin/man launchctl`에서 확인한 domain은 다음과 같다.

- `system/`: root Mach bootstrap을 관리하는 privileged domain
- `user/<uid>/`: 로그인하지 않은 사용자에게도 존재할 수 있는 user domain
- `login/<asid>/`: GUI login 때 만들어지는 login domain
- `gui/<uid>/`: 해당 GUI login domain을 UID로 지정하는 편의형

같은 manual은 `asuser UID command`가 target user bootstrap과 비슷한 Mach bootstrap namespace, exception server, security audit session을 채택하지만 process의 UID, GID, 환경 변수를 바꾸지 않는다고 명시한다. 새 subcommand 출력은 automation API가 아니며 형식이 보장되지 않는다는 caveat도 있다. 이 manual은 대상 macOS에서 직접 읽었고, Apple의 command-line manual 안내와 Apple이 배포하는 `launchd` source를 함께 확인했다. [Apple, macOS command-line과 man page 안내](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/CommandLInePrimer/CommandLine.html), [Apple open-source `launchctl`의 `asuser_cmd`](https://github.com/apple-oss-distributions/launchd/blob/main/support/launchctl.c#L3832-L3895)

Apple source의 `asuser_cmd`는 root가 아니면 거부하고, target bootstrap port를 설정한 뒤 command를 실행한다. source에 credential을 target UID로 바꾸는 동작은 없으므로, root system activation에서 사용할 때의 안전한 형태는 다음과 같다.

```text
launchctl asuser <uid> sudo -u <username> --set-home <user-activation-command>
```

이 형태는 Home Manager의 공식 nix-darwin integration이 각 `home-manager.users`에 대해 생성하는 command와 일치한다. [Home Manager nix-darwin integration](https://github.com/nix-community/home-manager/blob/99c9ec63390f1d8c14d95d9e8b17cc29cfbd4e11/nix-darwin/default.nix#L320-L372)

`asuser`만 사용해도 `gui/<uid>`가 없는 headless 또는 SSH 상황이 GUI 세션으로 변하는 것은 아니다. `gui/<uid>` 또는 login audit session이 없으면 AppleScript/LaunchServices 결과를 신뢰하지 말고 `deferred`로 처리하거나 사용자 login 시점의 user agent에서 재시도한다. Apple은 Launch Daemon을 system/root, Launch Agent를 현재 로그인한 사용자 context로 구분한다. [Apple, Designing Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/DesigningDaemons.html), [Apple, per-user launchd jobs](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

### 4. `lsregister`의 한계

Apple의 공개 Launch Services 문서는 등록 작업을 `LSRegisterURL` 같은 API로 설명한다. 반면 현재 구현이 사용하는

```text
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
```

는 공개 Developer API나 확인 가능한 Apple manual의 command contract로 문서화되어 있지 않다. 2026-09-01 대상 호스트에서 `lsregister -h`는 `-f`, `-u`, `-dump`, `-delete` 등의 옵션을 출력했지만 `/usr/bin/man lsregister`에는 manual이 없었다. 이 조사는 해당 binary가 모든 macOS에서 같은 옵션·출력·경로를 보장한다는 뜻이 아니다. 공개 API와 비교할 때 private tool의 호스트별 동작으로 취급해야 한다. [공개 등록 API `LSRegisterURL`](https://developer.apple.com/documentation/coreservices/1446350-lsregisterurl), [Apple Launch Services 개요](https://developer.apple.com/documentation/coreservices/launch_services)

따라서 shell script를 당장 유지해야 한다면 다음 경계를 둔다.

- `lsregister -dump`는 진단·best-effort adapter로만 사용하고, 사람이 읽는 출력의 `path:`/`identifier:` 형식을 장기 API처럼 취급하지 않는다.
- `-u`는 확인된 정확한 stale path에만 적용한다.
- `-f`는 target 사용자의 context에서 canonical bundle에만 적용한다.
- `-delete`는 activation에서 사용하지 않는다. 이 호스트의 help도 database 삭제 뒤 reboot가 필요하다고 경고한다.
- 장기적으로는 `NSWorkspace`로 후보를 열거하고, 필요하면 공개 LaunchServices API를 호출하는 작은 Swift/Objective-C helper로 교체한다.

Spotlight `mdimport`는 현재 script의 부수적인 metadata refresh다. LaunchServices 등록의 공개 source of truth는 앱 bundle의 `Info.plist`와 LaunchServices registration API이므로, `mdimport` 성공을 LaunchServices correctness의 증거로 사용하지 않는다. [Launch Services가 bundle `Info.plist`를 사용하는 설명](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts.html), [공개 registration API](https://developer.apple.com/documentation/coreservices/1446350-lsregisterurl)

## 조사 시 baseline 구현과 현재 적용 결과의 차이

아래 표의 “조사 시 baseline”은 이번 장애를 재현한 당시 구현을 뜻한다. “현재 적용 결과”는 이 조사 후 적용한 P0 변경을 뜻한다. P1/P2 항목은 아직 후속 과제로 남겨 두었다.

| 위치                                                                                     | 현재 구현                                                                                                                                              | 문제                                                                                                                     | 권장 방향                                                                                                                    |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| [scripts.nix](../../users/shared/darwin/scripts.nix)                                     | 조사 시 root `postActivation`이 `/bin/sh ... repair`를 직접 실행                                                                                       | root session의 AppleScript 결과를 canonical 판정에 사용하고, 실패하면 `set -e` 경로가 전체 switch를 중단시킨다.          | 적용 완료. 이 호출을 제거하고 system activation은 system-level 작업만 담당한다.                                              |
| [vscode-launchservices.nix](../../users/shared/darwin/vscode-launchservices.nix#L9-L12)  | Home Manager `home.activation`에서 `writeBoundary` 이후 script 실행                                                                                    | target user activation이라는 위치는 맞지만, mutating command가 Home Manager의 `run`/`DRY_RUN` 계약을 직접 따르지 않는다. | user activation의 단일 소유자로 유지하고, side effect를 `run`으로 감싸며 context와 결과를 명시한다.                          |
| [representative_app](../../users/shared/darwin/vscode-launchservices.sh#L63-L65)         | `osascript` stderr와 exit status를 버리고 빈 문자열 반환                                                                                               | 세션 접근 실패, 잘못된 script, 실제 앱 미탐색을 같은 `none`으로 합친다.                                                  | exit status와 stderr를 보존해 `deferred`와 `error`를 구분한다.                                                               |
| [audit](../../users/shared/darwin/vscode-launchservices.sh#L67-L100)                     | AppleScript가 고른 한 경로가 canonical과 완전히 같아야 통과                                                                                            | 한 경로 조회는 중복 앱 전체 정책을 검증하지 못한다.                                                                      | user context에서 후보를 열거하고 canonical/stale 정책을 별도로 판정한다.                                                     |
| [bundle_paths](../../users/shared/darwin/vscode-launchservices.sh#L33-L60)               | private `lsregister -dump`를 `awk`로 파싱                                                                                                              | private 출력·경로 의존성이 있고 root dump를 user 상태로 오해할 수 있다.                                                  | 당장은 adapter로 격리하고, 새 helper에서는 공개 API를 우선한다.                                                              |
| [repair](../../users/shared/darwin/vscode-launchservices.sh#L103-L119)                   | 매 실행마다 canonical에 `-f`, `mdimport` 실행 후 audit                                                                                                 | 최종 state는 중복되지 않아도 write side effect는 매번 반복된다.                                                          | audit-first, 필요한 경우에만 mutate, 두 번째 실행은 no-op이 되게 한다.                                                       |
| [현재 integration test](../../tests/integration/vscode-launchservices-test.nix#L45-L160) | fake `lsregister`/`mdimport`/`osascript`로 stale Nix path와 bundle ID를 검사하고, unavailable AppleScript에서 `representative=unavailable`을 기대한다. | root/user bootstrap, GUI domain, `DRY_RUN`, duplicate candidate를 모델링하지 않는다.                                     | 적용 완료. unavailable lookup fixture를 추가하고 focused integration build가 통과했다. 나머지 context fixture는 후속 과제다. |
| [현재 Darwin activation test](../../tests/unit/darwin-activation-test.nix#L36-L46)       | root source에 repair가 없고 Home Manager user activation에 repair가 있기를 기대한다.                                                                   | assembled system activation과 중첩된 Home Manager activation을 모두 검증하는 범위는 제한적이다.                          | 적용 완료. “root direct repair 없음”과 “user activation에 repair 있음” assertion이 통과했다.                                 |

현재 Home Manager 위치의 장점은 `writeBoundary` 이후라는 점이다. Home Manager 공식 source는 activation entry를 DAG로 정렬하고, side effect는 `writeBoundary` 이후에 두며, entry가 멱등적이어야 하고 `DRY_RUN`을 존중해야 한다고 설명한다. activation script 자체도 `set -eu`, `pipefail`, target `HOME`/`USER` sanity check를 사용한다. [Home Manager activation semantics](https://github.com/nix-community/home-manager/blob/99c9ec63390f1d8c14d95d9e8b17cc29cfbd4e11/modules/home-environment.nix#L2874-L2963), [Home Manager activation script context](https://github.com/nix-community/home-manager/blob/99c9ec63390f1d8c14d95d9e8b17cc29cfbd4e11/modules/home-environment.nix#L3398-L3554), [Home Manager activation manual](https://nix-community.github.io/home-manager/internals/activation.html)

## 권장 설계

### A. 실행 소유권을 하나로 둔다

가장 단순한 구조는 다음이다.

```text
nix-darwin system activation, root
  ├─ Homebrew cask 설치와 system-level 설정
  └─ LaunchServices/AppleScript repair는 실행하지 않음

Home Manager user activation, target user
  ├─ writeBoundary 이후 context 확인
  ├─ canonical bundle과 Bundle ID 검증
  ├─ user GUI LaunchServices 상태 audit
  ├─ 필요한 stale path만 repair
  └─ 같은 context에서 post-repair audit
```

이 저장소에서는 `vscode-launchservices.nix`의 user activation을 단일 entrypoint로 유지하고, `scripts.nix`의 root 직접 호출을 제거하는 방향이 P0다. system switch가 GUI login 없이도 자주 실행된다면, user activation이 다음 login에 실행되도록 user LaunchAgent를 추가하는 것을 P1 대안으로 검토한다. Apple의 agent/daemon 구분상 이 작업은 LaunchDaemon보다 user LaunchAgent가 맞다. [Apple Launch Agent/Daemon 구분](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/DesigningDaemons.html)

### B. root에서 dispatch해야 하는 경우

system activation 자체가 사용자별 repair를 완료해야 한다는 별도 요구가 생길 때만 다음 조건을 모두 만족시킨다.

1. 설정에서 target username과 UID를 명시적으로 결정한다. 현재 로그인한 사용자를 `whoami`나 root의 `HOME`으로 추측하지 않는다.
2. target의 `gui/<uid>` 또는 해당 login session이 있는지 preflight한다.
3. root가 `launchctl asuser <uid>`로 bootstrap context를 지정한다.
4. command는 `sudo -u <user> --set-home`으로 실제 credential과 HOME을 target에 맞춘다.
5. child가 target UID, HOME, bootstrap context를 로그나 테스트 hook으로 확인한다.
6. GUI domain이 없으면 `deferred`를 반환해 system switch를 깨지 않고, user login 시 다시 실행한다.

`launchctl asuser`는 root command이므로 user activation에서 무조건 중첩해 사용할 API가 아니다. 이미 target user로 실행 중인 Home Manager activation은 직접 AppleScript를 실행하면 된다. 이 구분은 `asuser`가 credential/env를 바꾸지 않는다는 Apple manual과 Home Manager의 root-to-user dispatch source에 근거한다. [Apple `launchctl` source](https://github.com/apple-oss-distributions/launchd/blob/main/support/launchctl.c#L3832-L3895), [Home Manager integration](https://github.com/nix-community/home-manager/blob/99c9ec63390f1d8c14d95d9e8b17cc29cfbd4e11/nix-darwin/default.nix#L320-L372)

### C. AppleScript와 canonicality를 분리한다

현재 목적이 “Nix store에 잘못 등록된 VS Code를 제거하고 `/Applications` 앱을 등록한다”라면 판정을 세 가지로 나눈다.

- bundle 검사: `/Applications/Visual Studio Code.app/Contents/Info.plist`의 `CFBundleIdentifier`가 기대값인지 확인한다. 불일치는 hard error다.
- registration 검사: target user context에서 canonical path가 등록 후보에 있는지 확인한다.
- selection 검사: `path to application id` 또는 `NSWorkspace`가 선택한 경로가 정책에 맞는지 확인한다. AppleScript query 자체가 context error면 `none`으로 축약하지 않는다.

새 API helper를 도입할 때는 `NSWorkspace.urlsForApplications(withBundleIdentifier:)`로 후보를 모두 수집하고, `Bundle`/`Info.plist` 검증과 경로 정책을 적용한다. 하나의 URL만 필요하더라도 `urlForApplication`의 heuristic 특성을 문서화한다. [NSWorkspace의 단일·복수 URL API](https://developer.apple.com/documentation/appkit/nsworkspace)

### D. 상태와 실패를 분리한다

권장 결과 분류는 다음과 같다.

| 결과       | 의미                                                                              | system root activation에서                 |
| ---------- | --------------------------------------------------------------------------------- | ------------------------------------------ |
| `ok`       | audit 통과, mutation 없음                                                         | 성공                                       |
| `repaired` | 정확한 stale path만 제거하고 canonical을 등록한 뒤 audit 통과                     | 성공                                       |
| `deferred` | target GUI/login context가 없음, 또는 예상된 세션 부재                            | 이유를 로그하고 성공. user login 때 재시도 |
| `error`    | canonical 없음/Bundle ID 불일치, tool/API 실패, mutation 실패, postcondition 실패 | 명확한 원인과 함께 실패                    |

`deferred`는 system activation이 사용자 GUI 상태를 소유하지 않을 때만 허용한다. target user activation에서 이미 GUI context가 있다고 판단했는데 AppleScript가 실패하면 `error`로 올려 context 문제를 숨기지 않는다. `mdimport` 같은 보조 refresh 실패를 허용할지 여부도 별도 정책으로 정하고, LaunchServices의 핵심 invariant와 한 command로 묶지 않는다.

### E. 멱등성은 결과 state와 side effect를 모두 본다

nix-darwin은 activation script를 반복 실행하므로 최종 database가 중복되지 않는 것만으로 충분하지 않다. 다음 실행에서 불필요한 `-u`, `-f`, `mdimport`가 다시 발생하지 않아야 한다. [nix-darwin의 idempotent activation 요구](https://github.com/nix-darwin/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/system/activation-scripts.nix#L597-L618)

권장 순서는 `audit -> 필요한 경우에만 exact mutation -> 같은 context에서 audit`다. Home Manager의 dry-run에서는 실제 LaunchServices와 Spotlight를 변경하지 않고 명령만 로그해야 한다. [Home Manager의 `run`/`DRY_RUN` 계약](https://github.com/nix-community/home-manager/blob/99c9ec63390f1d8c14d95d9e8b17cc29cfbd4e11/modules/home-environment.nix#L2874-L2963)

## 회귀 테스트와 검증 체크리스트

### Nix 평가·정적 회귀

- [x] assembled `system.activationScripts.script.text`에 root의 `vscode-launchservices.sh repair`가 들어가지 않는다.
- [x] Home Manager user activation에는 script가 `writeBoundary` 이후에 한 번만 연결된다.
- [ ] root system activation은 GUI context가 없더라도 LaunchServices repair 때문에 실패하지 않는다.
- [ ] target user의 `HOME`, `USER`, UID를 추측하지 않고 공식 Home Manager integration과 같은 root-to-user 경계를 사용한다.

현재 [darwin-activation-test](../../tests/unit/darwin-activation-test.nix#L36-L46)는 user-scoped 설계를 검증하고, [integration test](../../tests/integration/vscode-launchservices-test.nix#L135-L148)는 unavailable lookup에서 `representative=unavailable`을 검증한다. 두 focused build와 Darwin aggregate unit이 통과했다. 저장소 테스트 관례상 `make test`는 assertion을 build하지 않을 수 있으므로, 실제 assertion은 `make test-build` 또는 Darwin focused `nix build`로 실행한다. [tests README](../../tests/README.md#L1-L20)

### fake command 테스트

- [x] fake `osascript`가 stderr와 non-zero status를 반환하면 `representative=none`으로 성공/실패를 뭉개지 않고 `representative=unavailable`로 구분한다. user activation의 핵심 invariant 검사는 계속 수행한다.
- [ ] GUI domain이 없다는 fixture에서는 `lsregister`, `mdimport`, `osascript` mutation이 실행되지 않고 `deferred`가 된다.
- [ ] fake `launchctl`가 `asuser UID`와 `sudo -u USER --set-home`의 순서, target UID, HOME, bootstrap marker를 검증한다.
- [ ] 이미 올바른 상태에서 두 번째 repair는 register/unregister/metadata write를 모두 0회 수행한다.
- [ ] stale Nix path와 canonical path가 함께 있을 때 정확히 stale path만 unregister한다.
- [ ] canonical 앱이 없거나 `CFBundleIdentifier`가 다르면 hard error가 되고 state를 변경하지 않는다.
- [ ] `DRY_RUN=1`에서는 state와 side-effect log가 변하지 않는다.
- [ ] 동일 bundle ID의 여러 후보가 있을 때 후보를 모두 확인하고, canonical 정책 위반을 한 경로의 heuristic 결과로 통과시키지 않는다.
- [ ] `lsregister -dump`, `-u`, `-f`, `mdimport` 각각의 실패를 주입했을 때 원인과 대상 path가 보이며 후속 audit 실패로만 뭉개지지 않는다.

현재 [vscode-launchservices integration test](../../tests/integration/vscode-launchservices-test.nix#L45-L160)는 stale Nix path 제거, canonical 등록, wrong Bundle ID, 기본 반복 실행 state와 unavailable AppleScript fixture를 포함하며 focused build가 통과했다. launchctl context, GUI domain, `DRY_RUN`, duplicate candidate와 no-op side-effect를 완전히 검증하는 것은 후속 과제다.

### 대상 Mac에서의 read-only 확인

GUI로 로그인한 target user에서 다음을 확인한다. `launchctl print gui/<uid>`가 없는 상태는 headless 실행의 정상적인 `deferred` 조건으로 취급한다.

```text
id -u
id -un
launchctl manageruid
launchctl print "gui/$(id -u)"
sudo -n launchctl asuser "$(id -u <user>)" /usr/bin/osascript -e 'POSIX path of (path to application id "com.microsoft.VSCode")'
sudo -n -u <user> --set-home /usr/bin/osascript -e 'POSIX path of (path to application id "com.microsoft.VSCode")'
```

`lsregister -dump`는 database를 변경하지 않는 진단용으로만 실행하고, root 결과와 target user 결과를 비교할 때 어느 쪽도 상대 context의 진실로 대체하지 않는다. `lsregister -delete`는 실행하지 않는다. `launchctl` domain과 `asuser`의 의미는 대상 호스트의 manual 및 Apple source 버전을 기준으로 다시 확인한다. [Apple `launchctl` source](https://github.com/apple-oss-distributions/launchd/blob/main/support/launchctl.c), [Apple macOS command-line과 man page 안내](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/CommandLInePrimer/CommandLine.html)

### 실제 switch 검증

- [ ] `make test-build`에서 Darwin focused checks가 통과한다.
- [x] GUI login 상태에서 `make switch`가 exit 0으로 끝난다. 같은 호스트에서 2회 연속 확인했다.
- [x] target user로 audit를 실행해 canonical 등록, Nix store 등록 부재, selection 결과를 각각 확인했다.
- [x] 같은 `make switch`를 한 번 더 실행해 두 번째 activation도 exit 0인지 확인했다. 실제 mutation log를 수집하는 fixture 검증은 후속 과제다.
- [ ] 로그아웃/SSH headless 상태에서 system switch를 실행해 `deferred`로 끝나고 Remote Login 등 뒤의 system activation이 중단되지 않는지 확인한다.
- [ ] 다시 GUI login한 뒤 user activation 또는 login agent가 repair를 수행하고, target user context에서 최종 audit가 통과하는지 확인한다.

## 우선순위

| 우선순위 | 조치                                                                            | 이유                                                      |
| -------- | ------------------------------------------------------------------------------- | --------------------------------------------------------- |
| P0       | root `postActivation`의 직접 repair 호출 제거, user activation 단일 소유권 확립 | 현재 장애의 root/GUI 경계 위반과 중복 실행을 없앤다.      |
| P0       | AppleScript 오류 status 보존, `ok/repaired/deferred/error` 분류                 | 세션 부재와 실제 invariant 위반을 구분한다.               |
| P1       | `run`/`DRY_RUN`, audit-first, second-run no-op 보장                             | nix-darwin/Home Manager의 activation 계약을 따른다.       |
| P1       | context-aware fake regression과 GUI/headless live check 추가                    | 현재 테스트가 재현하지 못하는 root regression을 고정한다. |
| P2       | private `lsregister` parser를 공개 `NSWorkspace` 기반 helper로 교체             | macOS 내부 command의 경로와 출력 형식 의존성을 줄인다.    |

P0 source/test 수정과 GUI 로그인 상태의 실제 `make switch` 검증까지 이 문서와 함께 적용했다. `make test` 전체 wrapper의 오류 전파 개선, headless `deferred` 경로, `DRY_RUN`·duplicate candidate·no-op side-effect 검증, 공개 `NSWorkspace` 기반 helper 전환은 P1/P2 후속 과제다.
