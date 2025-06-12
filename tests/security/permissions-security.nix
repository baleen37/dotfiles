# ABOUTME: 파일 및 디렉토리 권한을 검증하는 보안 테스트
# ABOUTME: 부적절한 권한 설정으로 인한 보안 취약점을 방지함

{ pkgs, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Expected permissions for different file types

in
pkgs.runCommand "permissions-security-test"
{
  buildInputs = [ pkgs.findutils ];
} ''
  ${testHelpers.setupTestEnv}
  ${testHelpers.testSection "Permissions Security 검증"}

  cd ${src}

  TOTAL_ISSUES=0

  ${testHelpers.testSubsection "스크립트 파일 권한 검사"}

  # Check script files in scripts/ directory
  if [ -d "scripts" ]; then
    echo "scripts/ 디렉토리의 파일 권한 확인 중..."

    find scripts -type f -name "*" | while read -r script; do
      if [ -f "$script" ]; then
        PERMS=$(stat -f "%OLp" "$script" 2>/dev/null || stat -c "%a" "$script" 2>/dev/null)

        if [ "$PERMS" = "755" ] || [ "$PERMS" = "644" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $script ($PERMS)"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} $script ($PERMS) - 부적절한 권한"
          TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        fi
      fi
    done
  else
    echo "${testHelpers.colors.blue}ℹ${testHelpers.colors.reset} scripts 디렉토리 없음"
  fi

  ${testHelpers.testSubsection "설정 파일 권한 검사"}

  # Check Nix configuration files
  echo "Nix 설정 파일 권한 확인 중..."

  find . -name "*.nix" -type f ! -path "./tests/*" | while read -r config; do
    if [ -f "$config" ]; then
      PERMS=$(stat -f "%OLp" "$config" 2>/dev/null || stat -c "%a" "$config" 2>/dev/null)

      if [ "$PERMS" = "644" ] || [ "$PERMS" = "664" ] || [ "$PERMS" = "755" ]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $config ($PERMS)"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} $config ($PERMS) - 비표준 권한"
      fi
    fi
  done

  ${testHelpers.testSubsection "민감한 설정 파일 권한 검사"}

  # Check for potentially sensitive files
  SENSITIVE_FILES=0
  for pattern in "*.key" "*.pem" "*.p12" "*password*" "*secret*" "*token*" ".env*"; do
    if find . -name "$pattern" -type f ! -path "./tests/*" | head -1 | grep -q .; then
      find . -name "$pattern" -type f ! -path "./tests/*" | while read -r sensitive; do
        if [ -f "$sensitive" ]; then
          PERMS=$(stat -f "%OLp" "$sensitive" 2>/dev/null || stat -c "%a" "$sensitive" 2>/dev/null)

          if [ "$PERMS" = "600" ] || [ "$PERMS" = "400" ]; then
            echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $sensitive ($PERMS) - 보안 파일 권한 적절"
          else
            echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} $sensitive ($PERMS) - 민감한 파일의 권한이 과도함"
            SENSITIVE_FILES=$((SENSITIVE_FILES + 1))
          fi
        fi
      done
    fi
  done

  if [ $SENSITIVE_FILES -eq 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 민감한 파일 없음 또는 적절한 권한"
  fi

  ${testHelpers.testSubsection "디렉토리 권한 검사"}

  # Check directory permissions
  echo "디렉토리 권한 확인 중..."

  find . -type d ! -path "./.git*" ! -path "./tests/*" | while read -r dir; do
    if [ -d "$dir" ]; then
      PERMS=$(stat -f "%OLp" "$dir" 2>/dev/null || stat -c "%a" "$dir" 2>/dev/null)

      if [ "$PERMS" = "755" ] || [ "$PERMS" = "775" ]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $dir ($PERMS)"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} $dir ($PERMS) - 비표준 디렉토리 권한"
      fi
    fi
  done

  ${testHelpers.testSubsection "실행 권한 검사"}

  # Check for files that should not be executable
  NON_EXEC_ISSUES=0
  for ext in "*.md" "*.txt" "*.json" "*.lock" "*.yaml" "*.yml"; do
    if find . -name "$ext" -type f -perm +111 ! -path "./tests/*" | head -1 | grep -q .; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 실행 권한이 있는 비실행 파일:"
      find . -name "$ext" -type f -perm +111 ! -path "./tests/*"
      NON_EXEC_ISSUES=$((NON_EXEC_ISSUES + 1))
    fi
  done

  if [ $NON_EXEC_ISSUES -eq 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 비실행 파일의 실행 권한 없음"
  fi

  ${testHelpers.testSubsection "권한 검사 결과"}

  if [ $TOTAL_ISSUES -eq 0 ] && [ $SENSITIVE_FILES -eq 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 모든 파일 권한이 적절함"
    ${testHelpers.reportResults "Permissions Security" 1 1}
  else
    TOTAL_ALL_ISSUES=$((TOTAL_ISSUES + SENSITIVE_FILES))
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} $TOTAL_ALL_ISSUES개의 권한 이슈 발견"
    exit 1
  fi

  touch $out
''
