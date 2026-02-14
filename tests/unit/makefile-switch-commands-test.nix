# Makefile Switch Commands Test
#
# Tests for Makefile switch command behavior
#
# Test Coverage:
# - build-switch uses nix-darwin via dependency on switch (not home-manager)
# - switch uses nix-darwin
# - build-switch and switch do not use home-manager on Darwin
# - All commands have proper USER variable handling
# - switch is in .PHONY

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  inputs ? { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  makefilePath = ../../Makefile;

in
pkgs.runCommand "makefile-switch-commands-test"
  {
    buildInputs = [
      pkgs.gnumake
      pkgs.gnugrep
    ];
    makefileSource = makefilePath;
  }
  ''
    echo "Testing Makefile switch commands (Option 3)"

    # Test 1: build-switch should use nix-darwin on Darwin (via dependency on switch)
    # build-switch depends on switch, and switch contains nix-darwin command
    if (grep -A 5 "^build-switch:" "$makefileSource" | grep -q "switch") &&
       (grep -A 20 "^switch:" "$makefileSource" | grep -q "nix-darwin"); then
      echo "✅ Test 1 PASS: build-switch uses nix-darwin via dependency on switch"
    else
      echo "❌ Test 1 FAIL: build-switch should depend on switch which uses nix-darwin"
      exit 1
    fi

    # Test 2: switch should use nix-darwin on Darwin
    if grep -A 20 "^switch:" "$makefileSource" | grep -q "nix-darwin"; then
      echo "✅ Test 2 PASS: switch uses nix-darwin"
    else
      echo "❌ Test 2 FAIL: switch should use nix-darwin"
      exit 1
    fi

    # Test 3: build-switch should NOT use home-manager (check via switch dependency)
    # build-switch should use nix-darwin, not home-manager
    # Use awk to extract only the switch target (stop at next target or blank line)
    if (awk '/^switch:/{p=1} p && /^[a-z-]+:/ && !/^switch:/{exit} p' "$makefileSource" | grep -q "home-manager"); then
      echo "❌ Test 3 FAIL: switch (used by build-switch) should not use home-manager on Darwin"
      exit 1
    else
      echo "✅ Test 3 PASS: build-switch does not use home-manager on Darwin"
    fi

    # Test 4: All switch commands should have USER variable handling
    for cmd in "switch" "build-switch"; do
      if grep -A 15 "^$cmd:" "$makefileSource" | grep -q "USER"; then
        echo "✅ Test 4.$cmd PASS: $cmd has USER variable handling"
      else
        echo "❌ Test 4.$cmd FAIL: $cmd missing USER variable handling"
        exit 1
      fi
    done

    # Test 5: switch should be in .PHONY (build-switch is not in .PHONY by design)
    if grep "^\.PHONY:" "$makefileSource" | grep -q "switch"; then
      echo "✅ Test 5 PASS: switch is in .PHONY"
    else
      echo "❌ Test 5 FAIL: switch should be in .PHONY"
      exit 1
    fi

    echo ""
    echo "All tests passed! ✨"
    touch $out
  ''
