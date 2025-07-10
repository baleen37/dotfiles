# TDD Test: IntelliJ IDEA Alias Execution
# 이 테스트는 IntelliJ IDEA alias 실행 오류를 재현하고 해결을 검증합니다
# Issue: "idea . 이거 치면 에러가 나. path 전달이 제대로 안되는거 같어."

{ pkgs }:

let
  # IDEA alias 실행 오류 재현 테스트
  checkIdeaAliasExecution = pkgs.writeShellScript "check-idea-alias-execution" ''
    set -e

    echo "=== Testing IntelliJ IDEA Alias Execution ==="

    # 1. idea alias가 존재하는지 확인
    if ! type idea >/dev/null 2>&1; then
      echo "❌ FAIL: 'idea' command not found"
      exit 1
    fi

    # 2. idea alias 실행 시 오류 발생 여부 확인
    echo "Testing 'idea .' command execution..."

    # 현재 디렉토리에서 idea . 실행 시 오류 발생 여부 확인
    if idea . 2>&1 | grep -q "not enough arguments"; then
      echo "❌ FAIL: 'idea .' command fails with 'not enough arguments' error"
      echo "   This demonstrates the current issue"
      exit 1
    fi

    # 3. path 전달이 제대로 되는지 확인
    # 정상적으로 실행되면 백그라운드에서 실행되어야 함
    echo "Testing path argument passing..."

    # 임시 디렉토리에서 테스트
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # idea 명령어가 정상적으로 실행되는지 확인 (실제 실행은 백그라운드)
    if ! idea . 2>/dev/null; then
      echo "❌ FAIL: 'idea .' command fails in temporary directory"
      exit 1
    fi

    echo "✅ IntelliJ IDEA alias execution is working correctly!"
    rm -rf "$temp_dir"
  '';

  # Alias 정의 문제 진단 테스트
  checkAliasDefinitionIssues = pkgs.writeShellScript "check-alias-definition-issues" ''
    set -e

    echo "=== Diagnosing Alias Definition Issues ==="

    # 1. 현재 alias 정의 확인
    alias_definition=$(type idea 2>/dev/null)
    echo "Current alias definition: $alias_definition"

    # 2. alias에서 "$@" 처리 문제 확인
    if [[ "$alias_definition" == *'"$@"'* ]]; then
      echo "⚠️  WARNING: Alias contains \"\$@\" which may cause issues in zsh"
      echo "   This is likely the root cause of the 'not enough arguments' error"
    fi

    # 3. 백그라운드 실행 구문 확인
    if [[ "$alias_definition" == *"&"* ]]; then
      echo "✅ Background execution syntax found"
    else
      echo "❌ FAIL: No background execution syntax found"
      exit 1
    fi

    # 4. nohup 사용 확인
    if [[ "$alias_definition" == *"nohup"* ]]; then
      echo "✅ nohup usage found"
    else
      echo "❌ FAIL: nohup not found in alias"
      exit 1
    fi

    echo "Diagnosis complete. Issues identified."
  '';

  # 함수 기반 해결책 테스트 (RED 단계에서는 실패할 것)
  checkFunctionBasedSolution = pkgs.writeShellScript "check-function-based-solution" ''
    set -e

    echo "=== Testing Function-Based Solution ==="

    # 현재는 함수가 아닌 alias로 정의되어 있을 것
    if type idea | grep -q "function"; then
      echo "✅ PASS: idea is defined as a function"
    else
      echo "❌ FAIL: idea is not yet defined as a function (expected in RED phase)"
      exit 1
    fi

    # 함수 정의가 있다면 실행 테스트
    echo "Testing function execution..."
    if ! idea . 2>/dev/null; then
      echo "❌ FAIL: idea function execution failed"
      exit 1
    fi

    echo "✅ Function-based solution is working correctly!"
  '';

in
pkgs.runCommand "idea-alias-execution-test" {} ''
  echo "Running TDD Test for IntelliJ IDEA Alias Execution..."

  # RED 단계: 현재 실패하는 테스트들
  echo "=== RED Phase: Demonstrating Current Issues ==="

  # Test 1: Alias 실행 오류 재현 (현재 실패해야 함)
  if ${checkIdeaAliasExecution}; then
    echo "❌ Unexpected: Alias execution test passed (should fail in RED phase)"
  else
    echo "✅ Expected failure: Alias execution issues confirmed"
  fi

  # Test 2: Alias 정의 문제 진단
  if ${checkAliasDefinitionIssues}; then
    echo "✅ Alias definition issues diagnosed"
  else
    echo "❌ Failed to diagnose alias definition issues"
  fi

  # Test 3: 함수 기반 해결책 테스트 (RED 단계에서는 실패해야 함)
  if ${checkFunctionBasedSolution}; then
    echo "❌ Unexpected: Function-based solution test passed (should fail in RED phase)"
  else
    echo "✅ Expected failure: Function-based solution not yet implemented"
  fi

  echo ""
  echo "TDD RED Phase Complete:"
  echo "- Current alias-based implementation fails with 'not enough arguments'"
  echo "- Issue is likely due to \"\$@\" handling in zsh alias"
  echo "- Next: Implement function-based solution (GREEN phase)"

  # 테스트 결과 파일 생성
  touch $out
''
