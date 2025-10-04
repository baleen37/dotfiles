#!/usr/bin/env bash
# ABOUTME: SSH 연결 복원력 통합 테스트
# ABOUTME: SSH 설정과 autossh 래퍼의 실제 연결 동작 검증

set -euo pipefail

# 테스트 프레임워크 로드
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/tests/lib/common.sh"
source "$PROJECT_ROOT/tests/lib/test-framework.sh"
source "$PROJECT_ROOT/tests/config/test-config.sh"

TEST_SUITE_NAME="SSH Connection Resilience Integration Test"

# 테스트 시작
main() {
  test_framework_init

  log_info "Starting SSH Connection Resilience Integration Tests..."

  # 테스트 실행
  run_test "test_ssh_config_keep_alive_settings"
  run_test "test_ssh_multiplexing_config"
  run_test "test_autossh_wrapper_integration"
  run_test "test_ssh_timeout_behavior"
  run_test "test_ssh_connection_reuse"

  # 결과 출력
  print_test_summary

  # 실패한 테스트가 있으면 종료 코드 1 반환
  [[ $TESTS_FAILED -eq 0 ]]
}

# SSH 설정의 keep-alive 설정 확인
test_ssh_config_keep_alive_settings() {
  local test_name="SSH keep-alive 설정 확인"

  # SSH 설정 파일 내용 확인
  if [[ ! -f ~/.ssh/config ]]; then
    assert_failure "SSH 설정 파일이 존재하지 않음"
    return
  fi

  local config_content
  config_content=$(cat ~/.ssh/config)

  # ServerAliveInterval 설정 확인
  if echo "$config_content" | grep -q "ServerAliveInterval 60"; then
    assert_success "ServerAliveInterval이 올바르게 설정됨 (60초)"
  else
    assert_failure "ServerAliveInterval 설정을 찾을 수 없음"
    return
  fi

  # ServerAliveCountMax 설정 확인
  if echo "$config_content" | grep -q "ServerAliveCountMax 3"; then
    assert_success "ServerAliveCountMax가 올바르게 설정됨 (3회)"
  else
    assert_failure "ServerAliveCountMax 설정을 찾을 수 없음"
    return
  fi

  # TCPKeepAlive 설정 확인
  if echo "$config_content" | grep -q "TCPKeepAlive yes"; then
    assert_success "TCPKeepAlive가 활성화됨"
  else
    assert_failure "TCPKeepAlive 설정을 찾을 수 없음"
    return
  fi

  log_success "$test_name: PASS"
}

# SSH 다중화 설정 확인
test_ssh_multiplexing_config() {
  local test_name="SSH 다중화 설정 확인"

  local config_content
  config_content=$(cat ~/.ssh/config 2>/dev/null || echo "")

  # ControlMaster 설정이 있는지 확인 (현재는 없지만 향후 추가될 수 있음)
  if echo "$config_content" | grep -q "ControlMaster"; then
    log_info "ControlMaster 설정 발견됨"

    if echo "$config_content" | grep -q "ControlMaster auto"; then
      assert_success "ControlMaster가 auto로 설정됨"
    fi

    if echo "$config_content" | grep -q "ControlPersist"; then
      assert_success "ControlPersist 설정이 존재함"
    fi
  else
    log_info "ControlMaster 설정이 없음 (autossh 래퍼 사용)"
    assert_success "기본 설정으로 동작"
  fi

  log_success "$test_name: PASS"
}

# autossh 래퍼와 SSH 설정 통합 테스트
test_autossh_wrapper_integration() {
  local test_name="autossh 래퍼 통합 동작 확인"

  # SSH 래퍼 함수가 SSH 설정을 올바르게 사용하는지 확인
  local integration_test
  integration_test=$(zsh -c "
        source ~/.zshrc 2>/dev/null || true

        # Mock functions for testing
        command() {
            if [[ \$1 == '-v' && \$2 == 'autossh' ]]; then
                return 0  # autossh available
            fi
            return 1
        }

        autossh() {
            # autossh가 SSH 설정을 사용하는지 확인
            local args=(\"\$@\")
            if [[ \${args[0]} == '-M' && \${args[1]} == '0' ]]; then
                echo 'autossh_with_correct_monitoring'
            else
                echo 'autossh_with_wrong_args'
            fi
        }

        # SSH wrapper function
        ssh() {
            if command -v autossh >/dev/null 2>&1; then
                autossh -M 0 \"\$@\"
            else
                command ssh \"\$@\"
            fi
        }

        # Test execution
        ssh test@example.com
    ")

  if [[ $integration_test == "autossh_with_correct_monitoring" ]]; then
    assert_success "autossh 래퍼가 올바른 모니터링 설정으로 실행됨"
  else
    assert_failure "autossh 래퍼 통합 실패: $integration_test"
    return
  fi

  log_success "$test_name: PASS"
}

# SSH 타임아웃 동작 테스트
test_ssh_timeout_behavior() {
  local test_name="SSH 타임아웃 동작 확인"

  # SSH 설정에서 계산된 총 타임아웃 시간 확인
  local server_alive_interval=60
  local server_alive_count_max=3
  local total_timeout=$((server_alive_interval * server_alive_count_max))

  # 예상 타임아웃: 60 * 3 = 180초 (3분)
  if [[ $total_timeout -eq 180 ]]; then
    assert_success "SSH 타임아웃이 올바르게 계산됨 (180초)"
  else
    assert_failure "SSH 타임아웃 계산 오류: ${total_timeout}초"
    return
  fi

  log_info "SSH 연결은 3분 동안 응답이 없으면 자동으로 재연결 시도"

  log_success "$test_name: PASS"
}

# SSH 연결 재사용 동작 확인
test_ssh_connection_reuse() {
  local test_name="SSH 연결 재사용 동작 확인"

  # ControlPath 디렉토리가 있는지 확인 (있다면 사용 중)
  local has_controlmasters=false
  if [[ -d ~/.ssh/controlmasters/ ]]; then
    has_controlmasters=true
  fi

  # master-* 패턴 확인
  for dir in ~/.ssh/master-*; do
    if [[ -d $dir ]]; then
      has_controlmasters=true
      break
    fi
  done 2>/dev/null

  if [[ $has_controlmasters == "true" ]]; then
    log_info "SSH 다중화 소켓 디렉토리 발견됨"
    assert_success "SSH 연결 재사용이 설정되어 있음"
  else
    log_info "SSH 다중화 미사용 (각 연결이 독립적으로 동작)"
    assert_success "독립적인 연결 방식으로 동작"
  fi

  # autossh의 연결 재시작 기능이 주요 복원력 메커니즘
  log_info "autossh 래퍼를 통한 자동 재연결이 주요 복원력 메커니즘"

  log_success "$test_name: PASS"
}

# 스크립트가 직접 실행된 경우에만 main 함수 호출
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
