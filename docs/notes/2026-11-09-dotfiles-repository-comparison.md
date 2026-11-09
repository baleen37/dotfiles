# 실제 dotfiles 저장소의 단순화 패턴 비교

2026-11-09 확인. 비교 후 사용자가 [Misterio77의 standard](https://github.com/Misterio77/nix-starter-configs/tree/main/standard)를 구조 참고 기준으로 지정했다.
세 저장소의 README와 실제 Nix·셸 파일을 확인했다. 실행 검증이나 품질 순위는 아니다.

## 비교 결과

| 저장소                                                                                                            | 실제 구조                                                                        | 참고할 점                             | 그대로 도입하지 않을 점                    |
| ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------- | ------------------------------------------ |
| [Misterio77/nix-starter-configs](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/README.md) | minimal flake가 호스트와 독립 사용자 설정을 직접 연결하고, 표준 적용 명령을 사용 | 출력과 설정을 직접 연결하는 작은 구조 | 사용하지 않는 overlay·공통화 틀            |
| [Mic92/dotfiles](https://raw.githubusercontent.com/Mic92/dotfiles/main/Readme.md)                                 | Nix가 실행 도구 경로를 고정하지만, 호스트별 profile 선택은 Bash에도 선언         | 필요한 실행 도구를 Nix가 소유         | 호스트 목록을 셸에 다시 선언하는 방식      |
| [dustinlyons/nixos-config](https://raw.githubusercontent.com/dustinlyons/nixos-config/main/README.md)             | Nix app이 플랫폼별 셸 파일을 실행하며 build와 build-switch를 구분                | 준비·빌드·적용 역할을 드러내기        | 같은 명령을 위한 Nix 포장과 셸 진입점 증가 |

실제 구현 근거:

- Misterio77: [minimal/flake.nix](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/minimal/flake.nix)
- Mic92: [home-manager/flake-module.nix](https://raw.githubusercontent.com/Mic92/dotfiles/main/home-manager/flake-module.nix)
- dustinlyons: [flake.nix](https://raw.githubusercontent.com/dustinlyons/nixos-config/main/flake.nix), [Darwin build](https://raw.githubusercontent.com/dustinlyons/nixos-config/main/apps/aarch64-darwin/build), [Darwin build-switch](https://raw.githubusercontent.com/dustinlyons/nixos-config/main/apps/aarch64-darwin/build-switch)

## 이 저장소에 대한 판단

**사용자가 선택한 기준은 Misterio77의 standard 구성이다.** 초기 비교는 minimal을 살폈지만, 구현 기준은 standard로 변경했다.

`pkgs/default.nix`에 커스텀 패키지를 정의하고, `overlays/default.nix`에서 이름 있는 overlay를 내보낸다. 기존 flake-parts가 이 정의를 패키지 출력과 시스템 설정에 연결한다. 호스트·사용자 디렉터리와 입력 버전은 유지한다. 사용하지 않는 재사용 모듈 디렉터리는 추가하지 않는다.

구조 근거: [standard/flake.nix](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/standard/flake.nix), [standard/pkgs/default.nix](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/standard/pkgs/default.nix), [standard/overlays/default.nix](https://raw.githubusercontent.com/Misterio77/nix-starter-configs/main/standard/overlays/default.nix).

1. Nix에 이미 있는 호스트·플랫폼·설정 출력을 그대로 사용한다. 같은 목록을 셸에 다시 만들지 않는다.
2. `bootstrap`과 `switch`의 계약은 유지하되, 명령을 포장하기 위한 파일과 새 공개 진입점은 늘리지 않는다.

다른 저장소에서도 셸을 사용한다는 사실이 이 저장소의 셸 로직을 늘릴 근거는 아니다.
Nix app으로 명령을 감싸는 것과 Nix가 설정 정책을 소유하는 것도 구분해야 한다.

## 확인 범위와 한계

- **Nix 선언과 실행 스크립트의 책임 분리:** 실제 flake·module·셸 본문으로 확인했다.
- **bootstrap·switch의 크기와 진입점:** 표준 명령 직접 사용, Nix app, 플랫폼별 셸 진입점을 비교했다.
- **파일 분리·공통화가 실제로 복잡성을 줄이는지:** 파일을 따라가야 하는 구조를 비교했다. 유지 비용에 대한 평가는 설계 판단이다.

세 저장소가 현재 프로젝트의 키 비덮어쓰기·macOS 권한 검사·Debian 서비스 보존 계약을
모두 제공한다고 확인한 것은 아니다. 템플릿을 그대로 교체하거나 기존 보호 동작을 제거하지 않는다.
standard에 맞춘 패키지·overlay 경로 변경은 적용했다. 변경 전후 macOS 시스템·사용자 패키지 경로와 bootstrap-tools derivation이 동일함을 확인했다.
