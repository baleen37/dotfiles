# Enhanced User Resolution Functionality Tests
# 구현된 enhanced-get-user.nix의 기능을 검증하는 테스트

{ pkgs, flake ? null, src }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Import the enhanced user resolution function
  enhanced-get-user = import "${src}/lib/enhanced-get-user.nix";

in
pkgs.runCommand "enhanced-user-resolution-functionality-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Enhanced User Resolution Functionality Tests"}

  # 테스트 1: 기본 USER 환경변수 처리
  ${testHelpers.testSubsection "Basic USER Environment Variable"}

  result1=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc { mockEnv = { USER = "testuser"; }; };
    in result
  ' | tr -d '"')

  if [ "$result1" = "testuser" ]; then
    echo "\033[32m✓\033[0m Basic USER environment variable works: $result1"
  else
    echo "\033[31m✗\033[0m Basic USER test failed, got: $result1"
    exit 1
  fi

  # 테스트 2: SUDO_USER 우선순위 확인
  ${testHelpers.testSubsection "SUDO_USER Priority"}

  result2=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc {
          mockEnv = {
            USER = "root";
            SUDO_USER = "realuser";
          };
        };
    in result
  ' | tr -d '"')

  if [ "$result2" = "realuser" ]; then
    echo "\033[32m✓\033[0m SUDO_USER priority works: $result2"
  else
    echo "\033[31m✗\033[0m SUDO_USER priority test failed, got: $result2"
    exit 1
  fi

  # 테스트 3: 자동 감지 기능
  ${testHelpers.testSubsection "Auto Detection"}

  result3=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc {
          mockEnv = {};
          enableAutoDetect = true;
        };
    in result
  ' | tr -d '"')

  if [ "$result3" = "auto-detected-user" ]; then
    echo "\033[32m✓\033[0m Auto detection works: $result3"
  else
    echo "\033[31m✗\033[0m Auto detection test failed, got: $result3"
    exit 1
  fi

  # 테스트 4: 특수 문자가 포함된 사용자명 처리
  ${testHelpers.testSubsection "Special Characters in Username"}

  result4=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc {
          mockEnv = { USER = "test-user.with_special-chars"; };
        };
    in result
  ' | tr -d '"')

  if [ "$result4" = "test-user.with_special-chars" ]; then
    echo "\033[32m✓\033[0m Special characters handling works: $result4"
  else
    echo "\033[31m✗\033[0m Special characters test failed, got: $result4"
    exit 1
  fi

  # 테스트 5: 플랫폼별 동작 확인
  ${testHelpers.testSubsection "Platform-specific Behavior"}

  result5_darwin=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc {
          mockEnv = { USER = "macuser"; };
          platform = "darwin";
        };
    in result
  ' | tr -d '"')

  result5_linux=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc {
          mockEnv = { USER = "linuxuser"; };
          platform = "linux";
        };
    in result
  ' | tr -d '"')

  if [ "$result5_darwin" = "macuser" ] && [ "$result5_linux" = "linuxuser" ]; then
    echo "\033[32m✓\033[0m Platform-specific behavior works"
  else
    echo "\033[31m✗\033[0m Platform test failed, darwin: $result5_darwin, linux: $result5_linux"
    exit 1
  fi

  # 테스트 6: 에러 메시지 확인 (자동 감지 비활성화)
  ${testHelpers.testSubsection "Error Message Generation"}

  if error_result=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc {
          mockEnv = {};
          enableAutoDetect = false;
          enableFallbacks = false;
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Error test failed - should have thrown error but got: $error_result"
    exit 1
  else
    if echo "$error_result" | grep -q "export USER="; then
      echo "\033[32m✓\033[0m Error message contains helpful suggestion"
    else
      echo "\033[31m✗\033[0m Error message doesn't contain expected suggestion"
      echo "Got: $error_result"
      exit 1
    fi
  fi

  # 테스트 7: 유효하지 않은 사용자명 처리
  ${testHelpers.testSubsection "Invalid Username Handling"}

  if invalid_result=$(nix-instantiate --eval --expr '
    let getUserFunc = import ${src}/lib/enhanced-get-user.nix;
        result = getUserFunc {
          mockEnv = { USER = ""; };
          enableAutoDetect = false;
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Invalid username test failed - should have thrown error but got: $invalid_result"
    exit 1
  else
    echo "\033[32m✓\033[0m Invalid username correctly rejected"
  fi

  echo ""
  echo "\033[34m=== Test Results: Enhanced User Resolution Functionality ===\033[0m"
  echo "\033[32m✓ All functionality tests passed!\033[0m"
  echo ""
  echo "\033[33m📋 Summary of tested features:\033[0m"
  echo "  ✓ Basic USER environment variable processing"
  echo "  ✓ SUDO_USER priority handling"
  echo "  ✓ Automatic user detection"
  echo "  ✓ Special characters in usernames"
  echo "  ✓ Platform-specific behavior"
  echo "  ✓ Helpful error message generation"
  echo "  ✓ Invalid username validation"

  touch $out
''
