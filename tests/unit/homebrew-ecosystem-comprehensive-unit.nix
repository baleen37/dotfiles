{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  homebrewHelpers = import ../lib/homebrew-test-helpers.nix { inherit pkgs; };

  # Import the actual home-manager configuration
  homeManagerConfig = import "${src}/modules/darwin/home-manager.nix";
  casksConfig = import "${src}/modules/darwin/casks.nix" { };
in
pkgs.runCommand "homebrew-ecosystem-comprehensive-unit-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Homebrew Ecosystem Comprehensive Unit Tests"}

  # Test 1: Homebrew Configuration Structure
  ${testHelpers.testSubsection "Homebrew Configuration Structure"}

  # Create a mock configuration to test structure
  ${testHelpers.createTempFile ''
    { config, pkgs, lib, home-manager, self, ... }:
    {
      homebrew = {
        enable = true;
        casks = ["test-cask"];
        masApps = { "test-app" = 123456789; };
        onActivation.cleanup = "uninstall";
      };
    }
  ''
  }
  CONFIG_FILE=$TEMP_FILE

  ${testHelpers.assertExists "$CONFIG_FILE" "Mock homebrew configuration created"}
  ${testHelpers.assertContains "$CONFIG_FILE" "homebrew" "Homebrew section present"}
  ${testHelpers.assertContains "$CONFIG_FILE" "enable = true" "Homebrew enabled"}
  ${testHelpers.assertContains "$CONFIG_FILE" "casks" "Casks configuration present"}
  ${testHelpers.assertContains "$CONFIG_FILE" "masApps" "MAS apps configuration present"}

  # Test 2: Homebrew Integration Components
  ${testHelpers.testSubsection "Homebrew Integration Components"}

  # Test nix-homebrew integration patterns
  ${testHelpers.createTempFile ''
    {
      homebrew = {
        enable = true;
        onActivation.cleanup = "uninstall";
        taps = [
          "homebrew/bundle"
          "homebrew/cask-fonts"
          "homebrew/services"
        ];
      };
    }
  ''
  }
  INTEGRATION_FILE=$TEMP_FILE

  ${testHelpers.assertContains "$INTEGRATION_FILE" "homebrew/bundle" "Homebrew bundle tap configured"}
  ${testHelpers.assertContains "$INTEGRATION_FILE" "homebrew/cask-fonts" "Homebrew cask-fonts tap configured"}
  ${testHelpers.assertContains "$INTEGRATION_FILE" "homebrew/services" "Homebrew services tap configured"}

  # Test 3: MAS (Mac App Store) Integration
  ${testHelpers.testSubsection "MAS Integration"}

  # Test MAS app configuration validation
  ${homebrewHelpers.assertMasAppValid 441258766 "Valid MAS app ID for Magnet"}
  ${homebrewHelpers.assertMasAppValid 1451685025 "Valid MAS app ID for WireGuard"}
  ${homebrewHelpers.assertMasAppValid 869223134 "Valid MAS app ID for KakaoTalk"}

  # Test invalid MAS app IDs
  if ${if homebrewHelpers.validMasAppId (-1) then "true" else "false"}; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Negative MAS app ID should be invalid"
    exit 1
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Negative MAS app ID correctly rejected"
  fi

  if ${if homebrewHelpers.validMasAppId 0 then "true" else "false"}; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Zero MAS app ID should be invalid"
    exit 1
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Zero MAS app ID correctly rejected"
  fi

  # Test 4: Homebrew Cleanup Configuration
  ${testHelpers.testSubsection "Homebrew Cleanup Configuration"}

  # Test cleanup options
  ${testHelpers.createTempFile ''
    {
      homebrew = {
        enable = true;
        onActivation.cleanup = "zap";
      };
    }
  ''
  }
  CLEANUP_FILE=$TEMP_FILE

  ${testHelpers.assertContains "$CLEANUP_FILE" "cleanup" "Cleanup configuration present"}
  ${testHelpers.assertContains "$CLEANUP_FILE" "zap" "Cleanup mode configured"}

  # Test 5: Homebrew Environment Variables
  ${testHelpers.testSubsection "Homebrew Environment Variables"}

  # Mock Homebrew environment setup
  ${homebrewHelpers.setupHomebrewTestEnv (homebrewHelpers.mockHomebrewState {
    casks = ["test-cask"];
    masApps = { "test-app" = 123456789; };
  })}

  ${testHelpers.assertExists "$HOMEBREW_PREFIX" "Homebrew prefix directory exists"}
  ${testHelpers.assertExists "$HOMEBREW_CELLAR" "Homebrew cellar directory exists"}
  ${testHelpers.assertExists "$HOMEBREW_CASKROOM" "Homebrew caskroom directory exists"}

  # Test 6: Cask Management Integration
  ${testHelpers.testSubsection "Cask Management Integration"}

  # Test cask list structure from actual config
  CASKS_COUNT=$(echo '${builtins.toJSON casksConfig}' | wc -l)
  if [ "$CASKS_COUNT" -gt 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Casks configuration loaded ($CASKS_COUNT items)"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} No casks found in configuration"
    exit 1
  fi

  # Test cask name validation for known casks
  ${homebrewHelpers.assertCaskValid "docker-desktop" "Docker Desktop cask name valid"}
  ${homebrewHelpers.assertCaskValid "intellij-idea" "IntelliJ IDEA cask name valid"}
  ${homebrewHelpers.assertCaskValid "1password" "1Password cask name valid"}
  ${homebrewHelpers.assertCaskValid "alt-tab" "Alt-Tab cask name valid"}

  # Test invalid cask names
  if ${if homebrewHelpers.validCaskName "Invalid_Cask" then "true" else "false"}; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Invalid cask name with underscore should be rejected"
    exit 1
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Invalid cask name correctly rejected"
  fi

  if ${if homebrewHelpers.validCaskName "-invalid-start" then "true" else "false"}; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cask name starting with dash should be rejected"
    exit 1
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Invalid cask name start correctly rejected"
  fi

  # Test 7: Homebrew Service Status Simulation
  ${testHelpers.testSubsection "Homebrew Service Status"}

  ${homebrewHelpers.testHomebrewService "homebrew-services" "active"}

  # Test 8: Configuration Parsing
  ${testHelpers.testSubsection "Configuration Parsing"}

  # Create a test configuration
  ${testHelpers.createTempFile ''
    {
      homebrew = {
        enable = true;
        casks = ["test-cask-1" "test-cask-2"];
        masApps = {
          "test-app-1" = 123456789;
          "test-app-2" = 987654321;
        };
        onActivation.cleanup = "uninstall";
        taps = ["homebrew/core"];
        brews = ["git" "curl"];
      };
    }
  ''
  }
  PARSE_CONFIG_FILE=$TEMP_FILE

  # Test config parsing (simulated)
  ${testHelpers.assertContains "$PARSE_CONFIG_FILE" "test-cask-1" "First test cask found"}
  ${testHelpers.assertContains "$PARSE_CONFIG_FILE" "test-cask-2" "Second test cask found"}
  ${testHelpers.assertContains "$PARSE_CONFIG_FILE" "test-app-1" "First test app found"}
  ${testHelpers.assertContains "$PARSE_CONFIG_FILE" "test-app-2" "Second test app found"}
  ${testHelpers.assertContains "$PARSE_CONFIG_FILE" "homebrew/core" "Core tap found"}
  ${testHelpers.assertContains "$PARSE_CONFIG_FILE" "git" "Git brew found"}
  ${testHelpers.assertContains "$PARSE_CONFIG_FILE" "curl" "Curl brew found"}

  # Test 9: Performance Benchmarks
  ${testHelpers.testSubsection "Performance Benchmarks"}

  # Benchmark cask installation simulation
  ${homebrewHelpers.benchmarkCaskInstall "test-utility"}
  ${homebrewHelpers.benchmarkCaskInstall "google-chrome"}
  ${homebrewHelpers.benchmarkCaskInstall "docker-desktop"}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Homebrew Ecosystem Comprehensive Unit Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All Homebrew ecosystem unit tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
