# Extended test helpers for evantravers refactor
# Migrated to use unified-test-helpers.nix for backward compatibility
{
  pkgs,
  lib,
  # Parameterized test configuration to eliminate external dependencies
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
      isLinux = pkgs.stdenv.isLinux;
    };
  },
}:

let
  # Import unified test helpers
  unifiedHelpers = import ./unified-test-helpers.nix {
    inherit pkgs lib;
    inherit testConfig;
  };

  # Import existing NixTest framework
  nixtest = import ../unit/nixtest-template.nix { inherit pkgs lib; };
in

# Re-export everything from unified helpers for backward compatibility
unifiedHelpers // {
  # Re-export NixTest framework
  inherit (nixtest) nixtest;

  # Additional functions that were specific to this file

  # Configuration file integrity test (behavioral)
  assertConfigIntegrity =
    name: configPath: expectedFiles:
    nixtest.test "config-integrity-${name}" (
      builtins.all (
        file:
        let
          fullPath = "${configPath}/${file}";
          readResult = builtins.tryEval (builtins.readFile fullPath);
        in
        readResult.success && builtins.stringLength readResult.value > 0
      ) expectedFiles
    );

  # System factory validation
  assertSystemFactory =
    name: systemConfig:
    nixtest.suite "system-factory-${name}" {
      hasConfig = nixtest.test "has config attribute" (
        nixtest.assertions.assertHasAttr "config" systemConfig
      );
      hasSpecialArgs = nixtest.test "has special args" (
        nixtest.assertions.assertHasAttr "_module" systemConfig
      );
    };

  # Create parameterized test configuration for modules that require currentSystemUser
  createModuleTestConfig = moduleConfig: {
    currentSystemUser = testConfig.username;
    config = moduleConfig;
  };

  # Generate multiple test configurations for different users
  generateUserTests =
    testFunction: users:
    builtins.listToAttrs (
      map (user: {
        name = "user-${user}";
        value = testFunction {
          username = user;
          homeDirectory = "${testConfig.homeDirPrefix}/${user}";
        };
      }) users
    );

  # Run a list of tests and aggregate results
  runTestList =
    testName: tests:
    pkgs.runCommand "test-${testName}" { } ''
      echo "🧪 Running test suite: ${testName}"
      echo ""

      # Track overall success
      overall_success=true

      # Run each test
      ${lib.concatMapStringsSep "\n" (test: ''
        echo "🔍 Running test: ${test.name}"
        echo "  Expected: ${toString test.expected}"
        echo "  Actual: ${toString test.actual}"

        if [ "${toString test.expected}" = "${toString test.actual}" ]; then
          echo "  ✅ PASS: ${test.name}"
        else
          echo "  ❌ FAIL: ${test.name}"
          echo "    Expected: ${toString test.expected}"
          echo "    Actual: ${toString test.actual}"
          overall_success=false
        fi
        echo ""
      '') tests}

      # Final result
      if [ "$overall_success" = "true" ]; then
        echo "✅ All tests in '${testName}' passed!"
        touch $out
      else
        echo "❌ Some tests in '${testName}' failed!"
        exit 1
      fi
    '';
}
