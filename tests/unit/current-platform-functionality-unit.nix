# Current Platform Build Functionality Tests
# 구현된 platform-detector.nix 및 Makefile 기능을 검증하는 테스트

{ pkgs, flake ? null, src }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Import the platform detector
  platform-detector = import "${src}/lib/platform-detector.nix";

in
pkgs.runCommand "current-platform-functionality-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Current Platform Build Functionality Tests"}

  # 테스트 1: 플랫폼 감지 기본 기능
  ${testHelpers.testSubsection "Basic Platform Detection"}

  current_platform=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {};
    in detector.getCurrentPlatform
  ' | tr -d '"')

  current_arch=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {};
    in detector.getCurrentArch
  ' | tr -d '"')

  current_system=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {};
    in detector.getCurrentSystem
  ' | tr -d '"')

  if [ -n "$current_platform" ] && [ -n "$current_arch" ] && [ -n "$current_system" ]; then
    echo "\033[32m✓\033[0m Platform detection works: $current_system ($current_platform/$current_arch)"
  else
    echo "\033[31m✗\033[0m Platform detection failed"
    exit 1
  fi

  # 테스트 2: 플랫폼 검증 기능
  ${testHelpers.testSubsection "Platform Validation"}

  is_valid_platform=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {};
    in detector.validatePlatform detector.getCurrentPlatform
  ')

  if [ "$is_valid_platform" = "true" ]; then
    echo "\033[32m✓\033[0m Current platform validation works"
  else
    echo "\033[31m✗\033[0m Platform validation failed"
    exit 1
  fi

  # 테스트 3: 지원되는 시스템 목록
  ${testHelpers.testSubsection "Supported Systems"}

  supported_systems=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {};
    in detector.getSupportedSystems
  ')

  if echo "$supported_systems" | grep -q "darwin" && echo "$supported_systems" | grep -q "linux"; then
    echo "\033[32m✓\033[0m Supported systems include darwin and linux"
  else
    echo "\033[31m✗\033[0m Supported systems missing expected platforms"
    exit 1
  fi

  # 테스트 4: 플랫폼별 최적화 설정
  ${testHelpers.testSubsection "Platform Optimizations"}

  optimizations=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {};
    in builtins.toJSON detector.getOptimizations
  ')

  if echo "$optimizations" | grep -q "extraArgs"; then
    echo "\033[32m✓\033[0m Platform optimizations available"
  else
    echo "\033[31m✗\033[0m Platform optimizations missing"
    exit 1
  fi

  # 테스트 5: Boolean 체크 함수들
  ${testHelpers.testSubsection "Boolean Platform Checks"}

  # Test isDarwin and isLinux
  if [ "$current_platform" = "darwin" ]; then
    is_darwin=$(nix-instantiate --eval --expr '
      let detector = import ${src}/lib/platform-detector.nix {};
      in detector.isDarwin
    ')
    if [ "$is_darwin" = "true" ]; then
      echo "\033[32m✓\033[0m isDarwin check works correctly"
    else
      echo "\033[31m✗\033[0m isDarwin check failed"
      exit 1
    fi
  fi

  if [ "$current_platform" = "linux" ]; then
    is_linux=$(nix-instantiate --eval --expr '
      let detector = import ${src}/lib/platform-detector.nix {};
      in detector.isLinux
    ')
    if [ "$is_linux" = "true" ]; then
      echo "\033[32m✓\033[0m isLinux check works correctly"
    else
      echo "\033[31m✗\033[0m isLinux check failed"
      exit 1
    fi
  fi

  # 테스트 6: 아키텍처 체크
  ${testHelpers.testSubsection "Architecture Checks"}

  if [ "$current_arch" = "aarch64" ]; then
    is_aarch64=$(nix-instantiate --eval --expr '
      let detector = import ${src}/lib/platform-detector.nix {};
      in detector.isAarch64
    ')
    if [ "$is_aarch64" = "true" ]; then
      echo "\033[32m✓\033[0m isAarch64 check works correctly"
    else
      echo "\033[31m✗\033[0m isAarch64 check failed"
      exit 1
    fi
  fi

  if [ "$current_arch" = "x86_64" ]; then
    is_x86_64=$(nix-instantiate --eval --expr '
      let detector = import ${src}/lib/platform-detector.nix {};
      in detector.isX86_64
    ')
    if [ "$is_x86_64" = "true" ]; then
      echo "\033[32m✓\033[0m isX86_64 check works correctly"
    else
      echo "\033[31m✗\033[0m isX86_64 check failed"
      exit 1
    fi
  fi

  # 테스트 7: Override 기능
  ${testHelpers.testSubsection "Platform Override Functionality"}

  override_result=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {
      overridePlatform = "linux";
      overrideArch = "x86_64";
    };
    in detector.getCurrentSystem
  ' | tr -d '"')

  if [ "$override_result" = "x86_64-linux" ]; then
    echo "\033[32m✓\033[0m Platform override works correctly"
  else
    echo "\033[31m✗\033[0m Platform override failed, got: $override_result"
    exit 1
  fi

  # 테스트 8: 에러 처리 (잘못된 시스템)
  ${testHelpers.testSubsection "Error Handling for Invalid Systems"}

  if error_result=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {
      overridePlatform = "invalid";
      overrideArch = "invalid";
    };
    in detector.getCurrentSystem
  ' 2>&1); then
    echo "\033[31m✗\033[0m Error handling test failed - should have thrown error"
    exit 1
  else
    if echo "$error_result" | grep -q "Unsupported system"; then
      echo "\033[32m✓\033[0m Error handling works for invalid systems"
    else
      echo "\033[31m✗\033[0m Error message doesn't contain expected text"
      exit 1
    fi
  fi

  # 테스트 9: Cross compilation targets
  ${testHelpers.testSubsection "Cross Compilation Targets"}

  cross_targets=$(nix-instantiate --eval --expr '
    let detector = import ${src}/lib/platform-detector.nix {};
    in detector.getCrossTargets
  ')

  if echo "$cross_targets" | grep -v "$current_system" | grep -q "darwin\|linux"; then
    echo "\033[32m✓\033[0m Cross compilation targets available"
  else
    echo "\033[31m✗\033[0m Cross compilation targets missing"
    exit 1
  fi

  # 테스트 10: Makefile 통합 확인
  ${testHelpers.testSubsection "Makefile Integration"}

  ${testHelpers.assertExists "${src}/Makefile" "Makefile exists"}

  # Check if Makefile contains new targets
  if grep -q "build-current" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile contains build-current target"
  else
    echo "\033[31m✗\033[0m Makefile missing build-current target"
    exit 1
  fi

  if grep -q "platform-info" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile contains platform-info target"
  else
    echo "\033[31m✗\033[0m Makefile missing platform-info target"
    exit 1
  fi

  echo ""
  echo "\033[34m=== Test Results: Current Platform Build Functionality ===\033[0m"
  echo "\033[32m✓ All functionality tests passed!\033[0m"
  echo ""
  echo "\033[33m📋 Summary of tested features:\033[0m"
  echo "  ✓ Basic platform detection (platform, arch, system)"
  echo "  ✓ Platform validation functions"
  echo "  ✓ Supported systems enumeration"
  echo "  ✓ Platform-specific optimizations"
  echo "  ✓ Boolean platform/architecture checks"
  echo "  ✓ Platform override functionality"
  echo "  ✓ Error handling for invalid systems"
  echo "  ✓ Cross compilation target detection"
  echo "  ✓ Makefile integration verification"
  echo ""
  echo "\033[33m⚡ Performance Benefits:\033[0m"
  echo "  - Current platform only builds (vs. all 4 platforms)"
  echo "  - Platform-specific optimizations"
  echo "  - 75-85% faster build times estimated"

  touch $out
''
