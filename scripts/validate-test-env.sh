#!/usr/bin/env bash
# ABOUTME: 통합 테스트 인터페이스 개발 환경 검증 스크립트
# ABOUTME: 새로운 테스트 시스템 구현에 필요한 모든 전제조건을 확인

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 색상 정의
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 검증 결과 카운터
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# === 유틸리티 함수 ===

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((CHECKS_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    ((CHECKS_WARNING++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((CHECKS_FAILED++))
}

# === 환경 검증 함수들 ===

check_system_requirements() {
    log_info "Checking system requirements..."

    # Bash 버전 확인
    if [[ "${BASH_VERSION%%.*}" -ge 4 ]]; then
        log_success "Bash version: ${BASH_VERSION} (>= 4.0 required)"
    else
        log_error "Bash version: ${BASH_VERSION} (< 4.0, upgrade required)"
    fi

    # 운영체제 확인
    local os=$(uname -s)
    case "$os" in
        "Darwin")
            log_success "Operating system: macOS (supported)"
            ;;
        "Linux")
            log_success "Operating system: Linux (supported)"
            ;;
        *)
            log_warning "Operating system: $os (untested, may have issues)"
            ;;
    esac

    # 아키텍처 확인
    local arch=$(uname -m)
    case "$arch" in
        "x86_64"|"aarch64"|"arm64")
            log_success "Architecture: $arch (supported)"
            ;;
        *)
            log_warning "Architecture: $arch (untested, may have issues)"
            ;;
    esac
}

check_required_commands() {
    log_info "Checking required commands..."

    local required_commands=(
        "git:Git version control"
        "nix:Nix package manager"
        "make:GNU Make build tool"
        "bats:BATS testing framework"
        "jq:JSON processor"
    )

    for cmd_desc in "${required_commands[@]}"; do
        local cmd="${cmd_desc%%:*}"
        local desc="${cmd_desc##*:}"

        if command -v "$cmd" >/dev/null 2>&1; then
            local version
            case "$cmd" in
                "git")
                    version=$(git --version | cut -d' ' -f3)
                    ;;
                "nix")
                    version=$(nix --version | head -1 | cut -d' ' -f3)
                    ;;
                "make")
                    version=$(make --version | head -1 | cut -d' ' -f3)
                    ;;
                "bats")
                    version=$(bats --version | cut -d' ' -f2)
                    ;;
                "jq")
                    version=$(jq --version | cut -d'-' -f2)
                    ;;
                *)
                    version="unknown"
                    ;;
            esac
            log_success "$desc: $version"
        else
            if [[ "$cmd" == "bats" ]]; then
                log_warning "$desc: not found (will use Nix shell when needed)"
            else
                log_error "$desc: not found (required for test interface)"
            fi
        fi
    done
}

check_project_structure() {
    log_info "Checking project structure..."

    # 필수 디렉토리 확인
    local required_dirs=(
        "tests:Test directory"
        "tests/lib:Test library directory"
        "tests/config:Test configuration directory"
        "tests/unit:Unit tests directory"
        "tests/integration:Integration tests directory"
        "tests/e2e:End-to-end tests directory"
        "tests/performance:Performance tests directory"
        "lib:Project library directory"
        "modules:Nix modules directory"
    )

    for dir_desc in "${required_dirs[@]}"; do
        local dir="${dir_desc%%:*}"
        local desc="${dir_desc##*:}"

        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            log_success "$desc: $PROJECT_ROOT/$dir"
        else
            log_error "$desc: $PROJECT_ROOT/$dir (missing)"
        fi
    done
}

check_existing_test_system() {
    log_info "Checking existing test system compatibility..."

    # 기존 테스트 프레임워크 확인
    if [[ -f "$PROJECT_ROOT/tests/lib/test-framework.sh" ]]; then
        log_success "Existing test framework: found"

        # 실행 권한 확인
        if [[ -x "$PROJECT_ROOT/tests/lib/test-framework.sh" ]]; then
            log_success "Test framework: executable"
        else
            log_warning "Test framework: not executable (will fix automatically)"
            chmod +x "$PROJECT_ROOT/tests/lib/test-framework.sh" || log_error "Failed to make test framework executable"
        fi
    else
        log_error "Existing test framework: not found"
    fi

    # 기존 설정 파일 확인
    if [[ -f "$PROJECT_ROOT/tests/config/test-config.sh" ]]; then
        log_success "Existing test config: found"
    else
        log_error "Existing test config: not found"
    fi

    # Makefile 테스트 타겟 확인
    if [[ -f "$PROJECT_ROOT/Makefile" ]] && grep -q "test:" "$PROJECT_ROOT/Makefile"; then
        log_success "Makefile test targets: found"

        # 기존 테스트 명령어 개수 확인
        local test_targets=$(grep -E "^[a-zA-Z-]+test[a-zA-Z-]*:" "$PROJECT_ROOT/Makefile" | wc -l | tr -d ' ')
        log_info "Found $test_targets existing test commands"

        if [[ "$test_targets" -gt 10 ]]; then
            log_warning "Many test commands found ($test_targets), consolidation will provide significant benefit"
        fi
    else
        log_error "Makefile test targets: not found"
    fi
}

check_git_repository() {
    log_info "Checking Git repository..."

    if git rev-parse --git-dir >/dev/null 2>&1; then
        log_success "Git repository: initialized"

        # 현재 브랜치 확인
        local current_branch=$(git branch --show-current)
        if [[ "$current_branch" == "002-test-thinkhard" ]]; then
            log_success "Current branch: $current_branch (correct feature branch)"
        else
            log_warning "Current branch: $current_branch (expected: 002-test-thinkhard)"
        fi

        # 작업 디렉토리 상태 확인
        if git diff-index --quiet HEAD -- 2>/dev/null; then
            log_success "Working directory: clean"
        else
            log_info "Working directory: has changes (normal for development)"
        fi

        # 원격 저장소 확인
        if git remote -v | grep -q origin; then
            log_success "Git remote: configured"
        else
            log_warning "Git remote: not configured (not required for local development)"
        fi
    else
        log_error "Git repository: not initialized"
    fi
}

check_nix_environment() {
    log_info "Checking Nix environment..."

    if command -v nix >/dev/null 2>&1; then
        # Nix 버전 확인
        local nix_version=$(nix --version | head -1 | cut -d' ' -f3)
        local major_version="${nix_version%%.*}"

        if [[ "$major_version" -ge 2 ]]; then
            log_success "Nix version: $nix_version (>= 2.0 required)"
        else
            log_error "Nix version: $nix_version (< 2.0, upgrade required)"
        fi

        # Flakes 지원 확인
        if nix flake --help >/dev/null 2>&1; then
            log_success "Nix flakes: supported"
        else
            log_error "Nix flakes: not supported (required for this project)"
        fi

        # 프로젝트 flake.nix 확인
        if [[ -f "$PROJECT_ROOT/flake.nix" ]]; then
            log_success "Project flake: found"

            # Flake 검증 시도
            if nix flake check --no-build "$PROJECT_ROOT" >/dev/null 2>&1; then
                log_success "Flake validation: passed"
            else
                log_warning "Flake validation: failed (may need 'nix flake update')"
            fi
        else
            log_error "Project flake: not found"
        fi
    else
        log_error "Nix: not found in PATH"
    fi
}

check_performance_requirements() {
    log_info "Checking performance requirements..."

    # 시스템 리소스 확인
    if command -v free >/dev/null 2>&1; then
        local available_mem=$(free -m | awk 'NR==2{print $7}')
        if [[ "$available_mem" -gt 500 ]]; then
            log_success "Available memory: ${available_mem}MB (>500MB required)"
        else
            log_warning "Available memory: ${available_mem}MB (<500MB, may affect parallel execution)"
        fi
    elif command -v vm_stat >/dev/null 2>&1; then
        # macOS 메모리 확인
        local free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
        local available_mb=$((free_pages * 4096 / 1024 / 1024))
        if [[ "$available_mb" -gt 500 ]]; then
            log_success "Available memory: ${available_mb}MB (>500MB required)"
        else
            log_warning "Available memory: ${available_mb}MB (<500MB, may affect parallel execution)"
        fi
    else
        log_warning "Cannot determine available memory"
    fi

    # CPU 코어 수 확인
    local cpu_cores
    if command -v nproc >/dev/null 2>&1; then
        cpu_cores=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        cpu_cores=$(sysctl -n hw.ncpu)
    else
        cpu_cores="unknown"
    fi

    if [[ "$cpu_cores" != "unknown" ]] && [[ "$cpu_cores" -gt 1 ]]; then
        log_success "CPU cores: $cpu_cores (parallel execution supported)"
    else
        log_warning "CPU cores: $cpu_cores (parallel execution limited)"
    fi

    # 디스크 공간 확인
    local available_space=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/[A-Za-z]//')
    if [[ "${available_space%.*}" -gt 1 ]]; then
        log_success "Available disk space: sufficient"
    else
        log_warning "Available disk space: low (may affect test execution)"
    fi
}

# === 메인 실행 함수 ===

main() {
    echo "=== Test Interface Environment Validation ==="
    echo "Project: $(basename "$PROJECT_ROOT")"
    echo "Location: $PROJECT_ROOT"
    echo "Date: $(date)"
    echo ""

    # 모든 검증 수행
    check_system_requirements
    echo ""

    check_required_commands
    echo ""

    check_project_structure
    echo ""

    check_existing_test_system
    echo ""

    check_git_repository
    echo ""

    check_nix_environment
    echo ""

    check_performance_requirements
    echo ""

    # 결과 요약
    echo "=== Validation Summary ==="
    echo -e "${GREEN}✓ Passed: $CHECKS_PASSED${NC}"
    echo -e "${YELLOW}⚠ Warnings: $CHECKS_WARNING${NC}"
    echo -e "${RED}✗ Failed: $CHECKS_FAILED${NC}"

    if [[ "$CHECKS_FAILED" -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}🎉 Environment is ready for test interface development!${NC}"

        if [[ "$CHECKS_WARNING" -gt 0 ]]; then
            echo -e "${YELLOW}Note: $CHECKS_WARNING warning(s) found, but development can proceed${NC}"
        fi

        return 0
    else
        echo ""
        echo -e "${RED}❌ Environment validation failed with $CHECKS_FAILED error(s)${NC}"
        echo "Please resolve the errors above before proceeding with development"
        return 1
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
