# macOS의 반복 sh 백그라운드 알림 예방 조사

2026-11-09. **최종 상태: 커스텀 네이티브 launcher와 전용 테스트·문서 설명을 제거하고 표준 Home Manager로 복원했다.** 실제 서비스에는 적용하지 않았다. 아래 구현·검토 기록은 폐기한 시도의 이력이다.

## 복원 후 확인한 사실

- 복원한 Home Manager generation은 현재 적용된 시스템 세대 11이 참조하는 `/nix/store/xmg04znlkww1q9q8njkgbpa3aclk0l6s-home-manager-generation`과 동일하다.
- 생성된 사용자 LaunchAgent 5개의 plist는 실제 설치된 파일과 모두 동일하다. 다섯 항목 모두 launchctl에 loaded되어 있다. 따라서 이 상태는 upstream의 내용 동일·loaded 검사에서 교체를 생략하는 조건을 충족한다. 실제 switch는 실행하지 않았다.
- 보존된 시스템 세대 9·10의 Home Manager 출력에는 Syncthing과 syncthing-init이 없다. 오늘 20:58 적용된 세대 11에서 두 항목이 처음 나타난다. 20:58:58의 두 알림은 새로 추가된 두 서비스의 최초 등록과 일치한다. 해당 두 알림만으로 반복 재등록이 입증됐다고 본 앞선 해석을 정정한다.
- 사용자가 경험한 이후 반복 알림이나 항목 누적은 아직 재현하지 못했다. 별도 wrapper를 추가할 증거가 부족하다. 현 상태를 기준으로 다음 발생 시각의 UUID·label·plist 변화와 알림 로그를 비교해야 한다.

## 실제 확인

`sfltool dumpbtm`에서 Home Manager의 Syncthing, syncthing-init, SOPS, RustDesk, Tailscale이 `/bin/sh`로 등록되어 있었다. 실제 plist는 `/bin/sh -c '/bin/wait4path /nix/store && exec …'` 형태다.

통합 로그에서 20:58:58 Syncthing과 syncthing-init의 UUID에 대해 “sh can run in the background” 알림 두 건이 발생했다. 반복 알림은 확인했지만, 항목 수가 매번 누적된다는 전후 비교 증거는 없다.

로컬 Home Manager 소스의 활성화 코드는 plist 내용과 domain이 같고 서비스가 loaded이면 교체를 생략한다. 내용이 달라지면 bootout·파일 설치·bootstrap을 수행한다. 따라서 모든 switch가 무조건 재등록하는 구조는 아니다. Syncthing의 두 plist는 변경 가능한 store 경로를 참조하므로 패키지·설정 변경 시 plist가 달라질 수 있다. 이것이 이번 알림의 직접 원인인지는 변경 전 plist와 비교해야 확정된다.

## 방법 비교

| 방법                                               | 효과                                                          | 한계·비용                                                                                                       |
| -------------------------------------------------- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| 고정된 store 밖 실행 경로 + 필요한 서비스만 재시작 | plist와 실행 진입점 변화를 줄이고 mount 대기를 유지할 수 있음 | launcher 배포·업데이트·정리 구현이 필요. macOS 알림 영구 0회를 보장하지 않음                                    |
| 앱 자체 자동 시작 사용                             | 커스텀 LaunchAgent 관리 감소                                  | 앱이 실제 제공하는 기능부터 확인. 기존 agent와 중복 실행 방지. Syncthing의 선언형 초기 설정 계약 별도 유지 필요 |
| `waitForNixStore = false`                          | Home Manager가 이름 있는 launcher를 만들어 sh 표시 개선       | store 준비 전 시작 실패 가능. store 경로 변경과 재등록을 없애는 방법은 아님                                     |
| BTM 초기화·알림 억제                               | 표시 상태 초기화 또는 알림 숨김                               | 등록 원인 해결 아님. MDM 규칙은 관리 환경용                                                                     |

## 권고

1. Syncthing 두 항목을 대상으로 무변경 switch 전후 plist 해시·BTM UUID·알림을 비교한다. 이미 구현된 unchanged skip이 실제로 작동하는지 먼저 확인한다.
2. 변경 시 재등록이 반복되는 것이 확인되면 고정된 store 밖 launcher와 안정된 plist를 적용한다. 실행 대상만 갱신하고, 필요한 재시작은 재등록 대신 kickstart로 처리하는 방향을 검토한다. store 대기와 Syncthing 초기 설정 순서를 보존한다.
3. RustDesk·Tailscale은 앱 자체 자동 시작이 기존 요구를 충족하는지 확인한 뒤 중복 agent를 줄인다. 시스템 부팅용 Nix daemon에는 사용자 agent의 우회 설정을 일괄 적용하지 않는다.

현재 pinned 로컬 소스에는 waitForNixStore가 있지만 restartTriggers·launcher.name·launcher.shell은 없다. 조사 중 원격 revision URL 응답과 로컬 파일 내용이 일치하지 않아, 최신 옵션이 현재 lock에 존재한다고 판단하지 않았다. 단순 업데이트가 해결한다는 주장도 검증하지 못했다.

## 1차 출처

- [Apple: 로그인 항목과 백그라운드 작업 관리](https://support.apple.com/en-gb/guide/deployment/depdca572563/web): BTM, 진단 도구, 관리 환경 규칙.
- [Home Manager launchd 구현](https://github.com/nix-community/home-manager/blob/master/modules/launchd/default.nix): mount 대기 wrapper, launcher, 활성화 시 변경 비교. 최신 소스와 로컬 pinned는 구분해야 함.
- [Home Manager Syncthing 구현](https://github.com/nix-community/home-manager/blob/master/modules/services/syncthing.nix): syncthing·syncthing-init 두 agent와 store 기반 실행 경로.
- [nix-darwin #1678](https://github.com/nix-darwin/nix-darwin/issues/1678): sh 표시 문제, store 안 wrapper가 부팅 시 mount 문제를 해결하지 못한다는 유지보수자 설명.
- [nix-darwin #1219](https://github.com/nix-darwin/nix-darwin/issues/1219): store 밖 launcher 배포에 관한 upstream 논의.
- [공식 Syncthing macOS 앱](https://github.com/syncthing/syncthing-macos): 별도 앱 기반 운영 대안. 현재 저장소의 선언형 설정을 자동 대체한다고 확인한 것은 아님.

## 구현 결과

`users/shared/darwin/launchd/`가 Foundation 기반 네이티브 실행기를 Nix로 빌드한다. 사용자 Library 아래 고정 경로로 복사하고, 원래 Program·ProgramArguments를 별도 명령 plist에 저장한다. 실행기는 시스템의 wait4path가 성공한 뒤 이 명령을 exec한다. 런타임 라이브러리는 macOS 시스템 라이브러리만 사용한다.

생성된 사용자 LaunchAgent 5개의 고정 진입점, 인자 보존, 같은 PID의 실제 명령 교체, 동일 경로의 명령 갱신을 실행 검증했다. 실제 macOS 시스템 빌드도 통과했다. 서비스 적용·재부팅 및 반복 알림 소멸은 아직 검증하지 않았다. 시스템 부팅 서비스와 Determinate 설치기 hook은 upstream 구현을 유지한다.

## 추가 조사: 공개 dotfiles와 현재 구현 재검토

공개 코드 3곳을 확인했지만, 반복 BTM 알림을 완전히 해결했다고 입증한 사례 3개는 찾지 못했다.

| 실제 코드                                                                                                                                                           | 방법                                                                                                                 | 확인 한계                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| [chenxin-yan/sketchybar](https://github.com/chenxin-yan/nix-dotfiles/blob/18bc0ba69eb39679fb955022238b534a929ebe82/modules/features/desktop/sketchybar/default.nix) | store 밖 `/usr/local/libexec/nix-darwin/sketchybar-wrapper`에서 대기 후 `/run/current-system/sw/bin/sketchybar` 실행 | shell 사용. BTM 반복 알림 소멸을 입증하지 않음 |
| [gapul/launchd-agent](https://github.com/gapul/dotfiles/blob/4aa1d2a4b162f899558bd26af4dc4e38bd9b8837/nix/lib/launchd-agent.nix)                                    | calendar agent에 RunAtLoad=false                                                                                     | 불필요한 시작 감소이며 재등록 해결 아님        |
| [ahmedelgabri/mail](https://github.com/ahmedelgabri/dotfiles/blob/17be7800ba90931a78db29f930379535ed4413b6/nix/parts/modules/shared/mail.nix)                       | 표준 nix-darwin command·StartInterval·RunAtLoad                                                                      | sh 문제의 해결 사례 아님                       |

[nix-darwin #1052](https://github.com/nix-darwin/nix-darwin/pull/1052)는 마운트 전 실행 문제 때문에 wait4path를 도입했다. #1219·#1678은 조사 시 open이며, store 밖 이름 있는 실행기를 제안하는 방향이다. 현재 네이티브 실행기의 방향과는 일치하지만 모든 사용자 agent의 lifecycle 재구현이 필요하다는 뜻은 아니다.

현재 구현에는 **수정 전 적용을 권할 수 없는 결함**이 있다. command 파일만 변경되면 stopped one-shot은 PID가 없어 재실행을 건너뛴다. syncthing-init의 새로운 devices/folders 선언이 적용 시 반영되지 않을 수 있다. 네이티브 exec 테스트와 시스템 빌드 성공은 이 설정 갱신 계약을 검증하지 못했다.

또한 `$out/LaunchAgents` 치환은 Home Manager 내부 출력 형태에 의존하며, 제거한 agent의 runtime 복사본 정리가 없다. 활성 generation의 activation script가 command derivation을 직접 참조하므로 해당 closure가 유지되는 동안 GC 연결은 유지된다.

[chenxin-yan/kanata](https://github.com/chenxin-yan/nix-dotfiles/blob/18bc0ba69eb39679fb955022238b534a929ebe82/modules/features/desktop/kanata/default.nix)의 고정 경로·host-local signing은 TCC 승인 유지 목적이다. BTM 반복 알림 방지 근거로 혼용하지 않는다.

[SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)는 앱 helper의 공식 방법이지만 앱 bundle과 등록 관리가 필요하다. CLI 두 항목을 위해 새 앱을 만드는 것은 더 복잡하다. 기존 native 앱에 실행을 맡길 때 검토할 수 있다.

Apple은 BTM의 identity 알고리즘 전체를 공개하지 않는다. store 경로가 바뀌면 반드시 새 UUID와 알림이 생긴다고 단정할 수 없다. 다음 성공 조건은 (1) 무변경 적용에서 등록 유지, (2) Syncthing 선언 변경에서 one-shot 재실행 및 실제 설정 반영, (3) 적용·재로그인 후 BTM UUID와 알림 관찰이다. 추가 조사는 코드나 서비스 상태를 변경하지 않았다.

## 사용자가 요청한 실제 적용

`./switch.sh`를 실행했다. Nix 시스템·Home Manager 활성화는 완료됐고 시스템 profile은 같은 system-11-link를 유지했다. 사용자 plist 5개도 같은 내용이다. 후속 dotfiles-remote-apply의 sudo 인증은 비대화형 실행 환경에서 실패해 전체 명령은 exit 1이다. 원격 앱 후속 설정과 이후 정리는 완료로 보고하지 않는다.

적용 후 최근 5분의 BTM advisory notification 로그는 없었다. 다만 적용 후 dumpbtm 조회가 응답하지 않아 중단했으므로 전후 UUID 전체 비교는 완료하지 못했다. 부팅·로그인 이후까지 반복 알림이 사라졌다고 결론내릴 수 없다.
