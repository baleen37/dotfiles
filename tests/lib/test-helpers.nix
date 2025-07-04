{ pkgs }:
let
  # Import portable path utilities
  portablePaths = import ./portable-paths.nix { inherit pkgs; };

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

  # Test environment setup using portable paths
  setupTestEnv = ''
    export USER=testuser
    ${portablePaths.getTestHome}
    export PATH=${pkgs.nix}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH
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

  # File system test helpers using portable paths
  createTempFile = content: ''
    ${portablePaths.getTempDir}
    TEMP_FILE=$(${pkgs.coreutils}/bin/mktemp "$TEST_TEMP_DIR/tempfile-XXXXXX")
    ${pkgs.coreutils}/bin/cat > $TEMP_FILE << 'EOF'
    ${content}
    EOF
    echo $TEMP_FILE
  '';

  createTempDir = ''
    ${portablePaths.getTempDir}
    TEMP_DIR=$(${pkgs.coreutils}/bin/mktemp -d "$TEST_TEMP_DIR/tempdir-XXXXXX")
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

  # Cleanup helpers using portable paths
  cleanup = ''
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
      ${pkgs.coreutils}/bin/rm -rf "$TEMP_DIR"
    fi
    if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
      ${pkgs.coreutils}/bin/rm -f "$TEMP_FILE"
    fi
    # Main temp directory cleanup is handled by trap in getTempDir
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

  # Package list test helpers
  assertListIncludes = { name, haystack, needles, description }:
    pkgs.runCommand "assert-list-includes-${name}" { } ''
      echo "Testing: ${description}"
      ${builtins.concatStringsSep "\n" (map (needle:
        let
          needleName = if builtins.hasAttr "name" needle then needle.name else needle.pname or "unknown";
        in
        ''
          FOUND=0
          for item in ${builtins.concatStringsSep " " (map (item:
            if builtins.hasAttr "name" item then item.name else item.pname or "unknown"
          ) haystack)}; do
            if [ "$item" = "${needleName}" ]; then
              FOUND=1
              break
            fi
          done
          if [ $FOUND -eq 0 ]; then
            echo "Package ${needleName} not found in haystack"
            exit 1
          fi
        ''
      ) needles)}
      echo "All packages found"
      touch $out
    '';

  assertListContains = { name, list, items, description }:
    pkgs.runCommand "assert-list-contains-${name}" { } ''
      echo "Testing: ${description}"
      ${builtins.concatStringsSep "\n" (map (item:
        let
          itemName = if builtins.hasAttr "name" item then item.name else item.pname or "unknown";
        in
        ''
          FOUND=0
          for listItem in ${builtins.concatStringsSep " " (map (listItem:
            if builtins.hasAttr "name" listItem then listItem.name else listItem.pname or "unknown"
          ) list)}; do
            if [ "$listItem" = "${itemName}" ]; then
              FOUND=1
              break
            fi
          done
          if [ $FOUND -eq 0 ]; then
            echo "Package ${itemName} not found in list"
            exit 1
          fi
        ''
      ) items)}
      echo "All required packages found"
      touch $out
    '';

  assertAllDerivations = { name, lists, description }:
    pkgs.runCommand "assert-all-derivations-${name}" { } ''
      echo "Testing: ${description}"
      ${builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (listName: list:
        builtins.concatStringsSep "\n" (map (item:
          ''
            if [ ! -d "${item}" ]; then
              echo "Item ${item} is not a valid derivation"
              exit 1
            fi
          ''
        ) list)
      ) lists))}
      echo "All packages are valid derivations"
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
  inherit assertSetContains assertListIncludes assertListContains assertAllDerivations;
}
