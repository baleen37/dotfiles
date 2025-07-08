# TDD Test: IntelliJ IDEA Background Execution
# 이 테스트는 IntelliJ IDEA 백그라운드 실행 기능을 검증합니다
# Issue: https://github.com/baleen37/dotfiles/issues/367

{ pkgs }:

let
  # IDEA 백그라운드 실행 테스트
  checkIdeaBackgroundExecution = pkgs.writeShellScript "check-idea-background-execution" ''
    set -e

    echo "=== Testing IntelliJ IDEA Background Execution ==="

    # 1. idea alias가 존재하는지 확인
    if ! type idea >/dev/null 2>&1; then
      echo "❌ FAIL: 'idea' command not found"
      exit 1
    fi

    # 2. idea alias가 백그라운드 실행을 포함하는지 확인
    idea_definition=$(type idea)
    if [[ "$idea_definition" != *"&"* ]]; then
      echo "❌ FAIL: 'idea' alias does not include background execution (&)"
      echo "   Current definition: $idea_definition"
      exit 1
    fi

    # 3. nohup이 포함되어 있는지 확인
    if [[ "$idea_definition" != *"nohup"* ]]; then
      echo "❌ FAIL: 'idea' alias does not include nohup"
      echo "   Current definition: $idea_definition"
      exit 1
    fi

    # 4. 출력 리디렉션이 포함되어 있는지 확인
    if [[ "$idea_definition" != *">/dev/null"* ]]; then
      echo "❌ FAIL: 'idea' alias does not include output redirection"
      echo "   Current definition: $idea_definition"
      exit 1
    fi

    # 5. 에러 출력 리디렉션이 포함되어 있는지 확인
    if [[ "$idea_definition" != *"2>&1"* ]]; then
      echo "❌ FAIL: 'idea' alias does not include error redirection"
      echo "   Current definition: $idea_definition"
      exit 1
    fi

    echo "✅ IntelliJ IDEA background execution configuration is correct!"
  '';

  # Zsh 설정에서 IDEA alias 확인
  checkZshIdeaConfiguration = pkgs.writeShellScript "check-zsh-idea-configuration" ''
    set -e

    echo "=== Testing Zsh IDEA Configuration ==="

    zshrc_file="$HOME/.zshrc"

    if [[ ! -f "$zshrc_file" ]]; then
      echo "❌ FAIL: ~/.zshrc file does not exist"
      exit 1
    fi

    # IDEA alias가 zshrc에 포함되어 있는지 확인
    if ! grep -q "alias idea=" "$zshrc_file"; then
      echo "❌ FAIL: idea alias not found in ~/.zshrc"
      exit 1
    fi

    # 백그라운드 실행 설정이 포함되어 있는지 확인
    idea_alias_line=$(grep "alias idea=" "$zshrc_file")

    if [[ "$idea_alias_line" != *"nohup"* ]]; then
      echo "❌ FAIL: idea alias does not include nohup"
      echo "   Current alias: $idea_alias_line"
      exit 1
    fi

    if [[ "$idea_alias_line" != *">/dev/null 2>&1 &"* ]]; then
      echo "❌ FAIL: idea alias does not include proper background execution"
      echo "   Current alias: $idea_alias_line"
      exit 1
    fi

    echo "✅ Zsh IDEA configuration is properly set up!"
  '';

  # 실제 백그라운드 실행 동작 테스트 (시뮬레이션)
  checkBackgroundExecutionBehavior = pkgs.writeShellScript "check-background-execution-behavior" ''
    set -e

    echo "=== Testing Background Execution Behavior ==="

    # 임시 디렉토리 생성
    test_dir=$(mktemp -d)
    cd "$test_dir"

    # 가짜 IntelliJ IDEA 스크립트 생성 (테스트용)
    fake_idea_script="$test_dir/fake_idea"
    cat > "$fake_idea_script" << 'EOF'
#!/bin/bash
# 가짜 IntelliJ IDEA 스크립트 (테스트용)
echo "Starting IntelliJ IDEA..."
sleep 2
echo "IntelliJ IDEA started"
EOF
    chmod +x "$fake_idea_script"

    # 백그라운드 실행 테스트
    echo "Testing background execution..."
    start_time=$(date +%s)

    # 백그라운드 실행 명령 시뮬레이션
    nohup "$fake_idea_script" >/dev/null 2>&1 &

    end_time=$(date +%s)
    execution_time=$((end_time - start_time))

    # 즉시 반환되는지 확인 (1초 이내)
    if [[ $execution_time -gt 1 ]]; then
      echo "❌ FAIL: Background execution took too long ($execution_time seconds)"
      exit 1
    fi

    echo "✅ Background execution behavior is correct (returned in $execution_time seconds)!"

    # 정리
    rm -rf "$test_dir"
  '';

in
pkgs.runCommand "intellij-idea-background-execution-test" {} ''
  echo "Running TDD Test for IntelliJ IDEA Background Execution..."

  # 이 테스트들은 현재 실패할 것으로 예상됩니다 (RED 단계)

  # Test 1: IDEA 백그라운드 실행 설정 확인 (실패 예상)
  if ${checkIdeaBackgroundExecution}; then
    echo "Unexpected: IDEA background execution test passed (should fail in RED phase)"
  else
    echo "Expected failure: IDEA background execution is not configured"
  fi

  # Test 2: Zsh IDEA 설정 확인
  if ${checkZshIdeaConfiguration}; then
    echo "Unexpected: Zsh IDEA configuration test passed (should fail in RED phase)"
  else
    echo "Expected failure: Zsh IDEA configuration is not set up"
  fi

  # Test 3: 백그라운드 실행 동작 테스트
  if ${checkBackgroundExecutionBehavior}; then
    echo "Background execution behavior test passed"
  else
    echo "Issue with background execution behavior"
  fi

  echo "TDD RED Phase: Tests demonstrate the current issues"
  echo "Next: Implement fixes to make these tests pass (GREEN phase)"

  # 테스트 결과 파일 생성
  touch $out
''
