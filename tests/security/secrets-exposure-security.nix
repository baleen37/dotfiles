# ABOUTME: 민감정보 노출을 검사하는 보안 테스트
# ABOUTME: 설정 파일에서 비밀키, 토큰 등의 누출을 방지함

{ pkgs, flake ? null, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Patterns to search for sensitive information
  sensitivePatterns = [
    "password\\s*=\\s*[\"'][^\"']*[\"']"
    "token\\s*=\\s*[\"'][^\"']*[\"']"
    "key\\s*=\\s*[\"'][^\"']*[\"']"
    "secret\\s*=\\s*[\"'][^\"']*[\"']"
    "api[_-]?key\\s*=\\s*[\"'][^\"']*[\"']"
    "private[_-]?key\\s*=\\s*[\"'][^\"']*[\"']"
    "ssh[_-]?key\\s*=\\s*[\"'][^\"']*[\"']"
    "-----BEGIN [A-Z ]*PRIVATE KEY-----"
    "github\\.com/[^/]+/[^/]+\\.git"
  ];

  # Allowed patterns (false positives)
  allowedPatterns = [
    "password.*placeholder"
    "password.*example"
    "key.*example"
    "token.*placeholder"
    "secret.*example"
  ];

  # Files to exclude from scanning

in
pkgs.runCommand "secrets-exposure-security-test"
{
  buildInputs = [ pkgs.ripgrep pkgs.git ];
} ''
  ${testHelpers.setupTestEnv}
  ${testHelpers.testSection "Secrets Exposure Security 검증"}

  cd ${src}

  # Initialize result tracking
  TOTAL_ISSUES=0
  SCAN_FILES=0

  ${testHelpers.testSubsection "설정 파일 스캔"}

  # Scan Nix files for sensitive patterns
  echo "Nix 설정 파일에서 민감정보 검색 중..."

  for pattern in ${builtins.concatStringsSep " " (map (p: ''"${p}"'') sensitivePatterns)}; do
    echo "패턴 검색: $pattern"

    # Search for pattern in Nix files
    MATCHES=$(rg --type nix -i "$pattern" . 2>/dev/null || true)

    if [ -n "$MATCHES" ]; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 의심스러운 패턴 발견:"
      echo "$MATCHES"

      # Check if it's an allowed pattern
      IS_ALLOWED=false
      for allowed in ${builtins.concatStringsSep " " (map (p: ''"${p}"'') allowedPatterns)}; do
        if echo "$MATCHES" | rg -q -i "$allowed"; then
          IS_ALLOWED=true
          break
        fi
      done

      if [ "$IS_ALLOWED" = false ]; then
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} 허용되지 않은 민감정보 패턴"
        TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
      else
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 허용된 예시/플레이스홀더"
      fi
    fi
  done

  ${testHelpers.testSubsection "SSH 키 및 인증서 검사"}

  # Check for SSH private keys
  if find . -name "id_*" -type f ! -path "./tests/*" | head -1 | grep -q .; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} SSH 개인키 파일 발견"
    find . -name "id_*" -type f ! -path "./tests/*"
    TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} SSH 개인키 파일 없음"
  fi

  # Check for certificate files
  if find . -name "*.pem" -o -name "*.crt" -o -name "*.p12" | head -1 | grep -q .; then
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 인증서 파일 발견"
    find . -name "*.pem" -o -name "*.crt" -o -name "*.p12"
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 인증서 파일 없음"
  fi

  ${testHelpers.testSubsection "Git 히스토리 검사"}

  # Check if we're in a git repository
  if [ -d ".git" ]; then
    echo "Git 히스토리에서 민감정보 검색 중..."

    # Search for sensitive patterns in git history (last 100 commits)
    HISTORY_ISSUES=0
    for pattern in ${builtins.concatStringsSep " " (map (p: ''"${p}"'') sensitivePatterns)}; do
      if git log --oneline -100 | rg -q -i "$pattern" 2>/dev/null; then
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Git 히스토리에서 의심스러운 패턴: $pattern"
        HISTORY_ISSUES=$((HISTORY_ISSUES + 1))
      fi
    done

    if [ $HISTORY_ISSUES -eq 0 ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Git 히스토리 깨끗함"
    fi
  else
    echo "${testHelpers.colors.blue}ℹ${testHelpers.colors.reset} Git 저장소가 아님"
  fi

  ${testHelpers.testSubsection "파일 권한 검사"}

  # Check for files with overly permissive permissions
  PERM_ISSUES=0
  while IFS= read -r -d "" file; do
    if [ -f "$file" ]; then
      PERMS=$(stat -f "%OLp" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null)
      if [ -n "$PERMS" ] && [ "$PERMS" -gt 644 ]; then
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 과도한 파일 권한: $file ($PERMS)"
        PERM_ISSUES=$((PERM_ISSUES + 1))
      fi
    fi
  done < <(find . -name "*.nix" -print0)

  if [ $PERM_ISSUES -eq 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 파일 권한 적절함"
  fi

  # Final report
  ${testHelpers.testSubsection "보안 검사 결과"}
  echo "스캔된 패턴: ${toString (builtins.length sensitivePatterns)}개"
  echo "발견된 이슈: $TOTAL_ISSUES개"

  if [ $TOTAL_ISSUES -eq 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 민감정보 노출 없음"
    ${testHelpers.reportResults "Secrets Exposure Security" 1 1}
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} $TOTAL_ISSUES개의 보안 이슈 발견"
    exit 1
  fi

  touch $out
''
