# dotfiles: Declarative macOS & NixOS Environment

> **Complete development environment management with Nix flakes, Home Manager, and nix-darwin**

Fully reproducible, cross-platform development environments managed as code. Deploy identical setups across macOS and NixOS systems with a single command.

## 🚀 Overview

This repository provides a comprehensive solution for managing development environments using **Nix flakes**, **Home Manager**, and **nix-darwin**. Everything is declaratively configured as code, ensuring complete reproducibility across different machines and platforms.

### ✨ Key Features

- **🔄 Complete Reproducibility**: Every setting, package, and configuration managed as code
- **🌐 Multi-Platform Support**: macOS (Intel/Apple Silicon) and NixOS (x86_64/aarch64)
- **🛡️ Smart Configuration Preservation**: Automatic preservation of user customizations during updates
- **🧪 Comprehensive Testing**: Full CI/CD pipeline with unit, integration, and e2e tests
- **⚡ Developer-Friendly Tools**: `bl` command system and automated project initialization
- **📦 Advanced Package Management**: Custom overlays and cross-platform package resolution

## 🏗️ Architecture

### System Structure
- **Nix Flakes Foundation**: Fully reproducible environment declarations
- **Modular Design**: Shared, platform-specific, and host-specific modules
- **Integrated Management**: Home Manager + nix-darwin + NixOS unified approach

### Supported Platforms
- **macOS**: Intel (x86_64) and Apple Silicon (aarch64)
- **NixOS**: x86_64 and aarch64 architectures
- **Cross-Platform**: Unified package and configuration management

### Development Tools
- **bl Command System**: Global command dispatcher and tool management
- **setup-dev**: Automated Nix project initialization
- **Smart Configuration Preservation**: Intelligent user customization protection
- **Integrated Workflows**: Makefile-based development processes

### Quality Assurance
- **CI/CD Pipeline**: GitHub Actions with multi-platform matrix testing
- **Comprehensive Testing**: Unit, integration, e2e, and performance test suites
- **Code Quality**: Automated pre-commit hooks and linting
- **Build Validation**: Cross-platform build verification

## 📁 Project Structure

```
.
├── flake.nix              # Main Nix flake configuration
├── flake.lock             # Flake input locks
├── Makefile               # Development workflow commands
├── CLAUDE.md              # Claude Code integration guide
├── apps/                  # Platform-specific executable apps
│   ├── aarch64-darwin/    # macOS Apple Silicon executables
│   ├── x86_64-darwin/     # macOS Intel executables
│   ├── aarch64-linux/     # Linux ARM64 executables
│   └── x86_64-linux/      # Linux x86_64 executables
├── hosts/                 # Host-specific configurations
│   ├── darwin/            # macOS host configurations
│   └── nixos/             # NixOS host configurations
├── modules/               # Reusable Nix modules
│   ├── darwin/            # macOS-specific modules
│   ├── nixos/             # NixOS-specific modules
│   └── shared/            # Cross-platform modules
├── lib/                   # Nix utility functions
│   └── get-user.nix       # Dynamic user resolution
├── overlays/              # Custom package overlays
├── scripts/               # Management and development tools
│   ├── bl                 # Command system dispatcher
│   ├── setup-dev          # Project initialization
│   ├── install-setup-dev  # Global tool installer
│   └── merge-claude-config # Configuration merger
├── tests/                 # Comprehensive test suite
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   ├── e2e/               # End-to-end tests
│   └── performance/       # Performance benchmarks
└── docs/                  # Additional documentation
    ├── overview.md
    ├── structure.md
    └── testing-framework.md
```

### Key Components

- **`flake.nix`**: Entry point defining all system configurations and applications
- **`apps/`**: Platform-specific executables accessible via `nix run .#command`
- **`hosts/`**: Individual machine configurations using nix-darwin or NixOS
- **`modules/`**: Reusable configuration modules (shared, darwin-specific, nixos-specific)
- **`lib/get-user.nix`**: Dynamic user resolution supporting `$USER` environment variable
- **`scripts/`**: Development and management utilities
- **`tests/`**: Hierarchical test structure ensuring code quality across platforms

## 🚀 Quick Start

### Prerequisites

Before getting started, ensure you have the following requirements:

1. **Nix Package Manager** with flakes support
2. **Git** for cloning the repository
3. **Administrative access** for system-level configurations

### Installation

#### Step 1: Install Nix

**macOS:**
```bash
# Install Command Line Tools
xcode-select --install

# Install Nix with the Determinate Systems installer (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Linux:**
```bash
# Install Nix with flakes support
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Enable Flakes (if using traditional Nix install):**
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### Step 2: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/baleen/dotfiles.git
cd dotfiles

# Set the target user (required for build/evaluation)
export USER=<your-username>

# Test the configuration
make smoke
```

#### Step 3: Deploy Configuration

**For macOS:**
```bash
# Build and apply configuration
make build
make switch HOST=aarch64-darwin  # or x86_64-darwin for Intel Macs
```

**For NixOS:**
```bash
# Build and apply configuration
make build
make switch HOST=x86_64-linux   # or aarch64-linux for ARM systems
```

**Quick Deploy (Build + Apply):**
```bash
# Requires sudo privileges - builds and applies immediately
nix run --impure .#build-switch
```

### Environment Variables

**USER Variable**: Required for proper system evaluation and user resolution.

```bash
# Method 1: Export before commands
export USER=<your-username>
make build

# Method 2: Inline with command
USER=<your-username> nix run .#build

# Method 3: Use impure evaluation (reads environment automatically)
nix run --impure .#build
```

The system uses `lib/get-user.nix` to dynamically resolve the target user, supporting both `$USER` and `$SUDO_USER` environment variables.

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

