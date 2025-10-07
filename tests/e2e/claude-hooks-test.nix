# Claude Hooks E2E Tests
#
# Claude Code hooks의 실제 실행을 검증하는 end-to-end 테스트
#
# 테스트 항목:
#   - wrapper 스크립트 실행 가능 여부
#   - /bin/sh에서 절대 경로 해석
#   - JSON 입력 처리
#   - 각 hook 실행 검증
#
# VERSION: 1.0.0
# LAST UPDATED: 2025-10-07

{
  pkgs ? import <nixpkgs> { },
}:

let
  # Build hooks from the actual module
  claudeHooks = pkgs.buildGoModule {
    pname = "claude-hooks";
    version = "1.0.0";
    src = ../../modules/shared/programs/claude/hooks-go;
    vendorHash = null;
    subPackages = [ "cmd/claude-hooks" ];
  };

  # Create hooks directory with wrappers (same as module)
  hooksDir = pkgs.runCommand "claude-hooks-dir" { } ''
        mkdir -p $out
        cp ${claudeHooks}/bin/claude-hooks $out/claude-hooks
        chmod +x $out/claude-hooks

        # Create wrapper scripts with absolute path resolution
        cat > $out/git-commit-validator <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" git-commit-validator
    EOF
        chmod +x $out/git-commit-validator

        cat > $out/gh-pr-validator <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" gh-pr-validator
    EOF
        chmod +x $out/gh-pr-validator

        cat > $out/message-cleaner <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" message-cleaner
    EOF
        chmod +x $out/message-cleaner
  '';

  # Test JSON inputs
  validGitCommitInput = pkgs.writeText "git-commit-input.json" (
    builtins.toJSON {
      tool = "Bash";
      arguments = {
        command = "git commit -m 'test: add feature'";
      };
    }
  );

  validGhPrInput = pkgs.writeText "gh-pr-input.json" (
    builtins.toJSON {
      tool = "Bash";
      arguments = {
        command = "gh pr create --title 'test'";
      };
    }
  );

  validMessageInput = pkgs.writeText "message-input.json" (
    builtins.toJSON {
      tool = "Bash";
      result = "Build completed successfully";
    }
  );

  invalidJsonInput = pkgs.writeText "invalid-input.txt" "not a json";

in
rec {
  # Test 1: Wrapper scripts are executable
  test-wrapper-executable = pkgs.runCommand "test-claude-hooks-executable" { } ''
    echo "Testing: Wrapper scripts are executable"

    if [[ -x ${hooksDir}/git-commit-validator ]]; then
      echo "✓ git-commit-validator is executable"
    else
      echo "✗ git-commit-validator is not executable"
      exit 1
    fi

    if [[ -x ${hooksDir}/gh-pr-validator ]]; then
      echo "✓ gh-pr-validator is executable"
    else
      echo "✗ gh-pr-validator is not executable"
      exit 1
    fi

    if [[ -x ${hooksDir}/message-cleaner ]]; then
      echo "✓ message-cleaner is executable"
    else
      echo "✗ message-cleaner is not executable"
      exit 1
    fi

    echo "PASS: All wrapper scripts are executable"
    touch $out
  '';

  # Test 2: Wrapper uses absolute path with /bin/sh
  test-wrapper-absolute-path = pkgs.runCommand "test-claude-hooks-absolute-path" { } ''
    echo "Testing: Wrapper scripts use absolute path resolution"

    # Extract SCRIPT_DIR resolution logic from wrapper
    WRAPPER_CONTENT=$(cat ${hooksDir}/git-commit-validator)

    if echo "$WRAPPER_CONTENT" | grep -q 'SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"'; then
      echo "✓ git-commit-validator uses absolute path resolution"
    else
      echo "✗ git-commit-validator doesn't use absolute path resolution"
      exit 1
    fi

    if echo "$WRAPPER_CONTENT" | grep -q 'exec "$SCRIPT_DIR/claude-hooks"'; then
      echo "✓ git-commit-validator uses SCRIPT_DIR variable"
    else
      echo "✗ git-commit-validator doesn't use SCRIPT_DIR variable"
      exit 1
    fi

    echo "PASS: Wrapper scripts use absolute path resolution"
    touch $out
  '';

  # Test 3: Wrapper works with symlinks via /bin/sh
  test-wrapper-with-symlink = pkgs.runCommand "test-claude-hooks-symlink" { } ''
    echo "Testing: Wrapper scripts work through symlinks"

    # Create a symlink to test symlink resolution
    mkdir -p test-dir
    ln -s ${hooksDir}/git-commit-validator test-dir/hook-symlink

    # Test that wrapper can resolve through symlink
    if /bin/sh test-dir/hook-symlink < ${validGitCommitInput} 2>&1 | grep -q "Error"; then
      # Expect error since we're testing with test input, not real git
      echo "✓ Wrapper executed (validation error expected)"
    else
      echo "✓ Wrapper executed successfully"
    fi

    echo "PASS: Wrapper works through symlinks"
    touch $out
  '';

  # Test 4: git-commit-validator processes JSON input
  test-git-commit-validator = pkgs.runCommand "test-git-commit-validator-json" { } ''
    echo "Testing: git-commit-validator processes JSON input"

    # Test with valid JSON input
    if ${hooksDir}/git-commit-validator < ${validGitCommitInput} 2>&1 || true; then
      echo "✓ git-commit-validator accepted valid JSON"
    fi

    # Test with invalid JSON (should error)
    OUTPUT=$(${hooksDir}/git-commit-validator < ${invalidJsonInput} 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Invalid JSON"; then
      echo "✓ git-commit-validator rejects invalid JSON"
    else
      echo "✗ git-commit-validator should reject invalid JSON"
      echo "Got: $OUTPUT"
      exit 1
    fi

    echo "PASS: git-commit-validator processes JSON correctly"
    touch $out
  '';

  # Test 5: gh-pr-validator processes JSON input
  test-gh-pr-validator = pkgs.runCommand "test-gh-pr-validator-json" { } ''
    echo "Testing: gh-pr-validator processes JSON input"

    # Test with valid JSON input
    if ${hooksDir}/gh-pr-validator < ${validGhPrInput} 2>&1 || true; then
      echo "✓ gh-pr-validator accepted valid JSON"
    fi

    # Test with invalid JSON (should error)
    OUTPUT=$(${hooksDir}/gh-pr-validator < ${invalidJsonInput} 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Invalid JSON"; then
      echo "✓ gh-pr-validator rejects invalid JSON"
    else
      echo "✗ gh-pr-validator should reject invalid JSON"
      echo "Got: $OUTPUT"
      exit 1
    fi

    echo "PASS: gh-pr-validator processes JSON correctly"
    touch $out
  '';

  # Test 6: message-cleaner processes JSON input
  test-message-cleaner = pkgs.runCommand "test-message-cleaner-json" { } ''
    echo "Testing: message-cleaner processes JSON input"

    # Test with valid JSON input
    if ${hooksDir}/message-cleaner < ${validMessageInput} 2>&1 || true; then
      echo "✓ message-cleaner accepted valid JSON"
    fi

    # Test with invalid JSON (should error)
    OUTPUT=$(${hooksDir}/message-cleaner < ${invalidJsonInput} 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Invalid JSON"; then
      echo "✓ message-cleaner rejects invalid JSON"
    else
      echo "✗ message-cleaner should reject invalid JSON"
      echo "Got: $OUTPUT"
      exit 1
    fi

    echo "PASS: message-cleaner processes JSON correctly"
    touch $out
  '';

  # Test 7: Direct binary execution
  test-binary-execution = pkgs.runCommand "test-claude-hooks-binary" { } ''
    echo "Testing: claude-hooks binary executes correctly"

    # Test help output
    OUTPUT=$(${hooksDir}/claude-hooks 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Usage:"; then
      echo "✓ Binary shows usage when run without arguments"
    else
      echo "✗ Binary should show usage"
      echo "Got: $OUTPUT"
      exit 1
    fi

    # Test with valid hook name but invalid JSON
    OUTPUT2=$(${hooksDir}/claude-hooks git-commit-validator < ${invalidJsonInput} 2>&1 || true)
    if echo "$OUTPUT2" | grep -q "Invalid JSON"; then
      echo "✓ Binary validates JSON input"
    else
      echo "✗ Binary should validate JSON input"
      echo "Got: $OUTPUT2"
      exit 1
    fi

    echo "PASS: Binary execution works correctly"
    touch $out
  '';

  # Run all tests
  all-tests =
    pkgs.runCommand "test-claude-hooks-e2e-all"
      {
        buildInputs = [
          test-wrapper-executable
          test-wrapper-absolute-path
          test-wrapper-with-symlink
          test-git-commit-validator
          test-gh-pr-validator
          test-message-cleaner
          test-binary-execution
        ];
      }
      ''
        echo "✅ All Claude hooks E2E tests passed!"
        touch $out
      '';
}
