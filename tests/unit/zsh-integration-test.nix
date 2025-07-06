# TDD Test: zsh 설정이 의도대로 적용되는지 통합 테스트
# 실제 사용자 환경에서 zsh 설정이 올바르게 로딩되고 작동하는지 확인

{ pkgs }:

let
  # 현재 사용자의 shell 설정 상태를 검증
  testCurrentShellSetup = pkgs.writeShellScript "test-current-shell-setup" ''
    set -e

    echo "=== Testing Current Shell Setup ==="

    # 1. 시스템에 등록된 사용자 shell 확인
    user_shell=$(dscl . -read /Users/$(whoami) UserShell 2>/dev/null | awk '{print $2}' || echo "")
    expected_shell="$HOME/.nix-profile/bin/zsh"

    echo "Expected shell: $expected_shell"
    echo "Actual user shell: $user_shell"

    if [[ "$user_shell" == "$expected_shell" ]]; then
      echo "✅ PASS: User shell correctly set to nix-managed zsh"
    else
      echo "❌ FAIL: User shell is not nix-managed zsh"
      echo "   Run: chsh -s $expected_shell"
      return 1
    fi

    # 2. 현재 세션의 SHELL 환경변수 확인
    echo "Current SHELL environment: $SHELL"
    if [[ "$SHELL" == "$expected_shell" ]]; then
      echo "✅ PASS: SHELL environment variable correctly set"
    else
      echo "⚠️  WARNING: SHELL environment still points to old shell"
      echo "   Start a new terminal session to apply changes"
    fi

    # 3. nix-managed zsh가 실제로 존재하는지 확인
    if [[ -x "$expected_shell" ]]; then
      echo "✅ PASS: Nix-managed zsh binary exists and is executable"
    else
      echo "❌ FAIL: Nix-managed zsh binary not found or not executable"
      return 1
    fi
  '';

  # zshrc 파일과 Home Manager 링크 확인
  testZshrcConfiguration = pkgs.writeShellScript "test-zshrc-configuration" ''
    set -e

    echo "=== Testing Zshrc Configuration ==="

    # 1. ~/.zshrc 파일이 존재하고 Home Manager가 관리하는지 확인
    if [[ -L ~/.zshrc ]]; then
      zshrc_target=$(readlink ~/.zshrc)
      echo "✅ PASS: ~/.zshrc is a symlink managed by Home Manager"
      echo "   Target: $zshrc_target"
    else
      echo "❌ FAIL: ~/.zshrc is not a symlink or doesn't exist"
      return 1
    fi

    # 2. zshrc 파일이 유효한 구문인지 확인
    if ${pkgs.zsh}/bin/zsh -n ~/.zshrc; then
      echo "✅ PASS: ~/.zshrc has valid zsh syntax"
    else
      echo "❌ FAIL: ~/.zshrc has syntax errors"
      return 1
    fi

    # 3. 필수 설정들이 포함되어 있는지 확인
    required_configs=(
      "powerlevel10k"
      "nix-daemon.sh"
      "EDITOR.*vim"
      "direnv hook zsh"
      "SSH_AUTH_SOCK"
    )

    echo "Checking for required configurations in ~/.zshrc:"
    for config in "''${required_configs[@]}"; do
      if grep -q "$config" ~/.zshrc; then
        echo "  ✅ $config - found"
      else
        echo "  ❌ $config - missing"
        return 1
      fi
    done

    echo "✅ PASS: All required configurations found in zshrc"
  '';

  # Powerlevel10k 플러그인 설정 확인
  testPowerlevel10kSetup = pkgs.writeShellScript "test-powerlevel10k-setup" ''
    set -e

    echo "=== Testing Powerlevel10k Setup ==="

    # 1. 플러그인 디렉토리 구조 확인
    if [[ -d ~/.zsh/plugins/powerlevel10k ]]; then
      echo "✅ PASS: Powerlevel10k plugin directory exists"
    else
      echo "❌ FAIL: Powerlevel10k plugin directory not found"
      return 1
    fi

    # 2. 테마 파일 존재 확인
    theme_file="$HOME/.zsh/plugins/powerlevel10k/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
    if [[ -f "$theme_file" ]]; then
      echo "✅ PASS: Powerlevel10k theme file exists"
    else
      echo "❌ FAIL: Powerlevel10k theme file not found"
      echo "   Expected: $theme_file"
      return 1
    fi

    # 3. p10k 설정 파일 존재 확인
    config_file="$HOME/.zsh/plugins/powerlevel10k-config/p10k.zsh"
    if [[ -f "$config_file" ]]; then
      echo "✅ PASS: p10k configuration file exists"
    else
      echo "❌ FAIL: p10k configuration file not found"
      echo "   Expected: $config_file"
      return 1
    fi

    # 4. 설정 파일 내용 검증
    if grep -q "POWERLEVEL9K_LEFT_PROMPT_ELEMENTS" "$config_file"; then
      echo "✅ PASS: p10k configuration contains prompt elements"
    else
      echo "❌ FAIL: p10k configuration appears to be empty or invalid"
      return 1
    fi
  '';

  # 실제 zsh 세션에서 설정 로딩 테스트
  testZshSessionLoading = pkgs.writeShellScript "test-zsh-session-loading" ''
    set -e

    echo "=== Testing Zsh Session Loading ==="

    # 새로운 zsh 세션에서 설정 로딩 테스트
    echo "Testing in a new zsh session..."

    # 1. Powerlevel10k 함수들이 로드되는지 확인
    p10k_count=$(${pkgs.zsh}/bin/zsh -l -c 'typeset -f | grep -c "^p10k" || echo 0' 2>/dev/null)

    if [[ "$p10k_count" -gt 0 ]]; then
      echo "✅ PASS: Powerlevel10k functions loaded ($p10k_count functions)"
    else
      echo "❌ FAIL: Powerlevel10k functions not loaded"
      return 1
    fi

    # 2. Powerlevel10k 변수들이 설정되는지 확인
    p10k_vars=$(${pkgs.zsh}/bin/zsh -l -c 'env | grep -c "^POWERLEVEL9K_" || echo 0' 2>/dev/null)

    if [[ "$p10k_vars" -gt 0 ]]; then
      echo "✅ PASS: Powerlevel10k variables loaded ($p10k_vars variables)"
    else
      echo "❌ FAIL: Powerlevel10k variables not loaded"
      return 1
    fi

    # 3. 환경변수들이 올바르게 설정되는지 확인
    required_vars=("EDITOR" "VISUAL" "LANG" "LC_ALL")

    for var in "''${required_vars[@]}"; do
      var_value=$(${pkgs.zsh}/bin/zsh -l -c "echo \$$var" 2>/dev/null)
      if [[ -n "$var_value" ]]; then
        echo "✅ PASS: $var = $var_value"
      else
        echo "❌ FAIL: $var not set"
        return 1
      fi
    done

    # 4. direnv가 활성화되는지 확인
    if ${pkgs.zsh}/bin/zsh -l -c 'command -v direnv >/dev/null 2>&1'; then
      echo "✅ PASS: direnv is available"
    else
      echo "❌ FAIL: direnv not available"
      return 1
    fi

    # 5. 기본 PATH가 올바르게 설정되는지 확인
    nix_in_path=$(${pkgs.zsh}/bin/zsh -l -c 'echo $PATH | grep -c nix || echo 0' 2>/dev/null)

    if [[ "$nix_in_path" -gt 0 ]]; then
      echo "✅ PASS: Nix paths in PATH"
    else
      echo "❌ FAIL: Nix paths not in PATH"
      return 1
    fi
  '';

  # 대화형 기능들이 올바르게 작동하는지 확인
  testInteractiveFeatures = pkgs.writeShellScript "test-interactive-features" ''
    set -e

    echo "=== Testing Interactive Features ==="

    # 1. 자동완성이 활성화되는지 확인
    if ${pkgs.zsh}/bin/zsh -l -c 'autoload -U compinit && compinit -d && echo "Completion system loaded"' 2>/dev/null; then
      echo "✅ PASS: Zsh completion system loads successfully"
    else
      echo "❌ FAIL: Zsh completion system failed to load"
      return 1
    fi

    # 2. 히스토리 설정이 올바른지 확인
    histsize=$(${pkgs.zsh}/bin/zsh -l -c 'echo $HISTSIZE' 2>/dev/null)
    savehist=$(${pkgs.zsh}/bin/zsh -l -c 'echo $SAVEHIST' 2>/dev/null)

    if [[ "$histsize" == "10000" && "$savehist" == "10000" ]]; then
      echo "✅ PASS: History settings configured correctly"
    else
      echo "❌ FAIL: History settings incorrect (HISTSIZE=$histsize, SAVEHIST=$savehist)"
      return 1
    fi

    # 3. 별칭들이 올바르게 설정되는지 확인
    if ${pkgs.zsh}/bin/zsh -l -c 'alias diff' 2>/dev/null | grep -q 'difft'; then
      echo "✅ PASS: Custom aliases loaded (diff=difft)"
    else
      echo "❌ FAIL: Custom aliases not loaded"
      return 1
    fi

    echo "✅ PASS: All interactive features working correctly"
  '';

in
pkgs.runCommand "zsh-integration-test" {} ''
  echo "Running Comprehensive Zsh Integration Test..."
  echo "============================================="
  echo ""

  # Test 1: Shell 설정 상태 확인
  ${testCurrentShellSetup}
  echo ""

  # Test 2: Zshrc 설정 확인
  ${testZshrcConfiguration}
  echo ""

  # Test 3: Powerlevel10k 설정 확인
  ${testPowerlevel10kSetup}
  echo ""

  # Test 4: Zsh 세션 로딩 확인
  ${testZshSessionLoading}
  echo ""

  # Test 5: 대화형 기능 확인
  ${testInteractiveFeatures}
  echo ""

  echo "🎉 ALL ZSH INTEGRATION TESTS PASSED!"
  echo ""
  echo "📋 Test Summary:"
  echo "  ✅ Shell setup (chsh configuration)"
  echo "  ✅ Zshrc file and Home Manager integration"
  echo "  ✅ Powerlevel10k plugin installation"
  echo "  ✅ Session loading and environment variables"
  echo "  ✅ Interactive features (completion, history, aliases)"
  echo ""
  echo "🔧 If any test failed:"
  echo "  1. Run: nix run #build-switch"
  echo "  2. Run: chsh -s ~/.nix-profile/bin/zsh"
  echo "  3. Start a new terminal session"
  echo "  4. Re-run this test to verify fixes"

  # 테스트 결과 파일 생성
  touch $out
''
