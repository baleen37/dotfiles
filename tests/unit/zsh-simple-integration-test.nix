# Simple Integration Test: zsh 설정이 의도대로 되는지 간단 확인

{ pkgs }:

pkgs.runCommand "zsh-simple-integration-test" {} ''
  echo "=== Simple Zsh Integration Test ==="
  
  # 1. zshrc 파일 존재 확인
  if [[ -f ~/.zshrc ]]; then
    echo "✅ zshrc exists"
  else
    echo "❌ zshrc missing"
    exit 1
  fi
  
  # 2. powerlevel10k 설정 포함 확인
  if grep -q "powerlevel10k" ~/.zshrc; then
    echo "✅ powerlevel10k configured"
  else
    echo "❌ powerlevel10k missing"
    exit 1
  fi
  
  # 3. 새 zsh 세션에서 p10k 로딩 확인
  p10k_loaded=$(${pkgs.zsh}/bin/zsh -l -c 'typeset -f | grep -c "^p10k" || echo 0' 2>/dev/null)
  if [[ "$p10k_loaded" -gt 0 ]]; then
    echo "✅ powerlevel10k loads ($p10k_loaded functions)"
  else
    echo "❌ powerlevel10k not loading"
    exit 1
  fi
  
  # 4. 기본 환경변수 확인
  if ${pkgs.zsh}/bin/zsh -l -c 'test -n "$EDITOR"' 2>/dev/null; then
    echo "✅ environment variables set"
  else
    echo "❌ environment variables missing"
    exit 1
  fi
  
  echo ""
  echo "🎉 All tests passed! Zsh is configured correctly."
  
  touch $out
''