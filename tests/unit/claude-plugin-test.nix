# tests/unit/claude-plugin-test.nix
# Claude Code configuration tests
# Tests Claude Code settings and configuration management
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

  # Validate the Claude configuration structure
  validateClaudeConfig =
    let
      configExists = builtins.pathExists claudeCodeNix;
      scriptContent = if configExists then builtins.readFile claudeCodeNix else "";
      hasHomeFile = builtins.match ".*home\\.file.*" scriptContent != null;
      hasClaudeDir = builtins.match ".*\\.claude.*" scriptContent != null;
      hasSettings =
        builtins.match ".*settings\\.json.*" scriptContent != null
        || builtins.match ".*statusline\\.sh.*" scriptContent != null;
    in
    configExists && hasHomeFile && hasClaudeDir && hasSettings;

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
    echo "Running Claude Code configuration tests..."

    # Set up mock environment
    export PATH="${mockClaudeScript}/bin:$PATH"
    TEST_TEMP=$(mktemp -d)
    cd "$TEST_TEMP"

    # Test 1: Validate configuration exists and has proper structure
    echo "Test 1: Configuration structure validation..."
    if [ -f "${claudeCodeNix}" ]; then
      echo "✅ PASS: claude-code.nix exists"

      # Check for home.file configuration
      if grep -q "home\\.file" "${claudeCodeNix}" || grep -q "home.file" "${claudeCodeNix}"; then
        echo "✅ PASS: home.file configuration found"
      else
        echo "❌ FAIL: home.file configuration not found"
        exit 1
      fi

      # Check for .claude directory reference
      if grep -q "\\.claude" "${claudeCodeNix}"; then
        echo "✅ PASS: .claude directory reference found"
      else
        echo "❌ FAIL: .claude directory reference not found"
        exit 1
      fi

      # Check for Claude settings or statusline
      if grep -q "settings\\.json" "${claudeCodeNix}" || grep -q "statusline\\.sh" "${claudeCodeNix}"; then
        echo "✅ PASS: Claude configuration files found"
      else
        echo "❌ FAIL: Claude configuration files not found"
        exit 1
      fi

    else
      echo "❌ FAIL: claude-code.nix not found"
      exit 1
    fi

    # Test 2: Configuration directory validation
    echo ""
    echo "Test 2: Configuration directory validation..."

    # Check if configuration directory exists
    if [ -d "${claudeConfigDir}" ]; then
      echo "✅ PASS: Claude configuration directory exists"
    else
      echo "ℹ️  INFO: Configuration directory will be created by home-manager"
    fi

    echo ""
    echo "✅ All Claude Code configuration tests passed!"
    echo ""
    echo "Test Summary:"
    echo "  ✅ Configuration file structure validated"
    echo "  ✅ home.file directives confirmed"
    echo "  ✅ .claude directory references found"
    echo ""
    echo "Claude Code configuration is properly structured!"

    # Cleanup
    cd /
    rm -rf "$TEST_TEMP"
    touch $out
  ''
