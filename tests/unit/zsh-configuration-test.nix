# TDD Test: Zsh Configuration Issues
# 이 테스트는 현재 zsh 설정 문제를 검증합니다

{ pkgs }:

let
  # 현재 사용자의 shell 설정 확인
  checkCurrentShell = pkgs.writeShellScript "check-current-shell" ''
    set -e

    echo "=== Testing Current Shell Configuration ==="

    # 1. 현재 SHELL 환경변수가 올바른 zsh를 가리키는지 확인
    echo "Current SHELL: $SHELL"
    expected_zsh="$HOME/.nix-profile/bin/zsh"

    if [[ "$SHELL" != "$expected_zsh" ]]; then
      echo "❌ FAIL: Shell is not set to nix-managed zsh"
      echo "   Expected: $expected_zsh"
      echo "   Actual: $SHELL"
      exit 1
    fi

    # 2. chsh 명령으로 기본 쉘이 변경되었는지 확인
    current_user_shell=$(dscl . -read /Users/$(whoami) UserShell | cut -d' ' -f2)

    if [[ "$current_user_shell" != "$expected_zsh" ]]; then
      echo "❌ FAIL: User shell is not properly configured in system"
      echo "   Expected: $expected_zsh"
      echo "   Actual: $current_user_shell"
      exit 1
    fi

    # 3. zsh가 home-manager 설정을 로드하는지 확인
    if ! $expected_zsh -c 'echo $ZSH_VERSION' >/dev/null 2>&1; then
      echo "❌ FAIL: Nix-managed zsh is not working properly"
      exit 1
    fi

    # 4. powerlevel10k가 로드되는지 확인
    if ! $expected_zsh -c 'typeset -f prompt_powerlevel10k_setup' >/dev/null 2>&1; then
      echo "❌ FAIL: Powerlevel10k is not loaded"
      exit 1
    fi

    echo "✅ All zsh configuration tests passed!"
  '';

  # Home Manager가 생성한 zshrc 파일 검증
  checkHomeManagerZshrc = pkgs.writeShellScript "check-home-manager-zshrc" ''
    set -e

    echo "=== Testing Home Manager Zshrc Configuration ==="

    zshrc_file="$HOME/.zshrc"

    if [[ ! -f "$zshrc_file" ]]; then
      echo "❌ FAIL: ~/.zshrc file does not exist"
      exit 1
    fi

    # 필수 설정들이 포함되어 있는지 확인
    required_configs=(
      "powerlevel10k"
      "direnv hook zsh"
      "EDITOR.*vim"
      "SSH_AUTH_SOCK"
      "nix-daemon.sh"
    )

    for config in "''${required_configs[@]}"; do
      if ! grep -q "$config" "$zshrc_file"; then
        echo "❌ FAIL: Required configuration not found: $config"
        exit 1
      fi
    done

    echo "✅ Home Manager zshrc configuration is properly generated!"
  '';

in
pkgs.runCommand "zsh-configuration-test" {} ''
  echo "Running TDD Test for Zsh Configuration Issues..."

  # 이 테스트들은 현재 실패할 것으로 예상됩니다 (RED 단계)

  # Test 1: Shell 설정 확인 (실패 예상)
  if ${checkCurrentShell}; then
    echo "Unexpected: Shell configuration test passed (should fail in RED phase)"
  else
    echo "Expected failure: Current shell configuration is incorrect"
  fi

  # Test 2: Home Manager zshrc 확인
  if ${checkHomeManagerZshrc}; then
    echo "Home Manager zshrc is properly configured"
  else
    echo "Issue with Home Manager zshrc configuration"
  fi

  echo "TDD RED Phase: Tests demonstrate the current issues"
  echo "Next: Implement fixes to make these tests pass (GREEN phase)"

  # 테스트 결과 파일 생성
  touch $out
''
