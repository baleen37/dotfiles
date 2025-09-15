#!/usr/bin/env bash
# ABOUTME: 모의 환경 생성 라이브러리 - 재사용 가능한 테스트 환경 구축 함수들
# ABOUTME: 다양한 테스트 시나리오를 위한 표준화된 모의 환경

set -euo pipefail

# 의존성 체크
if [[ -z "${RED:-}" ]]; then
    echo "ERROR: common.sh 라이브러리가 로드되지 않았습니다" >&2
    exit 1
fi

# 모의 환경 버전
readonly MOCK_ENV_VERSION="1.0.0"

# === 기본 환경 설정 ===

# 임시 테스트 디렉토리 생성
create_test_directory() {
    local prefix="${1:-test}"
    local test_dir=$(mktemp -d -t "${prefix}_XXXXXX")
    echo "$test_dir"
    log_debug "임시 테스트 디렉토리 생성: $test_dir"
}

# 테스트 환경 기본 구조 생성
setup_basic_test_structure() {
    local test_dir="$1"
    local project_name="${2:-test-project}"

    mkdir -p "$test_dir"/{src,tests,config,tmp}
    touch "$test_dir/README.md"

    cat > "$test_dir/README.md" << EOF
# $project_name
Test environment for: $project_name
Created: $(date)
EOF

    log_debug "기본 테스트 구조 생성: $test_dir"
}

# === Claude 환경 모의 ===

# Claude 설정 환경 생성 (개선된 버전)
setup_mock_claude_environment() {
    local test_claude_dir="$1"
    local test_source_dir="$2"
    local include_dynamics="${3:-false}"

    log_debug "모의 Claude 환경 생성: $test_claude_dir -> $test_source_dir"

    # 소스 디렉토리 구조 생성
    mkdir -p "$test_source_dir"/{commands,agents,hooks}
    mkdir -p "$test_source_dir/commands"/{git,workflow,system,debug}

    # 기본 설정 파일들 생성
    create_mock_settings_json "$test_source_dir/settings.json" "$include_dynamics"
    create_mock_claude_md "$test_source_dir/CLAUDE.md"

    # 다양한 명령어 파일들 생성
    create_mock_commands "$test_source_dir/commands"

    # 에이전트 파일들 생성
    create_mock_agents "$test_source_dir/agents"

    # 훅 파일들 생성
    create_mock_hooks "$test_source_dir/hooks"

    # Claude 타겟 디렉토리 생성
    mkdir -p "$test_claude_dir"

    log_success "모의 Claude 환경 생성 완료"
}

# Mock settings.json 생성
create_mock_settings_json() {
    local settings_file="$1"
    local include_dynamics="${2:-false}"

    local settings_content='{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true,
  "debugMode": false,
  "workspaceSettings": {
    "defaultDirectory": "~/dev",
    "preferredShell": "zsh",
    "autoSaveInterval": 30
  },
  "experimentalFeatures": {
    "enablePreview": true,
    "betaIntegration": false
  }
}'

    if [[ "$include_dynamics" == "true" ]]; then
        settings_content=$(echo "$settings_content" | jq '. + {
          "feedbackSurveyState": {
            "lastShown": "2024-02-20",
            "dismissed": ["welcome", "feedback-v1"],
            "userPreferences": {
              "showNotifications": false,
              "frequency": "monthly"
            }
          },
          "runtimeState": {
            "sessionId": "test-session-12345",
            "lastActivity": "2024-02-20T10:30:00Z"
          }
        }')
    fi

    echo "$settings_content" > "$settings_file"
    log_debug "Mock settings.json 생성: $settings_file"
}

# Mock CLAUDE.md 생성
create_mock_claude_md() {
    local claude_md_file="$1"

    cat > "$claude_md_file" << 'EOF'
# Mock Claude Configuration

This is a test configuration file for Claude integration testing.

## Test Features
- Mock environment simulation
- Settings management testing
- Dynamic state preservation testing

## Test Scenarios
1. Clean environment setup
2. Symlink to copy conversion
3. Dynamic state preservation
4. Error recovery testing

## Mock Commands
- `/mock-test` - Test command
- `/mock-debug` - Debug command
- `/mock-deploy` - Deployment simulation

## Mock Agents
- `mock-reviewer` - Code review simulation
- `mock-tester` - Test generation simulation
EOF

    log_debug "Mock CLAUDE.md 생성: $claude_md_file"
}

# Mock 명령어들 생성
create_mock_commands() {
    local commands_dir="$1"

    # 루트 레벨 명령어들
    cat > "$commands_dir/mock-test.md" << 'EOF'
# Mock Test Command
Root level mock test command for testing framework validation.
Usage: `/mock-test [options]`
EOF

    cat > "$commands_dir/analyze.md" << 'EOF'
# Analyze Command
System analysis and diagnostic command.
Usage: `/analyze [component]`
EOF

    # Git 관련 명령어들
    cat > "$commands_dir/git/commit.md" << 'EOF'
# Git Commit Command
Automated commit with standardized messages.
Usage: `/commit [message]`
EOF

    cat > "$commands_dir/git/status.md" << 'EOF'
# Git Status Command
Enhanced git status with additional context.
Usage: `/status [--detailed]`
EOF

    # 워크플로우 명령어들
    cat > "$commands_dir/workflow/deploy.md" << 'EOF'
# Deployment Workflow
Automated deployment pipeline management.
Usage: `/deploy [environment]`
EOF

    cat > "$commands_dir/workflow/test.md" << 'EOF'
# Test Workflow
Comprehensive testing pipeline execution.
Usage: `/test [suite] [--parallel]`
EOF

    # 시스템 명령어들
    cat > "$commands_dir/system/monitor.md" << 'EOF'
# System Monitor Command
Real-time system monitoring and alerts.
Usage: `/monitor [--duration=60]`
EOF

    cat > "$commands_dir/debug/trace.md" << 'EOF'
# Debug Trace Command
Execution tracing and profiling utilities.
Usage: `/trace [process]`
EOF

    log_debug "Mock 명령어들 생성: $commands_dir"
}

# Mock 에이전트들 생성
create_mock_agents() {
    local agents_dir="$1"

    cat > "$agents_dir/mock-reviewer.md" << 'EOF'
# Mock Code Reviewer Agent
Simulated automated code review agent for testing.

## Capabilities
- Code quality analysis simulation
- Best practices checking simulation
- Security vulnerability detection simulation

## Test Scenarios
- Pull request review automation
- Code quality gate validation
- Review comment generation
EOF

    cat > "$agents_dir/mock-tester.md" << 'EOF'
# Mock Test Generator Agent
Simulated automated test generation agent.

## Capabilities
- Unit test generation simulation
- Integration test creation simulation
- Test data preparation simulation

## Test Scenarios
- TDD workflow automation
- Test coverage improvement
- Edge case identification
EOF

    cat > "$agents_dir/backend-engineer.md" << 'EOF'
# Backend Engineer Agent
Specialized backend development assistance.

## Expertise Areas
- API design and implementation
- Database optimization
- Microservices architecture
- Performance tuning

## Mock Capabilities
- API endpoint generation
- Database schema design
- Performance bottleneck identification
EOF

    log_debug "Mock 에이전트들 생성: $agents_dir"
}

# Mock 훅들 생성
create_mock_hooks() {
    local hooks_dir="$1"

    cat > "$hooks_dir/pre-command.sh" << 'EOF'
#!/usr/bin/env bash
# Mock pre-command hook
echo "Mock: Pre-command hook executed"
exit 0
EOF

    cat > "$hooks_dir/post-command.sh" << 'EOF'
#!/usr/bin/env bash
# Mock post-command hook
echo "Mock: Post-command hook executed"
exit 0
EOF

    chmod +x "$hooks_dir"/*.sh
    log_debug "Mock 훅들 생성: $hooks_dir"
}

# === Nix 환경 모의 ===

# Nix 빌드 환경 시뮬레이션
setup_mock_nix_environment() {
    local test_dir="$1"
    local project_name="${2:-mock-nix-project}"

    mkdir -p "$test_dir"/{lib,modules,tests}

    # 기본 flake.nix 생성
    cat > "$test_dir/flake.nix" << EOF
{
  description = "Mock Nix flake for testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    # Mock outputs for testing
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
EOF

    # 기본 default.nix 생성
    cat > "$test_dir/default.nix" << 'EOF'
{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
  pname = "mock-package";
  version = "1.0.0";
  src = ./.;
  installPhase = "mkdir -p $out; echo 'mock' > $out/mock.txt";
}
EOF

    log_debug "Mock Nix 환경 생성: $test_dir"
}

# === 파일 시스템 상태 시뮬레이션 ===

# 기존 설정이 있는 상태 시뮬레이션
setup_existing_configuration() {
    local target_dir="$1"
    local config_type="${2:-claude}"

    mkdir -p "$target_dir"

    case "$config_type" in
        "claude")
            # 기존 Claude 설정 시뮬레이션
            echo '{"version": "0.9.0", "legacy": true}' > "$target_dir/settings.json"
            echo "# Old Claude Config" > "$target_dir/CLAUDE.md"
            mkdir -p "$target_dir"/{commands,agents}
            echo "# Old command" > "$target_dir/commands/old-cmd.md"
            ln -sf "/nonexistent/path" "$target_dir/broken-link" 2>/dev/null || true
            ;;
        "symlink")
            # 심볼릭 링크 기반 설정 시뮬레이션
            local source_dir=$(mktemp -d)
            echo '{"symlinked": true}' > "$source_dir/settings.json"
            ln -sf "$source_dir/settings.json" "$target_dir/settings.json"
            ;;
    esac

    log_debug "기존 설정 상태 시뮬레이션: $target_dir ($config_type)"
}

# 권한 문제 시뮬레이션
simulate_permission_issues() {
    local target_file="$1"
    local issue_type="${2:-readonly}"

    touch "$target_file"

    case "$issue_type" in
        "readonly")
            chmod 444 "$target_file"
            ;;
        "no_access")
            chmod 000 "$target_file"
            ;;
        "no_write")
            chmod 555 "$target_file"
            ;;
    esac

    log_debug "권한 문제 시뮬레이션: $target_file ($issue_type)"
}

# === 동적 상태 시뮬레이션 ===

# 사용자 동적 상태 추가
add_dynamic_user_state() {
    local settings_file="$1"
    local state_type="${2:-feedback}"

    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq 없음: 동적 상태 시뮬레이션 건너뜀"
        return 0
    fi

    case "$state_type" in
        "feedback")
            jq '. + {
                "feedbackSurveyState": {
                    "lastShown": "2024-02-20",
                    "dismissed": ["welcome"],
                    "userPreferences": {"showNotifications": false}
                }
            }' "$settings_file" > "$settings_file.tmp"
            ;;
        "session")
            jq '. + {
                "sessionState": {
                    "sessionId": "test-session-67890",
                    "lastActivity": "2024-02-20T15:45:00Z",
                    "workspaceHistory": ["/home/test/project1", "/home/test/project2"]
                }
            }' "$settings_file" > "$settings_file.tmp"
            ;;
        "user_mods")
            jq '. + {
                "userModifications": {
                    "customTheme": "monokai",
                    "shortcuts": ["ctrl+s", "ctrl+z"],
                    "customCommands": ["/my-custom-cmd"]
                }
            }' "$settings_file" > "$settings_file.tmp"
            ;;
    esac

    mv "$settings_file.tmp" "$settings_file"
    log_debug "동적 상태 추가: $settings_file ($state_type)"
}

# === 병렬 테스트 환경 ===

# 병렬 테스트용 격리된 환경 생성
setup_isolated_test_environment() {
    local test_id="$1"
    local base_dir="${2:-/tmp}"

    local isolated_dir="$base_dir/test_env_${test_id}_$$"
    mkdir -p "$isolated_dir"

    # 환경 변수 격리
    cat > "$isolated_dir/env.sh" << EOF
export TEST_ID="$test_id"
export TEST_DIR="$isolated_dir"
export HOME="$isolated_dir/home"
export XDG_CONFIG_HOME="$isolated_dir/config"
export PATH="$isolated_dir/bin:\$PATH"
mkdir -p "\$HOME" "\$XDG_CONFIG_HOME" "$isolated_dir/bin"
EOF

    echo "$isolated_dir"
    log_debug "격리된 테스트 환경 생성: $isolated_dir (ID: $test_id)"
}

# === 정리 함수들 ===

# 테스트 환경 정리
cleanup_mock_environment() {
    local test_dirs=("$@")

    for dir in "${test_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            # 권한 문제 해결 후 삭제
            chmod -R u+w "$dir" 2>/dev/null || true
            rm -rf "$dir"
            log_debug "테스트 환경 정리: $dir"
        fi
    done
}

# 대량 정리 (패턴 기반)
cleanup_test_environments_by_pattern() {
    local pattern="${1:-test_*}"
    local base_dir="${2:-/tmp}"

    local cleanup_count=0
    for dir in "$base_dir"/$pattern; do
        if [[ -d "$dir" ]]; then
            chmod -R u+w "$dir" 2>/dev/null || true
            rm -rf "$dir"
            ((cleanup_count++))
        fi
    done

    if [[ $cleanup_count -gt 0 ]]; then
        log_debug "패턴 기반 정리 완료: $cleanup_count개 디렉토리"
    fi
}

# === Homebrew 테스트 환경 ===

# Homebrew 테스트 환경 설정
setup_mock_homebrew_environment() {
    local test_dir="$1"
    local mock_mode="${2:-safe}"  # safe, full, offline

    mkdir -p "$test_dir"/{brew,casks,logs}

    # Mock Homebrew 실행 파일 생성
    cat > "$test_dir/brew/brew" << 'EOF'
#!/usr/bin/env bash
# Mock Homebrew for testing

case "$1" in
    "--version")
        echo "Homebrew 4.0.0"
        echo "Homebrew/homebrew-core (git revision abc123; last commit 2024-02-20)"
        ;;
    "--prefix")
        if [[ "$(uname -m)" == "arm64" ]]; then
            echo "/opt/homebrew"
        else
            echo "/usr/local"
        fi
        ;;
    "--cellar")
        echo "$(brew --prefix)/Cellar"
        ;;
    "help")
        if [[ "$2" == "cask" ]]; then
            echo "Homebrew Cask provides a friendly macOS CLI workflow"
            echo "Usage: brew cask <command>"
        else
            echo "Example usage:"
            echo "  brew search TEXT|/REGEX/"
            echo "  brew info [FORMULA|CASK...]"
        fi
        ;;
    "info")
        if [[ "$2" == "--cask" ]]; then
            local cask_name="$3"
            echo "$cask_name: Mock application (cask)"
            echo "https://mock-app.example.com"
            echo "Not installed"
        fi
        ;;
    "list")
        if [[ "$2" == "--cask" ]]; then
            # Mock installed casks
            echo "alfred"
            echo "vlc"
            echo "discord"
        fi
        ;;
    "outdated")
        if [[ "$2" == "--cask" ]]; then
            # Mock outdated casks
            echo "discord (0.0.1) != 0.0.2"
        fi
        ;;
    "search")
        if [[ "$2" == "--cask" ]]; then
            echo "==> Casks"
            echo "$3 $3-pro $3-beta"
        fi
        ;;
    *)
        echo "Mock brew: Unknown command '$1'" >&2
        exit 1
        ;;
esac
EOF

    chmod +x "$test_dir/brew/brew"

    # Mock Cask 정보 파일들 생성
    create_mock_cask_info "$test_dir/casks"

    # Mock Homebrew 환경 변수 설정
    cat > "$test_dir/homebrew-env.sh" << EOF
export PATH="$test_dir/brew:\$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_CI_MODE=true
export HOMEBREW_MOCK_MODE="$mock_mode"
EOF

    log_debug "Mock Homebrew 환경 생성: $test_dir (모드: $mock_mode)"
}

# Mock Cask 정보 생성
create_mock_cask_info() {
    local casks_dir="$1"

    local cask_apps=(
        "alfred:생산성:Alfred App Ltd."
        "vlc:멀티미디어:VideoLAN"
        "discord:커뮤니케이션:Discord Inc."
        "docker-desktop:개발:Docker Inc."
        "google-chrome:브라우저:Google LLC"
        "firefox:브라우저:Mozilla"
        "1password:보안:AgileBits Inc."
        "karabiner-elements:시스템:Fumihiko Takayama"
        "tailscale-app:네트워크:Tailscale Inc."
        "hammerspoon:자동화:Hammerspoon"
    )

    for app_info in "${cask_apps[@]}"; do
        local app="${app_info%%:*}"
        local category="${app_info#*:}"
        category="${category%%:*}"
        local vendor="${app_info##*:}"

        cat > "$casks_dir/${app}.info" << EOF
{
  "name": "$app",
  "category": "$category",
  "vendor": "$vendor",
  "version": "1.0.0",
  "installed": false,
  "homepage": "https://$app.example.com",
  "description": "Mock $category application for testing",
  "requires_license": $(if [[ "$app" =~ (datagrip|intellij|1password) ]]; then echo "true"; else echo "false"; fi),
  "system_permissions": $(if [[ "$app" =~ (karabiner|tailscale|docker) ]]; then echo "true"; else echo "false"; fi)
}
EOF
    done

    log_debug "Mock Cask 정보 파일들 생성: $casks_dir"
}

# Homebrew 테스트 상태 시뮬레이션
simulate_homebrew_state() {
    local test_dir="$1"
    local state_type="$2"  # clean, partially_installed, problematic

    case "$state_type" in
        "clean")
            # 깨끗한 상태 - 아무것도 설치되지 않음
            rm -f "$test_dir/casks"/*.installed
            ;;
        "partially_installed")
            # 일부 앱만 설치된 상태
            touch "$test_dir/casks/alfred.installed"
            touch "$test_dir/casks/vlc.installed"
            touch "$test_dir/casks/discord.installed"
            ;;
        "problematic")
            # 문제가 있는 상태 - 일부 앱에 문제
            touch "$test_dir/casks/broken-app.problematic"
            echo "Error: Application damaged" > "$test_dir/logs/error.log"
            ;;
    esac

    log_debug "Homebrew 상태 시뮬레이션: $state_type"
}

# Homebrew 네트워크 상태 시뮬레이션
simulate_network_conditions() {
    local test_dir="$1"
    local condition="$2"  # online, offline, slow, timeout

    cat > "$test_dir/network-env.sh" << EOF
# Network simulation for Homebrew testing
export HOMEBREW_NETWORK_CONDITION="$condition"

case "$condition" in
    "offline")
        export HOMEBREW_CURL_TIMEOUT=1
        alias curl='curl --max-time 1'
        ;;
    "slow")
        export HOMEBREW_CURL_TIMEOUT=30
        alias curl='curl --limit-rate 1k'
        ;;
    "timeout")
        export HOMEBREW_CURL_TIMEOUT=5
        alias curl='timeout 5s curl'
        ;;
    "online")
        # Normal network conditions
        ;;
esac
EOF

    log_debug "네트워크 상태 시뮬레이션: $condition"
}

# macOS 시스템 정보 시뮬레이션
simulate_macos_environment() {
    local test_dir="$1"
    local macos_version="${2:-14.0}"  # Sonoma by default
    local architecture="${3:-arm64}"  # Apple Silicon by default

    cat > "$test_dir/macos-env.sh" << EOF
# macOS environment simulation
export MOCK_MACOS_VERSION="$macos_version"
export MOCK_ARCHITECTURE="$architecture"

# Override system commands for testing
uname() {
    case "\$1" in
        "-s") echo "Darwin" ;;
        "-m") echo "$architecture" ;;
        "-r") echo "23.0.0" ;;  # Kernel version for macOS 14
        *) command uname "\$@" ;;
    esac
}

sw_vers() {
    case "\$1" in
        "-productVersion") echo "$macos_version" ;;
        "-buildVersion") echo "23A344" ;;
        "-productName") echo "macOS" ;;
        *) echo "ProductName: macOS\\nProductVersion: $macos_version\\nBuildVersion: 23A344" ;;
    esac
}

csrutil() {
    if [[ "\$1" == "status" ]]; then
        echo "System Integrity Protection status: enabled."
    fi
}

spctl() {
    if [[ "\$1" == "--status" ]]; then
        echo "assessments enabled"
    fi
}

# Export functions for subshells
export -f uname sw_vers csrutil spctl
EOF

    log_debug "macOS 환경 시뮬레이션: $macos_version ($architecture)"
}

# Homebrew 테스트 시나리오 생성
create_homebrew_test_scenario() {
    local test_dir="$1"
    local scenario_name="$2"
    local scenario_config="$3"

    mkdir -p "$test_dir/scenarios/$scenario_name"

    case "$scenario_name" in
        "fresh_install")
            setup_mock_homebrew_environment "$test_dir/scenarios/$scenario_name" "safe"
            simulate_homebrew_state "$test_dir/scenarios/$scenario_name" "clean"
            simulate_network_conditions "$test_dir/scenarios/$scenario_name" "online"
            ;;
        "upgrade_scenario")
            setup_mock_homebrew_environment "$test_dir/scenarios/$scenario_name" "full"
            simulate_homebrew_state "$test_dir/scenarios/$scenario_name" "partially_installed"
            simulate_network_conditions "$test_dir/scenarios/$scenario_name" "online"
            ;;
        "offline_scenario")
            setup_mock_homebrew_environment "$test_dir/scenarios/$scenario_name" "offline"
            simulate_homebrew_state "$test_dir/scenarios/$scenario_name" "clean"
            simulate_network_conditions "$test_dir/scenarios/$scenario_name" "offline"
            ;;
        "problematic_scenario")
            setup_mock_homebrew_environment "$test_dir/scenarios/$scenario_name" "safe"
            simulate_homebrew_state "$test_dir/scenarios/$scenario_name" "problematic"
            simulate_network_conditions "$test_dir/scenarios/$scenario_name" "timeout"
            ;;
    esac

    # 시나리오 설정 파일 생성
    cat > "$test_dir/scenarios/$scenario_name/scenario.json" << EOF
{
    "name": "$scenario_name",
    "description": "Test scenario for $scenario_name",
    "config": $scenario_config,
    "created": "$(date -Iseconds)",
    "platform": "darwin",
    "homebrew_mock": true
}
EOF

    log_debug "Homebrew 테스트 시나리오 생성: $scenario_name"
}

# === 유틸리티 함수들 ===

# 환경 검증
validate_mock_environment() {
    local test_dir="$1"
    local env_type="${2:-basic}"

    case "$env_type" in
        "claude")
            [[ -f "$test_dir/settings.json" ]] || return 1
            [[ -f "$test_dir/CLAUDE.md" ]] || return 1
            [[ -d "$test_dir/commands" ]] || return 1
            [[ -d "$test_dir/agents" ]] || return 1
            ;;
        "nix")
            [[ -f "$test_dir/flake.nix" ]] || return 1
            [[ -f "$test_dir/default.nix" ]] || return 1
            ;;
        "homebrew")
            [[ -f "$test_dir/brew/brew" ]] || return 1
            [[ -x "$test_dir/brew/brew" ]] || return 1
            [[ -d "$test_dir/casks" ]] || return 1
            [[ -f "$test_dir/homebrew-env.sh" ]] || return 1
            ;;
        "basic")
            [[ -d "$test_dir" ]] || return 1
            [[ -f "$test_dir/README.md" ]] || return 1
            ;;
    esac

    log_debug "환경 검증 통과: $test_dir ($env_type)"
    return 0
}

# 환경 정보 출력
describe_mock_environment() {
    local test_dir="$1"

    log_info "Mock 환경 정보: $test_dir"
    log_info "  디렉토리 크기: $(du -sh "$test_dir" 2>/dev/null | cut -f1)"
    log_info "  파일 개수: $(find "$test_dir" -type f | wc -l)"
    log_info "  디렉토리 개수: $(find "$test_dir" -type d | wc -l)"
}

log_debug "모의 환경 라이브러리 로드 완료 (v$MOCK_ENV_VERSION)"
