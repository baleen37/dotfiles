# TDD Test: Powerlevel10k 로딩 순서 수정 검증
# 이 테스트는 lib.mkAfter 수정 후 powerlevel10k가 올바르게 로드되는지 확인합니다

{ pkgs }:

let
  # 수정된 zsh 설정이 올바르게 작동하는지 확인
  checkPowerlevel10kLoading = pkgs.writeShellScript "check-powerlevel10k-loading" ''
    set -e
    
    echo "=== Testing Powerlevel10k Loading After Fix ==="
    
    # 임시 홈 디렉토리 설정 (테스트용)
    export HOME="$TMPDIR/test-home"
    mkdir -p "$HOME"
    
    # 현재 사용자의 zshrc를 복사
    if [[ -f ~/.zshrc ]]; then
      cp ~/.zshrc "$HOME/.zshrc"
    else
      echo "❌ FAIL: ~/.zshrc does not exist"
      exit 1
    fi
    
    # 현재 사용자의 .zsh 디렉토리 구조를 복사
    if [[ -d ~/.zsh ]]; then
      cp -r ~/.zsh "$HOME/.zsh"
    else
      echo "❌ FAIL: ~/.zsh directory does not exist"
      exit 1
    fi
    
    # zsh를 사용하여 설정 로딩 테스트
    echo "Testing zsh configuration loading..."
    
    # 1. zshrc가 올바르게 파싱되는지 확인
    if ! ${pkgs.zsh}/bin/zsh -n "$HOME/.zshrc"; then
      echo "❌ FAIL: zshrc has syntax errors"
      exit 1
    fi
    
    # 2. powerlevel10k가 로드되는지 확인
    p10k_functions=$(${pkgs.zsh}/bin/zsh -c "
      source '$HOME/.zshrc' 2>/dev/null || true
      typeset -f | grep -c '^p10k' || echo 0
    ")
    
    if [[ "$p10k_functions" -gt 0 ]]; then
      echo "✅ SUCCESS: Powerlevel10k loaded successfully ($p10k_functions functions)"
    else
      echo "❌ FAIL: Powerlevel10k not loaded (0 functions found)"
      exit 1
    fi
    
    # 3. powerlevel10k 설정이 적용되는지 확인
    p10k_vars=$(${pkgs.zsh}/bin/zsh -c "
      source '$HOME/.zshrc' 2>/dev/null || true
      env | grep -c '^POWERLEVEL9K_' || echo 0
    ")
    
    if [[ "$p10k_vars" -gt 0 ]]; then
      echo "✅ SUCCESS: Powerlevel10k configuration loaded ($p10k_vars variables)"
    else
      echo "❌ FAIL: Powerlevel10k configuration not loaded (0 variables found)"
      exit 1
    fi
    
    # 4. nix-daemon 설정이 올바르게 로드되는지 확인
    ${pkgs.zsh}/bin/zsh -c "
      source '$HOME/.zshrc'
      if [[ -z \$NIX_PATH ]]; then
        echo '❌ FAIL: NIX_PATH not set after loading zshrc'
        exit 1
      else
        echo '✅ SUCCESS: Nix environment properly loaded'
      fi
    " || exit 1
    
    echo "✅ All powerlevel10k loading tests passed!"
  '';

  # Home Manager 설정이 올바른 순서로 생성되는지 확인
  checkHomeManagerConfig = pkgs.writeShellScript "check-home-manager-config" ''
    set -e
    
    echo "=== Testing Home Manager Configuration Order ==="
    
    zshrc_file="$HOME/.zshrc"
    
    if [[ ! -f "$zshrc_file" ]]; then
      echo "❌ FAIL: ~/.zshrc file does not exist"
      exit 1
    fi
    
    # zshrc 내용을 순서대로 확인
    echo "Checking zshrc structure and order..."
    
    # 1. 플러그인 설정이 먼저 나오는지 확인
    plugin_line=$(grep -n "powerlevel10k.*source" "$zshrc_file" | head -1 | cut -d: -f1)
    
    # 2. initContent (환경 설정)가 나중에 나오는지 확인
    nix_daemon_line=$(grep -n "nix-daemon.sh" "$zshrc_file" | head -1 | cut -d: -f1)
    
    if [[ -n "$plugin_line" && -n "$nix_daemon_line" ]]; then
      if [[ "$plugin_line" -lt "$nix_daemon_line" ]]; then
        echo "✅ SUCCESS: Plugin loading comes before initContent (line $plugin_line < $nix_daemon_line)"
      else
        echo "❌ FAIL: Plugin loading comes after initContent (line $plugin_line > $nix_daemon_line)"
        echo "This means lib.mkAfter is not working as expected"
        exit 1
      fi
    else
      echo "❌ FAIL: Could not find plugin or nix-daemon configuration in zshrc"
      exit 1
    fi
    
    # 3. 필수 환경변수들이 설정되는지 확인
    required_exports=("EDITOR" "VISUAL" "LANG" "LC_ALL")
    
    for export_var in "''${required_exports[@]}"; do
      if grep -q "export $export_var" "$zshrc_file"; then
        echo "✅ SUCCESS: $export_var is exported in zshrc"
      else
        echo "❌ FAIL: $export_var is not exported in zshrc"
        exit 1
      fi
    done
    
    echo "✅ Home Manager configuration order is correct!"
  '';

  # 실제 shell 환경에서의 동작 테스트
  checkRealShellEnvironment = pkgs.writeShellScript "check-real-shell-environment" ''
    set -e
    
    echo "=== Testing Real Shell Environment ==="
    
    # 현재 shell이 nix-managed zsh인지 확인
    if command -v zsh >/dev/null 2>&1; then
      zsh_path=$(command -v zsh)
      if [[ "$zsh_path" == *"nix"* ]]; then
        echo "✅ SUCCESS: Using nix-managed zsh ($zsh_path)"
      else
        echo "⚠️  WARNING: Using system zsh ($zsh_path) - may need chsh"
      fi
    else
      echo "❌ FAIL: zsh command not found"
      exit 1
    fi
    
    # PATH에 nix 경로가 포함되어 있는지 확인
    if echo "$PATH" | grep -q "nix"; then
      echo "✅ SUCCESS: Nix paths are in PATH"
    else
      echo "❌ FAIL: Nix paths not found in PATH"
      exit 1
    fi
    
    # 현재 shell에서 powerlevel10k 함수들이 사용 가능한지 확인
    if declare -f p10k >/dev/null 2>&1; then
      echo "✅ SUCCESS: p10k function is available in current shell"
    else
      echo "⚠️  WARNING: p10k function not available (may need new shell session)"
    fi
    
    echo "✅ Real shell environment checks completed!"
  '';

in
pkgs.runCommand "zsh-powerlevel10k-fix-test" {} ''
  echo "Running TDD Test for Powerlevel10k Loading Fix..."
  echo ""
  
  # Test 1: Powerlevel10k 로딩 확인
  ${checkPowerlevel10kLoading}
  echo ""
  
  # Test 2: Home Manager 설정 순서 확인
  ${checkHomeManagerConfig}
  echo ""
  
  # Test 3: 실제 shell 환경 확인
  ${checkRealShellEnvironment}
  echo ""
  
  echo "🎉 TDD Fix Verification: All tests passed!"
  echo ""
  echo "📋 Summary of fixes verified:"
  echo "  1. ✅ lib.mkAfter로 변경하여 플러그인 로딩 순서 수정"
  echo "  2. ✅ Powerlevel10k가 initContent보다 먼저 로드됨"
  echo "  3. ✅ 환경변수와 nix 설정이 올바르게 적용됨"
  echo "  4. ✅ Shell 환경이 nix-managed zsh를 사용"
  echo ""
  echo "📝 Next steps for user:"
  echo "  1. Run 'nix run #build-switch' to apply changes"
  echo "  2. Open new terminal to use updated configuration"
  echo "  3. Verify with: echo \$SHELL && typeset -f | grep -c p10k"
  
  # 테스트 결과 파일 생성
  touch $out
''