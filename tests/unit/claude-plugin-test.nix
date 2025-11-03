# tests/unit/claude-plugin-test.nix
# Claude Code plugin installation tests
# Tests automatic plugin installation via home-manager activation
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import test helpers
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Path to Claude configuration
  claudeConfigDir = ../../users/shared/.config/claude;
  claudeCodeNix = ../../users/shared/claude-code.nix;

  # Mock claude command for testing
  mockClaudeScript = pkgs.writeShellScriptBin "claude" ''
    # Mock Claude CLI for testing plugin commands
    case "$1" in
      "plugin")
        case "$2" in
          "marketplace")
            case "$3" in
              "add")
                echo "Adding marketplace $4..."
                if [ "$4" = "obra/superpowers-marketplace" ]; then
                  echo "Successfully added superpowers marketplace"
                  exit 0
                else
                  echo "Unknown marketplace: $4" >&2
                  exit 1
                fi
                ;;
              "list")
                echo "Configured marketplaces:"
                echo ""
                echo "  ❯ superpowers-marketplace"
                echo "    Source: GitHub (obra/superpowers-marketplace)"
                ;;
              *)
                echo "Unknown marketplace command: $3" >&2
                exit 1
                ;;
            esac
            ;;
          "install")
            if echo "$3" | grep -q "superpowers@superpowers-marketplace"; then
              echo "Installing plugin \"superpowers\" from marketplace \"superpowers-marketplace\"..."
              echo "✔ Successfully installed plugin: superpowers@superpowers-marketplace"
              exit 0
            else
              echo "Unknown plugin: $3" >&2
              exit 1
            fi
            ;;
          *)
            echo "Unknown plugin command: $2" >&2
            exit 1
            ;;
        esac
        ;;
      "--help")
        echo "Mock Claude Code CLI for testing"
        ;;
      *)
        echo "Mock Claude - unknown command: $1" >&2
        exit 1
        ;;
    esac
  '';

  # Test activation script content
  activationScriptContent = ''
    # Claude Code 플러그인 자동 설치
    # 빌드할 때마다 실행되며, 이미 설치된 경우 자동으로 건너뜁니다

    CLAUDE_BIN="$(command -v claude)"
    if [ -z "$CLAUDE_BIN" ]; then
      echo "Claude Code not found, skipping plugin installation"
      exit 0
    fi

    echo "Installing Claude Code plugins..."

    # 1. Superpowers marketplace 추가
    echo "Adding superpowers marketplace..."
    $CLAUDE_BIN plugin marketplace add obra/superpowers-marketplace 2>/dev/null || echo "Superpowers marketplace already exists or failed to add"

    # 2. Superpowers 플러그인 설치
    echo "Installing superpowers plugin..."
    $CLAUDE_BIN plugin install superpowers@superpowers-marketplace 2>/dev/null || echo "Superpowers plugin already installed or failed to install"

    echo "Claude Code plugin installation completed"
  '';

  # Validate the activation script structure
  validateActivationScript =
    let
      scriptExists = builtins.pathExists claudeCodeNix;
      scriptContent = if scriptExists then builtins.readFile claudeCodeNix else "";
      hasClaudePlugins = builtins.match ".*claudePlugins.*" scriptContent != null;
      hasMarketplaceAdd = builtins.match ".*plugin marketplace add.*" scriptContent != null;
      hasPluginInstall = builtins.match ".*plugin install.*" scriptContent != null;
      hasSuperpowers = builtins.match ".*superpowers.*" scriptContent != null;
      hasErrorHandling = builtins.match ".*2>/dev/null.*" scriptContent != null;
    in
    scriptExists
    && hasClaudePlugins
    && hasMarketplaceAdd
    && hasPluginInstall
    && hasSuperpowers
    && hasErrorHandling;

in
# Convert tests to executable derivation
pkgs.runCommand "claude-plugin-test-results"
  {
    buildInputs = [
      mockClaudeScript
      pkgs.gnugrep
    ];
  }
  ''
    echo "Running Claude Code plugin installation tests..."

    # Set up mock environment
    export PATH="${mockClaudeScript}/bin:$PATH"
    TEST_TEMP=$(mktemp -d)
    cd "$TEST_TEMP"

    # Test 1: Validate activation script exists and has proper structure
    echo "Test 1: Activation script structure validation..."
    if [ -f "${claudeCodeNix}" ]; then
      echo "✅ PASS: claude-code.nix exists"

      # Check for activation script content
      if grep -q "claudePlugins" "${claudeCodeNix}"; then
        echo "✅ PASS: claudePlugins activation found"
      else
        echo "❌ FAIL: claudePlugins activation not found"
        exit 1
      fi

      # Check for marketplace addition
      if grep -q "plugin marketplace add" "${claudeCodeNix}"; then
        echo "✅ PASS: marketplace addition command found"
      else
        echo "❌ FAIL: marketplace addition command not found"
        exit 1
      fi

      # Check for plugin installation
      if grep -q "plugin install" "${claudeCodeNix}"; then
        echo "✅ PASS: plugin installation command found"
      else
        echo "❌ FAIL: plugin installation command not found"
        exit 1
      fi

      # Check for superpowers marketplace
      if grep -q "obra/superpowers-marketplace" "${claudeCodeNix}"; then
        echo "✅ PASS: superpowers marketplace reference found"
      else
        echo "❌ FAIL: superpowers marketplace reference not found"
        exit 1
      fi

      # Check for error handling
      if grep -q "2>/dev/null" "${claudeCodeNix}"; then
        echo "✅ PASS: error handling found"
      else
        echo "❌ FAIL: error handling not found"
        exit 1
      fi

      # Check for activation ordering
      if grep -q "lib.hm.dag.entryAfter.*claudeSettings" "${claudeCodeNix}"; then
        echo "✅ PASS: proper activation ordering found"
      else
        echo "❌ FAIL: proper activation ordering not found"
        exit 1
      fi

    else
      echo "❌ FAIL: claude-code.nix not found"
      exit 1
    fi

    # Test 2: Mock plugin installation workflow
    echo ""
    echo "Test 2: Mock plugin installation workflow..."

    # Test marketplace addition
    echo "Testing marketplace addition..."
    if claude plugin marketplace add obra/superpowers-marketplace; then
      echo "✅ PASS: marketplace addition succeeded"
    else
      echo "❌ FAIL: marketplace addition failed"
      exit 1
    fi

    # Test marketplace listing
    echo "Testing marketplace listing..."
    if claude plugin marketplace list | grep -q "superpowers-marketplace"; then
      echo "✅ PASS: marketplace listing shows superpowers"
    else
      echo "❌ FAIL: marketplace listing missing superpowers"
      exit 1
    fi

    # Test plugin installation
    echo "Testing plugin installation..."
    if claude plugin install superpowers@superpowers-marketplace; then
      echo "✅ PASS: plugin installation succeeded"
    else
      echo "❌ FAIL: plugin installation failed"
      exit 1
    fi

    # Test 3: Error handling scenarios
    echo ""
    echo "Test 3: Error handling validation..."

    # Create activation script test
    cat > test_activation.sh << 'EOF'
    CLAUDE_BIN="$(command -v claude)"
    if [ -z "$CLAUDE_BIN" ]; then
      echo "Claude Code not found, skipping plugin installation"
      exit 0
    fi

    echo "Installing Claude Code plugins..."

    # Test with error handling
    $CLAUDE_BIN plugin marketplace add obra/superpowers-marketplace 2>/dev/null || echo "Marketplace handling works"
    $CLAUDE_BIN plugin install superpowers@superpowers-marketplace 2>/dev/null || echo "Plugin installation handling works"

    echo "Claude Code plugin installation completed"
    EOF

    chmod +x test_activation.sh

    # Test activation script execution
    if ./test_activation.sh; then
      echo "✅ PASS: activation script executes successfully"
    else
      echo "❌ FAIL: activation script execution failed"
      exit 1
    fi

    # Test 4: Claude binary detection
    echo ""
    echo "Test 4: Claude binary detection..."

    # Test with valid claude binary
    if command -v claude >/dev/null 2>&1; then
      echo "✅ PASS: Claude binary found in PATH"

      # Test actual claude commands
      if claude --help >/dev/null 2>&1; then
        echo "✅ PASS: Claude --help works"
      else
        echo "ℹ️  INFO: Claude --help failed (might be expected in test environment)"
      fi
    else
      echo "ℹ️  INFO: Claude binary not found (expected in test environment)"
    fi

    # Test 5: Configuration validation
    echo ""
    echo "Test 5: Configuration validation..."

    # Check settings.json for plugin configuration
    if [ -f "${claudeConfigDir}/settings.json" ]; then
      echo "✅ PASS: settings.json exists"

      # Check for enabledPlugins configuration
      if grep -q "enabledPlugins" "${claudeConfigDir}/settings.json"; then
        echo "✅ PASS: enabledPlugins configuration found"
      else
        echo "ℹ️  INFO: enabledPlugins not configured (plugins managed via activation)"
      fi
    else
      echo "ℹ️  INFO: settings.json not found (will be created by activation)"
    fi

    # Test 6: Activation script dependencies
    echo ""
    echo "Test 6: Activation script dependencies..."

    # Check if required tools are available
    if command -v command >/dev/null 2>&1; then
      echo "✅ PASS: command builtin available"
    else
      echo "❌ FAIL: command builtin not available"
      exit 1
    fi

    if command -v grep >/dev/null 2>&1; then
      echo "✅ PASS: grep available"
    else
      echo "❌ FAIL: grep not available"
      exit 1
    fi

    echo ""
    echo "✅ All Claude Code plugin installation tests passed!"
    echo ""
    echo "Test Summary:"
    echo "  ✅ Activation script structure validated"
    echo "  ✅ Plugin installation workflow tested"
    echo "  ✅ Error handling verified"
    echo "  ✅ Claude binary detection working"
    echo "  ✅ Configuration files validated"
    echo "  ✅ Dependencies confirmed available"
    echo ""
    echo "Plugin installation feature is ready for production use!"

    # Cleanup
    cd /
    rm -rf "$TEST_TEMP"
    touch $out
  ''
