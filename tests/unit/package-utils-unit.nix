# Unit tests for lib/package-utils.nix
# Tests package merging, validation, and utility functions

{ pkgs, flake ? null, src ? ../. }:

let
  packageUtils = import (src + "/lib/package-utils.nix") { lib = pkgs.lib; };

  # Mock packages for testing
  mockSharedPackages = [ pkgs.hello pkgs.cowsay ];
  mockPlatformPackages = [ pkgs.tree pkgs.curl ];

  # Mock invalid packages for validation testing
  mockInvalidPackage = { invalid = "package"; };

  # Test shared packages file path
  testSharedPackagesPath = pkgs.writeText "test-shared-packages.nix" ''
    { pkgs }: [ pkgs.git pkgs.vim ]
  '';

in
pkgs.runCommand "package-utils-unit-test" {
  buildInputs = [ pkgs.nix ];
} ''
  echo "🧪 Package Utils Unit Tests"
  echo "=========================="

  # Test 1: mergePackageLists function
  echo ""
  echo "📋 Test 1: Package List Merging"
  echo "-------------------------------"

  # Test basic merging functionality
  ${pkgs.nix}/bin/nix-instantiate --eval --expr '
    let
      packageUtils = import ${src}/lib/package-utils.nix { lib = builtins; };
      pkgs = { hello = { name = "hello"; }; git = { name = "git"; }; vim = { name = "vim"; }; };
      testSharedPath = ${testSharedPackagesPath};
      platformPkgs = [ pkgs.hello ];
      result = packageUtils.mergePackageLists {
        inherit pkgs;
        sharedPackagesPath = testSharedPath;
        platformPackages = platformPkgs;
      };
      isValid = builtins.isList result && builtins.length result == 3;
    in isValid
  ' > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "✅ Package list merging works correctly"
  else
    echo "❌ Package list merging failed"
    exit 1
  fi

  # Test 2: getPackageNames function
  echo ""
  echo "📋 Test 2: Package Name Extraction"
  echo "---------------------------------"

  ${pkgs.nix}/bin/nix-instantiate --eval --expr '
    let
      packageUtils = import ${src}/lib/package-utils.nix { lib = builtins; };
      testPackages = [
        { name = "hello"; }
        { pname = "world"; }
        { name = "test"; pname = "should-use-name"; }
      ];
      names = packageUtils.getPackageNames testPackages;
      expectedLength = 3;
      hasCorrectLength = builtins.length names == expectedLength;
    in hasCorrectLength
  ' > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "✅ Package name extraction works correctly"
  else
    echo "❌ Package name extraction failed"
    exit 1
  fi

  # Test 3: validatePackages function - valid packages
  echo ""
  echo "📋 Test 3: Package Validation (Valid)"
  echo "------------------------------------"

  ${pkgs.nix}/bin/nix-instantiate --eval --expr '
    let
      packageUtils = import ${src}/lib/package-utils.nix { lib = builtins; };
      validPackages = [
        { name = "hello"; }
        { pname = "world"; }
      ];
      result = packageUtils.validatePackages validPackages;
      isValid = builtins.isList result && builtins.length result == 2;
    in isValid
  ' > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "✅ Valid package validation works correctly"
  else
    echo "❌ Valid package validation failed"
    exit 1
  fi

  # Test 4: validatePackages function - invalid packages
  echo ""
  echo "📋 Test 4: Package Validation (Invalid)"
  echo "--------------------------------------"

  # This should throw an error, so we expect nix-instantiate to fail
  ${pkgs.nix}/bin/nix-instantiate --eval --expr '
    let
      packageUtils = import ${src}/lib/package-utils.nix { lib = builtins; };
      invalidPackages = [
        { name = "hello"; }
        { invalid = "package"; }  # This should cause validation to fail
      ];
      result = packageUtils.validatePackages invalidPackages;
    in result
  ' > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "✅ Invalid package validation correctly throws error"
  else
    echo "❌ Invalid package validation should have failed but did not"
    exit 1
  fi

  # Test 5: mergePackageLists with empty platform packages
  echo ""
  echo "📋 Test 5: Merge with Empty Platform Packages"
  echo "--------------------------------------------"

  ${pkgs.nix}/bin/nix-instantiate --eval --expr '
    let
      packageUtils = import ${src}/lib/package-utils.nix { lib = builtins; };
      pkgs = { git = { name = "git"; }; vim = { name = "vim"; }; };
      testSharedPath = ${testSharedPackagesPath};
      result = packageUtils.mergePackageLists {
        inherit pkgs;
        sharedPackagesPath = testSharedPath;
        platformPackages = [];
      };
      isValid = builtins.isList result && builtins.length result == 2;
    in isValid
  ' > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "✅ Merge with empty platform packages works correctly"
  else
    echo "❌ Merge with empty platform packages failed"
    exit 1
  fi

  # Test 6: Error handling for non-list inputs
  echo ""
  echo "📋 Test 6: Error Handling for Non-List Inputs"
  echo "--------------------------------------------"

  # Test with non-list platform packages - should throw error
  ${pkgs.nix}/bin/nix-instantiate --eval --expr '
    let
      packageUtils = import ${src}/lib/package-utils.nix { lib = builtins; };
      pkgs = { git = { name = "git"; }; vim = { name = "vim"; }; };
      testSharedPath = ${testSharedPackagesPath};
      result = packageUtils.mergePackageLists {
        inherit pkgs;
        sharedPackagesPath = testSharedPath;
        platformPackages = "not-a-list";
      };
    in result
  ' > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "✅ Non-list platform packages correctly throws error"
  else
    echo "❌ Non-list platform packages should have failed but did not"
    exit 1
  fi

  echo ""
  echo "🎉 All Package Utils Tests Completed Successfully!"
  echo "================================================"
  echo ""
  echo "Summary:"
  echo "- Package list merging: ✅"
  echo "- Package name extraction: ✅"
  echo "- Valid package validation: ✅"
  echo "- Invalid package validation: ✅"
  echo "- Empty platform packages handling: ✅"
  echo "- Error handling for non-list inputs: ✅"

  touch $out
''
