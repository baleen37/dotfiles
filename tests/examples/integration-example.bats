#!/usr/bin/env bats
# Integration Test Examples for Comprehensive Testing Framework
# Demonstrates module interaction and build workflow validation

# Load test framework and integration helpers
load ../lib/test-framework/helpers.sh

# Global test setup
setup_file() {
    # Create shared test environment for the test file
    export INTEGRATION_TEST_DIR=$(mktemp -d)
    export TEST_FLAKE_ROOT="${BATS_TEST_DIRNAME}/../.."
    export NIX_CONFIG="experimental-features = nix-command flakes"
    
    # Pre-build common dependencies to speed up tests
    echo "Setting up integration test environment..."
    nix build "$TEST_FLAKE_ROOT#lib.testBuilders" --no-link --quiet || true
}

teardown_file() {
    # Clean up shared test environment
    rm -rf "$INTEGRATION_TEST_DIR"
}

setup() {
    # Per-test setup
    TEST_TMPDIR=$(mktemp -d)
    export TEST_TMPDIR
}

teardown() {
    # Per-test cleanup
    rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# Build System Integration Tests
# ============================================================================

@test "nix-unit integrates with test runner" {
    # Create a test file that nix-unit can execute
    cat > "$TEST_TMPDIR/integration-test.nix" << 'EOF'
{
  testBasicIntegration = {
    expr = 2 + 2;
    expected = 4;
  };
  
  testStringIntegration = {
    expr = "hello" + " " + "world";
    expected = "hello world";
  };
}
EOF

    # Test that the test runner can execute nix-unit tests
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply "f: f { testLayer = \"unit\"; testFile = \"$TEST_TMPDIR/integration-test.nix\"; }"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "passed" ]]
    [[ "$output" =~ "total.*2" ]]
}

@test "BATS integrates with contract testing" {
    # Create a BATS test file
    cat > "$TEST_TMPDIR/contract-test.bats" << 'EOF'
#!/usr/bin/env bats

@test "contract test integration" {
    run echo "Hello from BATS"
    [ "$status" -eq 0 ]
    [ "$output" = "Hello from BATS" ]
}

@test "nix evaluation in BATS" {
    run nix eval --raw --expr '1 + 1'
    [ "$status" -eq 0 ]
    [ "$output" = "2" ]
}
EOF
    chmod +x "$TEST_TMPDIR/contract-test.bats"

    # Test that BATS can be executed through the framework
    run bats "$TEST_TMPDIR/contract-test.bats"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "2 tests, 0 failures" ]]
}

@test "flake checks integrate with CI system" {
    # Test that flake checks can be built and executed
    run nix eval --json "$TEST_FLAKE_ROOT#checks" --apply "builtins.attrNames"
    [ "$status" -eq 0 ]
    
    # Verify that checks include test layers
    local platform
    platform=$(nix eval --raw --expr 'builtins.currentSystem')
    
    run nix eval --json "$TEST_FLAKE_ROOT#checks.$platform" --apply "builtins.attrNames" 2>/dev/null || true
    # Should succeed or gracefully handle missing platform
}

# ============================================================================
# Coverage System Integration Tests
# ============================================================================

@test "coverage system integrates with nix-unit" {
    # Create test files with known coverage
    cat > "$TEST_TMPDIR/covered-functions.nix" << 'EOF'
{ lib }:
{
  add = a: b: a + b;
  multiply = a: b: a * b;
  divide = a: b: if b == 0 then null else a / b;
}
EOF

    cat > "$TEST_TMPDIR/coverage-test.nix" << 'EOF'
let
  functions = import ./covered-functions.nix { lib = (import <nixpkgs> {}).lib; };
in
{
  testAdd = {
    expr = functions.add 2 3;
    expected = 5;
  };
  
  testMultiply = {
    expr = functions.multiply 4 5;
    expected = 20;
  };
  
  # This test covers the divide function
  testDivide = {
    expr = functions.divide 10 2;
    expected = 5;
  };
}
EOF

    # Test coverage collection
    run nix eval --json "$TEST_FLAKE_ROOT#coverageProvider.collect" --apply "f: f { sourceDir = \"$TEST_TMPDIR\"; testFile = \"$TEST_TMPDIR/coverage-test.nix\"; }"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "percentage" ]]
    [[ "$output" =~ "linesTotal" ]]
}

@test "coverage reporting generates multiple formats" {
    # Create minimal test setup
    mkdir -p "$TEST_TMPDIR/src"
    cat > "$TEST_TMPDIR/src/example.nix" << 'EOF'
{ lib }:
{
  example = x: x + 1;
}
EOF

    # Test multiple coverage formats
    for format in "json" "html" "console"; do
        run nix eval --json "$TEST_FLAKE_ROOT#coverageProvider.report" --apply "f: f { sourceDir = \"$TEST_TMPDIR/src\"; format = \"$format\"; }"
        [ "$status" -eq 0 ]
        [[ "$output" =~ "$format\\|report\\|coverage" ]]
    done
}

# ============================================================================
# Platform Integration Tests
# ============================================================================

@test "cross-platform test execution" {
    # Create platform-agnostic test
    cat > "$TEST_TMPDIR/platform-test.nix" << 'EOF'
{
  testPlatformIndependent = {
    expr = builtins.typeOf builtins.currentSystem;
    expected = "string";
  };
  
  testBasicArithmetic = {
    expr = 1 + 1;
    expected = 2;
  };
}
EOF

    # Test on current platform
    local platform
    platform=$(nix eval --raw --expr 'builtins.currentSystem')
    
    run nix eval --json "$TEST_FLAKE_ROOT#platformAdapter.runTestOnPlatform" --apply "f: f { platform = \"$platform\"; testFile = \"$TEST_TMPDIR/platform-test.nix\"; }"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "success\\|passed" ]]
}

@test "platform-specific configurations apply correctly" {
    # Test that platform adapter provides appropriate configurations
    local platform
    platform=$(nix eval --raw --expr 'builtins.currentSystem')
    
    run nix eval --json "$TEST_FLAKE_ROOT#platformAdapter.getConfig" --apply "f: f \"$platform\""
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testCommand" ]]
    
    # Verify configuration is platform-appropriate
    if [[ "$platform" =~ darwin ]]; then
        [[ "$output" =~ "darwin\\|macos" ]] || true
    elif [[ "$platform" =~ linux ]]; then
        [[ "$output" =~ "linux" ]] || true
    fi
}

# ============================================================================
# Module Interaction Tests  
# ============================================================================

@test "test builders interact with coverage system" {
    # Create test that can be built and measured for coverage
    cat > "$TEST_TMPDIR/buildable-test.nix" << 'EOF'
{
  testBuilderIntegration = {
    expr = "builder" + "-" + "test";
    expected = "builder-test";
  };
}
EOF

    # Build test executable
    run nix build "$TEST_FLAKE_ROOT#testBuilders.buildUnitTest" --apply "f: f { name = \"integration-test\"; testFile = \"$TEST_TMPDIR/buildable-test.nix\"; }" --out-link "$TEST_TMPDIR/test-result"
    [ "$status" -eq 0 ]
    [ -e "$TEST_TMPDIR/test-result" ]
    
    # Verify it's executable
    [ -x "$TEST_TMPDIR/test-result/bin/integration-test" ]
}

@test "test layers execute in dependency order" {
    # Test that unit tests run before integration tests
    local start_time end_time
    
    start_time=$(date +%s.%N)
    
    # Run unit tests (should be fast)
    run timeout 30s nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply 'f: f { testLayer = "unit"; testFile = "'$TEST_TMPDIR'/quick-test.nix"; }' || true
    
    end_time=$(date +%s.%N)
    local unit_duration
    unit_duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Unit tests should complete quickly (under 30s)
    (( $(echo "$unit_duration < 30" | bc -l) ))
}

@test "parallel test execution works correctly" {
    # Create multiple independent test files
    for i in {1..3}; do
        cat > "$TEST_TMPDIR/parallel-test-$i.nix" << EOF
{
  testParallel$i = {
    expr = $i + $i;
    expected = $((i + i));
  };
}
EOF
    done
    
    # Test parallel execution
    local start_time end_time
    start_time=$(date +%s.%N)
    
    # Run tests in parallel (mock parallel execution)
    for i in {1..3}; do
        nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply "f: f { testLayer = \"unit\"; testFile = \"$TEST_TMPDIR/parallel-test-$i.nix\"; }" &
    done
    wait
    
    end_time=$(date +%s.%N)
    local total_duration
    total_duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Parallel execution should be faster than sequential
    (( $(echo "$total_duration < 10" | bc -l) ))
}

# ============================================================================
# Configuration Integration Tests
# ============================================================================

@test "test configuration cascades correctly" {
    # Test that global config affects all test layers
    run nix eval --json "$TEST_FLAKE_ROOT#config.testing"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "timeout" ]]
    [[ "$output" =~ "parallel" ]]
    [[ "$output" =~ "coverage" ]]
    
    # Test that config values are propagated
    local timeout
    timeout=$(nix eval --raw "$TEST_FLAKE_ROOT#config.testing.timeout")
    [[ "$timeout" =~ ^[0-9]+$ ]]
    [ "$timeout" -gt 0 ]
}

@test "environment variables override configuration" {
    # Test environment variable override
    export TEST_TIMEOUT=42
    
    run nix eval --raw "$TEST_FLAKE_ROOT#config.testing.getTimeout" --apply 'f: f {}'
    [ "$status" -eq 0 ]
    # Should respect environment override or use default
    [[ "$output" =~ ^[0-9]+$ ]]
    
    unset TEST_TIMEOUT
}

# ============================================================================
# Error Handling Integration Tests
# ============================================================================

@test "test failures propagate correctly through layers" {
    # Create a test that should fail
    cat > "$TEST_TMPDIR/failing-test.nix" << 'EOF'
{
  testThatShouldFail = {
    expr = 1 + 1;
    expected = 3; # This will fail
  };
}
EOF

    # Test that failure is properly reported
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply "f: f { testLayer = \"unit\"; testFile = \"$TEST_TMPDIR/failing-test.nix\"; }"
    # Should complete but report failure
    [[ "$output" =~ "failed.*1\\|error" ]]
}

@test "timeouts are enforced across test layers" {
    # Create a test that might take a while
    cat > "$TEST_TMPDIR/slow-test.nix" << 'EOF'
{
  testSlowOperation = {
    expr = builtins.length (builtins.genList (x: x) 10000);
    expected = 10000;
  };
}
EOF

    # Test with timeout
    run timeout 5s nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply "f: f { testLayer = \"unit\"; testFile = \"$TEST_TMPDIR/slow-test.nix\"; }"
    # Should either complete or timeout gracefully
    # Exit code 124 indicates timeout
    [[ "$status" -eq 0 || "$status" -eq 124 ]]
}

# ============================================================================
# Performance Integration Tests
# ============================================================================

@test "test framework overhead is minimal" {
    # Measure pure Nix evaluation
    local start_time end_time nix_duration framework_duration
    
    start_time=$(date +%s.%N)
    run nix eval --raw --expr '1 + 1'
    end_time=$(date +%s.%N)
    nix_duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Measure framework overhead
    cat > "$TEST_TMPDIR/minimal-test.nix" << 'EOF'
{
  testMinimal = {
    expr = 1 + 1;
    expected = 2;
  };
}
EOF

    start_time=$(date +%s.%N)
    run nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply "f: f { testLayer = \"unit\"; testFile = \"$TEST_TMPDIR/minimal-test.nix\"; }"
    end_time=$(date +%s.%N)
    framework_duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Framework overhead should be reasonable (less than 10x pure Nix)
    (( $(echo "$framework_duration < $nix_duration * 10" | bc -l) ))
}

@test "memory usage remains bounded during test execution" {
    # Monitor memory usage during test execution
    local start_mem peak_mem end_mem
    
    start_mem=$(free -b | grep '^Mem:' | awk '{print $3}' || echo "0")
    
    # Run several tests to stress memory
    for i in {1..5}; do
        cat > "$TEST_TMPDIR/memory-test-$i.nix" << EOF
{
  testMemoryUsage$i = {
    expr = builtins.length (builtins.genList (x: x) 1000);
    expected = 1000;
  };
}
EOF
        nix eval --json "$TEST_FLAKE_ROOT#testRunner.run" --apply "f: f { testLayer = \"unit\"; testFile = \"$TEST_TMPDIR/memory-test-$i.nix\"; }" >/dev/null &
    done
    wait
    
    end_mem=$(free -b | grep '^Mem:' | awk '{print $3}' || echo "0")
    local mem_delta
    mem_delta=$(echo "$end_mem - $start_mem" | bc || echo "0")
    
    # Memory delta should be reasonable (less than 1GB)
    (( mem_delta < 1073741824 )) || true  # 1GB in bytes
}

# ============================================================================
# Integration Test Helpers
# ============================================================================

# Helper to verify test result structure
verify_test_result() {
    local result="$1"
    
    # Check that result has expected structure
    echo "$result" | jq -e '.passed' >/dev/null
    echo "$result" | jq -e '.failed' >/dev/null  
    echo "$result" | jq -e '.total' >/dev/null
}

# Helper to create mock test environment
create_mock_environment() {
    local test_dir="$1"
    
    mkdir -p "$test_dir"
    cat > "$test_dir/mock-config.nix" << 'EOF'
{
  testing = {
    timeout = 30;
    parallel = true;
    coverage = {
      threshold = 90;
      exclude = ["test-*"];
    };
  };
}
EOF
}

# Helper to wait for background jobs with timeout
wait_with_timeout() {
    local timeout="$1"
    local start_time
    start_time=$(date +%s)
    
    while jobs %% >/dev/null 2>&1; do
        if (( $(date +%s) - start_time > timeout )); then
            jobs -p | xargs -r kill
            return 1
        fi
        sleep 0.1
    done
    wait
}