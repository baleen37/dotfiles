# Claude CLI Unit Tests - Improved Version
# 모듈화되고 격리된 환경에서 실행되는 포괄적인 단위 테스트

{ pkgs }:

let
  testLib = import ../lib/claude-cli-test-lib.nix { inherit pkgs; };
in

{
  # Test 1: CC Alias 기본 기능 테스트
  ccAliasTest = testLib.isolatedTest "cc-alias" ''
    echo "Testing CC alias functionality..."

    # CC alias 존재 확인
    assert_success "alias cc" "CC alias is defined"

    # CC alias 내용 확인
    cc_definition=$(alias cc 2>/dev/null)
    assert_contains "$cc_definition" "claude --dangerously-skip-permissions" "CC alias points to correct command"

    # Type 명령어로도 확인
    cc_type=$(type cc 2>/dev/null || echo "not found")
    assert_contains "$cc_type" "claude --dangerously-skip-permissions" "CC type shows correct command"
  '';

  # Test 2: CCW 함수 기본 기능 테스트
  ccwFunctionTest = testLib.isolatedTest "ccw-function" ''
    echo "Testing CCW function basic functionality..."

    # CCW 함수 존재 확인
    assert_success "declare -f ccw" "CCW function is defined"

    # 매개변수 없이 호출 시 사용법 출력 확인
    ccw_help=$(ccw 2>&1 || true)
    assert_contains "$ccw_help" "Usage: ccw <branch-name>" "CCW shows usage message without parameters"
    assert_contains "$ccw_help" "Creates/switches to git worktree" "CCW shows detailed help message"
  '';

  # Test 3: CCW Git Repository 검증 테스트
  ccwGitValidationTest = testLib.isolatedTest "ccw-git-validation" ''
    echo "Testing CCW git repository validation..."

    # 임시 디렉토리 생성 (git repo가 아닌)
    non_git_dir=$(mktemp -d -t "non-git-XXXXXX")
    cd "$non_git_dir"

    # Git repository가 아닌 곳에서 CCW 실행
    ccw_error=$(ccw test-branch 2>&1 || true)
    assert_contains "$ccw_error" "Not in a git repository" "CCW validates git repository correctly"

    # 정리
    cd "$original_dir"
    rm -rf "$non_git_dir"
  '';

  # Test 4: CCW 브랜치명 검증 테스트
  ccwBranchValidationTest = testLib.isolatedTest "ccw-branch-validation" ''
    echo "Testing CCW branch name validation..."

    # 테스트 git repository 생성
    ${testLib.createTestRepo "branch-validation"}

    # 빈 브랜치명 테스트
    empty_result=$(ccw "" 2>&1 || true)
    assert_contains "$empty_result" "Usage: ccw <branch-name>" "CCW rejects empty branch name"

    # 공백만 있는 브랜치명 테스트
    space_result=$(ccw "   " 2>&1 || true)
    assert_contains "$space_result" "Usage: ccw <branch-name>" "CCW rejects whitespace-only branch name"
  '';

  # Test 5: CCW 워크트리 생성 테스트
  ccwWorktreeCreationTest = testLib.isolatedTest "ccw-worktree-creation" ''
    echo "Testing CCW worktree creation..."

    # 테스트 git repository 생성
    ${testLib.createTestRepo "worktree-creation"}
    ${testLib.worktreeTestEnv}

    test_branch="test-feature-$(date +%s)"

    # CCW로 새 워크트리 생성
    ccw_result=$(ccw "$test_branch" 2>&1)
    assert_contains "$ccw_result" "Creating new git worktree" "CCW creates new worktree"
    assert_contains "$ccw_result" "TEST_MODE: Would start Claude CLI" "CCW would start Claude CLI"

    # 워크트리 디렉토리 존재 확인
    worktree_path="../$test_branch"
    assert_directory_exists "$worktree_path" "Worktree directory was created"

    # 현재 디렉토리가 워크트리인지 확인
    assert_contains "$(pwd)" "$test_branch" "Current directory is worktree"

    # 브랜치 확인
    assert_git_branch "$test_branch" "Current branch is correct"

    # 정리
    cleanup_test_worktree "$test_branch"
  '';

  # Test 6: CCW 기존 워크트리 재사용 테스트
  ccwWorktreeReuseTest = testLib.isolatedTest "ccw-worktree-reuse" ''
    echo "Testing CCW existing worktree reuse..."

    # 테스트 git repository 생성
    ${testLib.createTestRepo "worktree-reuse"}
    ${testLib.worktreeTestEnv}

    test_branch="reuse-test-$(date +%s)"

    # 첫 번째 CCW 실행으로 워크트리 생성
    ccw "$test_branch" >/dev/null

    # 워크트리에 테스트 파일 생성
    echo "test content" > test-file.txt
    git add test-file.txt
    git commit -m "Add test file"

    # 원래 디렉토리로 돌아가기
    cd "$test_repo"

    # 두 번째 CCW 실행으로 기존 워크트리 재사용
    ccw_reuse_result=$(ccw "$test_branch" 2>&1)
    assert_contains "$ccw_reuse_result" "Switching to existing worktree" "CCW switches to existing worktree"

    # 기존 파일이 여전히 존재하는지 확인
    assert_success "test -f test-file.txt" "Previous work is preserved in reused worktree"

    # 정리
    cleanup_test_worktree "$test_branch"
  '';

  # Test 7: CCW 원격 브랜치 체크아웃 시뮬레이션
  ccwRemoteBranchTest = testLib.isolatedTest "ccw-remote-branch" ''
    echo "Testing CCW remote branch checkout simulation..."

    # 테스트 git repository 생성
    ${testLib.createTestRepo "remote-branch"}

    # 가짜 원격 브랜치 시뮬레이션 (실제로는 로컬 브랜치를 원격으로 가정)
    git checkout -b remote-feature
    echo "remote content" > remote-file.txt
    git add remote-file.txt
    git commit -m "Add remote content"
    git checkout main

    # 원격 브랜치로 가정하기 위해 refs 조작
    git branch -D remote-feature
    git branch remote-feature HEAD~1

    test_branch="remote-feature"

    # 기존 워크트리가 있다면 정리
    git worktree remove "../$test_branch" 2>/dev/null || true
    rm -rf "../$test_branch" 2>/dev/null || true

    # CCW로 "원격" 브랜치 체크아웃 (실제로는 로컬 브랜치)
    ccw_result=$(ccw "$test_branch" 2>&1)

    # 워크트리가 생성되었는지 확인
    worktree_path="../$test_branch"
    assert_directory_exists "$worktree_path" "Remote branch worktree was created"

    # 정리
    cd "$test_repo"
    git worktree remove "../$test_branch" 2>/dev/null || true
    rm -rf "../$test_branch" 2>/dev/null || true
    git branch -D "$test_branch" 2>/dev/null || true
  '';

  # Test 8: 에러 처리 및 엣지 케이스 테스트
  ccwErrorHandlingTest = testLib.isolatedTest "ccw-error-handling" ''
    echo "Testing CCW error handling and edge cases..."

    # 테스트 git repository 생성
    ${testLib.createTestRepo "error-handling"}

    # 권한이 없는 디렉토리 시뮬레이션 (부모 디렉토리가 읽기 전용)
    # 실제 권한 변경은 테스트 환경에서 위험하므로 스킵

    # 매우 긴 브랜치명 테스트
    long_branch_name=$(printf 'a%.0s' {1..100})
    ccw_long_result=$(ccw "$long_branch_name" 2>&1)
    # Git에서는 긴 브랜치명도 허용하므로, 생성이 성공해야 함
    assert_contains "$ccw_long_result" "Creating new git worktree" "CCW handles long branch names"

    # 정리
    git worktree remove "../$long_branch_name" 2>/dev/null || true
    rm -rf "../$long_branch_name" 2>/dev/null || true
    git branch -D "$long_branch_name" 2>/dev/null || true

    # 특수 문자가 포함된 브랜치명 테스트
    special_branch="feature-with-dashes-and_underscores"
    ccw_special_result=$(ccw "$special_branch" 2>&1)
    assert_contains "$ccw_special_result" "Creating new git worktree" "CCW handles special characters in branch names"

    # 정리
    cd "$test_repo"
    git worktree remove "../$special_branch" 2>/dev/null || true
    rm -rf "../$special_branch" 2>/dev/null || true
    git branch -D "$special_branch" 2>/dev/null || true
  '';
}
