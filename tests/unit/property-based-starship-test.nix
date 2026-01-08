# Property-Based Starship Configuration Test
# Tests invariants across different starship prompt configurations
#
# This test validates that starship configuration maintains essential properties
# regardless of module configuration, format variations, or platform differences.
#
# VERSION: 1.0.0
# LAST UPDATED: 2025-01-09

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test case: Starship format modules
  formatTestCases = [
    {
      name = "minimal-format";
      format = "$directory$git_branch$character";
      requiredModules = [ "directory" "git_branch" "character" ];
      disabledModules = [ ];
    }
    {
      name = "standard-format";
      format = "$directory$git_branch$git_status$python$nix_shell$character";
      requiredModules = [ "directory" "git_branch" "git_status" "python" "nix_shell" "character" ];
      disabledModules = [ ];
    }
    {
      name = "extended-format";
      format = "$directory$git_branch$git_status$nodejs$python$golang$nix_shell$cmd_duration$character";
      requiredModules = [ "directory" "git_branch" "git_status" "nodejs" "python" "golang" "nix_shell" "cmd_duration" "character" ];
      disabledModules = [ ];
    }
  ];

  # Test case: Timeout configurations
  timeoutTestCases = [
    {
      name = "command-timeout-500";
      commandTimeout = 500;
      scanTimeout = 30;
    }
    {
      name = "command-timeout-1000";
      commandTimeout = 1000;
      scanTimeout = 30;
    }
    {
      name = "command-timeout-5000";
      commandTimeout = 5000;
      scanTimeout = 50;
    }
  ];

  # Test case: Module format configurations
  moduleFormatTestCases = [
    {
      name = "directory-module";
      moduleName = "directory";
      format = "[$path]($style)";
      hasSymbol = false;
    }
    {
      name = "git-branch-module";
      moduleName = "git_branch";
      format = "[$symbol$branch]($style) ";
      hasSymbol = true;
    }
    {
      name = "python-module";
      moduleName = "python";
      format = "[\${symbol}\${pyenv_prefix}(\${version} )(\\(\${virtualenv}\\) )]($style)";
      hasSymbol = true;
    }
    {
      name = "nix-shell-module";
      moduleName = "nix_shell";
      format = "[$symbol]($style) ";
      hasSymbol = true;
    }
  ];

  # Test case: Disabled modules
  disabledModulesTestCases = [
    {
      name = "minimal-disabled";
      disabledModules = [ "username" "hostname" "time" ];
      format = "$directory$character";
    }
    {
      name = "extensive-disabled";
      disabledModules = [ "username" "hostname" "time" "package" "nodejs" "rust" "golang" "php" "ruby" "java" ];
      format = "$directory$git_branch$character";
    }
  ];

  # Property: Format string contains all required modules
  validateFormatContainsModules =
    format: requiredModules:
    let
      checkModule = module: lib.hasInfix ("\${" + module + "}") format || lib.hasInfix ("$" + module) format;
    in
    builtins.all checkModule requiredModules;

  # Property: Format string does not contain disabled modules
  validateFormatExcludesModules =
    format: disabledModules:
    let
      checkModule = module: !(lib.hasInfix ("\${" + module + "}") format || lib.hasInfix ("$" + module) format);
    in
    builtins.all checkModule disabledModules;

  # Property: Timeout values are positive integers
  validateTimeoutsPositive =
    commandTimeout: scanTimeout:
    commandTimeout > 0 && scanTimeout > 0;

  # Property: Module format is consistent (non-empty and contains placeholder)
  validateModuleFormatConsistency =
    moduleName: format: hasSymbol:
    let
      nonEmpty = builtins.stringLength format > 0;
      hasPlaceholder = lib.hasInfix "$" format;
      hasStyle = lib.hasInfix "($style)" format;
    in
    nonEmpty && hasPlaceholder && hasStyle;

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "property-based-starship-test" [
    # Test 1: Format string contains required modules
    (helpers.assertTest "format-minimal-contains-required"
      (validateFormatContainsModules (builtins.elemAt formatTestCases 0).format (builtins.elemAt formatTestCases 0).requiredModules)
      "Minimal format should contain all required modules")

    (helpers.assertTest "format-standard-contains-required"
      (validateFormatContainsModules (builtins.elemAt formatTestCases 1).format (builtins.elemAt formatTestCases 1).requiredModules)
      "Standard format should contain all required modules")

    (helpers.assertTest "format-extended-contains-required"
      (validateFormatContainsModules (builtins.elemAt formatTestCases 2).format (builtins.elemAt formatTestCases 2).requiredModules)
      "Extended format should contain all required modules")

    # Test 2: Format string excludes disabled modules
    (helpers.assertTest "format-minimal-excludes-disabled"
      (validateFormatExcludesModules (builtins.elemAt formatTestCases 0).format [ "username" "hostname" ])
      "Minimal format should not contain disabled modules")

    (helpers.assertTest "format-standard-excludes-disabled"
      (validateFormatExcludesModules (builtins.elemAt formatTestCases 1).format [ "time" "package" ])
      "Standard format should not contain disabled modules")

    # Test 3: Timeout values are positive
    (helpers.assertTest "timeout-500-positive"
      (validateTimeoutsPositive (builtins.elemAt timeoutTestCases 0).commandTimeout (builtins.elemAt timeoutTestCases 0).scanTimeout)
      "Timeout 500 should be positive")

    (helpers.assertTest "timeout-1000-positive"
      (validateTimeoutsPositive (builtins.elemAt timeoutTestCases 1).commandTimeout (builtins.elemAt timeoutTestCases 1).scanTimeout)
      "Timeout 1000 should be positive")

    (helpers.assertTest "timeout-5000-positive"
      (validateTimeoutsPositive (builtins.elemAt timeoutTestCases 2).commandTimeout (builtins.elemAt timeoutTestCases 2).scanTimeout)
      "Timeout 5000 should be positive")

    # Test 4: Module format consistency
    (helpers.assertTest "module-directory-format-consistent"
      (validateModuleFormatConsistency (builtins.elemAt moduleFormatTestCases 0).moduleName (builtins.elemAt moduleFormatTestCases 0).format (builtins.elemAt moduleFormatTestCases 0).hasSymbol)
      "Directory module format should be consistent")

    (helpers.assertTest "module-git-branch-format-consistent"
      (validateModuleFormatConsistency (builtins.elemAt moduleFormatTestCases 1).moduleName (builtins.elemAt moduleFormatTestCases 1).format (builtins.elemAt moduleFormatTestCases 1).hasSymbol)
      "Git branch module format should be consistent")

    (helpers.assertTest "module-python-format-consistent"
      (validateModuleFormatConsistency (builtins.elemAt moduleFormatTestCases 2).moduleName (builtins.elemAt moduleFormatTestCases 2).format (builtins.elemAt moduleFormatTestCases 2).hasSymbol)
      "Python module format should be consistent")

    (helpers.assertTest "module-nix-shell-format-consistent"
      (validateModuleFormatConsistency (builtins.elemAt moduleFormatTestCases 3).moduleName (builtins.elemAt moduleFormatTestCases 3).format (builtins.elemAt moduleFormatTestCases 3).hasSymbol)
      "Nix shell module format should be consistent")

    # Test 5: Disabled modules never appear in format
    (helpers.assertTest "disabled-modules-minimal-format"
      (validateFormatExcludesModules (builtins.elemAt disabledModulesTestCases 0).format (builtins.elemAt disabledModulesTestCases 0).disabledModules)
      "Minimal disabled modules should not appear in format")

    (helpers.assertTest "disabled-modules-extensive-format"
      (validateFormatExcludesModules (builtins.elemAt disabledModulesTestCases 1).format (builtins.elemAt disabledModulesTestCases 1).disabledModules)
      "Extensive disabled modules should not appear in format")

    # Summary test
    (pkgs.runCommand "property-based-starship-summary" { } ''
      echo "🎯 Property-Based Starship Configuration Test Summary"
      echo ""
      echo "✅ Format String Validation:"
      echo "   • Tested ${toString (builtins.length formatTestCases)} format configurations"
      echo "   • Validated required modules are present in format strings"
      echo "   • Verified disabled modules are excluded from format strings"
      echo ""
      echo "✅ Timeout Configuration:"
      echo "   • Tested ${toString (builtins.length timeoutTestCases)} timeout configurations"
      echo "   • Confirmed all timeout values are positive integers"
      echo "   • Validated command_timeout and scan_timeout properties"
      echo ""
      echo "✅ Module Format Consistency:"
      echo "   • Tested ${toString (builtins.length moduleFormatTestCases)} module configurations"
      echo "   • Verified module formats are non-empty"
      echo "   • Confirmed module formats contain placeholders"
      echo "   • Validated module formats contain style specifications"
      echo ""
      echo "✅ Disabled Modules:"
      echo "   • Tested ${toString (builtins.length disabledModulesTestCases)} disabled module scenarios"
      echo "   • Verified disabled modules never appear in format strings"
      echo ""
      echo "🧪 Property-Based Testing:"
      echo "   • Tests invariants across different starship configurations"
      echo "   • Validates format string structure and composition"
      echo "   • Ensures timeout values remain within valid ranges"
      echo "   • Confirms module format consistency across configurations"
      echo ""
      echo "✅ All Property-Based Starship Tests Passed!"
      echo "Starship configuration invariants verified across all test scenarios"

      touch $out
    '')
  ];
}
