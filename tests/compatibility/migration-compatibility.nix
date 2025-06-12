# ABOUTME: 설정 마이그레이션 및 하위 호환성을 검증하는 테스트
# ABOUTME: 기존 설정에서 새 버전으로의 안전한 마이그레이션을 보장함

{ pkgs, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Legacy configuration patterns to check for
  legacyPatterns = [
    "home-manager.users.\\$\\{user\\}"
    "nixpkgs.config.allowUnfree"
    "environment.systemPackages.*with pkgs"
    "services.nix-daemon.enable"
  ];

  # New patterns that should be used instead

in
pkgs.runCommand "migration-compatibility-test"
{
  buildInputs = [ pkgs.ripgrep pkgs.gnugrep ];
} ''
  ${testHelpers.setupTestEnv}
  ${testHelpers.testSection "Migration Compatibility 검증"}

  cd ${src}

  ${testHelpers.testSubsection "레거시 패턴 검사"}

  # Check for deprecated patterns
  LEGACY_FOUND=0

  echo "레거시 설정 패턴 검색 중..."

  for pattern in ${builtins.concatStringsSep " " (map (p: ''"${p}"'') legacyPatterns)}; do
    echo "패턴 검색: $pattern"

    if rg --type nix -q "$pattern" . 2>/dev/null; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 레거시 패턴 발견: $pattern"
      rg --type nix -n "$pattern" . 2>/dev/null || true
      LEGACY_FOUND=$((LEGACY_FOUND + 1))
    else
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 레거시 패턴 없음: $pattern"
    fi
  done

  ${testHelpers.testSubsection "현대적 패턴 확인"}

  # Check for modern patterns
  MODERN_FOUND=0

  echo "현대적 설정 패턴 확인 중..."

  # Check if get-user.nix is properly used
  if grep -r "get-user" modules/ >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} get-user.nix 사용됨"
    MODERN_FOUND=$((MODERN_FOUND + 1))
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} get-user.nix 미사용"
  fi

  # Check for proper module structure
  if [ -d "modules/shared" ] && [ -d "modules/darwin" ] && [ -d "modules/nixos" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 모듈 구조 현대화됨"
    MODERN_FOUND=$((MODERN_FOUND + 1))
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 레거시 모듈 구조"
  fi

  # Check for flake-based configuration
  if [ -f "flake.nix" ] && [ -f "flake.lock" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Flake 기반 설정"
    MODERN_FOUND=$((MODERN_FOUND + 1))
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} 레거시 channels 기반 설정"
  fi

  ${testHelpers.testSubsection "마이그레이션 가이드 확인"}

  # Check if migration documentation exists
  MIGRATION_DOCS=0

  if [ -f "docs/migration.md" ] || grep -q -i "migration\|upgrade" README.md 2>/dev/null; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 마이그레이션 문서 존재"
    MIGRATION_DOCS=1
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 마이그레이션 문서 없음"
  fi

  ${testHelpers.testSubsection "하위 호환성 확인"}

  # Check for compatibility layers
  COMPAT_LAYER=0

  # Check if old API is still supported through compatibility functions
  if grep -r "lib.*mkDefault\|lib.*mkIf" modules/ >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 호환성 래퍼 함수 사용"
    COMPAT_LAYER=1
  else
    echo "${testHelpers.colors.blue}ℹ${testHelpers.colors.reset} 호환성 래퍼 함수 미사용"
  fi

  # Check for deprecation warnings
  if grep -r "lib.warn\|builtins.trace.*deprecated" modules/ >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 지원 중단 경고 구현"
  else
    echo "${testHelpers.colors.blue}ℹ${testHelpers.colors.reset} 지원 중단 경고 없음"
  fi

  ${testHelpers.testSubsection "설정 검증"}

  # Test that configurations can be built without deprecated warnings
  echo "설정 빌드 테스트 중..."

  BUILD_SUCCESS=true
  BUILD_OUTPUT=$(nix flake check --no-build . 2>&1) || BUILD_SUCCESS=false

  if [ "$BUILD_SUCCESS" = true ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 설정 빌드 성공"

    # Check for warnings in build output
    if echo "$BUILD_OUTPUT" | grep -q -i "warn\|deprecated"; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 빌드 중 경고 발견:"
      echo "$BUILD_OUTPUT" | grep -i "warn\|deprecated" || true
    else
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 경고 없는 깨끗한 빌드"
    fi
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} 설정 빌드 실패"
    echo "$BUILD_OUTPUT"
    exit 1
  fi

  ${testHelpers.testSubsection "마이그레이션 호환성 결과"}

  echo "레거시 패턴 발견: $LEGACY_FOUND개"
  echo "현대적 패턴 적용: $MODERN_FOUND개"
  echo "마이그레이션 문서: $MIGRATION_DOCS개"
  echo "호환성 레이어: $COMPAT_LAYER개"

  # Overall assessment
  if [ $LEGACY_FOUND -eq 0 ] && [ $MODERN_FOUND -ge 2 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 마이그레이션 호환성 우수"
    ${testHelpers.reportResults "Migration Compatibility" 1 1}
  elif [ $LEGACY_FOUND -le 2 ]; then
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 마이그레이션 부분 완료"
    ${testHelpers.reportResults "Migration Compatibility" 1 1}
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} 마이그레이션 필요"
    exit 1
  fi

  touch $out
''
