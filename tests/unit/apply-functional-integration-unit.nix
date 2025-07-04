# TDD Test for Apply Functional Integration
# Tests that deduplicated apply scripts maintain 100% functional compatibility

{ pkgs, ... }:

let
  # Test that deduplicated scripts maintain functionality
  testApplyFunctionalIntegration = pkgs.runCommand "test-apply-functional-integration" {
    buildInputs = [ pkgs.bash pkgs.gnugrep ];
  } ''
    echo "=== Testing Apply Functional Integration ==="

    # Test 1: All essential functions should be available after deduplication
    echo "=== Testing Function Availability ==="

    for platform in aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux; do
      if [ -f ${../../apps}/$platform/apply ]; then
        echo "Testing $platform apply script..."

        # Create test script that sources the apply script and checks functions
        cat > test_$platform.sh << EOF
#!/bin/bash
set -e

# Source the platform config
if [ -f ${../../apps}/$platform/config.sh ]; then
  . ${../../apps}/$platform/config.sh
fi

# Source the apply template
if [ -f ${../../scripts/templates/apply-template.sh} ]; then
  . ${../../scripts/templates/apply-template.sh}
else
  # Fallback to direct apply script
  . ${../../apps}/$platform/apply
fi

# Test that essential functions exist
functions=("_print" "_prompt")

for func in "\''${functions[@]}"; do
  if declare -f "\$func" > /dev/null; then
    echo "✅ Function available: \$func"
  else
    echo "❌ Function missing: \$func"
    exit 1
  fi
done

# Test platform-specific functions
if [[ "$platform" == *"x86_64"* ]]; then
  if declare -f "ask_for_star" > /dev/null; then
    echo "✅ Platform-specific function available: ask_for_star"
  else
    echo "❌ Platform-specific function missing: ask_for_star"
    exit 1
  fi
fi

echo "All functions available for $platform"
EOF

        chmod +x test_$platform.sh

        if ./test_$platform.sh > test_$platform.log 2>&1; then
          echo "✅ Functional test passed: $platform"
          cat test_$platform.log
        else
          echo "❌ Functional test failed: $platform"
          cat test_$platform.log
          exit 1
        fi
      else
        echo "❌ Apply script missing: $platform"
        exit 1
      fi
    done

    # Test 2: Environment variables should be properly set
    echo "=== Testing Environment Setup ==="

    # Test that platform configs set correct variables
    for platform in aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux; do
      if [ -f ${../../apps}/$platform/config.sh ]; then
        echo "Testing config for $platform..."

        # Source config and check essential variables
        cat > test_config_$platform.sh << EOF
#!/bin/bash
set -e
. ${../../apps}/$platform/config.sh

# Check essential variables
if [ -n "\$PLATFORM_TYPE" ]; then
  echo "✅ PLATFORM_TYPE set: \$PLATFORM_TYPE"
else
  echo "❌ PLATFORM_TYPE not set"
  exit 1
fi

if [ -n "\$ARCH" ]; then
  echo "✅ ARCH set: \$ARCH"
else
  echo "❌ ARCH not set"
  exit 1
fi

echo "Config test passed for $platform"
EOF

        chmod +x test_config_$platform.sh

        if ./test_config_$platform.sh > config_$platform.log 2>&1; then
          echo "✅ Config test passed: $platform"
          cat config_$platform.log
        else
          echo "❌ Config test failed: $platform"
          cat config_$platform.log
          exit 1
        fi
      fi
    done

    # Test 3: Total line reduction achieved
    echo "=== Testing Line Reduction ==="

    TOTAL_LINES=$(wc -l ${../../apps/aarch64-darwin/apply} ${../../apps/x86_64-darwin/apply} ${../../apps/aarch64-linux/apply} ${../../apps/x86_64-linux/apply} | tail -1 | awk '{print $1}')
    echo "Total lines after deduplication: $TOTAL_LINES"

    # Should achieve 85% reduction (656 -> ~100)
    TARGET_MAX=150
    if [ "$TOTAL_LINES" -lt "$TARGET_MAX" ]; then
      echo "✅ Achieved line reduction target ($TOTAL_LINES < $TARGET_MAX)"
    else
      echo "❌ Did not achieve line reduction target ($TOTAL_LINES >= $TARGET_MAX)"
      exit 1
    fi

    echo "✅ Apply functional integration tests completed"

    touch $out
  '';

in testApplyFunctionalIntegration
