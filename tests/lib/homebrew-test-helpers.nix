{ pkgs, lib ? pkgs.lib }:
let
  # Import base test helpers
  testHelpers = import ./test-helpers.nix { inherit pkgs lib; };

  # Color codes for test output (reuse from test-helpers)
  colors = testHelpers.colors;

  # Homebrew-specific validation patterns
  validCaskName = name:
    builtins.match "^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$" name != null;

  validMasAppId = id:
    builtins.isInt id && id > 0 && id < 2147483648; # 32-bit integer range

  # Assert cask name validity
  assertCaskValid = caskName: message:
    if validCaskName caskName then
      ''echo "${colors.green}✓${colors.reset} ${message} (${caskName})"''
    else
      ''
        echo "${colors.red}✗${colors.reset} ${message} (invalid cask name: ${caskName})"
        exit 1
      '';

  # Assert cask exists in the casks list
  assertCaskExists = casksList: caskName: message:
    if builtins.elem caskName casksList then
      ''echo "${colors.green}✓${colors.reset} ${message} (${caskName} found)"''
    else
      ''
        echo "${colors.red}✗${colors.reset} ${message} (${caskName} not found in casks list)"
        exit 1
      '';

  # Assert Mac App Store app ID validity
  assertMasAppValid = appId: message:
    if validMasAppId appId then
      ''echo "${colors.green}✓${colors.reset} ${message} (ID: ${toString appId})"''
    else
      ''
        echo "${colors.red}✗${colors.reset} ${message} (invalid MAS app ID: ${toString appId})"
        exit 1
      '';

  # Mock Homebrew state for testing
  mockHomebrewState = {
    casks ? [ "test-cask" ],
    masApps ? { "test-app" = 123456789; },
    taps ? [ ],
    brews ? [ ]
  }: {
    inherit casks masApps taps brews;
    enable = true;
    onActivation.cleanup = "zap";
  };

  # Parse homebrew configuration from a module
  parseHomebrewConfig = config:
    let
      homebrewConfig = config.homebrew or { };
    in
    {
      enabled = homebrewConfig.enable or false;
      casks = homebrewConfig.casks or [ ];
      masApps = homebrewConfig.masApps or { };
      taps = homebrewConfig.taps or [ ];
      brews = homebrewConfig.brews or [ ];
      cleanup = homebrewConfig.onActivation.cleanup or "none";
    };

  # Validate casks list structure and contents
  validateCasksList = casksList: name:
    pkgs.runCommand "validate-casks-${name}" { } ''
      echo "Validating casks list: ${name}"

      # Check if it's a list
      ${if builtins.isList casksList then
        ''echo "${colors.green}✓${colors.reset} Casks list is properly formatted"''
      else
        ''
          echo "${colors.red}✗${colors.reset} Casks must be a list"
          exit 1
        ''
      }

      # Check each cask name
      ${builtins.concatStringsSep "\n" (map (cask:
        if validCaskName cask then
          ''echo "${colors.green}✓${colors.reset} Valid cask name: ${cask}"''
        else
          ''
            echo "${colors.red}✗${colors.reset} Invalid cask name: ${cask}"
            exit 1
          ''
      ) casksList)}

      # Check for duplicates
      ${let
        duplicates = lib.filter (cask: (lib.count (x: x == cask) casksList) > 1) casksList;
        uniqueDuplicates = lib.unique duplicates;
      in
        if duplicates == [ ] then
          ''echo "${colors.green}✓${colors.reset} No duplicate casks found"''
        else
          ''
            echo "${colors.red}✗${colors.reset} Duplicate casks found: ${builtins.concatStringsSep ", " uniqueDuplicates}"
            exit 1
          ''
      }

      # Check alphabetical order
      ${let
        sorted = builtins.sort (a: b: a < b) casksList;
      in
        if casksList == sorted then
          ''echo "${colors.green}✓${colors.reset} Casks are in alphabetical order"''
        else
          ''
            echo "${colors.yellow}⚠${colors.reset} Casks are not in alphabetical order"
            echo "Expected order: ${builtins.concatStringsSep ", " sorted}"
            echo "Current order:  ${builtins.concatStringsSep ", " casksList}"
          ''
      }

      echo "Casks validation completed"
      touch $out
    '';

  # Validate MAS apps configuration
  validateMasApps = masApps: name:
    pkgs.runCommand "validate-mas-apps-${name}" { } ''
      echo "Validating MAS apps: ${name}"

      # Check if it's an attribute set
      ${if builtins.isAttrs masApps then
        ''echo "${colors.green}✓${colors.reset} MAS apps is properly formatted as attribute set"''
      else
        ''
          echo "${colors.red}✗${colors.reset} MAS apps must be an attribute set"
          exit 1
        ''
      }

      # Check each app ID
      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (appName: appId:
        if validMasAppId appId then
          ''echo "${colors.green}✓${colors.reset} Valid MAS app: ${appName} = ${toString appId}"''
        else
          ''
            echo "${colors.red}✗${colors.reset} Invalid MAS app ID for ${appName}: ${toString appId}"
            exit 1
          ''
      ) masApps)}

      echo "MAS apps validation completed"
      touch $out
    '';

  # Check for potential conflicts between Homebrew and Nix packages
  checkBrewNixConflicts = homebrewCasks: nixPackages:
    let
      # Common package names that might conflict
      potentialConflicts = [
        { brew = "docker"; nix = "docker"; }
        { brew = "git"; nix = "git"; }
        { brew = "nodejs"; nix = "nodejs"; }
        { brew = "python"; nix = "python3"; }
        { brew = "vim"; nix = "vim"; }
        { brew = "emacs"; nix = "emacs"; }
        { brew = "firefox"; nix = "firefox"; }
        { brew = "chrome"; nix = "google-chrome"; }
      ];

      nixPackageNames = map (pkg:
        if builtins.hasAttr "pname" pkg then pkg.pname
        else if builtins.hasAttr "name" pkg then pkg.name
        else "unknown"
      ) nixPackages;

      conflicts = lib.filter (conflict:
        builtins.elem conflict.brew homebrewCasks &&
        builtins.elem conflict.nix nixPackageNames
      ) potentialConflicts;
    in
    conflicts;

  # Assert no conflicts between Homebrew and Nix
  assertNoBrewNixConflicts = homebrewCasks: nixPackages: message:
    let
      conflicts = checkBrewNixConflicts homebrewCasks nixPackages;
    in
    if conflicts == [ ] then
      ''echo "${colors.green}✓${colors.reset} ${message}"''
    else
      ''
        echo "${colors.red}✗${colors.reset} ${message}"
        echo "Detected conflicts:"
        ${builtins.concatStringsSep "\n" (map (conflict:
          ''echo "  - ${conflict.brew} (Homebrew) vs ${conflict.nix} (Nix)"''
        ) conflicts)}
        exit 1
      '';

  # Create a test environment with Homebrew mock
  setupHomebrewTestEnv = homebrewState: ''
    ${testHelpers.setupTestEnv}

    # Mock Homebrew directories
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_CASKROOM="$HOMEBREW_PREFIX/Caskroom"

    # Create mock directories
    mkdir -p "$HOMEBREW_CELLAR"
    mkdir -p "$HOMEBREW_CASKROOM"

    # Mock installed casks
    ${builtins.concatStringsSep "\n" (map (cask:
      ''mkdir -p "$HOMEBREW_CASKROOM/${cask}"''
    ) homebrewState.casks)}

    echo "Homebrew test environment setup complete"
  '';

  # Test Homebrew service status
  testHomebrewService = serviceName: expectedStatus:
    ''
      # Mock service status check
      case "${serviceName}" in
        "homebrew-services")
          if [ "${expectedStatus}" = "active" ]; then
            echo "${colors.green}✓${colors.reset} Homebrew services are active"
          else
            echo "${colors.yellow}⚠${colors.reset} Homebrew services are ${expectedStatus}"
          fi
          ;;
        *)
          echo "${colors.blue}ℹ${colors.reset} Service ${serviceName} status: ${expectedStatus}"
          ;;
      esac
    '';

  # Benchmark cask installation simulation
  benchmarkCaskInstall = caskName:
    let
      # Simulate different installation times based on cask type
      estimatedTime = if builtins.elem caskName ["docker-desktop" "intellij-idea" "datagrip"] then
        5000  # Large applications
      else if builtins.elem caskName ["google-chrome" "firefox" "brave-browser"] then
        3000  # Browsers
      else
        1000; # Small utilities
    in
    ''
      echo "Simulating installation of ${caskName}..."
      ${testHelpers._measureTime ''sleep ${toString (estimatedTime / 1000)}''}
      echo "${colors.green}✓${colors.reset} ${caskName} installed in ''${DURATION}ms"
    '';

in
{
  # Expose base test helpers
  inherit (testHelpers) colors platform setupTestEnv testSection testSubsection;
  inherit (testHelpers) assertTrue assertExists assertCommand assertContains;
  inherit (testHelpers) skipOn onlyOn benchmark measureExecutionTime;
  inherit (testHelpers) createTempFile createTempDir cleanup reportResults;

  # Homebrew-specific helpers
  inherit validCaskName validMasAppId;
  inherit assertCaskValid assertCaskExists assertMasAppValid;
  inherit mockHomebrewState parseHomebrewConfig;
  inherit validateCasksList validateMasApps;
  inherit checkBrewNixConflicts assertNoBrewNixConflicts;
  inherit setupHomebrewTestEnv testHomebrewService benchmarkCaskInstall;
}
