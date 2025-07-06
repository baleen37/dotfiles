# iTerm2 Configuration Integration Tests
# Ensures iTerm2 dynamic profiles are correctly configured and deployed

{ pkgs, lib, ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # Test user for consistency  
  testUser = "integration-test-user";
  mockEnv = { USER = testUser; };
  
  # Expected paths for iTerm2 configuration
  expectedHomePath = "/Users/${testUser}";
  expectedIterm2ConfigPath = "${expectedHomePath}/Library/Application Support/iTerm2/DynamicProfiles";
  expectedDynamicProfilesPath = "${expectedIterm2ConfigPath}/DynamicProfiles.json";
  
  # Test that iTerm2 configuration files exist in the right locations
  testIterm2ConfigExists = ''
    ${testHelpers.testSubsection "iTerm2 Configuration File Existence"}
    
    # Test that the source configuration exists
    SOURCE_CONFIG="${../../modules/darwin/config/iterm2/DynamicProfiles.json}"
    ${testHelpers.assertExists "$SOURCE_CONFIG" "Source iTerm2 configuration exists"}
    
    # Test that the configuration is valid JSON
    ${testHelpers.assertCommand "cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq empty" "iTerm2 configuration is valid JSON"}
    
    echo "✓ iTerm2 configuration file tests passed"
  '';
  
  # Test that iTerm2 profiles have required structure
  testIterm2ProfileStructure = ''
    ${testHelpers.testSubsection "iTerm2 Profile Structure Validation"}
    
    SOURCE_CONFIG="${../../modules/darwin/config/iterm2/DynamicProfiles.json}"
    
    # Check that it has Profiles array
    ${testHelpers.assertCommand "cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq -e '.Profiles' > /dev/null" "Configuration has Profiles array"}
    
    # Check that profiles array is not empty
    ${testHelpers.assertCommand "test $(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq '.Profiles | length') -gt 0" "Profiles array is not empty"}
    
    # Check that each profile has required fields
    cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq -r '.Profiles[] | .Name' > profile-names.txt
    
    # Verify Default profile exists
    ${testHelpers.assertContains "profile-names.txt" "Default" "Default profile exists"}
    
    # Verify Development profile exists  
    ${testHelpers.assertContains "profile-names.txt" "Development" "Development profile exists"}
    
    # Test Default profile structure
    DEFAULT_PROFILE=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq '.Profiles[] | select(.Name=="Default")')
    
    # Check required fields for Default profile
    echo "$DEFAULT_PROFILE" | ${pkgs.jq}/bin/jq -e '.Guid' > /dev/null || { echo "✗ Default profile missing Guid"; exit 1; }
    echo "$DEFAULT_PROFILE" | ${pkgs.jq}/bin/jq -e '.Name' > /dev/null || { echo "✗ Default profile missing Name"; exit 1; }
    echo "$DEFAULT_PROFILE" | ${pkgs.jq}/bin/jq -e '."Normal Font"' > /dev/null || { echo "✗ Default profile missing Normal Font"; exit 1; }
    echo "$DEFAULT_PROFILE" | ${pkgs.jq}/bin/jq -e '."Background Color"' > /dev/null || { echo "✗ Default profile missing Background Color"; exit 1; }
    echo "$DEFAULT_PROFILE" | ${pkgs.jq}/bin/jq -e '."Foreground Color"' > /dev/null || { echo "✗ Default profile missing Foreground Color"; exit 1; }
    
    echo "✓ Default profile structure is valid"
    
    # Test Development profile structure
    DEV_PROFILE=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq '.Profiles[] | select(.Name=="Development")')
    
    # Check required fields for Development profile
    echo "$DEV_PROFILE" | ${pkgs.jq}/bin/jq -e '.Guid' > /dev/null || { echo "✗ Development profile missing Guid"; exit 1; }
    echo "$DEV_PROFILE" | ${pkgs.jq}/bin/jq -e '.Name' > /dev/null || { echo "✗ Development profile missing Name"; exit 1; }
    echo "$DEV_PROFILE" | ${pkgs.jq}/bin/jq -e '."Badge Text"' > /dev/null || { echo "✗ Development profile missing Badge Text"; exit 1; }
    echo "$DEV_PROFILE" | ${pkgs.jq}/bin/jq -e '."Working Directory"' > /dev/null || { echo "✗ Development profile missing Working Directory"; exit 1; }
    
    # Verify Development profile has larger dimensions
    DEV_ROWS=$(echo "$DEV_PROFILE" | ${pkgs.jq}/bin/jq -r '.Rows')
    DEV_COLS=$(echo "$DEV_PROFILE" | ${pkgs.jq}/bin/jq -r '.Columns')
    
    if [ "$DEV_ROWS" -gt 25 ] && [ "$DEV_COLS" -gt 80 ]; then
      echo "✓ Development profile has larger dimensions ($DEV_COLS x $DEV_ROWS)"
    else
      echo "✗ Development profile should have larger dimensions than Default"
      exit 1
    fi
    
    echo "✓ Development profile structure is valid"
    
    # Clean up
    rm -f profile-names.txt
    
    echo "✓ iTerm2 profile structure tests passed"
  '';
  
  # Test that iTerm2 configuration is properly integrated with darwin files module
  testIterm2DarwinIntegration = ''
    ${testHelpers.testSubsection "iTerm2 Darwin Module Integration"}
    
    # Test that files.nix includes iTerm2 configuration
    DARWIN_FILES="${../../modules/darwin/files.nix}"
    ${testHelpers.assertExists "$DARWIN_FILES" "Darwin files module exists"}
    
    # Check that iTerm2 configuration is referenced in files.nix
    ${testHelpers.assertContains "$DARWIN_FILES" "iTerm2/DynamicProfiles" "Darwin files module references iTerm2 config"}
    ${testHelpers.assertContains "$DARWIN_FILES" "Application Support" "Darwin files module uses correct macOS path"}
    
    echo "✓ iTerm2 Darwin integration tests passed"
  '';
  
  # Test that iTerm2 profiles have sensible defaults
  testIterm2ProfileDefaults = ''
    ${testHelpers.testSubsection "iTerm2 Profile Defaults Validation"}
    
    SOURCE_CONFIG="${../../modules/darwin/config/iterm2/DynamicProfiles.json}"
    
    # Test font configuration
    FONT_NAME=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq -r '.Profiles[] | select(.Name=="Default") | ."Normal Font"')
    if [[ "$FONT_NAME" =~ MesloLGS ]]; then
      echo "✓ Default profile uses MesloLGS font family"
    else
      echo "✗ Default profile should use MesloLGS font, got: $FONT_NAME"
      exit 1
    fi
    
    # Test scrollback configuration
    SCROLLBACK=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq -r '.Profiles[] | select(.Name=="Default") | ."Scrollback Lines"')
    if [ "$SCROLLBACK" -ge 1000 ]; then
      echo "✓ Default profile has reasonable scrollback ($SCROLLBACK lines)"
    else
      echo "✗ Default profile should have at least 1000 scrollback lines, got: $SCROLLBACK"
      exit 1
    fi
    
    # Test Development profile scrollback is larger
    DEV_SCROLLBACK=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq -r '.Profiles[] | select(.Name=="Development") | ."Scrollback Lines"')
    if [ "$DEV_SCROLLBACK" -gt "$SCROLLBACK" ]; then
      echo "✓ Development profile has larger scrollback ($DEV_SCROLLBACK lines)"
    else
      echo "✗ Development profile should have larger scrollback than Default"
      exit 1
    fi
    
    # Test that Development profile has badge text
    DEV_BADGE=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq -r '.Profiles[] | select(.Name=="Development") | ."Badge Text"')
    if [ -n "$DEV_BADGE" ] && [ "$DEV_BADGE" != "null" ]; then
      echo "✓ Development profile has badge text: $DEV_BADGE"
    else
      echo "✗ Development profile should have badge text"
      exit 1
    fi
    
    # Test that Development profile has custom working directory
    DEV_WORKDIR=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq -r '.Profiles[] | select(.Name=="Development") | ."Working Directory"')
    if [ "$DEV_WORKDIR" != "~" ]; then
      echo "✓ Development profile has custom working directory: $DEV_WORKDIR"
    else
      echo "✗ Development profile should have custom working directory"
      exit 1
    fi
    
    echo "✓ iTerm2 profile defaults tests passed"
  '';
  
  # Test that color schemes are properly configured
  testIterm2ColorSchemes = ''
    ${testHelpers.testSubsection "iTerm2 Color Scheme Validation"}
    
    SOURCE_CONFIG="${../../modules/darwin/config/iterm2/DynamicProfiles.json}"
    
    # Test that all profiles have color configurations
    for profile in "Default" "Development"; do
      echo "Testing color scheme for $profile profile..."
      
      PROFILE_DATA=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq ".Profiles[] | select(.Name==\"$profile\")")
      
      # Check essential colors exist
      echo "$PROFILE_DATA" | ${pkgs.jq}/bin/jq -e '."Background Color"' > /dev/null || { echo "✗ $profile profile missing Background Color"; exit 1; }
      echo "$PROFILE_DATA" | ${pkgs.jq}/bin/jq -e '."Foreground Color"' > /dev/null || { echo "✗ $profile profile missing Foreground Color"; exit 1; }
      echo "$PROFILE_DATA" | ${pkgs.jq}/bin/jq -e '."Cursor Color"' > /dev/null || { echo "✗ $profile profile missing Cursor Color"; exit 1; }
      echo "$PROFILE_DATA" | ${pkgs.jq}/bin/jq -e '."Selection Color"' > /dev/null || { echo "✗ $profile profile missing Selection Color"; exit 1; }
      
      # Check ANSI colors (0-15)
      for i in {0..15}; do
        echo "$PROFILE_DATA" | ${pkgs.jq}/bin/jq -e ".\"Ansi $i Color\"" > /dev/null || { echo "✗ $profile profile missing Ansi $i Color"; exit 1; }
      done
      
      echo "✓ $profile profile has complete color scheme"
    done
    
    echo "✓ iTerm2 color scheme tests passed"
  '';
  
  # Test keyboard mappings
  testIterm2KeyboardMappings = ''
    ${testHelpers.testSubsection "iTerm2 Keyboard Mapping Validation"}
    
    SOURCE_CONFIG="${../../modules/darwin/config/iterm2/DynamicProfiles.json}"
    
    # Test that profiles have keyboard mappings
    for profile in "Default" "Development"; do
      echo "Testing keyboard mappings for $profile profile..."
      
      PROFILE_DATA=$(cat $SOURCE_CONFIG | ${pkgs.jq}/bin/jq ".Profiles[] | select(.Name==\"$profile\")")
      
      # Check that Keyboard Map exists
      echo "$PROFILE_DATA" | ${pkgs.jq}/bin/jq -e '."Keyboard Map"' > /dev/null || { echo "✗ $profile profile missing Keyboard Map"; exit 1; }
      
      # Check that it has some key mappings
      KEYMAP_COUNT=$(echo "$PROFILE_DATA" | ${pkgs.jq}/bin/jq '."Keyboard Map" | length')
      if [ "$KEYMAP_COUNT" -gt 0 ]; then
        echo "✓ $profile profile has $KEYMAP_COUNT keyboard mappings"
      else
        echo "✗ $profile profile should have keyboard mappings"
        exit 1
      fi
      
      echo "✓ $profile profile keyboard mappings are valid"
    done
    
    echo "✓ iTerm2 keyboard mapping tests passed"
  '';

in
pkgs.runCommand "iterm2-configuration-integration-test" {
  buildInputs = [
    pkgs.jq
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.bash
  ];
} ''
  set -e
  
  ${testHelpers.testSection "iTerm2 Configuration Integration Tests"}
  
  # Create test environment
  ${testHelpers.setupTestEnv}
  
  # Run all iTerm2 configuration tests
  ${testIterm2ConfigExists}
  ${testIterm2ProfileStructure}
  ${testIterm2DarwinIntegration}
  ${testIterm2ProfileDefaults}
  ${testIterm2ColorSchemes}
  ${testIterm2KeyboardMappings}
  
  ${testHelpers.testSection "Test Summary"}
  
  # All tests passed if we reach this point
  ${testHelpers.reportResults "iTerm2 Configuration Integration Tests" 6 6}
  
  # Create success marker
  touch $out
  
  echo ""
  echo "✅ All iTerm2 configuration integration tests passed!"
  echo "- Configuration file existence: ✓"
  echo "- Profile structure validation: ✓"
  echo "- Darwin module integration: ✓"
  echo "- Profile defaults validation: ✓"
  echo "- Color scheme validation: ✓"
  echo "- Keyboard mapping validation: ✓"
''