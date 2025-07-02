# Enhanced Error Handler Functionality Tests
# 구현된 enhanced-error-handler.nix의 기능을 검증하는 테스트

{ pkgs, flake ? null, src }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Import the enhanced error handler function
  enhanced-error-handler = import "${src}/lib/enhanced-error-handler.nix";

in
pkgs.runCommand "enhanced-error-functionality-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Enhanced Error Handler Functionality Tests"}

  # 테스트 1: 기본 에러 메시지 생성
  ${testHelpers.testSubsection "Basic Error Message Generation"}

  if error_result=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "Test error message";
          component = "test-component";
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Basic error test failed - should have thrown error"
    exit 1
  else
    if echo "$error_result" | grep -q "test-component"; then
      echo "\033[32m✓\033[0m Basic error message contains component name"
    else
      echo "\033[31m✗\033[0m Basic error message missing component"
      exit 1
    fi
  fi

  # 테스트 2: 에러 타입별 아이콘 및 색상 확인
  ${testHelpers.testSubsection "Error Type Icons and Colors"}

  # Build error test
  if build_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "Build failed";
          component = "build-system";
          errorType = "build";
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Build error test failed"
    exit 1
  else
    if echo "$build_error" | grep -q "🔨"; then
      echo "\033[32m✓\033[0m Build error shows correct icon"
    else
      echo "\033[31m✗\033[0m Build error missing icon"
      exit 1
    fi
  fi

  # 테스트 3: 한국어 메시지 지원
  ${testHelpers.testSubsection "Korean Language Support"}

  if korean_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "Environment variable USER must be set";
          component = "user-detection";
          locale = "ko";
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Korean error test failed"
    exit 1
  else
    if echo "$korean_error" | grep -q "환경변수"; then
      echo "\033[32m✓\033[0m Korean error message translation works"
    else
      echo "\033[31m✗\033[0m Korean translation not working"
      exit 1
    fi
  fi

  # 테스트 4: 제안사항 표시
  ${testHelpers.testSubsection "Suggestions Display"}

  if suggestions_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "Configuration error";
          component = "config-system";
          suggestions = ["Check syntax" "Validate settings"];
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Suggestions error test failed"
    exit 1
  else
    if echo "$suggestions_error" | grep -q "1\. Check syntax"; then
      echo "\033[32m✓\033[0m Suggestions are properly formatted"
    else
      echo "\033[31m✗\033[0m Suggestions formatting incorrect"
      exit 1
    fi
  fi

  # 테스트 5: 심각도 레벨 처리
  ${testHelpers.testSubsection "Severity Level Handling"}

  # Critical error test
  if critical_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "System failure";
          component = "core-system";
          severity = "critical";
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Critical error test failed"
    exit 1
  else
    if echo "$critical_error" | grep -q "🚨"; then
      echo "\033[32m✓\033[0m Critical severity shows correct icon"
    else
      echo "\033[31m✗\033[0m Critical severity icon missing"
      exit 1
    fi
  fi

  # Warning test
  if warning_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "Deprecated feature";
          component = "legacy-module";
          severity = "warning";
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Warning test failed"
    exit 1
  else
    if echo "$warning_error" | grep -q "⚠️"; then
      echo "\033[32m✓\033[0m Warning severity shows correct icon"
    else
      echo "\033[31m✗\033[0m Warning severity icon missing"
      exit 1
    fi
  fi

  # 테스트 6: 컨텍스트 정보 표시
  ${testHelpers.testSubsection "Context Information Display"}

  if context_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "Context test";
          component = "context-module";
          context = { platform = "darwin"; arch = "aarch64"; };
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Context error test failed"
    exit 1
  else
    if echo "$context_error" | grep -q "platform: darwin"; then
      echo "\033[32m✓\033[0m Context information is displayed"
    else
      echo "\033[31m✗\033[0m Context information missing"
      exit 1
    fi
  fi

  # 테스트 7: 디버그 모드
  ${testHelpers.testSubsection "Debug Mode"}

  if debug_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "Debug test";
          component = "debug-module";
          debugMode = true;
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m Debug error test failed"
    exit 1
  else
    if echo "$debug_error" | grep -q "Original Message: Debug test"; then
      echo "\033[32m✓\033[0m Debug mode shows additional information"
    else
      echo "\033[31m✗\033[0m Debug mode not working"
      exit 1
    fi
  fi

  # 테스트 8: 영어 locale 지원
  ${testHelpers.testSubsection "English Locale Support"}

  if english_error=$(nix-instantiate --eval --expr '
    let errorHandler = import ${src}/lib/enhanced-error-handler.nix;
        result = errorHandler {
          message = "English test";
          component = "english-module";
          locale = "en";
        };
    in result
  ' 2>&1); then
    echo "\033[31m✗\033[0m English error test failed"
    exit 1
  else
    if echo "$english_error" | grep -q "Component:"; then
      echo "\033[32m✓\033[0m English locale works correctly"
    else
      echo "\033[31m✗\033[0m English locale not working"
      exit 1
    fi
  fi

  echo ""
  echo "\033[34m=== Test Results: Enhanced Error Handler Functionality ===\033[0m"
  echo "\033[32m✓ All functionality tests passed!\033[0m"
  echo ""
  echo "\033[33m📋 Summary of tested features:\033[0m"
  echo "  ✓ Basic error message generation"
  echo "  ✓ Error type icons and colors"
  echo "  ✓ Korean language support and translation"
  echo "  ✓ Suggestions display formatting"
  echo "  ✓ Severity level handling (critical, warning)"
  echo "  ✓ Context information display"
  echo "  ✓ Debug mode with detailed information"
  echo "  ✓ English locale support"

  touch $out
''
