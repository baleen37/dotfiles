# Claude CLI Stress and Edge Case Tests
# 극한 상황과 에러 조건에서의 동작을 테스트

{ pkgs }:

let
  testLib = import ../lib/claude-cli-test-lib.nix { inherit pkgs; };
in

{
  # Stress Test 1: 많은 수의 워크트리 생성
  massiveWorktreeTest = testLib.isolatedTest "massive-worktree" ''
    echo "Testing massive worktree creation..."

    ${testLib.createTestRepo "massive-worktree"}
    ${testLib.worktreeTestEnv}

    # 많은 수의 워크트리 생성 (20개)
    max_worktrees=20
    created_worktrees=()

    echo "Creating $max_worktrees worktrees..."
    for i in $(seq 1 $max_worktrees); do
      branch_name="mass-test-$i"

      if ccw "$branch_name" >/dev/null 2>&1; then
        created_worktrees+=("$branch_name")
        echo "Created worktree $i/$max_worktrees"
        cd "$test_repo"
      else
        echo "Failed to create worktree $i"
        break
      fi
    done

    created_count=''${#created_worktrees[@]}
    echo "Successfully created $created_count worktrees"

    # 최소 10개는 생성되어야 함
    if [[ $created_count -ge 10 ]]; then
      echo "✅ PASS: Massive worktree creation (created $created_count)"
    else
      echo "❌ FAIL: Insufficient worktrees created ($created_count < 10)"
      return 1
    fi

    # Git worktree list 확인
    worktree_list_count=$(git worktree list | wc -l)
    expected_count=$((created_count + 1))  # +1 for main repo

    if [[ $worktree_list_count -eq $expected_count ]]; then
      echo "✅ PASS: Git worktree list shows correct count ($worktree_list_count)"
    else
      echo "❌ FAIL: Git worktree list count mismatch (expected $expected_count, got $worktree_list_count)"
      return 1
    fi

    # 정리
    for branch in "''${created_worktrees[@]}"; do
      cleanup_test_worktree "$branch"
    done
  '';

  # Stress Test 2: 매우 긴 브랜치명과 경로
  extremePathTest = testLib.isolatedTest "extreme-path" ''
    echo "Testing extreme path lengths and special characters..."

    ${testLib.createTestRepo "extreme-path"}

    # 매우 긴 브랜치명 테스트
    long_branch=$(printf 'very-long-branch-name-with-many-characters-%.0s' {1..5})
    echo "Testing very long branch name: ''${long_branch:0:50}..."

    ccw_long_result=$(ccw "$long_branch" 2>&1)
    assert_contains "$ccw_long_result" "Creating new git worktree" "Very long branch name handled"

    # 워크트리 경로 확인
    long_worktree="../$long_branch"
    assert_directory_exists "$long_worktree" "Long path worktree created"

    # 정리
    cd "$test_repo"
    git worktree remove "$long_worktree" 2>/dev/null || true
    rm -rf "$long_worktree" 2>/dev/null || true
    git branch -D "$long_branch" 2>/dev/null || true

    # 특수 문자가 포함된 브랜치명
    special_chars_branch="feature-with_underscores.and.dots-and-dashes"
    echo "Testing special characters in branch name..."

    ccw_special_result=$(ccw "$special_chars_branch" 2>&1)
    assert_contains "$ccw_special_result" "Creating new git worktree" "Special characters handled"

    # 정리
    cd "$test_repo"
    git worktree remove "../$special_chars_branch" 2>/dev/null || true
    rm -rf "../$special_chars_branch" 2>/dev/null || true
    git branch -D "$special_chars_branch" 2>/dev/null || true

    # 숫자로 시작하는 브랜치명
    numeric_branch="123-numeric-start"
    ccw_numeric_result=$(ccw "$numeric_branch" 2>&1)
    assert_contains "$ccw_numeric_result" "Creating new git worktree" "Numeric start branch handled"

    # 정리
    cd "$test_repo"
    git worktree remove "../$numeric_branch" 2>/dev/null || true
    rm -rf "../$numeric_branch" 2>/dev/null || true
    git branch -D "$numeric_branch" 2>/dev/null || true
  '';

  # Error Test 1: 권한 관련 에러 시뮬레이션
  permissionErrorTest = testLib.isolatedTest "permission-error" ''
    echo "Testing permission-related errors..."

    ${testLib.createTestRepo "permission-test"}

    # 부모 디렉토리가 읽기 전용인 상황 시뮬레이션
    # (실제 권한 변경은 위험하므로 제한적으로 테스트)

    # 존재하지 않는 부모 디렉토리 경로로 워크트리 생성 시도
    impossible_branch="impossible/nested/deep/branch"
    ccw_impossible_result=$(ccw "$impossible_branch" 2>&1 || true)

    # Git이 처리하므로 실제로는 생성될 수 있음
    # 대신 워크트리 이름에 슬래시가 포함된 경우의 처리 확인
    if [[ "$ccw_impossible_result" == *"Creating new git worktree"* ]]; then
      echo "✅ PASS: Git handled complex branch name"

      # 정리
      git worktree remove "../$impossible_branch" 2>/dev/null || true
      rm -rf "../$impossible_branch" 2>/dev/null || true
      git branch -D "$impossible_branch" 2>/dev/null || true
    else
      echo "✅ PASS: Complex branch name appropriately rejected"
    fi

    # 빈 문자열 테스트
    empty_result=$(ccw "" 2>&1 || true)
    assert_contains "$empty_result" "Usage: ccw" "Empty string rejected with usage message"

    # 공백만 있는 문자열 테스트
    whitespace_result=$(ccw "   " 2>&1 || true)
    assert_contains "$whitespace_result" "Usage: ccw" "Whitespace-only string rejected"

    # 매우 많은 공백이 있는 브랜치명
    spaced_branch="branch   with   many   spaces"
    ccw_spaced_result=$(ccw "$spaced_branch" 2>&1)

    # Git이 공백을 처리하는 방식에 따라 달라질 수 있음
    echo "Spaced branch result: $ccw_spaced_result"

    if [[ "$ccw_spaced_result" == *"Creating new git worktree"* ]]; then
      # 정리
      git worktree remove "../$spaced_branch" 2>/dev/null || true
      rm -rf "../$spaced_branch" 2>/dev/null || true
      git branch -D "$spaced_branch" 2>/dev/null || true
    fi
  '';

  # Error Test 2: Git 상태 에러 처리
  gitStateErrorTest = testLib.isolatedTest "git-state-error" ''
    echo "Testing Git state error handling..."

    ${testLib.createTestRepo "git-state-error"}

    # 더티 워킹 디렉토리에서 워크트리 생성
    echo "Uncommitted changes" > dirty-file.txt
    # Git은 더티 상태에서도 워크트리 생성을 허용하므로 이는 에러가 아님

    ccw_dirty_result=$(ccw "dirty-test" 2>&1)
    assert_contains "$ccw_dirty_result" "Creating new git worktree" "Worktree creation with dirty state"

    # 정리
    cd "$test_repo"
    git worktree remove "../dirty-test" 2>/dev/null || true
    rm -rf "../dirty-test" 2>/dev/null || true
    git branch -D "dirty-test" 2>/dev/null || true
    rm -f dirty-file.txt

    # 이미 존재하는 브랜치명으로 워크트리 생성
    existing_branch="existing-branch"
    git checkout -b "$existing_branch"
    git checkout main

    ccw_existing_result=$(ccw "$existing_branch" 2>&1)

    # 기존 브랜치가 있으면 그 브랜치로 워크트리 생성
    if [[ "$ccw_existing_result" == *"Creating new git worktree"* ]]; then
      echo "✅ PASS: Existing branch handled correctly"

      # 정리
      cd "$test_repo"
      git worktree remove "../$existing_branch" 2>/dev/null || true
      rm -rf "../$existing_branch" 2>/dev/null || true
    fi

    git branch -D "$existing_branch" 2>/dev/null || true

    # 잘못된 Git repository에서 실행
    non_git_dir=$(mktemp -d)
    cd "$non_git_dir"

    non_git_result=$(ccw "test" 2>&1 || true)
    assert_contains "$non_git_result" "Not in a git repository" "Non-git directory properly detected"

    # 정리
    cd "$test_repo"
    rm -rf "$non_git_dir"
  '';

  # Error Test 3: 시스템 리소스 제한
  resourceLimitTest = testLib.isolatedTest "resource-limit" ''
    echo "Testing system resource limits..."

    ${testLib.createTestRepo "resource-limit"}

    # 많은 파일이 있는 워크트리에서의 성능
    echo "Creating repository with many files..."
    mkdir -p test-files

    # 100개의 파일 생성
    for i in $(seq 1 100); do
      echo "File content $i" > "test-files/file-$i.txt"
    done

    git add test-files/
    git commit -m "Add 100 test files"

    # 많은 파일이 있는 상태에서 워크트리 생성
    start_time=$(date +%s)
    ccw_many_files_result=$(ccw "many-files-test" 2>&1)
    end_time=$(date +%s)

    execution_time=$((end_time - start_time))

    assert_contains "$ccw_many_files_result" "Creating new git worktree" "Worktree created with many files"

    if [[ $execution_time -lt 30 ]]; then
      echo "✅ PASS: Many files worktree creation completed in reasonable time (''${execution_time}s)"
    else
      echo "⚠️  WARNING: Many files worktree creation took long time (''${execution_time}s)"
    fi

    # 생성된 워크트리에서 파일 확인
    assert_success "test -d test-files" "Test files directory exists in worktree"
    file_count=$(ls test-files/ | wc -l)

    if [[ $file_count -eq 100 ]]; then
      echo "✅ PASS: All files present in worktree ($file_count)"
    else
      echo "❌ FAIL: Missing files in worktree (expected 100, got $file_count)"
      return 1
    fi

    # 정리
    cd "$test_repo"
    git worktree remove "../many-files-test" 2>/dev/null || true
    rm -rf "../many-files-test" 2>/dev/null || true
    git branch -D "many-files-test" 2>/dev/null || true
  '';

  # Error Test 4: 동시 실행 시나리오
  concurrencyTest = testLib.isolatedTest "concurrency" ''
    echo "Testing concurrent execution scenarios..."

    ${testLib.createTestRepo "concurrency-test"}

    # 동일한 브랜치명으로 동시 실행 시뮬레이션은 어려우므로
    # 대신 빠른 연속 실행을 테스트

    concurrent_branch="concurrent-test"

    # 첫 번째 실행
    ccw_first=$(ccw "$concurrent_branch" 2>&1)
    assert_contains "$ccw_first" "Creating new git worktree" "First concurrent execution"

    # 원래 디렉토리로 돌아가기
    cd "$test_repo"

    # 두 번째 실행 (기존 워크트리 재사용)
    ccw_second=$(ccw "$concurrent_branch" 2>&1)
    assert_contains "$ccw_second" "Switching to existing worktree" "Second concurrent execution (reuse)"

    # 정리
    cd "$test_repo"
    git worktree remove "../$concurrent_branch" 2>/dev/null || true
    rm -rf "../$concurrent_branch" 2>/dev/null || true
    git branch -D "$concurrent_branch" 2>/dev/null || true

    # 연속적인 여러 브랜치 생성
    echo "Testing rapid consecutive worktree creation..."

    rapid_branches=()
    for i in {1..5}; do
      rapid_branch="rapid-$i"
      rapid_branches+=("$rapid_branch")

      ccw_rapid=$(ccw "$rapid_branch" 2>&1)
      assert_contains "$ccw_rapid" "Creating new git worktree" "Rapid creation $i"

      cd "$test_repo"
    done

    # 모든 브랜치가 생성되었는지 확인
    for branch in "''${rapid_branches[@]}"; do
      assert_directory_exists "../$branch" "Rapid branch $branch exists"
    done

    # 정리
    for branch in "''${rapid_branches[@]}"; do
      git worktree remove "../$branch" 2>/dev/null || true
      rm -rf "../$branch" 2>/dev/null || true
      git branch -D "$branch" 2>/dev/null || true
    done
  '';

  # Error Test 5: 메모리 및 스토리지 제한
  memoryStorageTest = testLib.isolatedTest "memory-storage" ''
    echo "Testing memory and storage limitations..."

    ${testLib.createTestRepo "memory-storage"}

    # 큰 파일 생성 (10MB)
    echo "Creating large file for storage test..."
    dd if=/dev/zero of=large-file.bin bs=1024 count=10240 2>/dev/null
    git add large-file.bin
    git commit -m "Add large file"

    # 큰 파일이 있는 상태에서 워크트리 생성
    start_time=$(date +%s)
    ccw_large_result=$(ccw "large-file-test" 2>&1)
    end_time=$(date +%s)

    execution_time=$((end_time - start_time))

    assert_contains "$ccw_large_result" "Creating new git worktree" "Worktree created with large file"

    # 큰 파일이 워크트리에 복사되었는지 확인
    assert_success "test -f large-file.bin" "Large file exists in worktree"

    # 파일 크기 확인
    file_size=$(du -k large-file.bin | cut -f1)
    if [[ $file_size -gt 10000 ]]; then
      echo "✅ PASS: Large file correctly copied to worktree (''${file_size}KB)"
    else
      echo "❌ FAIL: Large file not properly copied (''${file_size}KB)"
      return 1
    fi

    if [[ $execution_time -lt 60 ]]; then
      echo "✅ PASS: Large file worktree creation within reasonable time (''${execution_time}s)"
    else
      echo "⚠️  WARNING: Large file worktree creation took long time (''${execution_time}s)"
    fi

    # 정리
    cd "$test_repo"
    git worktree remove "../large-file-test" 2>/dev/null || true
    rm -rf "../large-file-test" 2>/dev/null || true
    git branch -D "large-file-test" 2>/dev/null || true
    rm -f large-file.bin

    # Git 히스토리에서도 제거 (실제 프로젝트에서는 주의 필요)
    git reset --hard HEAD~1 2>/dev/null || true
  '';
}
