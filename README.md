# dotfiles (Nix 기반 환경 관리)

이 저장소는 Nix, Home Manager, nix-darwin을 활용하여 macOS 및 공통 개발 환경을 선언적으로 관리합니다.

## 디렉토리 구조 및 역할

```
.
├── flake.nix                # Nix flake 진입점, 전체 환경 선언
├── flake.lock               # flake 의존성 lock 파일
├── install.sh               # Nix 및 환경 설치 스크립트
├── modules/                 # Nix 모듈(프로그램별/공통/OS별 설정)
│   ├── darwin/              # macOS(darwin) 전용 설정
│   │   └── programs/        # macOS용 프로그램별 모듈 및 파일
│   ├── nixos/               # NixOS 전용 설정
│   │   └── programs/        # NixOS용 프로그램별 모듈
│   └── shared/              # macOS/Linux 공통 설정
│       └── programs/        # 공통 프로그램별 모듈
├── libraries/               # 커스텀 Nix 패키지/모듈
│   ├── home-manager/        # Home Manager 확장 모듈
│   │   └── programs/        # Home Manager용 프로그램별 모듈
│   └── nixpkgs/             # 직접 빌드하는 패키지
│       └── programs/        # 패키지별 소스/테스트
├── config/                  # 앱별 설정파일(예: nvim, hammerspoon)
│   └── hammerspoon/         # 예시: Hammerspoon 설정
│       └── Spoons/          # Hammerspoon Spoons
├── bin/                     # 사용자 스크립트/실행파일
├── result/                  # Nix 빌드 결과물(환경 적용 시 자동 생성)
├── .zshrc, .tmux.conf 등    # 기타 dotfiles
└── ...
```

## Nix 환경 적용 흐름

1. **flake.nix**
   - Home Manager, nix-darwin, nixpkgs 등 주요 입력을 선언
   - `darwinConfigurations.<host>`로 macOS 환경을 선언적으로 정의
2. **modules/**
   - `modules/darwin/`: macOS 전용 시스템/유저/프로그램 설정(Nix-darwin)
   - `modules/nixos/`: NixOS 전용 시스템/프로그램 설정
   - `modules/shared/`: macOS/Linux 공통 프로그램 설정(Home Manager)
3. **libraries/**
   - 직접 빌드하는 패키지(예: Hammerspoon, Homerow 등)
   - Home Manager 확장 모듈
4. **config/**
   - nvim, hammerspoon 등 앱별 설정파일 및 하위 구조
5. **result/**
   - Nix 빌드 및 환경 적용 결과물이 저장되는 경로(자동 생성)
6. **기타 dotfiles**
   - `.zshrc`, `.tmux.conf` 등 쉘/에디터/툴 설정파일

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

### 1. 전체 통합 검증 (로컬)

모든 주요 테스트를 한 번에 실행하려면 아래 명령어를 사용하세요:

```sh
make verify-all
```
- `nix flake check` + 모든 호스트별 빌드, nvim smoke test, 커스텀 패키지 빌드, home-manager dry-run, NixOS VM 테스트까지 포함
- CI와 동일한 수준의 검증을 로컬에서 한 번에 수행할 수 있습니다.

### 2. NixOS VM 테스트 (로컬/CI 공통)

flake 기반 NixOS VM 테스트(homerow 등)는 아래 명령어로 직접 실행할 수 있습니다:

```sh
nix flake check
```
- `flake.nix`의 checks에 등록된 모든 VM 테스트가 실행됩니다.
- homerow VM 테스트 정의는 `libraries/nixpkgs/programs/homerow/test.nix`에 선언되어 있습니다.

### 3. macOS 환경 적용 테스트

```sh
darwin-rebuild switch --flake .#<host>
```
- 실제 시스템에 변경사항을 적용하여 정상 동작하는지 확인합니다.
- `<host>`는 flake에서 정의한 호스트 이름으로 교체해야 합니다. 예: `darwin-rebuild switch --flake .#my-macbook`

### 4. 설치

```sh
make install
```
- Nix 및 환경 설치 스크립트 실행

## CI(GitHub Actions) 테스트
- PR, main 브랜치 push 시 자동으로 `nix flake check`를 실행하여 모든 VM 테스트 및 환경 검증을 수행합니다.
- 별도의 개별 NixOS 테스트 스크립트는 사용하지 않습니다.

## 주요 관리 프로그램
- Home Manager: 유저별 dotfiles 선언적 관리
- nix-darwin: macOS 시스템 설정 선언적 관리
- 직접 빌드 패키지: Hammerspoon, Homerow 등

## 참고
- 모든 설정은 Nix로 선언적으로 관리됩니다.
- 새로운 프로그램/설정 추가는 `modules/` 또는 `libraries/`에 Nix로 선언하면 됩니다.
- macOS 외 Linux도 공통 모듈(`modules/shared/`)을 통해 확장 가능합니다.

```bash
./install.sh
```
