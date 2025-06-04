# dotfiles: Declarative macOS & NixOS Environment

> Nix, Home Manager, nix-darwin 기반의 macOS/Linux 개발 환경 선언적 관리

## Overview

이 저장소는 Nix, Home Manager, nix-darwin을 활용해 macOS 및 Linux 개발 환경을 **완전히 선언적**으로 관리합니다. 모든 설정은 코드로 관리되며, 새로운 시스템에서도 한 번의 명령어로 동일한 환경을 재현할 수 있습니다.

자동화된 변경 작업을 담당하는 Codex agent를 위해 별도의 가이드 파일(`AGENTS.md`)을 유지합니다. 에이전트 관련 규칙이나 작업 흐름을 수정할 경우 이 파일을 우선 갱신하세요. 이제 AGENTS.md에는 에이전트 테스트 방법도 포함됩니다. 추가 문서는 `docs/` 디렉터리에 저장되며, 프로젝트 구조에 대한 간략한 설명은 `docs/overview.md`에서 확인할 수 있습니다.

## Features

- macOS, NixOS 모두 지원
- flakes 기반의 reproducible 환경
- Home Manager, nix-darwin 통합
- 공통/호스트별/역할별 모듈화
- 주요 개발 도구 및 앱 자동 설치/설정
- GitHub Actions 기반 CI로 macOS/Linux(x86_64, aarch64) 빌드 및 테스트
- 멀티플랫폼 matrix smoke 테스트로 기본 빌드 오류 조기 확인
- 오래된 PR은 자동으로 stale로 표시 후 닫힘
- Makefile 기반 로컬/CI 명령어 통합

## Directory Layout

```
.
├── apps/           # Nix installable apps (mkApp 기반, 플랫폼별)
│   ├── x86_64-darwin/
│   ├── aarch64-darwin/
│   ├── x86_64-linux/
│   └── aarch64-linux/
├── hosts/          # 호스트별 설정 (macOS, NixOS)
│   ├── darwin/
│   └── nixos/
├── modules/        # 시스템/공통/프로그램별 모듈
│   ├── darwin/
│   ├── nixos/
│   └── shared/
├── overlays/       # Nixpkgs 오버레이
├── legacy/         # 이전 버전/백업/마이그레이션 자료
├── tests/          # flake checks and unit tests
├── docs/           # 추가 문서
├── flake.nix       # Nix flake entrypoint
├── flake.lock
└── README.md
```

- **apps/**: `nix run .#switch` 등으로 실행할 수 있는 Nix 앱 정의 (플랫폼별)
- **hosts/**: 각 호스트별 시스템/유저 설정(nix-darwin, home-manager, nixos)
- **modules/**: 공통/프로그램별/서비스별 Nix 모듈 (darwin, nixos, shared)
- **overlays/**: 패치, 커스텀 패키지
- **legacy/**: 이전 구조/마이그레이션 자료
- **tests/**: flake checks and unit tests
- **docs/**: 추가 설명을 위한 문서 모음

## Getting Started

### 1. Nix 설치 및 flakes 활성화

```sh
xcode-select --install
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
# flakes 활성화: ~/.config/nix/nix.conf에 아래 추가
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 2. 저장소 클론

```sh
git clone https://github.com/yourname/dotfiles.git
cd dotfiles
```

### 3. 환경 적용

#### macOS

```sh
make switch HOST=<host>
```

#### NixOS

```sh
make switch HOST=<host>
```

#### Home Manager만 적용

```sh
home-manager switch --flake .#<host>
```

## Development Workflow

1. 설정 파일 수정
2. 아래 명령어로 적용/테스트
   - `make lint` (optional `FILES=<paths>`)
   - `make smoke`
   - `make test`
   - `make build`
   - `make switch HOST=<host>`
   - `home-manager switch --flake .#<host>`

## Smoke Tests

GitHub Actions에서 각 플랫폼(macOS, Linux)의 x86_64와 aarch64 환경에 대해 smoke test를 실행해 빌드 오류를 조기에 확인합니다. 로컬에서는 `make smoke` 명령어로 동일한 테스트를 수행할 수 있습니다.
추가된 `tests/smoke.nix` 파일은 flake의 기본 정보를 검증하는 간단한 smoke 테스트를 제공합니다.

## How to Add/Modify Modules

- 공통 CLI 프로그램: `modules/shared/user-env/cli/<name>/default.nix`
- 공통 GUI 프로그램: `modules/shared/user-env/gui/<name>/default.nix`
- macOS 전용: `modules/darwin/`
- NixOS 전용: `modules/nixos/`
- 호스트별: `hosts/<platform>/<host>/home.nix`, `hosts/<platform>/<host>/configuration.nix`

## 참고

- [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config)
- [phip1611/nixos-configs](https://github.com/phip1611/nixos-configs)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

> 변경 이력, 마이그레이션 내역 등은 legacy/ 디렉토리와 커밋 로그를 참고하세요.

