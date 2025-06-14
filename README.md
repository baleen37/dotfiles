# dotfiles: Declarative macOS & NixOS Environment

> Nix flakes 기반의 크로스 플랫폼 개발 환경 선언적 관리

## 🚀 Overview

이 저장소는 **Nix flakes**, **Home Manager**, **nix-darwin**을 활용해 macOS 및 NixOS 개발 환경을 완전히 선언적으로 관리합니다. 모든 설정은 코드로 관리되며, 새로운 시스템에서도 한 번의 명령어로 동일한 환경을 재현할 수 있습니다.

### 🎯 주요 특징
- **완전한 재현성**: 코드로 관리되는 모든 설정
- **멀티 플랫폼**: macOS (Intel/Apple Silicon), NixOS (x86_64/aarch64) 지원
- **스마트 설정 보존**: 사용자 개인화 설정 자동 보존 시스템
- **통합 테스트**: 포괄적인 CI/CD 파이프라인
- **개발자 친화적**: bl command system과 자동화 도구

상세한 문서는 `docs/` 디렉터리에서 확인할 수 있습니다:
- 📋 `docs/overview.md` - 프로젝트 개요
- 🏗️ `docs/structure.md` - 아키텍처 구조  
- 🧪 `docs/testing-framework.md` - 테스트 프레임워크

## ✨ Features

### 🏗️ 아키텍처
- **Nix flakes** 기반 완전 재현 가능한 환경
- **모듈화된 구조**: 공통/호스트별/플랫폼별 분리
- **Home Manager** + **nix-darwin** 통합

### 🖥️ 플랫폼 지원
- **macOS**: Intel (x86_64) / Apple Silicon (aarch64)
- **NixOS**: x86_64 / aarch64 아키텍처
- 크로스 플랫폼 패키지 및 설정 관리

### ⚡ 개발 도구
- **bl command system**: 전역 명령어 시스템
- **setup-dev**: 새 Nix 프로젝트 자동 초기화
- **Claude 설정 보존**: 개인화 설정 스마트 보존 시스템
- Makefile 기반 통합 워크플로우

### 🧪 품질 보증
- GitHub Actions CI/CD 파이프라인
- 멀티플랫폼 매트릭스 테스트
- 포괄적인 테스트 스위트 (unit/integration/e2e/performance)
- 자동 코드 품질 검사 (pre-commit hooks)

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
├── lib/            # 공통 Nix 함수
├── overlays/       # Nixpkgs 오버레이
├── scripts/        # 관리 및 개발 스크립트
│   ├── auto-update-dotfiles
│   ├── bl          # bl command system 디스패처
│   ├── install-setup-dev
│   └── setup-dev   # 새 Nix 프로젝트 초기화 스크립트
├── tests/          # 계층적 테스트 구조 (unit/, integration/, e2e/, performance/)
├── docs/           # 추가 문서
├── node_modules/   # npm 의존성
├── package.json    # npm 패키지 설정
├── package-lock.json
├── flake.nix       # Nix flake entrypoint
├── flake.lock
├── Makefile        # 개발 워크플로우 명령어
├── CLAUDE.md       # Claude Code 가이드
└── README.md
```

- **apps/**: `nix run .#switch` 또는 `nix run .#build` 등으로 실행할 수 있는 Nix 앱 정의 (플랫폼별)
- **hosts/**: 각 호스트별 시스템/유저 설정(nix-darwin, home-manager, nixos)
- **modules/**: 공통/프로그램별/서비스별 Nix 모듈 (darwin, nixos, shared)
- **lib/**: 공통 함수 모음 (`get-user.nix`은 `USER`를 읽음)
- **overlays/**: 패치, 커스텀 패키지
- **scripts/**: 프로젝트 관리 및 개발 도구 스크립트
- **tests/**: 계층적 테스트 구조 (unit/, integration/, e2e/, performance/)
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
git clone https://github.com/baleen/dotfiles.git
cd dotfiles
# 필요 시 USER 환경변수로 대상 계정을 지정할 수 있습니다.
export USER=<username>
# USER가 비어 있으면 flake 평가 단계에서 오류가 발생합니다.
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

## 환경 변수 USER 지정 방법

flake 평가 및 빌드 시 USER 환경변수가 필요합니다. 아래와 같이 명령어 앞에 USER를 지정하거나, --impure 옵션을 사용하세요:

```sh
USER=<username> nix run #build
# 또는
nix run --impure #build
```

## 기본값 동작 (23.06 이후)

USER 환경변수가 없을 경우, 일부 Nix 코드에서 기본값을 사용할 수 있도록 개선되었습니다. (lib/get-user.nix 참고)

## Essential Commands

### Development Workflow
```bash
# 필수: USER 환경 변수 설정 (또는 --impure 플래그 사용)
export USER=<username>

# 핵심 개발 명령어
make lint           # pre-commit 훅 실행 (커밋 전 필수 통과)
make smoke          # 빌드 없이 빠른 flake 검증
make test           # 모든 단위 및 e2e 테스트 실행
make build          # 모든 구성 빌드
make switch HOST=<host>  # 현재 시스템에 구성 적용

# 플랫폼별 빌드
nix run .#build     # 현재 시스템용 빌드
nix run .#switch    # 현재 시스템용 빌드 및 전환
nix run .#build-switch  # 빌드 후 즉시 전환 (sudo 권한 필요)
```

### 새 프로젝트 초기화
```bash
# 프로젝트 초기화
./scripts/setup-dev [project-dir]  # flake.nix와 direnv로 새 Nix 프로젝트 초기화
nix run .#setup-dev [project-dir]  # 위와 동일 (nix flake app 사용)

# 전역 설치 (bl command system)
./scripts/install-setup-dev        # bl command system 설치 (한 번만 실행)
```

### bl Command System
```bash
# 설치 후 사용 가능한 명령어들
bl list              # 사용 가능한 명령어 목록
bl setup-dev my-app  # Nix 프로젝트 초기화
bl setup-dev --help  # 도움말
```

### Testing Requirements (CI 파이프라인 따르기)
변경사항 제출 전 아래 명령어들을 순서대로 실행:
```bash
make lint   # pre-commit run --all-files  
make smoke  # nix flake check --all-systems --no-build
make build  # 모든 NixOS/darwin 구성 빌드
make smoke  # 빌드 후 최종 flake 검증
```

### 개별 테스트 실행
```bash
# 현재 시스템용 모든 테스트 실행
nix run .#test                    # 종합 테스트 스위트 실행
nix flake check --impure          # flake 검증 실행

# 특정 테스트 카테고리 실행
nix run .#test-unit               # 단위 테스트만
nix run .#test-integration        # 통합 테스트만  
nix run .#test-e2e                # 종단간 테스트만
nix run .#test-perf               # 성능 테스트만
nix run .#test-smoke              # 빠른 smoke 테스트
```

Makefile targets internally run `nix` with `--extra-experimental-features 'nix-command flakes'` and `--impure` so that the `USER` environment variable is respected.
Even if these features are not globally enabled, the commands will still work.

## Contributing & Testing

프로젝트 수정 후에는 아래 명령을 순서대로 실행해 CI와 동일한 검증을 로컬에서 진행합니다.

```sh
make lint   # pre-commit run --all-files
make smoke  # nix flake check --all-systems --no-build
make build  # build all NixOS/darwin configurations
make smoke  # final flake check after build
```

Codex agent 규칙은 `AGENTS.md`에서 확인할 수 있습니다.

## Smoke Tests

GitHub Actions에서 각 플랫폼(macOS, Linux)의 x86_64와 aarch64 환경에 대해 smoke test를 실행해 빌드 오류를 조기에 확인합니다. 로컬에서는 `make smoke` 명령어로 동일한 테스트를 수행할 수 있습니다.

## Makefile Tests

`tests/makefile.nix`에서 `make help` 출력 여부를 확인합니다. `nix flake check`에 포함되어 자동 실행됩니다.

## Architecture Overview

### Module System
코드베이스는 엄격한 모듈 계층 구조를 따릅니다:

1. **플랫폼별 모듈** (`modules/darwin/`, `modules/nixos/`)
   - OS 특화 구성 (예: Homebrew casks, systemd 서비스)
   - 해당 플랫폼 구성에서만 import

2. **공유 모듈** (`modules/shared/`)
   - 크로스 플랫폼 구성 (패키지, dotfiles, 셸 설정)
   - Darwin, NixOS 구성 모두에서 import 가능

3. **호스트 구성** (`hosts/`)
   - 개별 머신 구성
   - 적절한 플랫폼 및 공유 모듈 import
   - 호스트별 설정 정의

### Key Architectural Patterns

1. **사용자 해결**: 시스템이 `lib/get-user.nix`를 통해 `$USER` 환경 변수를 동적으로 읽습니다. 항상 이것을 설정하거나 `--impure` 플래그를 사용하세요.

2. **Flake 출력 구조**:
   ```nix
   {
     darwinConfigurations."aarch64-darwin" = ...;
     nixosConfigurations."x86_64-linux" = ...;
     apps.{system}.{build,switch,rollback} = ...;
     checks.{system}.{test-name} = ...;
   }
   ```

3. **모듈 Import 패턴**:
   ```nix
   imports = [
     ../../modules/darwin/packages.nix
     ../../modules/shared/packages.nix
     ./configuration.nix
   ];
   ```

## How to Add/Modify Modules

- **공통 패키지**: `modules/shared/packages.nix`
- **macOS 전용**: `modules/darwin/packages.nix`, `modules/darwin/casks.nix`
- **NixOS 전용**: `modules/nixos/packages.nix`
- **호스트별**: `hosts/<platform>/<host>/home.nix`, `hosts/<platform>/<host>/configuration.nix`

### Adding a New Package
1. 모든 플랫폼용: `modules/shared/packages.nix` 편집
2. macOS 전용: `modules/darwin/packages.nix` 편집
3. NixOS 전용: `modules/nixos/packages.nix` 편집
4. Homebrew casks용: `modules/darwin/casks.nix` 편집

### Adding a New Module
1. 적절한 디렉토리에 모듈 파일 생성
2. 관련 호스트 구성 또는 상위 모듈에서 import
3. 영향받는 모든 플랫폼에서 테스트
4. 새로운 컨벤션을 문서화

## 참고

- [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config)
- [phip1611/nixos-configs](https://github.com/phip1611/nixos-configs)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

> 변경 이력, 마이그레이션 내역 등은 legacy/ 디렉토리와 커밋 로그를 참고하세요.

