#!/usr/bin/env bash
# ABOUTME: Homebrew 시스템 통합 테스트 - 전체 Cask 목록 및 시스템 레벨 통합 검증
# ABOUTME: macOS 시스템과 Homebrew Cask의 완전한 통합 상태를 검증하는 종합 테스트

set -euo pipefail

# 테스트 프레임워크 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-framework.sh
source "$SCRIPT_DIR/../lib/test-framework.sh"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트 설정
readonly TEST_SUITE_NAME="Homebrew System Integration"
readonly DOTFILES_ROOT="$SCRIPT_DIR/../.."
readonly CASKS_FILE="$DOTFILES_ROOT/modules/darwin/casks.nix"

# === 테스트 초기화 ===

main() {
  test_framework_init
  setup_signal_handlers

  log_header "Homebrew 시스템 통합 테스트 시작"

  # 플랫폼 검증
  if ! validate_test_environment; then
    log_error "테스트 환경이 적합하지 않습니다"
    exit 1
  fi

  # 테스트 실행
  run_all_tests

  # 결과 보고
  report_test_results
}

# === 환경 검증 ===

validate_test_environment() {
  start_test_group "환경 검증"

  # macOS 플랫폼 확인
  if [[ "$(detect_platform)" != "darwin" ]]; then
    log_error "이 테스트는 macOS(Darwin)에서만 실행됩니다"
    return 1
  fi

  assert "[[ -f '$CASKS_FILE' ]]" "Cask 설정 파일 존재"
  assert "[[ -r '$CASKS_FILE' ]]" "Cask 설정 파일 읽기 권한"

  # Homebrew 설치 확인
  assert "command -v brew >/dev/null 2>&1" "Homebrew 설치 확인"

  # 필수 도구 확인
  check_required_tools "brew" "grep" "wc" "sort"

  end_test_group
  return 0
}

# === 메인 테스트 스위트 ===

run_all_tests() {
  test_homebrew_installation
  test_cask_configuration
  test_application_categories
  test_system_integration
  test_performance_monitoring
  test_update_mechanisms
  test_conflict_resolution
  test_security_validation
  test_automation_support
}

# === Homebrew 설치 및 기본 기능 테스트 ===

test_homebrew_installation() {
  start_test_group "Homebrew 설치 및 기본 기능"

  # Homebrew 버전 확인
  local brew_version
  brew_version=$(brew --version | head -n1)
  assert "[[ -n '$brew_version' ]]" "Homebrew 버전 정보 조회" "non-empty" "$brew_version"
  log_info "Homebrew 버전: $brew_version"

  # Homebrew 설치 경로 확인
  local brew_prefix
  brew_prefix=$(brew --prefix)
  assert "[[ -d '$brew_prefix' ]]" "Homebrew 설치 디렉토리 존재"

  # 아키텍처별 경로 확인
  local expected_prefix
  if [[ "$(detect_architecture)" == "aarch64" ]]; then
    expected_prefix="/opt/homebrew"
  else
    expected_prefix="/usr/local"
  fi
  assert_equals "$expected_prefix" "$brew_prefix" "아키텍처별 Homebrew 설치 경로"

  # Cask 서브커맨드 사용 가능 확인
  assert_command_success "brew help cask >/dev/null 2>&1" "Cask 서브커맨드 사용 가능"

  # Homebrew 환경 변수 확인
  local homebrew_cellar
  homebrew_cellar=$(brew --cellar)
  assert "[[ -d '$homebrew_cellar' ]]" "Homebrew Cellar 디렉토리 존재"

  end_test_group
}

# === Cask 설정 파일 구조 테스트 ===

test_cask_configuration() {
  start_test_group "Cask 설정 파일 구조"

  # 파일 구조 검증
  assert_file_exists "$CASKS_FILE" "Cask 설정 파일 존재"

  # Nix 배열 구조 확인
  local first_line
  first_line=$(head -n1 "$CASKS_FILE")
  assert_equals "[" "$first_line" "Nix 배열 시작 구조"

  local last_line
  last_line=$(tail -n1 "$CASKS_FILE")
  assert_equals "]" "$last_line" "Nix 배열 종료 구조"

  # 문법 오류 검사
  assert "! grep -q '\"\"' '$CASKS_FILE'" "빈 문자열 없음"
  assert "! grep -q '[^[:print:]]' '$CASKS_FILE'" "비출력 문자 없음"

  # 중복 Cask 확인
  local duplicates
  duplicates=$(grep -o '"[^"]*"' "$CASKS_FILE" | sort | uniq -d)
  assert "[[ -z '$duplicates' ]]" "중복 Cask 없음"

  # 전체 Cask 개수 확인
  local total_casks
  total_casks=$(extract_cask_names | wc -l | tr -d ' ')
  assert_greater_or_equal "$total_casks" "30" "최소 Cask 개수 (현재: $total_casks개)"
  assert_less_or_equal "$total_casks" "50" "최대 Cask 개수 (관리 용이성)"

  end_test_group
}

# === 애플리케이션 카테고리별 테스트 ===

test_application_categories() {
  start_test_group "애플리케이션 카테고리별 검증"

  # 개발 도구 카테고리
  test_development_tools_category

  # 커뮤니케이션 도구 카테고리
  test_communication_tools_category

  # 브라우저 카테고리
  test_browsers_category

  # 유틸리티 도구 카테고리
  test_utility_tools_category

  # 보안 도구 카테고리
  test_security_tools_category

  end_test_group
}

test_development_tools_category() {
  push_test_context "개발 도구"

  local dev_tools=("datagrip" "docker-desktop" "intellij-idea")

  for tool in "${dev_tools[@]}"; do
    assert_contains "$(cat "$CASKS_FILE")" "\"$tool\"" "$tool 정의됨"

    # CI 환경이 아닌 경우 Cask 정보 확인
    if [[ ${CI:-false} != "true" ]]; then
      if timeout 30s brew info --cask "$tool" >/dev/null 2>&1; then
        log_success "$tool Cask 정보 조회 성공"
      else
        log_warning "$tool Cask 정보 조회 실패 (네트워크 문제 가능)"
      fi
    fi
  done

  pop_test_context
}

test_communication_tools_category() {
  push_test_context "커뮤니케이션 도구"

  local comm_tools=("discord" "notion" "slack" "telegram" "zoom" "obsidian")
  local found_count=0

  for tool in "${comm_tools[@]}"; do
    if grep -q "\"$tool\"" "$CASKS_FILE"; then
      found_count=$((found_count + 1))
      log_success "$tool 발견됨"
    fi
  done

  assert_greater_or_equal "$found_count" "4" "최소 커뮤니케이션 도구 개수"

  pop_test_context
}

test_browsers_category() {
  push_test_context "브라우저"

  local browsers=("google-chrome" "brave-browser" "firefox")
  local found_browsers=0

  for browser in "${browsers[@]}"; do
    if grep -q "\"$browser\"" "$CASKS_FILE"; then
      found_browsers=$((found_browsers + 1))
      log_success "$browser 브라우저 정의됨"
    fi
  done

  assert_greater_or_equal "$found_browsers" "2" "최소 브라우저 개수 (다양성 확보)"

  pop_test_context
}

test_utility_tools_category() {
  push_test_context "유틸리티 도구"

  local utilities=("alt-tab" "claude" "karabiner-elements" "tailscale-app" "hammerspoon" "alfred")
  local system_level_tools=("karabiner-elements" "tailscale-app" "hammerspoon")

  # 유틸리티 도구 존재 확인
  for util in "${utilities[@]}"; do
    if grep -q "\"$util\"" "$CASKS_FILE"; then
      log_success "$util 유틸리티 정의됨"

      # 시스템 레벨 도구의 경우 권한 요구사항 로깅
      if [[ " ${system_level_tools[*]} " =~ " $util " ]]; then
        log_info "$util는 시스템 레벨 권한이 필요한 도구입니다"
      fi
    fi
  done

  pop_test_context
}

test_security_tools_category() {
  push_test_context "보안 도구"

  local security_tools=("1password" "1password-cli")

  for tool in "${security_tools[@]}"; do
    assert_contains "$(cat "$CASKS_FILE")" "\"$tool\"" "$tool 보안 도구 정의됨"
  done

  # 패스워드 매니저와 CLI 도구의 일관성 확인
  if grep -q '"1password"' "$CASKS_FILE" && grep -q '"1password-cli"' "$CASKS_FILE"; then
    log_success "1Password GUI와 CLI 도구가 모두 정의되어 일관성 있음"
  fi

  pop_test_context
}

# === 시스템 통합 테스트 ===

test_system_integration() {
  start_test_group "시스템 통합"

  # Applications 폴더 접근 권한 확인
  assert "[[ -d '/Applications' ]]" "Applications 폴더 존재"
  assert "[[ -r '/Applications' ]]" "Applications 폴더 읽기 권한"

  # 시스템 무결성 보호(SIP) 상태 확인
  local sip_status
  if command -v csrutil >/dev/null 2>&1; then
    sip_status=$(csrutil status 2>/dev/null || echo "SIP status unknown")
    log_info "SIP 상태: $sip_status"
  fi

  # 디스크 공간 확인 (최소 5GB 여유공간 권장)
  local available_space
  available_space=$(df -g /Applications | tail -n1 | awk '{print $4}')
  assert_greater_or_equal "$available_space" "5" "충분한 디스크 공간 (${available_space}GB 여유)"

  # 네트워크 연결 확인 (Cask 다운로드용)
  if [[ ${CI:-false} != "true" ]]; then
    if ping -c 1 -W 5000 github.com >/dev/null 2>&1; then
      log_success "외부 네트워크 연결 정상"
    else
      log_warning "외부 네트워크 연결 확인 실패 (Cask 다운로드에 영향 가능)"
    fi
  fi

  end_test_group
}

# === 성능 모니터링 테스트 ===

test_performance_monitoring() {
  start_test_group "성능 모니터링"

  # Homebrew 명령어 실행 시간 측정
  measure_execution_time "brew --version" "Homebrew 버전 조회 성능" 1000

  # Cask 목록 추출 성능 측정
  measure_execution_time "extract_cask_names" "Cask 목록 추출 성능" 500

  # 대용량 Cask들의 디스크 공간 요구사항 계산
  local large_casks=("docker-desktop" "intellij-idea" "datagrip")
  log_info "대용량 애플리케이션 디스크 요구사항:"

  for cask in "${large_casks[@]}"; do
    if grep -q "\"$cask\"" "$CASKS_FILE"; then
      # 예상 크기 정보 (실제로는 brew info로 확인 가능하지만 시간이 오래 걸림)
      case "$cask" in
      "docker-desktop") log_tree 1 "$cask: ~2-4GB" ;;
      "intellij-idea") log_tree 1 "$cask: ~1-2GB" ;;
      "datagrip") log_tree 1 "$cask: ~500MB-1GB" ;;
      esac
    fi
  done

  end_test_group
}

# === 업데이트 메커니즘 테스트 ===

test_update_mechanisms() {
  start_test_group "업데이트 메커니즘"

  # Homebrew 업데이트 비활성화 설정 확인 (CI 환경용)
  if [[ ${CI:-false} == "true" ]]; then
    assert "[[ '${HOMEBREW_NO_AUTO_UPDATE:-}' == '1' ]]" "CI 환경에서 자동 업데이트 비활성화"
    assert "[[ '${HOMEBREW_NO_ANALYTICS:-}' == '1' ]]" "CI 환경에서 분석 비활성화"
  fi

  # 업데이트 가능한 Cask 확인 (실제 업데이트는 하지 않음)
  if [[ ${CI:-false} != "true" ]]; then
    log_info "업데이트 가능한 Cask 확인 중..."
    if timeout 60s brew outdated --cask >/dev/null 2>&1; then
      log_success "Cask 업데이트 상태 확인 완료"
    else
      log_warning "Cask 업데이트 상태 확인 시간 초과"
    fi
  fi

  # 설정 파일의 변경 감지 메커니즘
  local casks_checksum
  casks_checksum=$(shasum -a 256 "$CASKS_FILE" | cut -d' ' -f1)
  assert "[[ -n '$casks_checksum' ]]" "설정 파일 체크섬 생성" "non-empty" "$casks_checksum"
  log_info "현재 casks.nix 체크섬: ${casks_checksum:0:8}..."

  end_test_group
}

# === 충돌 해결 테스트 ===

test_conflict_resolution() {
  start_test_group "충돌 해결"

  # 동일한 기능을 제공하는 애플리케이션들의 공존 가능성 확인
  test_browser_coexistence
  test_development_tool_conflicts
  test_system_tool_conflicts

  end_test_group
}

test_browser_coexistence() {
  push_test_context "브라우저 공존성"

  local browsers=("google-chrome" "brave-browser" "firefox")
  local found_browsers=()

  for browser in "${browsers[@]}"; do
    if grep -q "\"$browser\"" "$CASKS_FILE"; then
      found_browsers+=("$browser")
    fi
  done

  # 여러 브라우저가 정의된 경우 공존 가능성 확인
  if [[ ${#found_browsers[@]} -gt 1 ]]; then
    log_success "다중 브라우저 환경 - 사용자 선택권 제공"
    for browser in "${found_browsers[@]}"; do
      log_tree 1 "$browser"
    done
  fi

  pop_test_context
}

test_development_tool_conflicts() {
  push_test_context "개발 도구 충돌"

  # JetBrains 제품군 내 충돌 확인
  local jetbrains_tools=("intellij-idea" "datagrip" "pycharm" "webstorm")
  local found_jetbrains=()

  for tool in "${jetbrains_tools[@]}"; do
    if grep -q "\"$tool\"" "$CASKS_FILE"; then
      found_jetbrains+=("$tool")
    fi
  done

  if [[ ${#found_jetbrains[@]} -gt 0 ]]; then
    log_info "JetBrains 제품군: ${found_jetbrains[*]}"
    # JetBrains 제품들은 일반적으로 충돌하지 않음
    log_success "JetBrains 제품군 공존 가능"
  fi

  pop_test_context
}

test_system_tool_conflicts() {
  push_test_context "시스템 도구 충돌"

  # 키보드 관리 도구 충돌 확인
  local keyboard_tools=("karabiner-elements" "bettertouchtool" "keyboard-maestro")
  local found_keyboard_tools=()

  for tool in "${keyboard_tools[@]}"; do
    if grep -q "\"$tool\"" "$CASKS_FILE"; then
      found_keyboard_tools+=("$tool")
    fi
  done

  # 키보드 관리 도구는 충돌 가능성이 있으므로 주의 필요
  if [[ ${#found_keyboard_tools[@]} -gt 1 ]]; then
    log_warning "다중 키보드 관리 도구 감지 - 충돌 가능성 있음"
    for tool in "${found_keyboard_tools[@]}"; do
      log_tree 1 "$tool (주의 필요)"
    done
  elif [[ ${#found_keyboard_tools[@]} -eq 1 ]]; then
    log_success "키보드 관리 도구: ${found_keyboard_tools[0]}"
  fi

  pop_test_context
}

# === 보안 검증 테스트 ===

test_security_validation() {
  start_test_group "보안 검증"

  # 신뢰할 수 있는 소스에서 제공되는 Cask들인지 확인
  test_trusted_sources

  # 권한 요구사항이 높은 애플리케이션들 식별
  test_privileged_applications

  # 코드 서명 요구사항 확인
  test_code_signing_requirements

  end_test_group
}

test_trusted_sources() {
  push_test_context "신뢰할 수 있는 소스"

  # 주요 공급업체별 애플리케이션 분류
  local microsoft_apps=("teams" "office" "vscode")
  local google_apps=("google-chrome" "google-drive")
  local jetbrains_apps=("intellij-idea" "datagrip")
  local opensource_apps=("firefox" "vlc" "discord")

  # 각 카테고리별 검증
  for category in "Microsoft" "Google" "JetBrains" "오픈소스"; do
    case "$category" in
    "Microsoft") apps=("${microsoft_apps[@]}") ;;
    "Google") apps=("${google_apps[@]}") ;;
    "JetBrains") apps=("${jetbrains_apps[@]}") ;;
    "오픈소스") apps=("${opensource_apps[@]}") ;;
    esac

    local found_apps=()
    for app in "${apps[@]}"; do
      if grep -q "\"$app\"" "$CASKS_FILE"; then
        found_apps+=("$app")
      fi
    done

    if [[ ${#found_apps[@]} -gt 0 ]]; then
      log_info "$category 애플리케이션: ${found_apps[*]}"
    fi
  done

  pop_test_context
}

test_privileged_applications() {
  push_test_context "권한 요구 애플리케이션"

  # 시스템 레벨 권한이 필요한 애플리케이션들
  local privileged_apps=(
    "karabiner-elements:키보드 입력 모니터링"
    "tailscale-app:네트워크 설정 변경"
    "hammerspoon:접근성 권한"
    "docker-desktop:시스템 확장 및 네트워크"
  )

  for app_desc in "${privileged_apps[@]}"; do
    local app="${app_desc%:*}"
    local permission="${app_desc#*:}"

    if grep -q "\"$app\"" "$CASKS_FILE"; then
      log_warning "$app 감지 - $permission 권한 필요"
    fi
  done

  pop_test_context
}

test_code_signing_requirements() {
  push_test_context "코드 서명 요구사항"

  # macOS 보안 정책에 따른 코드 서명 확인
  local gatekeeper_status
  gatekeeper_status=$(spctl --status 2>/dev/null || echo "Gatekeeper status unknown")
  log_info "Gatekeeper 상태: $gatekeeper_status"

  # 공증이 필요한 애플리케이션들 (macOS 10.15+)
  if [[ "$(sw_vers -productVersion | cut -d. -f1)" -ge 10 ]] && [[ "$(sw_vers -productVersion | cut -d. -f2)" -ge 15 ]]; then
    log_info "macOS 10.15+ 환경: 공증된 애플리케이션 권장"
  fi

  pop_test_context
}

# === 자동화 지원 테스트 ===

test_automation_support() {
  start_test_group "자동화 지원"

  # 스크립트 기반 Cask 관리 테스트
  test_script_integration

  # 배치 설치 시나리오 테스트
  test_batch_installation_scenario

  # 설정 백업 및 복원 메커니즘 테스트
  test_configuration_backup

  end_test_group
}

test_script_integration() {
  push_test_context "스크립트 통합"

  # Cask 목록을 스크립트에서 사용할 수 있는 형태로 추출
  local cask_array
  cask_array=$(extract_cask_names | tr '\n' ' ')
  assert "[[ -n '$cask_array' ]]" "스크립트용 Cask 배열 생성"

  # JSON 형태로 변환 가능한지 테스트
  if command -v jq >/dev/null 2>&1; then
    local cask_json
    cask_json=$(extract_cask_names | jq -R . | jq -s .)
    assert "[[ -n '$cask_json' ]]" "JSON 형태 Cask 목록 생성"
    log_debug "JSON 형태 변환 성공"
  fi

  pop_test_context
}

test_batch_installation_scenario() {
  push_test_context "배치 설치 시나리오"

  # 카테고리별 설치 순서 최적화 테스트
  local install_order=(
    "보안 도구"
    "시스템 유틸리티"
    "개발 도구"
    "커뮤니케이션 도구"
    "브라우저"
    "엔터테인먼트"
  )

  for category in "${install_order[@]}"; do
    log_info "설치 순서 $category 단계"
  done

  # 병렬 설치 가능성 확인
  local independent_casks=("vlc" "alfred" "discord")
  log_info "독립적 설치 가능: ${independent_casks[*]}"

  # 의존성이 있는 설치 순서 확인
  if grep -q '"1password"' "$CASKS_FILE" && grep -q '"1password-cli"' "$CASKS_FILE"; then
    log_info "권장 설치 순서: 1password → 1password-cli"
  fi

  pop_test_context
}

test_configuration_backup() {
  push_test_context "설정 백업"

  # 현재 설정의 체크섬 생성
  local current_checksum
  current_checksum=$(shasum -a 256 "$CASKS_FILE" | cut -d' ' -f1)

  # 백업 파일 생성 시뮬레이션
  local backup_file="/tmp/casks.nix.backup.$$"
  cp "$CASKS_FILE" "$backup_file"

  # 백업 파일 검증
  assert_file_exists "$backup_file" "백업 파일 생성"

  local backup_checksum
  backup_checksum=$(shasum -a 256 "$backup_file" | cut -d' ' -f1)
  assert_equals "$current_checksum" "$backup_checksum" "백업 파일 무결성"

  # 정리
  rm -f "$backup_file"

  pop_test_context
}

# === 유틸리티 함수들 ===

# Cask 이름 추출 함수
extract_cask_names() {
  grep -o '"[^"]*"' "$CASKS_FILE" | tr -d '"' | grep -v '^#' | sort
}

# 카테고리별 Cask 개수 계산
count_casks_by_category() {
  local category="$1"
  local pattern

  case "$category" in
  "development")
    pattern="datagrip\|docker\|intellij\|pycharm\|webstorm\|vscode"
    ;;
  "communication")
    pattern="discord\|slack\|zoom\|telegram\|teams\|notion"
    ;;
  "browsers")
    pattern="chrome\|firefox\|brave\|safari\|edge"
    ;;
  "utilities")
    pattern="alfred\|alt-tab\|karabiner\|hammerspoon\|tailscale"
    ;;
  "security")
    pattern="1password\|bitwarden\|keepass"
    ;;
  *)
    echo "0"
    return 1
    ;;
  esac

  extract_cask_names | grep -E "$pattern" | wc -l | tr -d ' '
}

# === 메인 실행 ===

# 스크립트가 직접 실행된 경우에만 main 함수 호출
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
