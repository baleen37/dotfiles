# CLAUDE.md

> **Last Updated:** 2025-01-06  
> **Version:** 2.0  
> **For:** Claude Code (claude.ai/code)

This file provides comprehensive guidance for Claude Code when working with this Nix flake-based dotfiles repository.

## Quick Start

### TL;DR - Essential Commands
```bash
# Setup (run once)
export USER=<username>

# Daily workflow
make lint    # Always run before committing
make build   # Test your changes
make switch HOST=<host>  # Apply to system

# Emergency fixes
nix run --impure .#build-switch  # Build and switch (requires sudo)
```

### First Time Setup
1. Set user environment: `export USER=<username>`
2. Test the build: `make build`
3. Apply configuration: `make switch HOST=<host>`
4. Install global tools: `./scripts/install-setup-dev`

## Repository Overview

This is a Nix flake-based dotfiles repository for managing macOS and NixOS development environments declaratively. It supports x86_64 and aarch64 architectures on both platforms.

**Key Features:**
- Declarative environment management with Nix flakes
- Cross-platform support (macOS via nix-darwin, NixOS via nixos-rebuild)
- Comprehensive testing suite with CI/CD
- Modular architecture for easy customization
- Global command system (`bl`) for project management

## Essential Commands

### Development Workflow
```bash
# Required: Set USER environment variable (or use --impure flag)
export USER=<username>

# Core development commands (in order of frequency)
make lint           # Run pre-commit hooks (MUST pass before committing)
make smoke          # Quick flake validation without building
make test           # Run all unit and e2e tests
make build          # Build all configurations
make switch HOST=<host>  # Apply configuration to current system

# Platform-specific builds
nix run .#build     # Build for current system
nix run .#switch    # Build and switch for current system
nix run .#build-switch  # Build and switch with sudo (immediate application)
```

### Testing Requirements (Follow CI Pipeline)
**Always run these commands in order before submitting changes:**
```bash
make lint   # pre-commit run --all-files  
make smoke  # nix flake check --all-systems --no-build
make build  # build all NixOS/darwin configurations
make smoke  # final flake check after build
```

### Running Individual Tests
```bash
# Run all tests for current system
nix run .#test                    # Run comprehensive test suite
nix flake check --impure          # Run flake checks

# Run specific test categories
nix run .#test-unit               # Unit tests only
nix run .#test-integration        # Integration tests only  
nix run .#test-e2e                # End-to-end tests only
nix run .#test-perf               # Performance tests only
nix run .#test-smoke              # Quick smoke tests

# Run specific test file
nix eval --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').simple
```

## Development Workflows

### 🔄 Daily Development Cycle
```bash
# 1. Start work
git checkout -b feature/my-change
export USER=<username>

# 2. Make changes
# ... edit files ...

# 3. Test changes
make lint && make build

# 4. Apply locally (optional)
make switch HOST=<host>

# 5. Commit and push
git add . && git commit -m "feat: description"
git push -u origin feature/my-change

# 6. Create PR
gh pr create --assignee @me
```

### 🚀 Quick Configuration Apply
```bash
# For immediate system changes (requires sudo)
nix run --impure .#build-switch

# For testing without system changes
make build
```

### 🔧 Adding New Software
```bash
# 1. Identify target platform
# All platforms: modules/shared/packages.nix
# macOS only: modules/darwin/packages.nix  
# NixOS only: modules/nixos/packages.nix
# Homebrew casks: modules/darwin/casks.nix

# 2. Edit appropriate file
# 3. Test the change
make build

# 4. Apply if successful
make switch HOST=<host>
```

## Architecture Overview

### Module System Hierarchy
The codebase follows a strict modular hierarchy:

1. **Platform-specific modules** (`modules/darwin/`, `modules/nixos/`)
   - Contains OS-specific configurations (e.g., Homebrew casks, systemd services)
   - Imported only by respective platform configurations

2. **Shared modules** (`modules/shared/`)
   - Cross-platform configurations (packages, dotfiles, shell setup)
   - Can be imported by both Darwin and NixOS configurations

3. **Host configurations** (`hosts/`)
   - Individual machine configurations
   - Import appropriate platform and shared modules
   - Define host-specific settings

### Key Architectural Patterns

1. **User Resolution**: The system dynamically reads the `$USER` environment variable via `lib/get-user.nix`. Always ensure this is set or use `--impure` flag.

2. **Flake Outputs Structure**:
   ```nix
   {
     darwinConfigurations."aarch64-darwin" = ...;
     nixosConfigurations."x86_64-linux" = ...;
     apps.{system}.{build,switch,rollback} = ...;
     checks.{system}.{test-name} = ...;
   }
   ```

3. **Module Import Pattern**:
   ```nix
   imports = [
     ../../modules/darwin/packages.nix
     ../../modules/shared/packages.nix
     ./configuration.nix
   ];
   ```

4. **Overlay System**: Custom packages and patches are defined in `overlays/` and automatically applied to nixpkgs.

### File Organization

- `flake.nix`: Entry point defining all outputs
- `hosts/{platform}/{host}/`: Host-specific configurations
- `modules/{platform}/`: Platform-specific modules
- `modules/shared/`: Cross-platform modules
- `apps/{architecture}/`: Platform-specific shell scripts
- `tests/`: Unit and integration tests
- `lib/`: Shared Nix functions (especially `get-user.nix`)
- `scripts/`: Management and development tools

## Common Tasks

### Adding a New Package
1. **For all platforms**: Edit `modules/shared/packages.nix`
2. **For macOS only**: Edit `modules/darwin/packages.nix`
3. **For NixOS only**: Edit `modules/nixos/packages.nix`
4. **For Homebrew casks**: Edit `modules/darwin/casks.nix`

**Testing checklist:**
- [ ] `make lint` passes
- [ ] `make build` succeeds
- [ ] Package installs correctly on target platform(s)
- [ ] No conflicts with existing packages

### Adding a New Module
1. Create module file in appropriate directory
2. Import it in relevant host configurations or parent modules
3. Test on all affected platforms:
   - x86_64-darwin
   - aarch64-darwin  
   - x86_64-linux
   - aarch64-linux
4. Document any new conventions

### Creating a New Nix Project

1. **Using setup-dev script:**
   ```bash
   ./scripts/setup-dev [project-directory]  # Local execution
   nix run .#setup-dev [project-directory]  # Via flake app
   ```

2. **What it creates:**
   - Basic `flake.nix` with development shell
   - `.envrc` for direnv integration
   - `.gitignore` with Nix patterns

3. **Next steps:**
   - Customize `flake.nix` to add project-specific dependencies
   - Use `nix develop` or let direnv auto-activate the environment

## Troubleshooting & Best Practices

### 🔍 Common Issues & Solutions

#### Build Failures
```bash
# Show detailed error trace
nix build --impure --show-trace .#darwinConfigurations.aarch64-darwin.system

# Check flake outputs
nix flake show --impure

# Validate flake structure
nix flake check --impure --no-build

# Clear build cache
nix store gc
```

#### Environment Variable Issues
```bash
# USER not set
export USER=$(whoami)

# For CI/scripts
nix run --impure .#build

# Persistent solution
echo "export USER=$(whoami)" >> ~/.bashrc  # or ~/.zshrc
```

#### Permission Issues with build-switch
```bash
# build-switch requires sudo from the start
sudo nix run --impure .#build-switch

# Alternative: use separate commands
nix run .#build
sudo nix run .#switch
```

### 🔒 Security Best Practices

1. **Never commit secrets**
   - Use `age` encryption for sensitive files
   - Store secrets in separate encrypted repository
   - Use environment variables for dynamic secrets

2. **Verify package sources**
   - Only use packages from nixpkgs or trusted overlays
   - Review custom overlays before applying

3. **Limit sudo usage**
   - Only use `build-switch` when necessary
   - Test builds without sudo first

### ⚡ Performance Optimization

1. **Build optimization**
   - Use `make smoke` for quick validation
   - Run `nix store gc` regularly to clean cache
   - Use `--max-jobs` flag for parallel builds

2. **Development workflow**
   - Use `direnv` for automatic environment activation
   - Keep separate dev shells for different projects
   - Cache frequently used packages

### 📋 Pre-commit Checklist

- [ ] `export USER=<username>` is set
- [ ] `make lint` passes without errors
- [ ] `make smoke` validates flake structure
- [ ] `make build` completes successfully
- [ ] Changes tested on target platform(s)
- [ ] Documentation updated if needed
- [ ] No secrets or sensitive information committed

## Pre-commit Hooks

이 프로젝트는 pre-commit 훅을 사용하여 코드 품질을 보장합니다.

### 설치 및 설정

```bash
# pre-commit 설치 (pip 또는 conda 사용)
pip install pre-commit

# 또는 nix로 설치 (권장)
nix-shell -p pre-commit

# 훅 설치
pre-commit install

# 모든 파일에 대해 훅 실행
pre-commit run --all-files
```

### 현재 설정된 훅

- **Nix Flake Check**: 모든 `.nix` 파일이 변경될 때 `nix flake check --all-systems --no-build` 실행
- 빠른 구문 검사와 플레이크 유효성 검증을 제공합니다

### 사용법

```bash
# 커밋 전 자동 실행 (훅 설치 후)
git commit -m "your commit message"

# 수동으로 모든 파일 체크
pre-commit run --all-files

# 특정 파일만 체크
pre-commit run --files flake.nix

# 훅 우회 (권장하지 않음)
git commit --no-verify -m "emergency commit"
```

### 문제 해결

```bash
# pre-commit 캐시 정리
pre-commit clean

# 훅 재설치
pre-commit uninstall
pre-commit install

# 특정 훅 비활성화 (임시)
SKIP=nix-flake-check git commit -m "message"
```

## Advanced Topics

### Global Installation (bl command system)

Run `./scripts/install-setup-dev` to install the `bl` command system:
- Installs `bl` dispatcher to `~/.local/bin`
- Sets up command directory at `~/.bl/commands/`
- Installs `setup-dev` as `bl setup-dev`

**Available commands after installation:**
```bash
bl list              # List available commands
bl setup-dev my-app  # Initialize Nix project
bl setup-dev --help  # Get help
```

### Adding Custom Commands

To add new commands to the bl system:
1. Create executable script in `~/.bl/commands/`
2. Use `bl <command-name>` to run it
3. All arguments are passed through to your script

### Script Reusability

- Copy `scripts/setup-dev` to any location for standalone use
- No dependencies on dotfiles repository structure
- Includes help with `-h` or `--help` flag

## Important Notes
<<<<<<< HEAD

### Critical Development Guidelines

1. **Always use `--impure` flag** when running nix commands that need environment variables
2. **Module Dependencies**: When modifying modules, check both direct imports and transitive dependencies
3. **Platform Testing**: Changes to shared modules should be tested on all four platforms
4. **Configuration Application**: 
   - Darwin: Uses `darwin-rebuild switch`
   - NixOS: Uses `nixos-rebuild switch`
   - Both are wrapped by platform-specific scripts in `apps/`
5. **Home Manager Integration**: User-specific configurations are managed through Home Manager

## Claude 설정 보존 시스템

이 dotfiles는 **스마트 Claude 설정 보존 시스템**을 포함하고 있어, 사용자가 개인화한 Claude 설정이 시스템 업데이트 시에도 안전하게 보존됩니다.

### 작동 방식

1. **자동 수정 감지**: SHA256 해시를 통해 사용자 수정 여부를 자동 감지
2. **우선순위 기반 보존**: 중요한 파일(`settings.json`, `CLAUDE.md`)은 항상 보존
3. **안전한 업데이트**: 새 버전을 `.new` 파일로 저장하여 안전한 업데이트 제공
4. **사용자 알림**: 업데이트 발생 시 자동 알림 생성
5. **병합 도구**: 대화형 병합 도구로 설정 통합 지원

### 주요 특징

- ✅ **무손실 보존**: 사용자 설정이 절대 손실되지 않음
- ✅ **자동 백업**: 모든 변경 시 자동 백업 생성
- ✅ **대화형 병합**: JSON 및 텍스트 파일 병합 지원
- ✅ **커스텀 파일 보호**: 사용자가 추가한 명령어 파일 완전 보존
- ✅ **깔끔한 정리**: 병합 후 임시 파일 자동 정리

### 사용법

#### 일반적인 상황 (자동 처리)
시스템 재빌드 시 자동으로 작동합니다:
```bash
nix run --impure .#build-switch
# 또는
make switch HOST=<host>
```

사용자 수정이 감지되면 다음과 같은 파일들이 생성됩니다:
- `~/.claude/settings.json.new` - 새로운 dotfiles 버전
- `~/.claude/settings.json.update-notice` - 업데이트 알림

#### 수동 병합
업데이트 알림을 받은 후 병합 도구를 사용하세요:

```bash
# 병합이 필요한 파일 확인
./scripts/merge-claude-config --list

# 특정 파일 병합
./scripts/merge-claude-config settings.json

# 모든 파일 대화형 병합
./scripts/merge-claude-config

# 차이점만 확인
./scripts/merge-claude-config --diff CLAUDE.md
```

#### 고급 사용법

**JSON 설정 병합**: `settings.json`은 키별로 선택적 병합 가능
```bash
./scripts/merge-claude-config settings.json
# c) 현재 값 유지
# n) 새 값 사용  
# s) 건너뛰기
```

**백업 관리**: 
```bash
# 백업 파일 위치
ls ~/.claude/.backups/

# 30일 이상된 백업 자동 정리됨
```

### 문제 해결

#### 업데이트 알림이 생성된 경우
```bash
# 1. 알림 파일 확인
find ~/.claude -name "*.update-notice"

# 2. 변경사항 검토
./scripts/merge-claude-config --diff settings.json

# 3. 병합 또는 현재 버전 유지 결정
./scripts/merge-claude-config settings.json

# 4. 완료 후 정리
rm ~/.claude/*.new ~/.claude/*.update-notice
```

#### 백업에서 복원
```bash
# 백업 파일 확인
ls ~/.claude/.backups/

# 원하는 백업으로 복원
cp ~/.claude/.backups/settings.json.backup.20240106_143022 ~/.claude/settings.json
```

### 보존 정책

| 파일 | 우선순위 | 동작 |
|------|----------|------|
| `settings.json` | 높음 | 사용자 수정 시 보존, 새 버전 `.new`로 저장 |
| `CLAUDE.md` | 높음 | 사용자 수정 시 보존, 새 버전 `.new`로 저장 |
| `commands/*.md` (dotfiles) | 중간 | 백업 후 덮어쓰기 |
| `commands/*.md` (사용자) | 높음 | 항상 보존 (dotfiles에 없는 파일) |

## Important Notes

### Critical Development Guidelines

1. **Always use `--impure` flag** when running nix commands that need environment variables
2. **Module Dependencies**: When modifying modules, check both direct imports and transitive dependencies
3. **Platform Testing**: Changes to shared modules should be tested on all four platforms
4. **Configuration Application**: 
   - Darwin: Uses `darwin-rebuild switch`
   - NixOS: Uses `nixos-rebuild switch`
   - Both are wrapped by platform-specific scripts in `apps/`
5. **Home Manager Integration**: User-specific configurations are managed through Home Manager

### Workflow Requirements

- **Ask before major changes**: Always confirm before proceeding with significant modifications
- **Enable auto-merge for PRs**: Always turn on auto-merge option when creating pull requests
- **No AI attribution**: Act as if Claude Code was not used - do not mention AI assistance in commits or PRs
- **sudo requirements**: `nix run .#build-switch` can only be executed with root privileges
- **Tab navigation**: Maintain tab navigation functionality in UI components
- **Claude config preservation**: User modifications to Claude settings are automatically preserved

### Legacy Information

- System uses `build-switch` command for immediate configuration application
- All builds require USER environment variable to be set
- Root privileges are required for system-level configuration changes
