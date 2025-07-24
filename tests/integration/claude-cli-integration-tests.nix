# Claude CLI Integration Tests - Improved Version
# 여러 컴포넌트가 함께 작동하는 시나리오를 테스트

{ pkgs }:

let
  testLib = import ../lib/claude-cli-test-lib.nix { inherit pkgs; };
in

{
  # Integration Test 1: 완전한 워크플로우 테스트
  completeWorkflowTest = testLib.isolatedTest "complete-workflow" ''
    echo "Testing complete Claude CLI workflow..."

    # 테스트 프로젝트 설정
    ${testLib.createTestRepo "complete-workflow"}

    # 시나리오: 새 기능 개발 워크플로우
    feature_branch="feature/user-authentication"

    # 1. 새 기능 브랜치 워크트리 생성
    echo "Step 1: Creating feature branch worktree..."
    ccw_result=$(ccw "$feature_branch" 2>&1)
    assert_contains "$ccw_result" "Creating new git worktree" "Feature branch worktree created"
    assert_git_branch "$feature_branch" "Switched to feature branch"

    # 2. 개발 작업 시뮬레이션
    echo "Step 2: Simulating development work..."
    mkdir -p src/auth
    echo "export const authenticate = () => {}" > src/auth/auth.js
    echo "# Authentication Feature" > FEATURE.md
    echo "Implementation details..." >> FEATURE.md

    git add .
    git commit -m "Add authentication feature"

    # 3. 메인 브랜치로 돌아가기
    echo "Step 3: Returning to main branch..."
    cd "$test_repo"
    assert_git_branch "main" "Back on main branch"

    # 4. 다른 기능 브랜치 작업
    other_branch="feature/ui-improvements"
    ccw_other_result=$(ccw "$other_branch" 2>&1)
    assert_contains "$ccw_other_result" "Creating new git worktree" "Second feature branch created"
    assert_git_branch "$other_branch" "Switched to second feature branch"

    # 5. 첫 번째 브랜치로 다시 전환 (기존 워크트리 재사용)
    echo "Step 5: Switching back to first feature branch..."
    ccw_switch_result=$(ccw "$feature_branch" 2>&1)
    assert_contains "$ccw_switch_result" "Switching to existing worktree" "Switched to existing worktree"
    assert_git_branch "$feature_branch" "Back on first feature branch"

    # 6. 이전 작업이 보존되었는지 확인
    assert_success "test -f src/auth/auth.js" "Previous development work preserved"
    assert_success "test -f FEATURE.md" "Feature documentation preserved"

    # 정리
    cd "$test_repo"
    git worktree remove "../$feature_branch" 2>/dev/null || true
    git worktree remove "../$other_branch" 2>/dev/null || true
    rm -rf "../$feature_branch" "../$other_branch" 2>/dev/null || true
    git branch -D "$feature_branch" "$other_branch" 2>/dev/null || true
  '';

  # Integration Test 2: 멀티 워크트리 동시 관리
  multiWorktreeTest = testLib.isolatedTest "multi-worktree" ''
    echo "Testing multiple worktree management..."

    # 테스트 프로젝트 설정
    ${testLib.createTestRepo "multi-worktree"}

    # 여러 브랜치 생성
    branches=("frontend" "backend" "documentation" "testing")

    # 각 브랜치에 대해 워크트리 생성
    for branch in "''${branches[@]}"; do
      echo "Creating worktree for: $branch"
      ccw_result=$(ccw "$branch" 2>&1)
      assert_contains "$ccw_result" "Creating new git worktree" "Worktree created for $branch"

      # 각 워크트리에서 브랜치별 작업 시뮬레이션
      case "$branch" in
        "frontend")
          mkdir -p src/components
          echo "React component" > src/components/App.js
          ;;
        "backend")
          mkdir -p server
          echo "Express server" > server/app.js
          ;;
        "documentation")
          echo "# Project Documentation" > README.md
          ;;
        "testing")
          mkdir -p tests
          echo "test('should work', () => {})" > tests/app.test.js
          ;;
      esac

      git add .
      git commit -m "Add $branch components"

      # 메인 디렉토리로 돌아가기
      cd "$test_repo"
    done

    # 모든 워크트리가 생성되었는지 확인
    for branch in "''${branches[@]}"; do
      assert_directory_exists "../$branch" "Worktree directory exists for $branch"
    done

    # Git worktree list 명령어로 확인
    worktree_list=$(git worktree list)
    for branch in "''${branches[@]}"; do
      assert_contains "$worktree_list" "$branch" "Branch $branch appears in worktree list"
    done

    # 각 워크트리에서 독립적인 작업 확인
    for branch in "''${branches[@]}"; do
      cd "../$branch"
      current_branch=$(git branch --show-current)
      assert_git_branch "$branch" "Correct branch in $branch worktree"
      cd "$test_repo"
    done

    # 정리
    for branch in "''${branches[@]}"; do
      git worktree remove "../$branch" 2>/dev/null || true
      rm -rf "../$branch" 2>/dev/null || true
      git branch -D "$branch" 2>/dev/null || true
    done
  '';

  # Integration Test 3: 실제 Git 상황 시뮬레이션
  realGitScenarioTest = testLib.isolatedTest "real-git-scenario" ''
    echo "Testing real-world Git scenarios..."

    # 복잡한 Git 히스토리를 가진 프로젝트 시뮬레이션
    ${testLib.createTestRepo "real-git-scenario"}

    # 메인 브랜치에 여러 커밋 생성
    for i in {1..3}; do
      echo "Feature $i implementation" > "feature$i.txt"
      git add "feature$i.txt"
      git commit -m "Add feature $i"
    done

    # 개발 브랜치 생성
    git checkout -b development
    echo "Development changes" > dev.txt
    git add dev.txt
    git commit -m "Development work"
    git checkout main

    # 릴리스 브랜치 생성
    git checkout -b release/v1.0
    echo "v1.0.0" > VERSION
    git add VERSION
    git commit -m "Prepare v1.0 release"
    git checkout main

    # CCW로 개발 브랜치 워크트리 생성
    ccw_dev_result=$(ccw "development" 2>&1)
    assert_contains "$ccw_dev_result" "Creating new git worktree" "Development worktree created"
    assert_success "test -f dev.txt" "Development files accessible in worktree"

    # 메인으로 돌아가서 릴리스 브랜치 워크트리 생성
    cd "$test_repo"
    ccw_release_result=$(ccw "release/v1.0" 2>&1)
    assert_contains "$ccw_release_result" "Creating new git worktree" "Release worktree created"
    assert_success "test -f VERSION" "Release files accessible in worktree"

    # 새 기능 브랜치 생성
    cd "$test_repo"
    ccw_feature_result=$(ccw "feature/new-api" 2>&1)
    assert_contains "$ccw_feature_result" "Creating new git worktree" "New feature worktree created"

    # 기능 개발 시뮬레이션
    mkdir -p api
    echo "New API endpoints" > api/endpoints.js
    git add api/
    git commit -m "Add new API endpoints"

    # 각 워크트리가 독립적으로 작동하는지 확인
    cd "../development"
    assert_git_branch "development" "Development worktree has correct branch"
    assert_success "test -f dev.txt" "Development files exist"
    assert_failure "test -f api/endpoints.js" "Feature files not in development worktree"

    cd "../release/v1.0"
    assert_git_branch "release/v1.0" "Release worktree has correct branch"
    assert_success "test -f VERSION" "Release files exist"
    assert_failure "test -f api/endpoints.js" "Feature files not in release worktree"

    cd "../feature/new-api"
    assert_git_branch "feature/new-api" "Feature worktree has correct branch"
    assert_success "test -f api/endpoints.js" "Feature files exist"

    # 정리
    cd "$test_repo"
    for branch in "development" "release/v1.0" "feature/new-api"; do
      git worktree remove "../$branch" 2>/dev/null || true
      rm -rf "../$branch" 2>/dev/null || true
    done
    git branch -D "development" "release/v1.0" "feature/new-api" 2>/dev/null || true
  '';

  # Integration Test 4: 시스템 통합 테스트
  systemIntegrationTest = testLib.isolatedTest "system-integration" ''
    echo "Testing system-level integration..."

    # 실제 dotfiles 환경에서 테스트 (현재 디렉토리가 git repo인 경우)
    if [[ -d ".git" ]]; then
      echo "Testing in actual dotfiles repository..."

      # 임시 테스트 브랜치 사용
      test_branch="integration-test-$(date +%s)"

      # CCW로 임시 브랜치 생성
      ccw_result=$(ccw "$test_branch" 2>&1)
      assert_contains "$ccw_result" "Creating new git worktree" "Test worktree created in real repo"

      # 현재 디렉토리 확인
      assert_contains "$(pwd)" "$test_branch" "Current directory is test worktree"

      # Git 상태 확인
      git_status=$(git status --porcelain)
      echo "Git status in test worktree: $git_status"

      # 테스트 파일 생성
      echo "Integration test $(date)" > INTEGRATION_TEST.tmp
      git add INTEGRATION_TEST.tmp
      git commit -m "Integration test commit"

      # 커밋이 올바른 브랜치에 있는지 확인
      commit_branch=$(git branch --contains HEAD | grep '^\*' | cut -d' ' -f2)
      assert_git_branch "$test_branch" "Commit is on correct branch"

      # 원래 디렉토리로 돌아가기
      cd "$(git rev-parse --show-toplevel)"

      # 메인 브랜치에는 테스트 파일이 없는지 확인
      assert_failure "test -f INTEGRATION_TEST.tmp" "Test file not in main branch"

      # 정리
      git worktree remove "../$test_branch" 2>/dev/null || true
      rm -rf "../$test_branch" 2>/dev/null || true
      git branch -D "$test_branch" 2>/dev/null || true

      echo "✅ System integration test completed successfully"
    else
      echo "⚠️  SKIP: Not in git repository, skipping system integration test"
    fi
  '';
}
