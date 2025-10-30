# Makefile Switch Commands Test
#
# Tests for Makefile switch command behavior (Option 3 implementation)
#
# Test Coverage:
# - build-switch uses darwin-rebuild (not home-manager)
# - switch uses darwin-rebuild
# - switch-user uses home-manager
# - All commands have proper USER variable handling

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

    # Test 1: build-switch should use darwin-rebuild on Darwin
    if grep -A 20 "^build-switch:" "$makefileSource" | grep -q "darwin-rebuild"; then
      echo "✅ Test 1 PASS: build-switch uses darwin-rebuild"
    else
      echo "❌ Test 1 FAIL: build-switch should use darwin-rebuild, not home-manager"
      exit 1
    fi

    # Test 2: switch should use darwin-rebuild on Darwin
    if grep -A 20 "^switch:" "$makefileSource" | grep -q "darwin-rebuild"; then
      echo "✅ Test 2 PASS: switch uses darwin-rebuild"
    else
      echo "❌ Test 2 FAIL: switch should use darwin-rebuild"
      exit 1
    fi

    # Test 3: switch-user target should exist
    if grep -q "^switch-user:" "$makefileSource"; then
      echo "✅ Test 3 PASS: switch-user target exists"
    else
      echo "❌ Test 3 FAIL: switch-user target does not exist"
      exit 1
    fi

    # Test 4: switch-user should use home-manager
    if grep -A 10 "^switch-user:" "$makefileSource" | grep -q "home-manager"; then
      echo "✅ Test 4 PASS: switch-user uses home-manager"
    else
      echo "❌ Test 4 FAIL: switch-user should use home-manager"
      exit 1
    fi

    # Test 5: build-switch should NOT use home-manager on Darwin
    if grep -A 20 "^build-switch:" "$makefileSource" | grep "Darwin" | grep -q "home-manager"; then
      echo "❌ Test 5 FAIL: build-switch should not use home-manager on Darwin"
      exit 1
    else
      echo "✅ Test 5 PASS: build-switch does not use home-manager on Darwin"
    fi

    # Test 6: All switch commands should have USER variable handling
    for cmd in "switch" "build-switch" "switch-user"; do
      if grep -A 15 "^$cmd:" "$makefileSource" | grep -q "USER"; then
        echo "✅ Test 6.$cmd PASS: $cmd has USER variable handling"
      else
        echo "❌ Test 6.$cmd FAIL: $cmd missing USER variable handling"
        exit 1
      fi
    done

    # Test 7: switch-user should be in .PHONY
    if grep "^\.PHONY:" "$makefileSource" | grep -q "switch-user"; then
      echo "✅ Test 7 PASS: switch-user is in .PHONY"
    else
      echo "❌ Test 7 FAIL: switch-user should be in .PHONY"
      exit 1
    fi

    echo ""
    echo "All tests passed! ✨"
    touch $out
  ''
