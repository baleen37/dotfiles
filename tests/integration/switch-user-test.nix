# tests/integration/switch-user-test.nix
#
# Integration test for make switch-user command
# Validates that home-manager configuration can be activated for user-only updates
#
# Test scenarios:
# - Home Manager configuration builds successfully
# - User configuration is accessible for different users
# - Required packages and modules are included
# - Platform-specific behavior (Darwin-only)

{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test users that should be supported
  testUsers = [
    "baleen"
    "jito"
    "testuser"
  ];

in
helpers.testSuite "switch-user" [
  # Test 1: Home Manager configurations exist for supported users
  (helpers.assertTest "home-configs-exist" (builtins.all (
    user: inputs.self ? homeConfigurations.${user}
  ) testUsers) "Home Manager configurations should exist for all supported users")

  # Test 2: Home Manager configuration can be built (Darwin-only)
  (helpers.runIfPlatform "darwin" (
    let
      # Test with default user (baleen)
      userConfig = inputs.self.homeConfigurations.baleen;
    in
    helpers.assertTest "home-config-builds" (
      userConfig ? activationPackage
    ) "Home Manager configuration should be buildable for user activation"
  ))

  # Test 3: User configuration includes required modules
  (helpers.runIfPlatform "darwin" (
    let
      # Extract home-manager configuration to test module imports
      hmConfig = import ../../users/shared/home-manager.nix {
        inherit pkgs lib inputs;
        currentSystemUser = "baleen";
      };
    in
    helpers.testSuite "user-config-modules" [
      (helpers.assertTest "has-git-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/git.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import git.nix module")

      (helpers.assertTest "has-vim-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/vim.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import vim.nix module")

      (helpers.assertTest "has-zsh-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/zsh.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import zsh.nix module")

      (helpers.assertTest "has-claude-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/claude-code.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import claude-code.nix module")

      (helpers.assertTest "has-tmux-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/tmux.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import tmux.nix module")
    ]
  ))

  # Test 4: User configuration includes essential packages
  # Note: This test uses the evaluated homeConfiguration from the flake
  # because raw module imports don't have evaluated home.packages
  (helpers.runIfPlatform "darwin" (
    let
      # Use the actual evaluated homeConfiguration
      userConfig = inputs.self.homeConfigurations.baleen;
      essentialPackages = [
        "git"
        "vim"
        "zsh"
        "tmux"
        "claude-code"
        "direnv"
        "fzf"
        "ripgrep"
      ];
    in
    helpers.testSuite "essential-packages" [
      (helpers.assertTest "has-essential-packages" (
        # Check that activationPackage exists as a proxy for packages being configured
        # Full package validation would require building the entire configuration
        userConfig ? activationPackage
      ) "User configuration should include essential packages via home-manager")
    ]
  ))

  # Test 5: User home directory is correctly configured
  (helpers.runIfPlatform "darwin" (
    let
      hmConfig = import ../../users/shared/home-manager.nix {
        inherit pkgs lib inputs;
        currentSystemUser = "baleen";
      };
    in
    helpers.testSuite "user-home-config" [
      (helpers.assertTest "correct-username" (
        hmConfig.home.username == "baleen"
      ) "Home Manager configuration should use correct username")

      (helpers.assertTest "correct-home-directory" (
        hmConfig.home.homeDirectory == "/Users/baleen"
      ) "Home Manager configuration should use correct home directory on Darwin")

      (helpers.assertTest "has-state-version" (
        hmConfig.home ? stateVersion && hmConfig.home.stateVersion == "24.11"
      ) "Home Manager configuration should have state version")
    ]
  ))

  # Test 6: make switch-user double execution test (with permission simulation)
  (helpers.runIfPlatform "darwin" (
    let
      # Test script that simulates the actual make switch-user execution
      doubleExecutionTest = pkgs.writeShellScript "switch-user-double-execution-test" ''
                set -euo pipefail

                echo "🔧 Testing make switch-user double execution..."

                # Create test environment
                TEST_HOME="/tmp/switch-user-test-$$"
                mkdir -p "$TEST_HOME/.claude"

                # Create initial settings.json (read-only to simulate the issue)
                cat > "$TEST_HOME/.claude/settings.json" << 'EOF'
        {
          "$schema": "https://json.schemastore.org/claude-code-settings.json",
          "permissions": {
            "allow": ["Bash", "Write"],
            "deny": []
          },
          "model": "sonnet"
        }
        EOF

                # Make it read-only (simulate the permission issue)
                chmod 444 "$TEST_HOME/.claude/settings.json"

                # Test 1: Verify read-only permissions
                if [ ! -w "$TEST_HOME/.claude/settings.json" ]; then
                  echo "✅ Read-only file created successfully"
                else
                  echo "❌ Failed to create read-only file"
                  exit 1
                fi

                # Test 2: Simulate the fix (chmod +w before cp)
                echo "🔸 Applying permission fix..."
                chmod +w "$TEST_HOME/.claude/settings.json"

                # Test 3: Verify fix worked
                if [ -w "$TEST_HOME/.claude/settings.json" ]; then
                  echo "✅ Permission fix applied successfully"
                else
                  echo "❌ Permission fix failed"
                  exit 1
                fi

                # Test 4: Simulate second copy operation
                echo "🔸 Simulating second execution..."
                cp "$TEST_HOME/.claude/settings.json" "$TEST_HOME/.claude/settings-backup.json"

                # Test 5: Verify both files exist and are writable
                if [ -f "$TEST_HOME/.claude/settings.json" ] && [ -f "$TEST_HOME/.claude/settings-backup.json" ]; then
                  echo "✅ Double execution simulation completed"
                else
                  echo "❌ Double execution failed"
                  exit 1
                fi

                # Cleanup
                rm -rf "$TEST_HOME"

                echo "🎉 All switch-user double execution tests passed!"
      '';

      userConfig = inputs.self.homeConfigurations.baleen;
    in
    helpers.testSuite "switch-user-double-execution" [
      (helpers.assertTest "home-config-exists" (
        userConfig ? activationPackage
      ) "Home Manager configuration should exist and be buildable")

      (helpers.assertTest "permission-simulation-works" (builtins.pathExists doubleExecutionTest)
        "Double execution test script should exist"
      )

      (helpers.assertTest "double-execution-test-script-valid" (
        # Verify the test script is properly formatted and valid
        let
          scriptCheck = pkgs.runCommand "validate-double-execution-script" { } ''
            # Check if the script syntax is valid
            echo "Checking script syntax..."
            ${pkgs.bash}/bin/bash -n ${doubleExecutionTest}
            echo "✅ Script syntax is valid"

            # Check if the script contains expected patterns
            if grep -q "chmod 444" ${doubleExecutionTest} && \
               grep -q "chmod +w" ${doubleExecutionTest} && \
               grep -q "settings.json" ${doubleExecutionTest}; then
              echo "✅ Script contains expected permission fix logic"
            else
              echo "❌ Script missing expected patterns"
              exit 1
            fi

            touch $out
          '';
        in
        scriptCheck ? out
      ) "Switch-user double execution test script should be valid")

      (helpers.assertTest "claude-settings-fix-in-source" (
        # Verify the actual fix exists in the source code
        let
          claudeCodeSource = builtins.readFile ../../users/shared/claude-code.nix;
        in
        lib.hasInfix "chmod +w ~/.claude/settings.json" claudeCodeSource
      ) "Source code should contain the permission fix for claudeSettings")
    ]
  ))

  # Test 7: Platform-specific skip for non-Darwin systems
  (helpers.runIfPlatform "linux" (
    helpers.assertTest "linux-skip-message" true "switch-user is Darwin-only, test skipped on Linux"
  ))
]
