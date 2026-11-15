# 실행 경계 리팩토링과 just 전환 검증

- 날짜: 2026-11-15
- 실행 환경: debian-dev-pve4, x86_64-linux
- 기존 미커밋 변경을 유지했으며 실제 호스트 활성화·APT 설치·서비스 변경·커밋은 하지 않았다.

## 변경 범위

Makefile을 justfile로 교체하고 CI, pre-commit/pre-push, 개발 셸, 사용자 개발 패키지와
현재 운영 문서를 연결했다. `just check`는 전체 플랫폼 평가, `just test`는 항상
단위·통합 assertion 실행, `just test-containers`는 명시적인 VM 실행이다.
`test-build`는 `test`의 별칭이며 기본 `just`는 명령 목록만 출력한다.

Nix와 Debian 실행기는 같은 필터링된 소스를 사용한다. 정상 switch는 네이티브
도구·복호화 준비 상태도 HM 활성화 전에 검사하고, 후속 적용 실패에는 완료 단계와
부분 적용 가능성을 알린다. 자동 롤백은 없다. Python bytecode가 실행 소스를
변경하지 않도록 네이티브 실행기에 `-B`를 사용한다.

Mac 개발 환경의 공통 선택을 `machines/darwin/development.nix`로 모으고, 설정을
관리하는 GUI 앱은 기능 플래그에서 설치 목록을 도출한다. 기기별 sudo 정책과 최소
호스트 구성은 유지했다. Debian의 설치, 동기화, 순서 제어를 별도 파일로 분리했다.

wiki 경로·제외 규칙은 Mac과 Debian이 공유한다. Debian은 수동 `.stignore` 규칙을
보존하면서 관리 제외 규칙을 먼저 적용한다. 이 부분은 의도적인 정책 보완이며,
기존 장치·폴더를 삭제하거나 실제 동기화 상태를 변경하지는 않았다.

## 실행한 검증

`just check`로 aarch64-darwin, x86_64-linux, aarch64-linux 전체 평가를 통과했다.
`just test`의 x86_64-linux 단위·통합 검사 82개가 통과했다. 이 수는 aggregate에
포함된 검사 derivation 수이며 내부의 개별 assertion·시나리오 수와 구분한다.

실제 just CLI 계약 검사 7개, Debian 준비·적용 시나리오 12개, Debian 원격 접속
검사 3개, 공통 원격 접속 검사 10개를 포함한다. 소스 변경 중에도 스냅샷 일관성 유지,
네이티브 사전검사 실패 시 HM 미활성화, 부분 실패 보고, 플랫폼별 실패 전파,
캐시 업로드 실패 전파, 수동 제외 규칙 보존과 반복 실행을 검증했다.

실제 `just build`는 Home Manager activationPackage를 빌드하고 Debian 네이티브
선언을 검증한 뒤 활성화 없이 종료했다. `nix develop --command just --list`도 통과했다.

변경 전 소스와 이후 소스를 평가해 Mac 4개와 독립 Home Manager 4개의 패키지 이름,
앱 목록, sudo 정책, hostname, launchd 구성, 키보드 설정, 기능 선택, 배포 파일 대상,
activation 이름, Syncthing 정책을 비교했다. 비교한 항목의 차이는 8개 개발 환경에
`just` 패키지가 추가된 것뿐이었다. 이는 모든 생성 스크립트의 바이트 동일성이나
실제 실행 환경의 완전한 동등성을 주장하는 검사는 아니다.

전체 treefmt 검사와 ShellCheck·bashate·파일·YAML·캐시 동기화 pre-commit 검사를
통과했다. pre-commit의 `test`·`test-all` 훅은 별도로 실행한 Nix 검사와 중복되어
생략했다. 새 미추적 파일도 검사 목록에 포함했다.

## 검증 한계와 로그

`just test-containers`는 현재 사용자가 `/dev/kvm`을 읽고 쓸 수 없어 사전조건에서
실패했다. Nix 빌더의 system-features에도 kvm이 없었다. VM은 부팅하지 않았으며
macOS 실제 빌드·활성화, Windows 네이티브 실행, 실제 서비스 적용도 검증하지 않았다.

실행 로그와 전후 비교 JSON은 ignored `.direnv/refactor-just/`에 보관한다.
`assertions.log`, `evaluate.log`, `linux-build.log`, `format-check.log`, `pre-commit.log`,
`dev-shell.log`, `vm-tests.log`, `comparison-summary.json`을 구분해서 확인할 수 있다.

## 병합 전 재검증과 최초 설치 경로

최초 준비와 첫 적용은 `bash ./bootstrap.sh`, `bash ./switch.sh`로 안내한다.
bootstrap이 끝나도 호출한 셸의 PATH에 just가 생긴다고 가정하지 않는다. 개발 프로필
적용 후 새 로그인 셸이나 Nix가 준비된 환경의 `nix develop`에서 runner를 사용한다.

PATH에 Nix와 just가 모두 없는 격리 fixture에서 외부 설치 프로그램만 대역으로 교체하고,
실제 bootstrap, build-only, 첫 switch 진입점을 순서대로 실행했다. 해시 검증·준비·
시크릿 검사와 just 없는 실행이 통과했다. 설치 프로그램과 활성화 자체는 대역이며,
실제 새 운영체제 설치 검증과 구분한다. 나머지 플랫폼 시나리오도 just를 호출하면
실패하는 대역으로 runner에 대한 역방향 의존성을 검사했다.

이 변경을 포함한 `just check`, `just test`(82개), `just build`, `just fmt-diff`와
전체 파일 pre-commit 검사를 재실행해 통과했다. 중복 Nix pre-commit 훅은 위 검사로
대체했다. 로그는 ignored `.direnv/merge-verification/`에 보관한다.
