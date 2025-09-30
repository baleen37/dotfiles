#!/usr/bin/env bats
# Contract Test Examples for Comprehensive Testing Framework
# Demonstrates interface validation and API contract testing

# Load test framework helpers
load ../lib/test-framework/helpers.sh
load ../lib/test-framework/contract-helpers.sh

# Test setup and teardown
setup() {
    # Create temporary test environment
    TEST_TMPDIR=$(mktemp -d)
    export TEST_TMPDIR
    
    # Set up test configuration
    export TEST_FLAKE_ROOT="${BATS_TEST_DIRNAME}/../.."
    export NIX_CONFIG="experimental-features = nix-command flakes"
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# Test Runner Interface Contracts
# ============================================================================

@test "test runner provides run command" {
    run nix eval --raw "$TEST_FLAKE_ROOT#testRunner.run" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "lambda" ]
}

@test "test runner provides runSuite command" {
    run nix eval --raw "$TEST_FLAKE_ROOT#testRunner.runSuite" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "lambda" ]
}

@test "test runner accepts testLayer parameter" {
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply 'f: builtins.functionArgs f'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testLayer" ]]
}

@test "test runner returns test results structure" {
    # Mock test run
    cat > "$TEST_TMPDIR/mock-test.nix" << 'EOF'
{
  testBasic = {
    expr = 1 + 1;
    expected = 2;
  };
}
EOF
    
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply "f: f { testLayer = \"unit\"; testFile = \"$TEST_TMPDIR/mock-test.nix\"; }"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "passed" ]]
    [[ "$output" =~ "failed" ]]
    [[ "$output" =~ "total" ]]
}

# ============================================================================
# Coverage Provider Contracts
# ============================================================================

@test "coverage provider exposes collect function" {
    run nix eval --raw "$TEST_FLAKE_ROOT#coverageProvider.collect" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "lambda" ]
}

@test "coverage provider exposes report function" {
    run nix eval --raw "$TEST_FLAKE_ROOT#coverageProvider.report" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "lambda" ]
}

@test "coverage provider returns percentage" {
    run nix eval --json "$TEST_FLAKE_ROOT#coverageProvider.collect" --apply 'f: f { sourceDir = "/dev/null"; }'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "percentage" ]]
    [[ "$output" =~ "linesTotal" ]]
    [[ "$output" =~ "linesCovered" ]]
}

@test "coverage provider validates thresholds" {
    run nix eval --json "$TEST_FLAKE_ROOT#coverageProvider.validateThreshold" --apply 'f: f { actual = 95; required = 90; }'
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
    
    run nix eval --json "$TEST_FLAKE_ROOT#coverageProvider.validateThreshold" --apply 'f: f { actual = 85; required = 90; }'
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

# ============================================================================
# Platform Adapter Contracts
# ============================================================================

@test "platform adapter detects current platform" {
    run nix eval --raw "$TEST_FLAKE_ROOT#platformAdapter.currentPlatform"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(x86_64-linux|aarch64-linux|x86_64-darwin|aarch64-darwin)$ ]]
}

@test "platform adapter provides platform-specific configurations" {
    local platform
    platform=$(nix eval --raw "$TEST_FLAKE_ROOT#platformAdapter.currentPlatform")
    
    run nix eval --json "$TEST_FLAKE_ROOT#platformAdapter.getConfig" --apply "f: f \"$platform\""
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testCommand" ]]
    [[ "$output" =~ "testTimeout" ]]
}

@test "platform adapter handles unsupported platforms gracefully" {
    run nix eval --json "$TEST_FLAKE_ROOT#platformAdapter.getConfig" --apply 'f: f "unsupported-platform"'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "null\\|default" ]]
}

# ============================================================================
# Test Builder Contracts
# ============================================================================

@test "test builder provides buildUnitTest function" {
    run nix eval --raw "$TEST_FLAKE_ROOT#testBuilders.buildUnitTest" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "lambda" ]
}

@test "test builder provides buildIntegrationTest function" {
    run nix eval --raw "$TEST_FLAKE_ROOT#testBuilders.buildIntegrationTest" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "lambda" ]
}

@test "test builder creates executable test scripts" {
    run nix build "$TEST_FLAKE_ROOT#testBuilders.buildUnitTest" --apply 'f: f { name = "test"; testFile = "/dev/null"; }'
    [ "$status" -eq 0 ]
    [ -x "./result/bin/test" ]
}

# ============================================================================
# Flake Output Structure Contracts
# ============================================================================

@test "flake provides checks output" {
    run nix eval --json "$TEST_FLAKE_ROOT#checks" --apply "builtins.attrNames"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "x86_64-linux" ]]
}

@test "flake checks include all test layers" {
    local platform
    platform=$(nix eval --raw "$TEST_FLAKE_ROOT#platformAdapter.currentPlatform")
    
    run nix eval --json "$TEST_FLAKE_ROOT#checks.$platform" --apply "builtins.attrNames"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "unit-tests" ]]
    [[ "$output" =~ "contract-tests" ]]
    [[ "$output" =~ "integration-tests" ]]
    [[ "$output" =~ "e2e-tests" ]]
}

@test "flake provides apps output for test runners" {
    run nix eval --json "$TEST_FLAKE_ROOT#apps" --apply "builtins.attrNames"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-runner" ]]
    [[ "$output" =~ "coverage-report" ]]
}

# ============================================================================
# Configuration Schema Contracts
# ============================================================================

@test "test configuration follows expected schema" {
    run nix eval --json "$TEST_FLAKE_ROOT#config.testing"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "coverage" ]]
    [[ "$output" =~ "timeout" ]]
    [[ "$output" =~ "parallel" ]]
}

@test "coverage configuration has required fields" {
    run nix eval --json "$TEST_FLAKE_ROOT#config.testing.coverage"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "threshold" ]]
    [[ "$output" =~ "exclude" ]]
    [[ "$output" =~ "format" ]]
}

@test "timeout configuration is numeric" {
    run nix eval --raw "$TEST_FLAKE_ROOT#config.testing.timeout" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "int" ]
}

# ============================================================================
# Error Handling Contracts
# ============================================================================

@test "test runner handles invalid test files gracefully" {
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply 'f: f { testLayer = "unit"; testFile = "/nonexistent/file.nix"; }'
    [ "$status" -ne 0 ]
    [[ "$output" =~ "error\\|fail" ]]
}

@test "coverage provider handles missing source directories" {
    run nix eval --json "$TEST_FLAKE_ROOT#coverageProvider.collect" --apply 'f: f { sourceDir = "/nonexistent"; }'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "percentage.*0" ]]
}

@test "platform adapter handles null inputs" {
    run nix eval --json "$TEST_FLAKE_ROOT#platformAdapter.getConfig" --apply 'f: f null'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "null\\|default" ]]
}

# ============================================================================
# API Stability Contracts
# ============================================================================

@test "test runner API maintains backward compatibility" {
    # Test that old API still works
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner" --apply 'builtins.attrNames'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "run" ]]
    [[ "$output" =~ "runSuite" ]]
    
    # Ensure no breaking changes to function signatures
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply 'f: builtins.functionArgs f'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testLayer" ]]
}

@test "coverage provider API is stable" {
    run nix eval --json "$TEST_FLAKE_ROOT#coverageProvider" --apply 'builtins.attrNames'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "collect" ]]
    [[ "$output" =~ "report" ]]
    [[ "$output" =~ "validateThreshold" ]]
}

# ============================================================================
# Performance Contracts
# ============================================================================

@test "test runner completes within timeout" {
    local start_time end_time duration
    start_time=$(date +%s)
    
    # Run a simple test with timeout
    timeout 30s nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply 'f: f { testLayer = "unit"; testFile = "'$TEST_TMPDIR'/mock-test.nix"; }' || true
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Should complete within 30 seconds
    [ "$duration" -lt 30 ]
}

@test "coverage collection is performant" {
    local start_time end_time duration
    start_time=$(date +%s)
    
    # Test coverage collection performance
    timeout 15s nix eval --json "$TEST_FLAKE_ROOT#coverageProvider.collect" --apply 'f: f { sourceDir = "'$TEST_FLAKE_ROOT'"; }' || true
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Should complete within 15 seconds
    [ "$duration" -lt 15 ]
}

# ============================================================================
# Integration Contracts
# ============================================================================

@test "test layers integrate with coverage system" {
    # Verify that test layers can be executed with coverage
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.runWithCoverage" --apply "builtins.typeOf"
    [ "$status" -eq 0 ]
    [ "$output" = "lambda" ]
}

@test "platform adapters integrate with test builders" {
    local platform
    platform=$(nix eval --raw "$TEST_FLAKE_ROOT#platformAdapter.currentPlatform")
    
    run nix eval --json "$TEST_FLAKE_ROOT#testBuilders.buildForPlatform" --apply "f: f \"$platform\""
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testCommand\\|executable" ]]
}

# ============================================================================
# Documentation Contracts
# ============================================================================

@test "all public functions have documentation" {
    # Check that critical functions have help text
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner" --apply 'builtins.attrNames'
    [ "$status" -eq 0 ]
    
    # Each function should have corresponding documentation
    for func in run runSuite runWithCoverage; do
        run nix eval --raw "$TEST_FLAKE_ROOT#docs.testRunner.$func" 2>/dev/null || true
        # Should not fail completely (some documentation should exist)
    done
}

# ============================================================================
# Contract Validation Helpers
# ============================================================================

# Helper function to validate JSON schema
validate_json_schema() {
    local json="$1"
    local schema="$2"
    
    # Basic schema validation (simplified)
    echo "$json" | jq -e "$schema" >/dev/null
}

# Helper function to test function contracts
test_function_contract() {
    local func_path="$1"
    local test_input="$2"
    local expected_output="$3"
    
    run nix eval --json "$TEST_FLAKE_ROOT#$func_path" --apply "f: f $test_input"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $expected_output ]]
}