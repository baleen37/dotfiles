#!/usr/bin/env bash
# ABOUTME: 테스트 설정 파일 - 하드코딩된 값들을 중앙화

# Git commands 파일 목록
readonly EXPECTED_GIT_COMMANDS=(
    "commit.md"
    "fix-pr.md"
    "upsert-pr.md"
)

# Claude 설정 파일 목록
readonly EXPECTED_CONFIG_FILES=(
    "CLAUDE.md"
    "settings.json"
    "MCP.md"
    "SUBAGENT.md"
    "FLAGS.md"
    "ORCHESTRATOR.md"
)

# 테스트 환경 설정
readonly TEST_TIMEOUT=300
readonly TEST_DIR_PREFIX="claude_test"

# 해시 검증에 사용할 도구 우선순위
readonly HASH_TOOLS=("shasum" "sha256sum" "md5sum")

# 플랫폼별 설정
if [[ "$OSTYPE" == "darwin"* ]]; then
    readonly PLATFORM="darwin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    readonly PLATFORM="linux"
else
    readonly PLATFORM="unknown"
fi

# 설정 로드 완료 메시지
if [[ "${DEBUG:-false}" == "true" ]]; then
    echo "[DEBUG] 테스트 설정 로드 완료" >&2
fi
