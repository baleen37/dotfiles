#!/usr/bin/env bash
# ABOUTME: 테스트 성능 모니터링 및 리그레션 감지 스크립트
# ABOUTME: 테스트 실행 시간을 추적하고 성능 저하를 조기에 발견

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly PERF_LOG_DIR="$PROJECT_ROOT/.test-performance"
readonly PERF_LOG_FILE="$PERF_LOG_DIR/performance.log"

# 색상 정의
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 성능 데이터 디렉토리 생성
mkdir -p "$PERF_LOG_DIR"

# 로그 함수들
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 성능 임계값 설정 (초)
readonly SMOKE_THRESHOLD=5.0
readonly CORE_THRESHOLD=30.0
readonly WORKFLOW_THRESHOLD=300.0
readonly PERF_THRESHOLD=60.0

# 테스트 실행 및 시간 측정
measure_test_performance() {
    local test_name="$1"
    local test_command="$2"
    local start_time end_time duration

    log_info "$test_name 테스트 성능 측정 시작..."

    start_time=$(date +%s.%N)

    if eval "$test_command" >/dev/null 2>&1; then
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc)

        # 성능 로그 기록
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$test_name,$duration,PASS" >> "$PERF_LOG_FILE"

        log_success "$test_name: ${duration}초 (통과)"
        return 0
    else
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc)

        # 실패도 기록
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$test_name,$duration,FAIL" >> "$PERF_LOG_FILE"

        log_error "$test_name: ${duration}초 (실패)"
        return 1
    fi
}

# 성능 임계값 확인
check_performance_threshold() {
    local test_name="$1"
    local duration="$2"
    local threshold

    case $test_name in
        "smoke")
            threshold=$SMOKE_THRESHOLD
            ;;
        "core")
            threshold=$CORE_THRESHOLD
            ;;
        "workflow")
            threshold=$WORKFLOW_THRESHOLD
            ;;
        "perf")
            threshold=$PERF_THRESHOLD
            ;;
        *)
            threshold=60.0  # 기본값
            ;;
    esac

    if (( $(echo "$duration > $threshold" | bc -l) )); then
        log_warning "$test_name 테스트가 임계값(${threshold}초)을 초과했습니다: ${duration}초"
        return 1
    else
        log_success "$test_name 테스트가 임계값 내에서 완료되었습니다: ${duration}초 < ${threshold}초"
        return 0
    fi
}

# 성능 트렌드 분석
analyze_performance_trend() {
    local test_name="$1"

    if [[ ! -f "$PERF_LOG_FILE" ]]; then
        log_info "성능 로그가 없어 트렌드 분석을 건너뜁니다."
        return 0
    fi

    # 최근 5회 실행 데이터 가져오기
    local recent_data
    recent_data=$(grep "$test_name" "$PERF_LOG_FILE" | tail -5 | cut -d',' -f3)

    if [[ -z "$recent_data" ]]; then
        log_info "$test_name에 대한 이전 성능 데이터가 없습니다."
        return 0
    fi

    # 평균 계산
    local count=0
    local total=0
    local max_time=0
    local min_time=999999

    while read -r time; do
        if [[ -n "$time" ]]; then
            total=$(echo "$total + $time" | bc)
            count=$((count + 1))

            if (( $(echo "$time > $max_time" | bc -l) )); then
                max_time=$time
            fi

            if (( $(echo "$time < $min_time" | bc -l) )); then
                min_time=$time
            fi
        fi
    done <<< "$recent_data"

    if [[ $count -gt 0 ]]; then
        local average=$(echo "scale=3; $total / $count" | bc)

        echo ""
        log_info "$test_name 성능 트렌드 (최근 ${count}회):"
        echo "  평균: ${average}초"
        echo "  최대: ${max_time}초"
        echo "  최소: ${min_time}초"

        # 최신 결과와 평균 비교
        local latest_time
        latest_time=$(echo "$recent_data" | tail -1)

        if [[ -n "$latest_time" ]]; then
            local variance=$(echo "$latest_time - $average" | bc)
            local variance_percent=$(echo "scale=1; ($variance / $average) * 100" | bc)

            if (( $(echo "$variance_percent > 20" | bc -l) )); then
                log_warning "성능이 평균보다 ${variance_percent}% 저하되었습니다!"
            elif (( $(echo "$variance_percent < -10" | bc -l) )); then
                log_success "성능이 평균보다 ${variance_percent#-}% 개선되었습니다!"
            else
                log_info "성능이 평균 수준입니다 (${variance_percent}% 차이)"
            fi
        fi
    fi
}

# 성능 리포트 생성
generate_performance_report() {
    echo ""
    echo "════════════════════════════════════════════"
    echo "🚀 테스트 성능 모니터링 리포트"
    echo "════════════════════════════════════════════"

    if [[ -f "$PERF_LOG_FILE" ]]; then
        echo "📊 오늘의 테스트 실행 요약:"

        local today=$(date '+%Y-%m-%d')
        local today_data
        today_data=$(grep "$today" "$PERF_LOG_FILE" 2>/dev/null || true)

        if [[ -n "$today_data" ]]; then
            echo "$today_data" | while IFS=',' read -r timestamp test_name duration status; do
                local time_only=$(echo "$timestamp" | cut -d' ' -f2)
                printf "  %s %-12s %8.3fs %s\n" "$time_only" "$test_name" "$duration" "$status"
            done
        else
            echo "  오늘 실행된 테스트가 없습니다."
        fi

        echo ""
        echo "📈 전체 통계:"
        echo "  총 실행 횟수: $(wc -l < "$PERF_LOG_FILE")"
        echo "  로그 파일 크기: $(du -h "$PERF_LOG_FILE" | cut -f1)"
        echo "  첫 기록일: $(head -1 "$PERF_LOG_FILE" | cut -d',' -f1 | cut -d' ' -f1 2>/dev/null || echo "N/A")"
    else
        echo "  성능 로그 파일이 없습니다."
    fi

    echo "════════════════════════════════════════════"
}

# 메인 실행 함수
main() {
    log_info "테스트 성능 모니터링 시작..."

    # USER 변수 확인
    if [[ -z "${USER:-}" ]]; then
        export USER=$(whoami)
    fi

    local exit_code=0
    local failed_tests=()

    # 각 테스트 카테고리 성능 측정
    local tests=(
        "smoke:nix run --impure $PROJECT_ROOT#test-smoke"
        "core:nix run --impure $PROJECT_ROOT#test-core"
    )

    # 선택적으로 더 무거운 테스트들
    if [[ "${1:-}" == "--full" ]]; then
        tests+=(
            "workflow:nix run --impure $PROJECT_ROOT#test-workflow"
            "perf:nix run --impure $PROJECT_ROOT#test-perf"
        )
    fi

    for test_spec in "${tests[@]}"; do
        local test_name="${test_spec%:*}"
        local test_command="${test_spec#*:}"

        if measure_test_performance "$test_name" "$test_command"; then
            # 최근 실행 시간 가져오기
            local latest_duration
            latest_duration=$(grep "$test_name" "$PERF_LOG_FILE" | tail -1 | cut -d',' -f3)

            if ! check_performance_threshold "$test_name" "$latest_duration"; then
                failed_tests+=("$test_name")
                exit_code=1
            fi

            analyze_performance_trend "$test_name"
        else
            failed_tests+=("$test_name")
            exit_code=1
        fi

        echo ""
    done

    # 최종 리포트
    generate_performance_report

    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        echo ""
        log_error "다음 테스트들이 성능 기준을 충족하지 못했습니다:"
        printf '  - %s\n' "${failed_tests[@]}"
    else
        echo ""
        log_success "모든 테스트가 성능 기준을 충족했습니다! 🎉"
    fi

    return $exit_code
}

# bc 명령어 확인
if ! command -v bc &> /dev/null; then
    log_error "bc 명령어가 필요합니다. 설치 후 다시 시도하세요."
    exit 1
fi

# 스크립트 실행
main "$@"
