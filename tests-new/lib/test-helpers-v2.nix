{ pkgs, lib ? pkgs.lib }:
let
  # Import original test helpers for compatibility
  originalHelpers = import ../../tests/lib/test-helpers.nix { inherit pkgs lib; };
  
  # Import portable path utilities
  portablePaths = import ../../tests/lib/portable-paths.nix { inherit pkgs; };

  # Enhanced color codes for better test output
  colors = originalHelpers.colors // {
    magenta = "\033[35m";
    cyan = "\033[36m";
    bold = "\033[1m";
    dim = "\033[2m";
  };

  # Enhanced platform detection with more detailed info
  platform = originalHelpers.platform // {
    arch = if pkgs.stdenv.isAarch64 then "aarch64" else "x86_64";
    os = if pkgs.stdenv.isDarwin then "darwin" else "linux";
    systemId = "${if pkgs.stdenv.isAarch64 then "aarch64" else "x86_64"}-${if pkgs.stdenv.isDarwin then "darwin" else "linux"}";
  };

  # Enhanced test environment setup with better isolation
  setupEnhancedTestEnv = ''
    export USER=testuser
    export HOME=$PWD/test-home
    ${portablePaths.getTestHome}
    export PATH=${pkgs.nix}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:$PATH
    
    # Create isolated test directories
    mkdir -p test-home/{.config,.cache,.local/share}
    mkdir -p test-temp test-artifacts test-logs
    
    # Set up test logging
    export TEST_LOG_DIR="$PWD/test-logs"
    export TEST_ARTIFACTS_DIR="$PWD/test-artifacts"
    
    # Initialize test session metadata
    echo "Test session started: $(date)" > "$TEST_LOG_DIR/session.log"
    echo "Platform: ${platform.systemId}" >> "$TEST_LOG_DIR/session.log"
    echo "Nix version: $(nix --version)" >> "$TEST_LOG_DIR/session.log"
  '';

  # Enhanced assertion functions with better error reporting
  assertTrueWithDetails = condition: message: details: ''
    if ${condition}; then
      echo "${colors.green}✓${colors.reset} ${message}"
      echo "  ${colors.dim}${details}${colors.reset}"
    else
      echo "${colors.red}✗${colors.reset} ${message}"
      echo "  ${colors.red}Details: ${details}${colors.reset}"
      echo "  ${colors.red}Condition: ${condition}${colors.reset}"
      exit 1
    fi
  '';

  assertExistsWithType = path: expectedType: message: ''
    if [ -${expectedType} "${path}" ]; then
      echo "${colors.green}✓${colors.reset} ${message}"
      echo "  ${colors.dim}Found: ${path} (${expectedType})${colors.reset}"
    else
      echo "${colors.red}✗${colors.reset} ${message}"
      echo "  ${colors.red}Expected: ${path} (type: ${expectedType})${colors.reset}"
      if [ -e "${path}" ]; then
        echo "  ${colors.yellow}Note: Path exists but wrong type${colors.reset}"
        ls -la "${path}"
      fi
      exit 1
    fi
  '';

  assertCommandWithOutput = cmd: expectedPattern: message: ''
    OUTPUT=$(${cmd} 2>&1 || true)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "${expectedPattern}"; then
      echo "${colors.green}✓${colors.reset} ${message}"
      echo "  ${colors.dim}Command: ${cmd}${colors.reset}"
      echo "  ${colors.dim}Output matched: ${expectedPattern}${colors.reset}"
    else
      echo "${colors.red}✗${colors.reset} ${message}"
      echo "  ${colors.red}Command: ${cmd}${colors.reset}"
      echo "  ${colors.red}Exit code: $EXIT_CODE${colors.reset}"
      echo "  ${colors.red}Output:${colors.reset}"
      echo "$OUTPUT" | sed 's/^/    /'
      echo "  ${colors.red}Expected pattern: ${expectedPattern}${colors.reset}"
      exit 1
    fi
  '';

  assertJsonValid = file: message: ''
    if command -v jq >/dev/null 2>&1; then
      if jq empty "${file}" >/dev/null 2>&1; then
        echo "${colors.green}✓${colors.reset} ${message}"
        echo "  ${colors.dim}Valid JSON: ${file}${colors.reset}"
      else
        echo "${colors.red}✗${colors.reset} ${message}"
        echo "  ${colors.red}Invalid JSON: ${file}${colors.reset}"
        jq empty "${file}" 2>&1 | head -5 | sed 's/^/    /'
        exit 1
      fi
    else
      echo "${colors.yellow}⚠${colors.reset} ${message} (jq not available, skipping JSON validation)"
    fi
  '';

  assertNixEvaluates = nixFile: message: ''
    if nix-instantiate --eval "${nixFile}" >/dev/null 2>&1; then
      echo "${colors.green}✓${colors.reset} ${message}"
      echo "  ${colors.dim}Nix evaluation successful: ${nixFile}${colors.reset}"
    else
      echo "${colors.red}✗${colors.reset} ${message}"
      echo "  ${colors.red}Nix evaluation failed: ${nixFile}${colors.reset}"
      nix-instantiate --eval "${nixFile}" 2>&1 | head -10 | sed 's/^/    /'
      exit 1
    fi
  '';

  # Enhanced test organization helpers
  testSuite = name: description: tests: ''
    echo ""
    echo "${colors.bold}${colors.blue}╭─ Test Suite: ${name} ─╮${colors.reset}"
    echo "${colors.blue}│ ${description}${colors.reset}"
    echo "${colors.blue}╰─────────────────────────────────╯${colors.reset}"
    
    # Initialize suite metadata
    SUITE_START_TIME=$(date +%s)
    SUITE_TESTS_TOTAL=0
    SUITE_TESTS_PASSED=0
    
    # Store suite info for reporting
    echo "suite_start: $SUITE_START_TIME" >> "$TEST_LOG_DIR/${name}.log"
    echo "suite_name: ${name}" >> "$TEST_LOG_DIR/${name}.log"
    echo "suite_description: ${description}" >> "$TEST_LOG_DIR/${name}.log"
    
    ${tests}
    
    # Suite completion reporting
    SUITE_END_TIME=$(date +%s)
    SUITE_DURATION=$((SUITE_END_TIME - SUITE_START_TIME))
    
    echo ""
    echo "${colors.bold}${colors.blue}╭─ Suite Results: ${name} ─╮${colors.reset}"
    echo "${colors.blue}│ Tests: $SUITE_TESTS_PASSED/$SUITE_TESTS_TOTAL${colors.reset}"
    echo "${colors.blue}│ Duration: ''${SUITE_DURATION}s${colors.reset}"
    echo "${colors.blue}╰─────────────────────────────────╯${colors.reset}"
    
    if [ $SUITE_TESTS_PASSED -ne $SUITE_TESTS_TOTAL ]; then
      echo "${colors.red}Suite ${name} failed${colors.reset}"
      exit 1
    fi
  '';

  testGroup = name: tests: ''
    echo ""
    echo "${colors.cyan}┌─ ${name} ─┐${colors.reset}"
    
    GROUP_START_TIME=$(date +%s)
    ${tests}
    GROUP_END_TIME=$(date +%s)
    GROUP_DURATION=$((GROUP_END_TIME - GROUP_START_TIME))
    
    echo "${colors.cyan}└─ ${name} completed (''${GROUP_DURATION}s) ─┘${colors.reset}"
  '';

  testCase = name: test: ''
    echo ""
    echo "${colors.yellow}── ${name}${colors.reset}"
    
    CASE_START_TIME=$(date +%s)
    SUITE_TESTS_TOTAL=$((SUITE_TESTS_TOTAL + 1))
    
    # Run the test in a subshell to isolate failures
    if (
      ${test}
    ); then
      CASE_END_TIME=$(date +%s)
      CASE_DURATION=$((CASE_END_TIME - CASE_START_TIME))
      echo "   ${colors.green}✓ Passed (''${CASE_DURATION}s)${colors.reset}"
      SUITE_TESTS_PASSED=$((SUITE_TESTS_PASSED + 1))
    else
      CASE_END_TIME=$(date +%s)
      CASE_DURATION=$((CASE_END_TIME - CASE_START_TIME))
      echo "   ${colors.red}✗ Failed (''${CASE_DURATION}s)${colors.reset}"
      # Suite will fail, but we continue to run other tests
    fi
  '';

  # Enhanced performance measurement with statistics
  performanceBenchmark = { name, command, iterations ? 1, warmupRuns ? 0 }: ''
    echo "${colors.magenta}🏃 Performance Benchmark: ${name}${colors.reset}"
    
    # Warmup runs
    if [ ${toString warmupRuns} -gt 0 ]; then
      echo "  ${colors.dim}Running ${toString warmupRuns} warmup iterations...${colors.reset}"
      for i in $(seq 1 ${toString warmupRuns}); do
        ${command} >/dev/null 2>&1 || true
      done
    fi
    
    # Benchmark runs
    echo "  ${colors.dim}Running ${toString iterations} benchmark iterations...${colors.reset}"
    TIMES=""
    TOTAL_TIME=0
    
    for i in $(seq 1 ${toString iterations}); do
      START_TIME=$(date +%s%N)
      ${command} >/dev/null 2>&1 || true
      END_TIME=$(date +%s%N)
      DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
      TIMES="$TIMES $DURATION"
      TOTAL_TIME=$((TOTAL_TIME + DURATION))
    done
    
    # Calculate statistics
    AVG_TIME=$((TOTAL_TIME / ${toString iterations}))
    
    # Find min and max
    MIN_TIME=999999999
    MAX_TIME=0
    for time in $TIMES; do
      if [ $time -lt $MIN_TIME ]; then MIN_TIME=$time; fi
      if [ $time -gt $MAX_TIME ]; then MAX_TIME=$time; fi
    done
    
    echo "  ${colors.green}Results:${colors.reset}"
    echo "    ${colors.dim}Iterations: ${toString iterations}${colors.reset}"
    echo "    ${colors.dim}Average: ''${AVG_TIME}ms${colors.reset}"
    echo "    ${colors.dim}Min: ''${MIN_TIME}ms${colors.reset}"
    echo "    ${colors.dim}Max: ''${MAX_TIME}ms${colors.reset}"
    
    # Save benchmark results
    echo "benchmark_name: ${name}" >> "$TEST_ARTIFACTS_DIR/benchmarks.log"
    echo "benchmark_avg: $AVG_TIME" >> "$TEST_ARTIFACTS_DIR/benchmarks.log"
    echo "benchmark_min: $MIN_TIME" >> "$TEST_ARTIFACTS_DIR/benchmarks.log"
    echo "benchmark_max: $MAX_TIME" >> "$TEST_ARTIFACTS_DIR/benchmarks.log"
    echo "---" >> "$TEST_ARTIFACTS_DIR/benchmarks.log"
  '';

  # Enhanced mock data generators with more realistic data
  mockFlakeWithInputs = { description ? "Test flake", inputs ? {}, outputs ? {} }: {
    description = description;
    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      flake-utils.url = "github:numtide/flake-utils";
    } // inputs;
    outputs = { self, nixpkgs, ... }: {
      packages = {};
      apps = {};
      devShells = {};
    } // outputs;
  };

  mockSystemConfig = { system ? platform.systemId, modules ? [], specialArgs ? {} }: {
    inherit system;
    modules = [
      # Mock modules that simulate real system configuration
      ({ config, pkgs, ... }: {
        environment.systemPackages = with pkgs; [ curl wget git ];
        programs.zsh.enable = true;
      })
    ] ++ modules;
    specialArgs = {
      inherit (pkgs) lib;
    } // specialArgs;
  };

  # Enhanced file system helpers with better error handling
  createMockFile = { path, content, permissions ? "644" }: ''
    mkdir -p "$(dirname "${path}")"
    cat > "${path}" << 'EOF'
${content}
EOF
    chmod ${permissions} "${path}"
    echo "Created mock file: ${path}"
  '';

  createMockDirectory = { path, structure ? {} }: ''
    mkdir -p "${path}"
    ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
      if builtins.isString value then
        createMockFile { path = "${path}/${name}"; content = value; }
      else if builtins.isAttrs value && value ? content then
        createMockFile { 
          path = "${path}/${name}"; 
          content = value.content;
          permissions = value.permissions or "644";
        }
      else
        createMockDirectory { path = "${path}/${name}"; structure = value; }
    ) structure)}
    echo "Created mock directory structure: ${path}"
  '';

  # Resource monitoring utilities
  monitorResources = command: ''
    echo "${colors.cyan}📊 Monitoring resources for: ${command}${colors.reset}"
    
    # Start resource monitoring in background
    {
      while true; do
        if command -v ps >/dev/null 2>&1; then
          ps -o pid,ppid,pcpu,pmem,command | grep -v grep || true
        fi
        sleep 1
      done
    } > "$TEST_ARTIFACTS_DIR/resource_monitor.log" 2>&1 &
    MONITOR_PID=$!
    
    # Run the command
    START_MEM=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
    START_TIME=$(date +%s%N)
    
    ${command}
    
    END_TIME=$(date +%s%N)
    END_MEM=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
    DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
    MEM_DIFF=$((END_MEM - START_MEM))
    
    # Stop monitoring
    kill $MONITOR_PID 2>/dev/null || true
    
    echo "  ${colors.dim}Duration: ''${DURATION}ms${colors.reset}"
    echo "  ${colors.dim}Memory change: ''${MEM_DIFF}KB${colors.reset}"
  '';

  # Test data validation helpers
  validateTestData = { name, data, schema }: ''
    echo "${colors.cyan}🔍 Validating test data: ${name}${colors.reset}"
    
    # Basic validation - check if data exists and is not empty
    if [ -z "${toString data}" ]; then
      echo "${colors.red}✗ Test data '${name}' is empty${colors.reset}"
      exit 1
    fi
    
    # Schema validation would go here if we had a schema validator
    echo "${colors.green}✓ Test data '${name}' is valid${colors.reset}"
  '';

  # Test artifacts collection
  collectArtifacts = testName: ''
    echo "${colors.cyan}📦 Collecting test artifacts for: ${testName}${colors.reset}"
    
    ARTIFACT_DIR="$TEST_ARTIFACTS_DIR/${testName}"
    mkdir -p "$ARTIFACT_DIR"
    
    # Collect logs if they exist
    if [ -d "$TEST_LOG_DIR" ]; then
      cp -r "$TEST_LOG_DIR" "$ARTIFACT_DIR/" 2>/dev/null || true
    fi
    
    # Collect any temporary files that might be useful
    find . -name "*.tmp" -o -name "*.log" -o -name "core.*" 2>/dev/null | while read file; do
      if [ -f "$file" ]; then
        cp "$file" "$ARTIFACT_DIR/" 2>/dev/null || true
      fi
    done
    
    echo "  ${colors.dim}Artifacts saved to: $ARTIFACT_DIR${colors.reset}"
  '';

  # Enhanced cleanup with comprehensive cleanup
  enhancedCleanup = ''
    echo "${colors.cyan}🧹 Performing enhanced cleanup...${colors.reset}"
    
    # Clean up temporary files and directories
    ${originalHelpers.cleanup}
    
    # Clean up test-specific directories
    if [ -d "test-home" ]; then rm -rf test-home; fi
    if [ -d "test-temp" ]; then rm -rf test-temp; fi
    
    # Clean up any leftover processes
    jobs -p | while read pid; do
      kill "$pid" 2>/dev/null || true
    done
    
    # Clean up any test locks
    find . -name "*.lock" -type f -delete 2>/dev/null || true
    
    echo "  ${colors.green}✓ Cleanup completed${colors.reset}"
  '';

  # Create test script function if not available from original helpers
  createTestScriptInternal = { name, script }:
    pkgs.runCommand name
      {
        buildInputs = with pkgs; [ bash coreutils ];
      } ''
      set -e
      ${setupEnhancedTestEnv}
      ${script}
      echo "Test ${name} completed successfully"
      touch $out
    '';

in
{
  # Export all original helpers for compatibility, with fallbacks
  inherit (originalHelpers) 
    setupTestEnv assertTrue assertExists assertCommand assertContains
    testSection testSubsection skipOn onlyOn benchmark measureExecutionTime
    assertPerformance mockFlake mockConfig createTempFile createTempDir
    evalFlake reportResults cleanup assertSetContains assertListIncludes
    assertListContains assertAllDerivations;
    
  # Export functions with fallbacks
  createTestScript = originalHelpers.createTestScript or createTestScriptInternal;
  runShellTest = originalHelpers.runShellTest or createTestScriptInternal;
  makeTest = originalHelpers.makeTest or createTestScriptInternal;

  # Export enhanced functionality
  inherit colors platform setupEnhancedTestEnv;
  inherit assertTrueWithDetails assertExistsWithType assertCommandWithOutput
    assertJsonValid assertNixEvaluates;
  inherit testSuite testGroup testCase;
  inherit performanceBenchmark;
  inherit mockFlakeWithInputs mockSystemConfig;
  inherit createMockFile createMockDirectory;
  inherit monitorResources validateTestData collectArtifacts enhancedCleanup;

  # Convenience aliases for common patterns
  assertFileExists = path: message: assertExistsWithType path "f" message;
  assertDirExists = path: message: assertExistsWithType path "d" message;
  assertSymlinkExists = path: message: assertExistsWithType path "L" message;
  
  # Quick test creation helpers
  quickTest = name: script: createTestScriptInternal { inherit name script; };
  quickBenchmark = name: command: performanceBenchmark { inherit name command; };
  
  # Test metadata helpers
  getTestMetadata = {
    platform = platform.systemId;
    timestamp = "$(date -Iseconds)";
    nixVersion = "$(nix --version)";
    user = "$USER";
  };
}