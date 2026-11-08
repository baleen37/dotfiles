# ADR 0003: 반복 준비와 적용에서 sudo 암호 입력을 없앤다

- 상태: 채택 — 구현 완료, 현재 Mac의 sudoers 최초 적용 대기
- 날짜: 2026-11-08
- 결정·운영 책임자: dotfiles 관리자

## 배경과 결정

기존 bootstrap은 이미 도구가 설치된 Mac에서도 시작 시 `sudo -v`를 실행했다.
switch의 호스트 적용도 sudo 허용 규칙이 없으면 암호를 요청했다. 이 때문에
대화형 암호 입력이 어려운 에이전트 환경에서 반복 실행이 중단된다.

bootstrap은 관리자 작업이 실제 필요한 설치 경로에서만 인증하도록 변경한다.
도구가 준비된 머신의 재실행은 불필요한 sudo 인증 없이 준비와 키 검사를 수행한다.
새 머신의 최초 설치에 필요한 관리자 인증까지 없애지는 않는다.

현재 Mac이 사용하는 `machines/darwin/macbook-pro.nix`에 두 명령의 `NOPASSWD`
규칙을 선언한다. 호스트 이름은 `currentSystemName`, 사용자는 `currentSystemUser`로
선택하여 `baleens-MacBook-Pro` 같은 로컬 등록도 같은 머신 모듈을 사용한다.

- `/run/current-system/sw/bin/darwin-rebuild switch --flake <source>#<host>`:
  source는 `.` 또는 `path:/tmp/dotfiles-source.<영숫자>/source`만 허용하고,
  호스트는 해당 flake 출력 이름과 정확히 일치해야 한다. 추가 인자는 허용하지 않는다.
- `/run/current-system/sw/bin/nh clean all --keep 3`: 이 인자 조합만 허용한다.

다른 호스트의 기존 정책은 유지한다. 명령 인자 정규식은 현재 macOS의 sudo가
지원하는 POSIX 확장 정규식이며, sudoers에서 `#`를 이스케이프한다.

## 검토한 대안과 권한 범위

매번 암호나 Touch ID를 요구하면 별도 sudo 규칙은 줄지만 무인 반복 실행은
계속 중단된다. `NOPASSWD: ALL`은 간단하지만 요청한 작업 밖의 모든 명령에도
관리자 권한을 부여하므로 채택하지 않는다.

허용 명령을 좁혀도 사용자가 수정할 수 있는 flake를 root로 활성화하면 해당
설정의 코드를 관리자 권한으로 실행할 수 있다. 이 정책은 신뢰하는 로컬 사용자와
그 사용자가 실행하는 에이전트에 대한 관리자 실행 위임이며, 코드 격리 수단이 아니다.

macOS 앱 관리 동의와 1Password 인증은 sudo와 별개다.
[ADR 0001](0001-macos-permission-preflight.md)의 권한 검사는 유지한다.

## 적용·철회·검증

최초 sudoers 적용에는 기존 관리자 인증이 필요하다. `./switch.sh`를 대화형
터미널에서 한 번 실행해 규칙을 적용한다. 적용 후 인증 캐시가 없는 환경에서
bootstrap 재실행과 switch를 검증하고, 허용하지 않은 명령·호스트는 거부되는지
확인한다. `--build` 성공만으로 암호 없는 실제 적용을 검증했다고 보고하지 않는다.

철회할 때는 호스트의 추가 sudo 규칙을 제거한 구성을 적용한다.
구현 검증에서는 실제 bootstrap의 `--skip-secrets` 재실행이 sudo 인증 없이
완료됐고, 현재 호스트의 생성 규칙은 `visudo -cf`를 통과했다. 시스템 빌드도
성공했다. 현재 시스템의 sudoers 변경과 인증 캐시 없는 실제 적용은 최초 관리자
인증 후 별도로 확인해야 한다.
