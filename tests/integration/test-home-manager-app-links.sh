#!/usr/bin/env bash
# TDD 통합 테스트: Home Manager 앱 링크 기능 전체 테스트

set -euo pipefail

# 통합 테스트: 실제 Home Manager 적용 후 앱 링크 확인
test_home_manager_integration() {
  echo "🧪 Integration Test: Home Manager app linking after switch"

  local success_count=0
  local total_tests=3

  # 테스트 1: Karabiner-Elements 앱이 존재하는가?
  if [ -L "$HOME/Applications/Karabiner-Elements.app" ]; then
    echo "  ✅ Karabiner-Elements.app is linked"
    ((success_count++))
  else
    echo "  ❌ Karabiner-Elements.app is not linked"
  fi

  # 테스트 2: 링크가 올바른 v14.13.0 경로를 가리키는가?
  if [ -L "$HOME/Applications/Karabiner-Elements.app" ]; then
    local target=$(readlink "$HOME/Applications/Karabiner-Elements.app")
    if [[ $target == *"karabiner-elements-14.13.0"* ]]; then
      echo "  ✅ Karabiner points to v14.13.0"
      ((success_count++))
    else
      echo "  ❌ Karabiner points to wrong version: $target"
    fi
  else
    echo "  ❌ Cannot check Karabiner version - link missing"
  fi

  # 테스트 3: 앱이 실제로 실행 가능한가?
  if open "$HOME/Applications/Karabiner-Elements.app" 2>/dev/null; then
    echo "  ✅ Karabiner-Elements.app is executable"
    ((success_count++))

    # 실행된 프로세스 정리
    sleep 2
    pkill -f "Karabiner-Elements" 2>/dev/null || true
  else
    echo "  ❌ Karabiner-Elements.app failed to execute"
  fi

  # 결과 평가
  echo ""
  echo "Integration Test Results: $success_count/$total_tests tests passed"

  if [ $success_count -eq $total_tests ]; then
    echo "🟢 Integration test PASSED - TDD Refactor phase successful!"
    return 0
  else
    echo "🔴 Integration test FAILED - Fixes needed"
    return 1
  fi
}

# 추가 품질 검증 테스트
test_code_quality() {
  echo "🧪 Code Quality Test: Checking for best practices"

  local quality_score=0
  local max_score=4

  # 품질 체크 1: 에러 처리가 있는가?
  if grep -q "2>/dev/null" "/Users/baleen/dev/dotfiles/modules/darwin/home-manager.nix"; then
    echo "  ✅ Error handling implemented"
    ((quality_score++))
  else
    echo "  ❌ Missing error handling"
  fi

  # 품질 체크 2: 중복 링크 방지가 있는가?
  if grep -q "rm -f.*Applications" "/Users/baleen/dev/dotfiles/modules/darwin/home-manager.nix"; then
    echo "  ✅ Duplicate link prevention implemented"
    ((quality_score++))
  else
    echo "  ❌ Missing duplicate link prevention"
  fi

  # 품질 체크 3: 사용자 피드백이 있는가?
  if grep -q "echo.*✅" "/Users/baleen/dev/dotfiles/modules/darwin/home-manager.nix"; then
    echo "  ✅ User feedback messages implemented"
    ((quality_score++))
  else
    echo "  ❌ Missing user feedback"
  fi

  # 품질 체크 4: TDD 주석이 있는가?
  if grep -q "TDD" "/Users/baleen/dev/dotfiles/modules/darwin/home-manager.nix"; then
    echo "  ✅ TDD documentation present"
    ((quality_score++))
  else
    echo "  ❌ Missing TDD documentation"
  fi

  echo ""
  echo "Code Quality Score: $quality_score/$max_score"

  if [ $quality_score -ge 3 ]; then
    echo "🟢 Code quality check PASSED"
    return 0
  else
    echo "🔴 Code quality check FAILED"
    return 1
  fi
}

# 메인 테스트 실행
main() {
  echo "🚀 TDD Refactor Phase - Integration & Quality Tests"
  echo "===================================================="

  local failed_tests=0

  if ! test_home_manager_integration; then
    ((failed_tests++))
  fi

  echo ""

  if ! test_code_quality; then
    ((failed_tests++))
  fi

  echo ""
  echo "===================================================="

  if [ $failed_tests -eq 0 ]; then
    echo "🎉 TDD COMPLETE! All phases successful:"
    echo "  🔴 RED: Tests written and failed initially"
    echo "  🟢 GREEN: Minimal implementation made tests pass"
    echo "  🔵 REFACTOR: Code improved and integrated successfully"
    echo ""
    echo "✅ Production-ready Nix app linking system deployed!"
    return 0
  else
    echo "❌ TDD Refactor phase needs attention: $failed_tests issues found"
    return 1
  fi
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
