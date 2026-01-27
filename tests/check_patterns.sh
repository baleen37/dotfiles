#!/usr/bin/env bash

echo "=== Checking unit test files ==="
cd unit || exit
for f in *-test.nix; do
    needs_standardization=false
    reasons=()

    # Check for non-standard helper imports
    if grep -q "testHelpers = import" "$f" 2>/dev/null; then
        needs_standardization=true
        reasons+=("uses testHelpers instead of helpers")
    fi

    # Check for direct pkgs.runCommand usage
    if grep -q "^pkgs\.runCommand" "$f" 2>/dev/null; then
        needs_standardization=true
        reasons+=("uses direct pkgs.runCommand")
    fi

    # Check for nested attribute sets in value
    if grep -q "value = {" "$f" 2>/dev/null && ! grep -q "value = helpers.testSuite" "$f" 2>/dev/null; then
        # Check if it's a nested set (has multiple test-name = ... patterns)
        if grep -E "^\s+\w+\s+=\s+helpers\.assertTest" "$f" 2>/dev/null | head -1 >/dev/null; then
            needs_standardization=true
            reasons+=("uses nested attribute set instead of testSuite")
        fi
    fi

    if $needs_standardization; then
        echo "✗ $f"
        for reason in "${reasons[@]}"; do
            echo "  - $reason"
        done
    else
        echo "✓ $f"
    fi
done

echo ""
echo "=== Checking integration test files ==="
cd ../integration || exit
for f in *-test.nix; do
    needs_standardization=false
    reasons=()

    # Check for non-standard helper imports
    if grep -q "testHelpers = import" "$f" 2>/dev/null; then
        needs_standardization=true
        reasons+=("uses testHelpers instead of helpers")
    fi

    # Check for direct pkgs.runCommand usage
    if grep -q "^pkgs\.runCommand" "$f" 2>/dev/null; then
        needs_standardization=true
        reasons+=("uses direct pkgs.runCommand")
    fi

    # Check for nested attribute sets in value
    if grep -q "value = {" "$f" 2>/dev/null && ! grep -q "value = helpers.testSuite" "$f" 2>/dev/null; then
        if grep -E "^\s+\w+\s+=\s+helpers\.assertTest" "$f" 2>/dev/null | head -1 >/dev/null; then
            needs_standardization=true
            reasons+=("uses nested attribute set instead of testSuite")
        fi
    fi

    if $needs_standardization; then
        echo "✗ $f"
        for reason in "${reasons[@]}"; do
            echo "  - $reason"
        done
    else
        echo "✓ $f"
    fi
done
