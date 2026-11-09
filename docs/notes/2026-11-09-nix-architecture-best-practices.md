# Nix 중심 호스트 준비·적용 구조: upstream 사례와 개선점

조사일: 2026-11-09. 범위는 현재 진행 중인 준비·적용 정책, 설정 소스, age identity 개선이다.
[이전 전체 조사](2026-11-06-nix-flake-dotfiles-best-practices.md)를 대체하지 않는다.

## 먼저 할 일

**정책·도구·검증은 Nix module이 소유하고, 설치 전 준비와 외부 상태 변경만 실행 adapter에 남긴다.**
Bash를 `writeShellApplication` 문자열로 옮기는 것만으로 선언형 전환이 되지는 않는다.
호스트 분기·패키지 목록·검증 순서를 여러 곳에서 다시 계산하면 locality는 그대로다. 이는 아래 upstream 패턴을 이 저장소에 적용한 설계 판단이다.

| 우선순위 | 현재 저장소와 비교한 개선점                               | 적용 상태·판단                                                                                                                | 예상 시간        |
| -------- | --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| 1        | identity 경로·필요 도구·복호화 검사를 Nix module에서 조립 | 이번 변경: `users/shared/secrets.nix`가 identity 도구 의존성과 `prepareIdentity`·`preflight`를 함께 선언                      | 이번 작업 범위   |
| 2        | 준비와 적용의 부작용을 분리                               | 이번 변경: Debian bootstrap은 설치·키 준비, switch는 검증·서비스 적용. 이전 옵션 거부                                         | 이번 작업 범위   |
| 3        | 검사와 적용에 같은 설정 소스 사용                         | 이번 변경: Darwin은 검사한 snapshot 디렉터리에서 기존 `--flake .#호스트` 명령 실행                                            | 이번 작업 범위   |
| 4        | 호스트 요구사항 계산도 Nix에 집중                         | 구현: `lib/setup-requirements.nix`의 읽기 전용 option에서 앱 관리·Homebrew 요구사항을 계산. bootstrap/switch가 공통 결과 소비 | 완료             |
| 5        | 평가·파생물 빌드·실제 CLI 검증을 구분                     | 검증: 실제 age/sops CLI 시나리오와 Debian 12·13 ARM64 APT·systemd·권한 확인. GUI와 신규 tailnet 가입은 제외                   | 서비스·권한 완료 |

## 1. flake-parts: 도구와 검증을 출력으로 선언

**직접 근거:** flake-parts는 시스템별 `apps`, `packages`, `devShells`, `checks`를 제공한다. `checks`는 빌드할 derivation이다. [공식 문서](https://flake.parts/options/flake-parts.html)

**로컬 비교:** 이미 `flake-modules/packages.nix`에 bootstrap 도구, `flake-modules/checks.nix`에 검사 탐색이 있다. 이 구조는 유지한다. identity 도구 의존성과 호스트별 경로·복호화 대상은 `users/shared/secrets.nix`에 함께 선언했다.

**적용:** `lib/setup-requirements.nix`의 typed read-only option이 앱 관리·Homebrew 요구사항을 계산한다. 실행 adapter는 같은 정책을 재구현하지 않고 결과를 읽는다. Nix가 없는 최초 설치까지 Nix에 맡기는 것은 순환 의존이므로, 최초 Nix 설치만 작은 bootstrap으로 남긴다.

## 2. Home Manager: 빌드 결과와 활성화를 분리

**직접 근거:** Home Manager는 먼저 설정을 빌드한 뒤 결과를 활성화하며, `switch`는 두 동작을 합친다. module의 옵션 타입과 assertion은 빌드 과정에서 검증된다. [공식 문서](https://nix-community.github.io/home-manager/usage.html)

**로컬 비교:** ADR 0002·0004는 도구·identity 준비와 구성 적용을 분리한다. 기존 Debian 구현은 bootstrap 인자를 받지 못했고 apply가 설치·키 복원·서비스 적용을 함께 수행했다. 이번 변경으로 공개 CLI 계약과 역할을 맞춘다.

**적용 한계:** Home Manager가 이 저장소의 bootstrap 분리를 요구하는 것은 아니다. Debian의 APT·systemd 소유권은 ADR대로 유지한다. 비교 사례를 이유로 Debian 전체를 NixOS나 Home Manager로 전환하지 않는다.

## 3. Nix: 고정한 소스에서 검사하고 빌드

**직접 근거:** `nix flake archive`는 flake와 input을 store에 복사하고 경로를 반환한다. [공식 문서, 2.35](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-flake-archive)

**로컬 비교:** `prepare_flake`는 ignored 파일을 제외한 snapshot을 만들지만 기존 Darwin 적용은 다시 checkout의 `.`을 선택했다. 이번 변경은 snapshot의 `.`에서 적용해 검사·적용 입력을 일치시킨다. Git 파일 선택과 symlink 보존, 로컬 호스트 등록 예외는 유지한다.

**후속 개선 — 추론:** 여러 호스트에 동일 소스를 전송하거나 재시작 뒤에도 같은 소스를 재사용해야 한다면, snapshot을 한 번 archive한 store path로 고정하는 방법을 검토한다. 현재 단일 로컬 실행에는 추가 archive 수명 관리까지 도입할 근거가 부족하다. “같은 소스”와 “같은 빌드 산출물”은 다르므로, 향후 build/activate 분리를 더 진행할 때 구분해야 한다.

## 4. sops-nix: 시크릿 선언과 identity 준비를 분리

**직접 근거:** sops-nix는 활성화 시 시크릿을 복호화하고 소유자·권한을 선언한다. `sops.age.generateKey = false`일 때는 기존 keyFile을 준비해야 한다. [upstream 옵션 문서](https://dl.thalheim.io/)

**로컬 비교:** 이미 `users/shared/secrets.nix`가 경로와 복호화 대상을 선언하고 키 자동 생성을 끈다. 이번 변경은 같은 module이 identity 준비 명령도 조립하도록 한다. 실제 인증·파일 검증·원자적 비덮어쓰기 게시는 Python implementation이 맡고 Nix와 네이티브 Debian이 재사용한다.

**근거의 한계:** 잘못된 기존 키, symlink, 복원 경쟁에서 비덮어쓰기는 sops-nix 옵션만으로 보장된다고 말할 수 없다. 실제 CLI·파일시스템 시나리오로 별도 검증해야 한다. 1Password 인증과 macOS TCC는 순수 Nix 평가가 수행할 작업도 아니다.

## 5. nix-starter-configs: 실제 dotfiles의 선언 구조

**직접 근거:** `Misterio77/nix-starter-configs`의 standard 구성은 `systems`를 한곳에 선언하고 `packages`·`formatter`를 생성한다. `nixosConfigurations`와 독립 `homeConfigurations`도 나눈다. [실제 flake.nix](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/standard/flake.nix)

저장소 안내는 기존 배포판에서도 사용자 구성을 사용할 수 있도록 설명한다. [README](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/README.md)

프로그램 활성화는 `programs.*.enable`, 사용자 정보는 `home.*`, 시스템 Nix 설정은 `nix.settings`에 선언한다. [home module](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/standard/home-manager/home.nix), [호스트 module](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/standard/nixos/configuration.nix)

**로컬 비교:** 이 저장소도 이미 typed host registry와 `perSystem`을 쓴다. 따라서 템플릿의 자체 시스템 반복 함수를 추가하지 않는다. 남은 실행 요구사항을 Nix option·assertion으로 집중하는 패턴만 참고한다. 기존 Debian의 APT·systemd 소유권을 바꿀 이유도 없다.

**비채택:** 템플릿의 초기 암호, 쓰지 않는 overlay, 추가 플랫폼 목록은 복사하지 않는다. 확인한 템플릿의 25.11 버전도 이 저장소의 버전 선택 근거가 아니다. 이 템플릿이 준비·적용 분리나 identity 복원 경쟁을 해결했다고 주장하지 않는다.

## 검증은 평가·빌드·실행으로 구분

**직접 근거:** Nix의 `--all-systems`는 모든 시스템 출력을 평가하지만 `--no-build`는 checks를 빌드하지 않는다. [공식 문서, 2.35](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-flake-check)

**로컬 비교:** 이 저장소의 assertion derivation은 실제 빌드해야 실행된다. `setup-scripts.sh`는 공개 CLI를 외부 명령 adapter로 실행한다. Debian 테스트는 내부 함수 여러 개를 patch하던 방식에서 실제 CLI·age/sops·임시 파일을 검증하는 방식으로 바꾼다.

**실행 결과:** [Debian 12·13 ARM64 네이티브 검증](2026-11-09-debian-native-verification.md)에서 APT 설치 후 자동 시작 문제를 발견해 수정했다. 신규 서비스의 비활성 상태, 기존 실행 ID 보존, 키·상태 파일 권한, 권한 부족 거부를 확인했다. GUI와 신규 tailnet 가입, 네이티브 amd64 실행은 별도 검증 범위다.

## 조사 범위와 한계

- Nix가 도구·설정·검증을 소유하고 Bash를 최소화하는 방식: flake-parts와 Home Manager의 출력·module 패턴 확인.
- bootstrap 준비와 switch 적용 분리: upstream의 build/activation 분리를 참고하되, 프로젝트 ADR의 준비·적용 분리와 구분.
- 동일한 설정 소스를 검사하고 적용하는 방식: archive의 store 고정 패턴 확인. 현재 snapshot 방식과의 절충은 로컬 설계 판단.
- 기존 age identity 보존과 시크릿 검증: sops-nix 선언과 외부 상태 adapter의 책임을 구분. 무덮어쓰기 보장은 별도 구현·검증 필요.
- 실제 CLI·플랫폼별 검증: 전체 평가, checks 빌드, 네이티브 동작의 증거를 구분.

개인 dotfiles 저장소의 인기나 유행을 베스트 프랙티스의 증거로 삼지 않았다. flake-parts·Home Manager·Nix·sops-nix·nix-starter-configs의 공식 문서·저장소에서 확인 가능한 패턴만 비교했다. 위에서 구현·검증으로 표시한 항목은 적용했다. store archive 등 “후속 개선”은 미구현 제안이다.
