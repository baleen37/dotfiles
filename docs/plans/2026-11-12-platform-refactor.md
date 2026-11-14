# 플랫폼별 구성 리팩토링 계획

- 날짜: 2026-11-12
- 상태: 후속 사용자 요청으로 시스템 조립 기준을 mitchellh로 변경. 실제 구현은 `users/shared/{darwin,nixos,home-manager}.nix`와 `development.nix`를 사용한다. 아래는 변경 전 제안 기록이다.
- 계획 작성: Codex / 결정·운영 책임: dotfiles 관리자
- 예상 작업량: 구현·로컬 검증 3~5시간. 원격 CI·플랫폼 빌드 대기 시간은 별도다.

## 결정 요약

현재 flake-parts·시스템 생성기·모듈 자동 발견을 유지한다. 공유 Darwin 구현을 `system`과 `home`으로 분리하고, 실제 반복되는 개발 도구 선택만 하나의 Home Manager 모듈로 추출한다. 호스트는 어떤 공유 설정을 사용할지 계속 직접 선택한다.

구조 기준은 기존에 정한 Misterio77/nix-starter-configs의 standard다. 다른 레포의 전체 구조를 가져오지 않는다. 최신 AGENTS.md의 공유 구현 `users/shared/`, 호스트 선택 `machines/` 원칙을 따른다.

이번 작업은 설정 결과를 유지하는 구조 변경이다. 시크릿 설계, 키·주입 방식, 패키지 버전, 설치 앱, 서비스 정책은 변경하지 않는다. 실제 시스템 활성화와 앱 삭제는 작업 범위에 포함하지 않는다.

## 현재 상태와 문제

1. `users/shared/darwin/`에 nix-darwin 시스템 모듈과 HM 모듈이 함께 있어 파일의 적용 주체를 이름만으로 구분하기 어렵다.
2. 세 Mac 머신 파일, WSL, 독립 HM 생성 코드에 동일한 프로그램·패키지 활성화 24개가 반복된다. 이는 소스의 명시적 `enable = true` 목록을 비교한 관찰이며, 최종 평가값의 동등성은 구현 전에 별도로 기록해야 한다.
3. 호스트별 선택은 이미 구현되어 있다. optional 모듈을 기본 활성화하는 옛 구조로 되돌리거나 자동 발견을 제거할 필요는 없다.
4. 현재 등록 호스트는 Mac 4개와 WSL이며, Mac 2개가 같은 머신 모듈을 사용한다. 독립 HM 출력은 4개다. Debian 네이티브 적용과 Windows 설정은 별도 경로다.

## 목표 구조

```text
flake.nix                      # 입력·지원 플랫폼
flake-modules/                 # 호스트 선언·flake 출력 조립
lib/                           # 시스템 생성·공통 로직
pkgs/                          # 커스텀 패키지
overlays/                      # additions → modifications → worktree

machines/
  darwin/                      # Mac 공통 최소 설정·호스트 기능 선택
  nixos/wsl.nix                # NixOS-WSL 기능 선택
  debian/                      # 기존 네이티브 준비·적용
  windows/                     # 기존 winget·PowerShell

users/shared/
  home-manager.nix             # 공통 HM 진입점
  programs/                    # 도구별 구현·자동 발견 유지
  packages/                    # 분야별 패키지 구현·자동 발견 유지
  profiles/development.nix     # 이미 반복되는 HM 기능 선택만 재사용
  darwin/
    system/                    # 공유 nix-darwin 설정
    home/                      # macOS 전용 HM 설정
```

공개 `modules/nixos`·`modules/home-manager` 출력, 빈 Linux 공통 폴더, 아키텍처별 디렉터리는 추가하지 않는다. CPU 차이는 호스트의 `system`과 기존 패키지 조건으로 표현한다.

## 플랫폼별 책임

| 대상      | 시스템 설정·실행                           | 사용자 환경                                       |
| --------- | ------------------------------------------ | ------------------------------------------------- |
| macOS     | 머신이 공유 Darwin system 모듈과 앱을 선택 | 공통 HM + 선택한 macOS HM 기능                    |
| NixOS·WSL | 기존 NixOS 생성기와 WSL 머신 모듈          | 공통 HM + 머신의 기능 선택                        |
| Debian    | 기존 네이티브 apply 경로                   | 기존 Nix/HM 환경에 대한 적용 범위를 확대하지 않음 |
| Windows   | 기존 winget·PowerShell                     | WSL 내부는 별도 NixOS 구성                        |

## 1단계: 변경 전 결과 확보 — 30~45분

코드 변경 전에 현재 동작과 실제 CLI를 기록한다. 사용자의 기존 README 변경과 조사 문서는 보존한다.

- 등록된 Darwin·WSL 출력과 독립 HM 출력의 패키지·enable 값·앱·파일·activation 목록을 평가한다.
- Darwin casks, brews, taps, MAS 앱, 주요 defaults, sudo 규칙과 launchd 구성을 기록한다.
- 최소 Darwin 호스트를 격리된 복사본에 추가해 optional 도구·GUI 앱·개인 자동화가 없는지 확인한다.
- 현재 CLI는 실제 스크립트와 ADR 0004를 기준으로 한다. 과거 문서의 호스트 인자·`--home` 예제를 기준으로 인터페이스를 변경하지 않는다.

검증: 변경 전 평가가 성공하고 비교 자료가 생성되어야 다음 단계로 진행한다. 기존 실패가 있으면 위치·원인을 기록해 구조 변경에서 생긴 실패와 구분한다.

## 2단계: Darwin 적용 주체 분리 — 45~90분

### 이동할 파일

| 현재 `users/shared/darwin/` 내부 경로                   | 변경 후 내부 경로                           |
| ------------------------------------------------------- | ------------------------------------------- |
| `default.nix`, `homebrew.nix`                           | `system/default.nix`, `system/homebrew.nix` |
| `power.nix`, `scripts.nix`, `activation.sh`             | `system/` 아래 같은 파일명                  |
| `raycast.nix`, `remote-access.nix`                      | `system/` 아래 같은 파일명                  |
| `keyboard-input.nix`                                    | `home/keyboard-input.nix`                   |
| `vscode-launchservices.nix`, `vscode-launchservices.sh` | `home/` 아래 같은 파일명                    |

머신 3개 파일의 공유 Darwin import를 `users/shared/darwin/system`으로, 공통 HM 진입점의 import를 `darwin/home/`으로 바꾼다. 기존 option 이름과 활성화 순서를 유지한다.

`remote-access.nix`는 기존 구현을 그대로 이동하고 상대 경로만 수정한다. 관련 기능의 설계는 변경하지 않는다. 다른 `.config/` 자산의 전면 이동은 포함하지 않는다.

상대 경로 깊이가 한 단계 늘어난다. Nix import뿐 아니라 scripts·정책 파일·테스트의 `readFile`과 실행 파일 참조를 함께 갱신한다. 내용이 같은 스크립트를 여러 위치에 남기는 호환 래퍼는 추가하지 않는다.

검증: `darwin-test`, `darwin-activation`, `darwin-activation-script`, `darwin-brew-bundle-skip`, `darwin-lid-awake`, `vscode-launchservices`, `keyboard-input` 등 관련 검사를 실행하고 1단계 결과와 비교한다. 사용자 GUI 작업이 시스템 root activation으로 옮겨지면 안 된다.

## 3단계: 반복되는 개발 환경 선택 추출 — 45~60분

`users/shared/profiles/development.nix`에 Mac·WSL·독립 HM에서 이미 공통인 24개 선택만 옮긴다. 이 파일은 HM 모듈이며 자동으로 모든 호스트에 import하지 않는다.

| 진입점                                                             | 변경                                                     |
| ------------------------------------------------------------------ | -------------------------------------------------------- |
| `machines/darwin/{macbook-pro,baleen-macbook,kakaostyle-jito}.nix` | 공통 프로필을 선택하고 Mac 전용 항목은 그대로 유지       |
| `machines/nixos/wsl.nix`                                           | 같은 공통 프로필 선택                                    |
| `flake-modules/home.nix`                                           | 같은 공통 프로필 사용, 기존 Darwin 조건과 출력 조립 유지 |

공통 프로필은 프로그램·패키지 선택만 포함한다. 사용자 이름, 홈 경로, Homebrew 목록, 시스템 서비스, 호스트 정보를 넣지 않는다. 기존 설정 우선순위를 바꾸지 않으며 `mkDefault` 전환 같은 정책 변경은 섞지 않는다.

Mac의 Tailscale·Syncthing 등 추가 기능과 독립 HM의 Darwin 조건은 각 진입점에 남긴다. 독립 HM에 현재 없는 기능이 새로 추가되어서는 안 된다. 새 최소 호스트는 이 프로필을 선택하지 않으므로 기존 최소 구성을 유지한다.

검증: 실제 평가된 각 출력의 enable·패키지 집합이 이전과 동일해야 한다. 격리된 한 호스트의 기능을 바꿔 다른 호스트나 독립 HM에 전파되지 않는지도 확인한다. 평가 자체만 검사하는 기존 테스트가 놓치는 경우 이 동작을 검증하는 assertion을 보완한다.

## 4단계: 전체 검증과 문서 반영 — 60~90분

1. 격리된 복사본에서 전체 플랫폼을 평가한다: `nix flake check --no-build --all-systems --show-trace`.
2. 현재 플랫폼에서 `make test-build`로 assertion을 실제 빌드한다.
3. Nix CLI를 통해 Darwin 시스템과 독립 HM을 활성화 없이 빌드한다. WSL은 Linux 빌더 또는 CI에서 빌드하며, 사용할 빌더가 없으면 평가 성공과 실제 빌드 미실행을 구분해 보고한다.
4. Debian 선언 검증과 기존 플랫폼 분기 시나리오를 실행한다. Windows는 변경된 참조가 있는 경우 기존 winget·PowerShell 검사를 실행한다. 어떤 경우도 설치·서비스 적용을 실행하지 않는다.
5. README의 구조, CONTRIBUTING의 모듈 추가 위치, CLAUDE.md의 관련 경로·명령을 실제 구현과 맞춘다. 문서 전체를 다시 작성하지 않는다. 이때 에이전트 문서 수정 스킬을 적용한다.

검증은 저장소의 `.agents/skills/verify/SKILL.md` 절차를 따른다. 사용자의 ignored 로컬 호스트는 비교 복사본에서 제외하고, 최소 호스트 probe만 그 복사본에 추가한다.

### 완료 기준

- 호스트 이름·사용자·flake 출력 키가 유지된다.
- 각 호스트의 패키지·앱·서비스·설정값과 독립 HM 기능 선택이 유지된다.
- 최소 호스트에는 개발 프로필이나 GUI 설정이 추가되지 않는다.
- bootstrap/switch의 공개 실행 방법과 플랫폼 분기 동작이 유지된다.
- 평가·assertion·실제 빌드의 결과와 미실행 플랫폼이 구분되어 기록된다.

패키지는 순서가 아닌 집합으로 비교한다. 소스 경로 이동에 따라 activation derivation과 store 해시가 달라질 수 있으므로 경로 문자열의 일치만 요구하지 않는다. 생성 파일 내용·명령·순서와 실제 설정값을 비교하고, 변경을 가리도록 store 경로 전체를 무차별적으로 제거하지 않는다.

## 대안과 판단

| 대안                                         | 장점                                            | 이번에 선택하지 않은 이유                                      |
| -------------------------------------------- | ----------------------------------------------- | -------------------------------------------------------------- |
| 경로만 정리하고 반복 선택은 유지             | 변경량이 가장 적음                              | 이미 5개 진입점에 반복되는 선택이 있어 갱신 위치가 분산됨      |
| 공유 시스템 구현을 전부 `machines/`로 이동   | 플랫폼별 파일이 한곳에 모임                     | 최신 지침의 공유 구현·호스트 선택 구분과 맞지 않음             |
| apps 출력·새 factory·새 역할 프레임워크 도입 | 운영 명령이나 구성 조합을 새 방식으로 표현 가능 | 기존 CLI와 생성기가 있어 이번 문제를 해결하는 데 필요하지 않음 |

시스템 생성기는 이번에 유지한다. 이후 독립적인 정책 변경 때문에 조립 코드 수정이 반복될 때만 추가 추출을 검토한다. 외부 의존성은 추가하지 않는다.

## 변경 단위와 되돌리기

Darwin 경로 분리와 개발 프로필 추출을 별도 변경 단위로 유지한다. 단계별 검증이 실패하면 해당 단계만 되돌리고 이전 단계의 검증된 구성을 유지한다. 사용자의 기존 변경을 되돌리거나 실제 시스템 generation을 전환하지 않는다.

## 검토할 결정

공유 Darwin 구현을 `users/shared/darwin/{system,home}`으로 나누고, 기존 선택을 보존하는 `development.nix` 하나만 추출하는 안을 제안한다. 구현 전 이 두 변경의 범위를 검토할 수 있도록 계획을 기록했다. 이번 작업에서는 계획 문서만 작성했다.
