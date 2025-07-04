# TDD Test for Apply Script Deduplication
# Tests that apply scripts can be deduplicated without losing functionality

{ pkgs, ... }:

let
  # Test that all apply scripts have the same core functions
  testApplyScriptDeduplication = pkgs.runCommand "test-apply-script-deduplication" {
    buildInputs = [ pkgs.bash pkgs.gnugrep ];
  } ''
    # Test 1: Verify current duplication exists (Red Phase)
    echo "=== Testing Apply Script Deduplication ==="

    # Count total lines across all apply scripts
    TOTAL_LINES=$(wc -l ${../../apps/aarch64-darwin/apply} ${../../apps/x86_64-darwin/apply} ${../../apps/aarch64-linux/apply} ${../../apps/x86_64-linux/apply} | tail -1 | awk '{print $1}')
    echo "Current total lines: $TOTAL_LINES"

    # Target: Reduce to ~200 lines total (85% reduction from 656)
    TARGET_LINES=200

    if [ "$TOTAL_LINES" -gt "$TARGET_LINES" ]; then
      echo "✅ RED: Duplication exists ($TOTAL_LINES > $TARGET_LINES)"
    else
      echo "❌ No duplication to fix"
      exit 1
    fi

    # Test 2: Identify common functions that should be extracted
    echo "=== Identifying Common Functions ==="

    # Check for color code duplication
    for script in ${../../apps/aarch64-darwin/apply} ${../../apps/x86_64-darwin/apply} ${../../apps/aarch64-linux/apply} ${../../apps/x86_64-linux/apply}; do
      if grep -q "RED=.*0;31" "$script"; then
        echo "✅ Found color codes in $(basename $(dirname $script))"
      else
        echo "❌ Missing color codes in $(basename $(dirname $script))"
        exit 1
      fi
    done

    # Check for _print function duplication
    for script in ${../../apps/aarch64-darwin/apply} ${../../apps/x86_64-darwin/apply} ${../../apps/aarch64-linux/apply} ${../../apps/x86_64-linux/apply}; do
      if grep -q "_print()" "$script"; then
        echo "✅ Found _print function in $(basename $(dirname $script))"
      else
        echo "❌ Missing _print function in $(basename $(dirname $script))"
        exit 1
      fi
    done

    # Check for _prompt function duplication
    for script in ${../../apps/aarch64-darwin/apply} ${../../apps/x86_64-darwin/apply} ${../../apps/aarch64-linux/apply} ${../../apps/x86_64-linux/apply}; do
      if grep -q "_prompt()" "$script"; then
        echo "✅ Found _prompt function in $(basename $(dirname $script))"
      else
        echo "❌ Missing _prompt function in $(basename $(dirname $script))"
        exit 1
      fi
    done

    # Test 3: Verify platform-specific differences that should be preserved
    echo "=== Identifying Platform Differences ==="

    # Darwin vs Linux OS detection
    for script in ${../../apps/aarch64-darwin/apply} ${../../apps/x86_64-darwin/apply}; do
      if grep -q 'OS.*Darwin' "$script"; then
        echo "✅ Found Darwin OS detection in $(basename $(dirname $script))"
      fi
    done

    for script in ${../../apps/aarch64-linux/apply} ${../../apps/x86_64-linux/apply}; do
      if grep -q 'PRIMARY_IFACE' "$script"; then
        echo "✅ Found Linux network interface detection in $(basename $(dirname $script))"
      fi
    done

    # Test 4: Check for ask_for_star function (only in some scripts)
    if grep -q "ask_for_star" ${../../apps/x86_64-darwin/apply}; then
      echo "✅ Found ask_for_star in x86_64-darwin (expected difference)"
    fi

    if grep -q "ask_for_star" ${../../apps/x86_64-linux/apply}; then
      echo "✅ Found ask_for_star in x86_64-linux (expected difference)"
    fi

    echo "✅ Apply script deduplication analysis completed"
    echo "Target: Extract common functions to reduce $TOTAL_LINES lines to ~$TARGET_LINES lines"

    touch $out
  '';

in testApplyScriptDeduplication
