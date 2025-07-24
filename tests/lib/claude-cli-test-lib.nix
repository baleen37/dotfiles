# Claude CLI Test Library
# 테스트에 필요한 공통 유틸리티와 헬퍼 함수들

{ pkgs }:

rec {
  # 테스트용 Claude CLI 함수 정의 (실제 구현과 동일)
  claudeCliDefinitions = ''
    # Claude CLI shortcuts
    # Note: 'cc' alias may conflict with system C compiler. Use '\cc' to access system cc if needed.
    alias cc="claude --dangerously-skip-permissions"

    # Claude CLI with Git Worktree workflow
    ccw() {
      local branch_name="$1"

      if [[ -z "$branch_name" ]]; then
        echo "Usage: ccw <branch-name>"
        echo "Creates/switches to git worktree at ../<branch-name> and starts Claude"
        return 1
      fi

      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
      fi

      local worktree_path="../$branch_name"

      if [[ -d "$worktree_path" ]]; then
        echo "Switching to existing worktree: $worktree_path"
        cd "$worktree_path" || return 1
      else
        echo "Creating new git worktree for branch '$branch_name'..."

        if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
          git worktree add "$worktree_path" "origin/$branch_name"
        else
          git worktree add -b "$branch_name" "$worktree_path"
        fi

        cd "$worktree_path" || return 1
      fi

      echo "Worktree: $(pwd) | Branch: $(git branch --show-current)"
      echo "TEST_MODE: Would start Claude CLI here"
      return 0
    }
  '';

  # 테스트용 Git repository 생성 헬퍼
  createTestRepo = repoName: ''
    test_repo=$(mktemp -d -t "${repoName}-XXXXXX")
    original_dir=$(pwd)

    cd "$test_repo"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"

    # 초기 파일 및 커밋 생성
    echo "# Test Repository: ${repoName}" > README.md
    echo "Created: $(date)" >> README.md
    git add README.md
    git commit --quiet -m "Initial commit"

    # main 브랜치 설정
    git branch -M main

    echo "Test repo created at: $test_repo"
  '';

  # 테스트 환경 정리 헬퍼
  cleanupTestRepo = ''
    if [[ -n "$test_repo" && -d "$test_repo" ]]; then
      cd "$original_dir" 2>/dev/null || true
      rm -rf "$test_repo" 2>/dev/null || true
      echo "Test repo cleaned up"
    fi
  '';

  # 어설션 헬퍼 함수들
  assertHelpers = ''
    # 성공 어설션
    assert_success() {
      local command="$1"
      local description="$2"

      if eval "$command" >/dev/null 2>&1; then
        echo "✅ PASS: $description"
        return 0
      else
        echo "❌ FAIL: $description"
        echo "   Command: $command"
        return 1
      fi
    }

    # 실패 어설션
    assert_failure() {
      local command="$1"
      local description="$2"

      if ! eval "$command" >/dev/null 2>&1; then
        echo "✅ PASS: $description"
        return 0
      else
        echo "❌ FAIL: $description (expected failure but succeeded)"
        echo "   Command: $command"
        return 1
      fi
    }

    # 문자열 포함 어설션
    assert_contains() {
      local output="$1"
      local expected="$2"
      local description="$3"

      if [[ "$output" == *"$expected"* ]]; then
        echo "✅ PASS: $description"
        return 0
      else
        echo "❌ FAIL: $description"
        echo "   Expected: '$expected'"
        echo "   Got: '$output'"
        return 1
      fi
    }

    # 디렉토리 존재 어설션
    assert_directory_exists() {
      local dir="$1"
      local description="$2"

      if [[ -d "$dir" ]]; then
        echo "✅ PASS: $description"
        return 0
      else
        echo "❌ FAIL: $description"
        echo "   Directory: $dir"
        return 1
      fi
    }

    # Git 브랜치 어설션
    assert_git_branch() {
      local expected_branch="$1"
      local description="$2"

      local current_branch=$(git branch --show-current 2>/dev/null)
      if [[ "$current_branch" == "$expected_branch" ]]; then
        echo "✅ PASS: $description"
        return 0
      else
        echo "❌ FAIL: $description"
        echo "   Expected branch: $expected_branch"
        echo "   Current branch: $current_branch"
        return 1
      fi
    }
  '';

  # 테스트 실행 컨텍스트 설정
  testContext = testName: ''
    echo "=========================================="
    echo "Test: ${testName}"
    echo "Time: $(date)"
    echo "PWD: $(pwd)"
    echo "=========================================="

    # 에러 발생 시 즉시 종료
    set -e

    # 테스트 환경 초기화
    ${claudeCliDefinitions}
    ${assertHelpers}

    # 트랩 설정 (정리 함수)
    trap 'echo "Test cleanup triggered"; ${cleanupTestRepo}' EXIT
  '';

  # 테스트 결과 리포팅
  testResults = ''
    echo ""
    echo "=========================================="
    echo "Test Results Summary"
    echo "=========================================="
    echo "✅ All assertions passed"
    echo "Test completed successfully at: $(date)"
  '';

  # 특정 명령어 테스트를 위한 격리된 환경
  isolatedTest = testName: testScript: pkgs.writeShellScript "isolated-${testName}" ''
    ${testContext testName}

    ${testScript}

    ${testResults}
  '';

  # 워크트리 테스트용 특수 환경
  worktreeTestEnv = ''
    # 워크트리 전용 테스트 헬퍼
    create_test_worktree() {
      local branch_name="$1"
      local worktree_path="../$branch_name"

      # 기존 워크트리 정리
      git worktree remove "$worktree_path" 2>/dev/null || true
      rm -rf "$worktree_path" 2>/dev/null || true

      # 새 워크트리 생성
      git worktree add -b "$branch_name" "$worktree_path"
      echo "Test worktree created: $worktree_path"
    }

    cleanup_test_worktree() {
      local branch_name="$1"
      local worktree_path="../$branch_name"

      cd "$original_dir" 2>/dev/null || true
      git worktree remove "$worktree_path" 2>/dev/null || true
      rm -rf "$worktree_path" 2>/dev/null || true
      git branch -D "$branch_name" 2>/dev/null || true
    }
  '';
}
