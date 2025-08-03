#!/usr/bin/env bash
# ABOUTME: 병렬 테스트 실행으로 최대 성능 달성하는 빠른 검증 스크립트
# ABOUTME: smoke, core 테스트를 동시 실행하여 총 시간을 최소화

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 색상 정의
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 시간 측정 시작
start_time=$(date +%s)

echo -e "${BLUE}🚀 빠른 병렬 테스트 실행 시작${NC}"
echo "=================================="

# 병렬 실행을 위한 임시 파일
smoke_result=$(mktemp)
core_result=$(mktemp)

# 정리 함수
cleanup() {
    rm -f "$smoke_result" "$core_result"
}
trap cleanup EXIT

echo -e "${YELLOW}⚡ 병렬 테스트 실행 중...${NC}"

# Smoke 테스트 (백그라운드)
{
    echo -e "  ${BLUE}▶${NC} Smoke 테스트 실행 중..."
    if nix run --impure "$PROJECT_ROOT"#test-smoke >/dev/null 2>&1; then
        echo "PASS" > "$smoke_result"
    else
        echo "FAIL" > "$smoke_result"
    fi
} &
smoke_pid=$!

# Core 테스트 (백그라운드)
{
    echo -e "  ${BLUE}▶${NC} Core 테스트 실행 중..."
    if nix run --impure "$PROJECT_ROOT"#test-core >/dev/null 2>&1; then
        echo "PASS" > "$core_result"
    else
        echo "FAIL" > "$core_result"
    fi
} &
core_pid=$!

# 두 테스트 완료 대기
wait $smoke_pid $core_pid

# 결과 확인
smoke_status=$(cat "$smoke_result")
core_status=$(cat "$core_result")

echo
echo "=================================="
echo -e "${BLUE}📊 테스트 결과${NC}"
echo "=================================="

if [[ "$smoke_status" == "PASS" ]]; then
    echo -e "  ${GREEN}✅ Smoke 테스트: PASSED${NC}"
else
    echo -e "  ${RED}❌ Smoke 테스트: FAILED${NC}"
fi

if [[ "$core_status" == "PASS" ]]; then
    echo -e "  ${GREEN}✅ Core 테스트: PASSED${NC}"
else
    echo -e "  ${RED}❌ Core 테스트: FAILED${NC}"
fi

# 총 시간 계산
end_time=$(date +%s)
duration=$((end_time - start_time))

echo
echo "=================================="
if [[ "$smoke_status" == "PASS" && "$core_status" == "PASS" ]]; then
    echo -e "${GREEN}🎉 모든 테스트 통과! (${duration}초)${NC}"
    echo -e "${GREEN}✨ 코드가 배포 준비 완료되었습니다${NC}"
    exit 0
else
    echo -e "${RED}💥 일부 테스트 실패 (${duration}초)${NC}"
    echo -e "${YELLOW}🔧 개별 테스트를 실행하여 자세한 정보를 확인하세요:${NC}"
    [[ "$smoke_status" == "FAIL" ]] && echo -e "  ${YELLOW}make smoke${NC}"
    [[ "$core_status" == "FAIL" ]] && echo -e "  ${YELLOW}make test-core${NC}"
    exit 1
fi
