{ pkgs }:
let
  # Color codes for test output
  colors = {
    red = "\033[31m";
    green = "\033[32m";
    yellow = "\033[33m";
    blue = "\033[34m";
    reset = "\033[0m";
  };

  # Platform detection helpers
  platform = {
    isDarwin = pkgs.stdenv.isDarwin;
    isLinux = pkgs.stdenv.isLinux;
    isAarch64 = pkgs.stdenv.isAarch64;
    isX86_64 = pkgs.stdenv.isx86_64;
    system = pkgs.system;
  };

  # Test environment setup
  setupTestEnv = ''
    export USER=testuser
    export HOME=/tmp/test-home-$$
    mkdir -p $HOME
    export PATH=${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH
  '';

  # Assertion helpers
  assertTrue = condition: message:
    ''
      if ${condition}; then
        echo "${colors.green}✓${colors.reset} ${message}"
      else
        echo "${colors.red}✗${colors.reset} ${message}"
        exit 1
      fi
    '';

  assertExists = path: message:
    ''
      if [ -e "${path}" ]; then
        echo "${colors.green}✓${colors.reset} ${message}"
      else
        echo "${colors.red}✗${colors.reset} ${message} (${path} not found)"
        exit 1
      fi
    '';

  assertCommand = cmd: message:
    ''
      if ${cmd} >/dev/null 2>&1; then
        echo "${colors.green}✓${colors.reset} ${message}"
      else
        echo "${colors.red}✗${colors.reset} ${message} (command failed: ${cmd})"
        exit 1
      fi
    '';

  assertContains = file: pattern: message:
    ''
      if grep -q "${pattern}" "${file}" 2>/dev/null; then
        echo "${colors.green}✓${colors.reset} ${message}"
      else
        echo "${colors.red}✗${colors.reset} ${message} (pattern '${pattern}' not found in ${file})"
        exit 1
      fi
    '';

  # Test section helpers
  testSection = name: ''
    echo ""
    echo "${colors.blue}=== ${name} ===${colors.reset}"
  '';

  testSubsection = name: ''
    echo "${colors.yellow}--- ${name} ---${colors.reset}"
  '';

  # Skip test on unsupported platforms
  skipOn = platforms: reason: testBody:
    if builtins.elem platform.system platforms then ''
      echo "${colors.yellow}⚠${colors.reset} Skipping test: ${reason}"
      touch $out
      exit 0
    '' else testBody;

  # Only run test on specific platforms
  onlyOn = platforms: reason: testBody:
    if builtins.elem platform.system platforms then testBody else ''
      echo "${colors.yellow}⚠${colors.reset} Skipping test: ${reason}"
      touch $out
      exit 0
    '';

  # Benchmark helpers
  benchmark = name: cmd: ''
    echo "${colors.blue}Benchmarking: ${name}${colors.reset}"
    START_TIME=$(date +%s%N)
    ${cmd}
    END_TIME=$(date +%s%N)
    DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
    echo "${colors.green}✓${colors.reset} ${name} completed in ''${DURATION}ms"
  '';

  # Mock data generators
  mockFlake = attrs: {
    description = "Test flake";
    inputs = { };
    outputs = { };
  } // attrs;

  mockConfig = attrs: {
    system = platform.system;
    modules = [ ];
  } // attrs;

  # File system test helpers
  createTempFile = content: ''
        TEMP_FILE=$(mktemp)
        cat > $TEMP_FILE << 'EOF'
    ${content}
    EOF
        echo $TEMP_FILE
  '';

  createTempDir = ''
    TEMP_DIR=$(mktemp -d)
    echo $TEMP_DIR
  '';

  # Flake evaluation helpers
  evalFlake = flakePath: attr:
    let
      flake = builtins.getFlake (toString flakePath);
    in
    if builtins.hasAttr attr flake.outputs then
      flake.outputs.${attr}
    else
      throw "Attribute ${attr} not found in flake outputs";

  # Test result reporting
  reportResults = testName: passed: total: ''
    echo ""
    echo "${colors.blue}=== Test Results: ${testName} ===${colors.reset}"
    echo "Passed: ${colors.green}${toString passed}${colors.reset}/${toString total}"

    if [ ${toString passed} -eq ${toString total} ]; then
      echo "${colors.green}✓ All tests passed!${colors.reset}"
    else
      FAILED=$((${toString total} - ${toString passed}))
      echo "${colors.red}✗ $FAILED tests failed${colors.reset}"
      exit 1
    fi
  '';

  # Cleanup helpers
  cleanup = ''
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
      rm -rf "$TEMP_DIR"
    fi
    if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
      rm -f "$TEMP_FILE"
    fi
  '';

  # Enhanced Mock File System Operations
  createMockFileSystem = ''
    MOCK_FS_DIR=$(mktemp -d)
    MOCK_FS_STATE="$MOCK_FS_DIR/fs_state"
    echo "MOCK_FS_STATE=$MOCK_FS_STATE"

    # Initialize empty state
    echo "# Mock File System State" > "$MOCK_FS_STATE"
    echo "operations=0" >> "$MOCK_FS_STATE"
    echo "MOCK_FS_DIR=$MOCK_FS_DIR"
  '';

  # Mock file operations with tracking
  mockFileCreate = path: content: ''
    if [ -n "$MOCK_FS_STATE" ]; then
      echo "CREATE:${path}" >> "$MOCK_FS_STATE"
      OPERATIONS=$(grep "operations=" "$MOCK_FS_STATE" | cut -d'=' -f2)
      OPERATIONS=$((OPERATIONS + 1))
      sed -i "s/operations=.*/operations=$OPERATIONS/" "$MOCK_FS_STATE"
    fi
    mkdir -p "$(dirname "${path}")"
    echo "${content}" > "${path}"
  '';

  mockFileRead = path: ''
    if [ -n "$MOCK_FS_STATE" ]; then
      echo "READ:${path}" >> "$MOCK_FS_STATE"
      OPERATIONS=$(grep "operations=" "$MOCK_FS_STATE" | cut -d'=' -f2)
      OPERATIONS=$((OPERATIONS + 1))
      sed -i "s/operations=.*/operations=$OPERATIONS/" "$MOCK_FS_STATE"
    fi
    if [ -f "${path}" ]; then
      cat "${path}"
    else
      echo "Mock: File not found: ${path}" >&2
      return 1
    fi
  '';

  mockFileDelete = path: ''
    if [ -n "$MOCK_FS_STATE" ]; then
      echo "DELETE:${path}" >> "$MOCK_FS_STATE"
      OPERATIONS=$(grep "operations=" "$MOCK_FS_STATE" | cut -d'=' -f2)
      OPERATIONS=$((OPERATIONS + 1))
      sed -i "s/operations=.*/operations=$OPERATIONS/" "$MOCK_FS_STATE"
    fi
    rm -f "${path}"
  '';

  # Permission error simulation
  mockPermissionError = path: errorType: ''
    if [ -n "$MOCK_FS_STATE" ]; then
      echo "PERMISSION_ERROR:${errorType}:${path}" >> "$MOCK_FS_STATE"
    fi
    echo "Mock: Permission denied: ${errorType} on ${path}" >&2
    echo "PERMISSION_ERROR_OCCURRED"
  '';

  # File content verification
  mockFileVerify = path: expectedContent: ''
    if [ -f "${path}" ]; then
      if [ "$(cat "${path}")" = "${expectedContent}" ]; then
        echo "${colors.green}✓${colors.reset} File content matches: ${path}"
        return 0
      else
        echo "${colors.red}✗${colors.reset} File content mismatch: ${path}"
        echo "Expected: ${expectedContent}"
        echo "Actual: $(cat "${path}")"
        return 1
      fi
    else
      echo "${colors.red}✗${colors.reset} File does not exist: ${path}"
      return 1
    fi
  '';

  # Directory operations
  mockDirCreate = path: ''
    if [ -n "$MOCK_FS_STATE" ]; then
      echo "MKDIR:${path}" >> "$MOCK_FS_STATE"
      OPERATIONS=$(grep "operations=" "$MOCK_FS_STATE" | cut -d'=' -f2)
      OPERATIONS=$((OPERATIONS + 1))
      sed -i "s/operations=.*/operations=$OPERATIONS/" "$MOCK_FS_STATE"
    fi
    mkdir -p "${path}"
  '';

  # Get mock operation count
  getMockOperationCount = ''
    if [ -n "$MOCK_FS_STATE" ] && [ -f "$MOCK_FS_STATE" ]; then
      grep "operations=" "$MOCK_FS_STATE" | cut -d'=' -f2
    else
      echo "0"
    fi
  '';

  # Get mock operation history
  getMockOperationHistory = ''
    if [ -n "$MOCK_FS_STATE" ] && [ -f "$MOCK_FS_STATE" ]; then
      grep -v "^#\|^operations=" "$MOCK_FS_STATE" || echo "No operations recorded"
    else
      echo "Mock file system not initialized"
    fi
  '';

  # Clean up mock file system
  cleanupMockFileSystem = ''
    if [ -n "$MOCK_FS_DIR" ] && [ -d "$MOCK_FS_DIR" ]; then
      echo "Cleaning up mock file system at $MOCK_FS_DIR"
      rm -rf "$MOCK_FS_DIR"
    fi
    if [ -n "$MOCK_FS_STATE" ] && [ -f "$MOCK_FS_STATE" ]; then
      rm -f "$MOCK_FS_STATE"
    fi
    unset MOCK_FS_DIR MOCK_FS_STATE
  '';

  # Nix attribute set test helpers
  assertSetContains = attrSet: expectedKeys:
    pkgs.runCommand "assert-set-contains" { } ''
      ${builtins.concatStringsSep "\n" (map (key:
        ''if [ -z "${if builtins.hasAttr key attrSet then "has" else ""}" ]; then
            echo "Missing key: ${key}"
            exit 1
          fi''
      ) expectedKeys)}
      echo "All keys found"
      touch $out
    '';


in
{
  inherit colors platform setupTestEnv;
  inherit assertTrue assertExists assertCommand assertContains;
  inherit testSection testSubsection;
  inherit skipOn onlyOn benchmark;
  inherit mockFlake mockConfig;
  inherit createTempFile createTempDir;
  inherit evalFlake reportResults cleanup;
  inherit assertSetContains;
  # Enhanced Mock File System
  inherit createMockFileSystem mockFileCreate mockFileRead mockFileDelete;
  inherit mockPermissionError mockFileVerify mockDirCreate;
  inherit getMockOperationCount getMockOperationHistory cleanupMockFileSystem;
}
