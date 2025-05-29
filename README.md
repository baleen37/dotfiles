# dotfiles (Nix 기반 환경 관리)

이 저장소는 Nix, Home Manager, nix-darwin을 활용하여 macOS 개발 환경을 선언적으로 관리합니다.

## 디렉토리 구조 및 역할

```
.
├── flake.nix                # Nix flake 진입점, 전체 환경 선언
├── flake.lock               # flake 의존성 lock 파일
├── install.sh               # Nix 및 환경 설치 스크립트
├── modules/                 # Nix 모듈(프로그램별/공통/OS별 설정)
│   ├── darwin/              # macOS(darwin) 전용 설정
│   └── shared/              # macOS/Linux 공통 설정
├── libraries/               # 커스텀 Nix 패키지(직접 빌드, 예: Hammerspoon)
│   ├── home-manager/        # Home Manager 확장 모듈
│   └── nixpkgs/             # 직접 빌드하는 패키지
├── config/                  # 앱별 설정파일(예: nvim, hammerspoon)
├── bin/                     # 사용자 스크립트/실행파일
└── ...                      # 기타 dotfiles 및 설정
```

## Nix 환경 적용 흐름

1. **flake.nix**
   - Home Manager, nix-darwin, nixpkgs 등 주요 입력을 선언
   - `darwinConfigurations.<host>`로 macOS 환경을 선언적으로 정의
2. **modules/**
   - `modules/darwin/`: macOS 전용 시스템/유저 설정(Nix-darwin)
   - `modules/shared/`: 공통 프로그램 설정(Home Manager)
3. **libraries/**
   - 직접 빌드하는 패키지(예: Hammerspoon, Homerow 등)
   - Home Manager 확장 모듈
4. **config/**
   - nvim, hammerspoon 등 앱별 설정파일

## 설치 방법

```bash
./install.sh
# 또는
make install
```
- Nix가 없으면 자동 설치
- 적용할 호스트명(`baleen` 또는 `jito`)을 입력
- flake 기반 환경 빌드 및 적용 자동화

## 테스트 실행 방법

Nix 관련 파일(예: flake.nix, 모듈, 패키지 등)을 수정한 후에는 반드시 아래 테스트를 수행해야 합니다.

### 1. 전체 통합 검증 (verify-all)

모든 주요 테스트를 한 번에 실행하려면 아래 명령어를 사용하세요:

```sh
make verify-all
```
- `nix flake check` + 모든 호스트별 빌드, nvim smoke test, 커스텀 패키지 빌드, home-manager dry-run, NixOS 테스트(nixosTests)까지 포함
- CI와 동일한 수준의 검증을 로컬에서 한 번에 수행할 수 있습니다.

> 더 이상 `make test`, `make build-custom`, `make dryrun-home` 등 개별 테스트 타겟은 제공하지 않으며, `make verify-all`만 사용하면 됩니다.

### 2. macOS 환경 적용 테스트

```sh
darwin-rebuild switch --flake .#<host>
```
- 실제 시스템에 변경사항을 적용하여 정상 동작하는지 확인합니다.
- `<host>`는 flake에서 정의한 호스트 이름으로 교체해야 합니다. 예: `darwin-rebuild switch --flake .#my-macbook`

### 3. 설치

```sh
make install
```
- Nix 및 환경 설치 스크립트 실행

## 주요 관리 프로그램
- Home Manager: 유저별 dotfiles 선언적 관리
- nix-darwin: macOS 시스템 설정 선언적 관리
- 직접 빌드 패키지: Hammerspoon, Homerow 등

## 참고
- 모든 설정은 Nix로 선언적으로 관리됩니다.
- 새로운 프로그램/설정 추가는 `modules/` 또는 `libraries/`에 Nix로 선언하면 됩니다.
- macOS 외 Linux도 확장 가능(공통 모듈 활용)

```bash
./install.sh
```
