{ pkgs }:

{
  # Create a portable temporary directory that works across systems
  getTempDir = ''
    # Use TMPDIR if available, otherwise fall back to mktemp
    if [ -n "$TMPDIR" ]; then
      TEMP_BASE="$TMPDIR"
    else
      TEMP_BASE="/tmp"
    fi
    
    # Create unique test directory
    TEST_TEMP_DIR=$(${pkgs.coreutils}/bin/mktemp -d "$TEMP_BASE/dotfiles-test-XXXXXX")
    export TEST_TEMP_DIR
    
    # Cleanup function
    cleanup_temp() {
      if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$TEST_TEMP_DIR"
      fi
    }
    trap cleanup_temp EXIT
  '';

  # Create a portable test home directory
  getTestHome = ''
    # Create isolated test home
    TEST_HOME=$(${pkgs.coreutils}/bin/mktemp -d "''${TMPDIR:-/tmp}/test-home-XXXXXX")
    export HOME="$TEST_HOME"
    export TEST_HOME
    
    # Cleanup function for test home
    cleanup_test_home() {
      if [ -n "$TEST_HOME" ] && [ -d "$TEST_HOME" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$TEST_HOME"
      fi
    }
    trap cleanup_test_home EXIT
  '';

  # Get system binary path using Nix packages
  getSystemBinary = name: 
    if name == "time" then "${pkgs.time}/bin/time"
    else if name == "echo" then "${pkgs.coreutils}/bin/echo"
    else if name == "cat" then "${pkgs.coreutils}/bin/cat"
    else if name == "find" then "${pkgs.findutils}/bin/find"
    else if name == "touch" then "${pkgs.coreutils}/bin/touch"
    else if name == "rm" then "${pkgs.coreutils}/bin/rm"
    else if name == "mkdir" then "${pkgs.coreutils}/bin/mkdir"
    else if name == "cp" then "${pkgs.coreutils}/bin/cp"
    else if name == "mv" then "${pkgs.coreutils}/bin/mv"
    else if name == "ls" then "${pkgs.coreutils}/bin/ls"
    else throw "Unknown system binary: ${name}";

  # Create a mock system file for testing
  createMockSystemFile = content: ''
    MOCK_SYSTEM_FILE=$(${pkgs.coreutils}/bin/mktemp "''${TEST_TEMP_DIR:-''${TMPDIR:-/tmp}}/mock-system-XXXXXX")
    ${pkgs.coreutils}/bin/echo "${content}" > "$MOCK_SYSTEM_FILE"
    export MOCK_SYSTEM_FILE
  '';

  # Get portable path separator and create cross-platform paths
  getPortablePath = path: 
    # Convert Windows-style paths to Unix-style if needed
    builtins.replaceStrings ["\\"] ["/"] path;

  # Check if we're running on macOS or Linux for platform-specific behavior
  getPlatformInfo = ''
    if [[ "$OSTYPE" == "darwin"* ]]; then
      export PLATFORM="macos"
      export HOME_PREFIX="/Users"
    else
      export PLATFORM="linux" 
      export HOME_PREFIX="/home"
    fi
  '';
}