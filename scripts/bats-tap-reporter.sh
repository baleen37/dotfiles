#!/usr/bin/env bash
# TAP (Test Anything Protocol) compatible BATS reporter
# Enhanced reporting with Korean language support and detailed output

set -euo pipefail

# Import unified color system
SCRIPTS_DIR="$(dirname "$0")"
. "${SCRIPTS_DIR}/lib/unified-colors.sh"
# Additional colors for this script
CYAN='\033[0;36m'
BOLD='\033[1m'

# Configuration
REPORT_DIR="${1:-./test-reports}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/bats_report_$TIMESTAMP.tap"
SUMMARY_FILE="$REPORT_DIR/bats_summary_$TIMESTAMP.json"

# Create report directory
mkdir -p "$REPORT_DIR"

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0
skipped_tests=0
start_time=$(date +%s)

# Function to log test results
log_test_result() {
  local status="$1"
  local test_name="$2"
  local details="${3:-}"

  case "$status" in
  "ok")
    ((passed_tests++))
    echo -e "${GREEN}✓${NC} ${test_name}" >&2
    ;;
  "not ok")
    ((failed_tests++))
    echo -e "${RED}✗${NC} ${test_name}" >&2
    if [[ -n $details ]]; then
      echo -e "${RED}  Error: $details${NC}" >&2
    fi
    ;;
  "skip")
    ((skipped_tests++))
    echo -e "${YELLOW}⊘${NC} ${test_name} (SKIPPED)" >&2
    ;;
  esac
  ((total_tests++))
}

# Function to run BATS tests with TAP output
run_bats_with_tap() {
  local test_file="$1"
  local test_name="$2"

  echo -e "\n${CYAN}${BOLD}🧪 Running: $test_name${NC}"
  echo "# Running $test_name" >>"$REPORT_FILE"

  # Run BATS test and capture output
  if command -v bats >/dev/null 2>&1; then
    bats "$test_file" 2>&1 | tee -a "$REPORT_FILE" | while IFS= read -r line; do
      if [[ $line =~ ^ok\ ([0-9]+)\ (.+)$ ]]; then
        log_test_result "ok" "${BASH_REMATCH[2]}"
      elif [[ $line =~ ^not\ ok\ ([0-9]+)\ (.+)$ ]]; then
        log_test_result "not ok" "${BASH_REMATCH[2]}" "Test failed"
      elif [[ $line =~ ^ok\ ([0-9]+)\ (.+)\ #\ SKIP ]]; then
        log_test_result "skip" "${BASH_REMATCH[2]}"
      fi
    done
  else
    echo "Installing BATS via Nix..." >&2
    nix shell nixpkgs#bats -c bats "$test_file" 2>&1 | tee -a "$REPORT_FILE" | while IFS= read -r line; do
      if [[ $line =~ ^ok\ ([0-9]+)\ (.+)$ ]]; then
        log_test_result "ok" "${BASH_REMATCH[2]}"
      elif [[ $line =~ ^not\ ok\ ([0-9]+)\ (.+)$ ]]; then
        log_test_result "not ok" "${BASH_REMATCH[2]}" "Test failed"
      elif [[ $line =~ ^ok\ ([0-9]+)\ (.+)\ #\ SKIP ]]; then
        log_test_result "skip" "${BASH_REMATCH[2]}"
      fi
    done
  fi
}

# Main execution
main() {
  echo -e "${BOLD}${CYAN}🚀 BATS TAP Reporter${NC}"
  echo -e "${BOLD}Report Directory: $REPORT_DIR${NC}"
  echo -e "${BOLD}Timestamp: $(date)${NC}"

  # Initialize TAP file
  echo "TAP version 14" >"$REPORT_FILE"
  echo "# BATS Test Report - $(date)" >>"$REPORT_FILE"

  # Test files to run
  local test_files=(
    "tests/bats/test_platform_detection.bats:플랫폼 감지"
    "tests/bats/test_build_system.bats:빌드 시스템"
    "tests/bats/test_claude_activation.bats:Claude 활성화"
    "tests/bats/test_lib_user_resolution.bats:사용자 해결"
    "tests/bats/test_lib_error_system.bats:에러 시스템"
  )

  # Run tests
  for test_info in "${test_files[@]}"; do
    IFS=':' read -r test_file test_name <<<"$test_info"
    if [[ -f $test_file ]]; then
      run_bats_with_tap "$test_file" "$test_name"
    else
      echo -e "${YELLOW}⚠ Warning: $test_file not found${NC}" >&2
    fi
  done

  # Calculate duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # Generate summary
  echo "1..$total_tests" >>"$REPORT_FILE"

  # Create JSON summary
  cat >"$SUMMARY_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "duration_seconds": $duration,
  "total_tests": $total_tests,
  "passed": $passed_tests,
  "failed": $failed_tests,
  "skipped": $skipped_tests,
  "success_rate": $((passed_tests * 100 / (total_tests > 0 ? total_tests : 1))),
  "report_file": "$REPORT_FILE",
  "test_categories": {
    "platform_detection": "플랫폼 감지",
    "build_system": "빌드 시스템",
    "claude_activation": "Claude 활성화",
    "user_resolution": "사용자 해결",
    "error_system": "에러 시스템"
  }
}
EOF

  # Print summary
  echo -e "\n${BOLD}${CYAN}📊 테스트 결과 요약${NC}"
  echo -e "========================="
  echo -e "${GREEN}✓ 성공: $passed_tests${NC}"
  echo -e "${RED}✗ 실패: $failed_tests${NC}"
  echo -e "${YELLOW}⊘ 건너뜀: $skipped_tests${NC}"
  echo -e "${BOLD}총 테스트: $total_tests${NC}"
  echo -e "${BOLD}실행 시간: ${duration}초${NC}"
  echo -e "${BOLD}성공률: $((passed_tests * 100 / (total_tests > 0 ? total_tests : 1)))%${NC}"

  echo -e "\n${CYAN}📄 보고서 파일:${NC}"
  echo -e "  TAP: $REPORT_FILE"
  echo -e "  JSON: $SUMMARY_FILE"

  # Exit with appropriate code
  if [[ $failed_tests -eq 0 ]]; then
    echo -e "\n${GREEN}${BOLD}🎉 모든 테스트가 성공했습니다!${NC}"
    exit 0
  else
    echo -e "\n${RED}${BOLD}❌ 일부 테스트가 실패했습니다.${NC}"
    exit 1
  fi
}

# Check if we're being sourced or executed
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
