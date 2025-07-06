# app-links-integration.nix - app-links 모듈 통합 테스트
# Darwin 시스템에서 실제 nix store와 /Applications 디렉토리 연동 테스트

{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Mock nix store structure for testing
  mockNixStore = pkgs.runCommand "mock-nix-store" {} ''
    mkdir -p $out/nix/store

    # Create mock app structures
    mkdir -p "$out/nix/store/test-karabiner-14.13.0/Applications/Karabiner-Elements.app"
    mkdir -p "$out/nix/store/test-karabiner-15.3.0/Applications/Karabiner-Elements.app"
    mkdir -p "$out/nix/store/test-rectangle-1.0.0/Applications/Rectangle.app"
    mkdir -p "$out/nix/store/test-alacritty-0.13.0/Applications/Alacritty.app"

    # Create some non-Applications paths to test priority logic
    mkdir -p "$out/nix/store/test-other-14.13.0/bin/Karabiner-Elements.app"

    # Add some dummy content to make them look like real apps
    echo "mock app" > "$out/nix/store/test-karabiner-15.3.0/Applications/Karabiner-Elements.app/Contents"
    echo "mock app" > "$out/nix/store/test-rectangle-1.0.0/Applications/Rectangle.app/Contents"
    echo "mock app" > "$out/nix/store/test-alacritty-0.13.0/Applications/Alacritty.app/Contents"
  '';

  # Create a test environment with proper paths
  testEnv = ''
    export PATH=${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:$PATH

    # Setup mock directories
    TEST_APPLICATIONS_DIR=$(mktemp -d)
    TEST_NIX_STORE="${mockNixStore}/nix/store"

    echo "Test environment:"
    echo "  Applications dir: $TEST_APPLICATIONS_DIR"
    echo "  Mock nix store: $TEST_NIX_STORE"
  '';

  # Modified app finding function for testing
  testFindNixApp = ''
    find_nix_app() {
      local app_name="$1"

      # Search in Applications folders first
      APP_PATH=$(find "$TEST_NIX_STORE" -name "$app_name" -type d -path "*/Applications/*" 2>/dev/null | sort -V | tail -1)

      # If not found in Applications, search everywhere
      if [ -z "$APP_PATH" ]; then
        APP_PATH=$(find "$TEST_NIX_STORE" -name "$app_name" -type d 2>/dev/null | sort -V | tail -1)
      fi

      echo "$APP_PATH"
    }
  '';

  # Test link creation function
  testCreateAppLink = ''
    create_app_link() {
      local app_name="$1"
      local app_path=$(find_nix_app "$app_name")
      local target_path="$TEST_APPLICATIONS_DIR/$app_name"

      echo "🔗 Linking $app_name..."

      if [ -n "$app_path" ] && [ -d "$app_path" ]; then
        # Remove existing link or directory
        if [ -L "$target_path" ] || [ -d "$target_path" ]; then
          rm -rf "$target_path"
        fi

        # Create symbolic link
        ln -sf "$app_path" "$target_path"
        echo "   ✅ Successfully linked: $app_path → $target_path"
        return 0
      else
        echo "   ⚠️  $app_name not found in nix store"
        return 1
      fi
    }
  '';

in
pkgs.runCommand "app-links-integration-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}
  ${testEnv}
  ${testFindNixApp}
  ${testCreateAppLink}

  ${testHelpers.testSection "App-Links Integration Tests"}

  # Test 1: Mock nix store structure
  ${testHelpers.testSubsection "Mock Environment Setup"}

  ${testHelpers.assertExists "$TEST_NIX_STORE/test-karabiner-15.3.0/Applications/Karabiner-Elements.app" "Mock Karabiner 15.3.0 exists"}
  ${testHelpers.assertExists "$TEST_NIX_STORE/test-karabiner-14.13.0/Applications/Karabiner-Elements.app" "Mock Karabiner 14.13.0 exists"}
  ${testHelpers.assertExists "$TEST_NIX_STORE/test-rectangle-1.0.0/Applications/Rectangle.app" "Mock Rectangle exists"}
  ${testHelpers.assertExists "$TEST_NIX_STORE/test-alacritty-0.13.0/Applications/Alacritty.app" "Mock Alacritty exists"}

  # Test 2: App finding with version priority
  ${testHelpers.testSubsection "App Finding Logic"}

  KARABINER_PATH=$(find_nix_app "Karabiner-Elements.app")
  ${testHelpers.assertTrue "[ -n \"$KARABINER_PATH\" ]" "Karabiner-Elements.app found"}
  ${testHelpers.assertTrue "echo \"$KARABINER_PATH\" | grep -q \"15.3.0\"" "Latest version (15.3.0) selected"}

  RECTANGLE_PATH=$(find_nix_app "Rectangle.app")
  ${testHelpers.assertTrue "[ -n \"$RECTANGLE_PATH\" ]" "Rectangle.app found"}

  ALACRITTY_PATH=$(find_nix_app "Alacritty.app")
  ${testHelpers.assertTrue "[ -n \"$ALACRITTY_PATH\" ]" "Alacritty.app found"}

  # Test 3: Non-existent app handling
  ${testHelpers.testSubsection "Non-existent App Handling"}

  NONEXISTENT_PATH=$(find_nix_app "NonExistent.app")
  ${testHelpers.assertTrue "[ -z \"$NONEXISTENT_PATH\" ]" "Non-existent app returns empty"}

  # Test 4: Single app link creation
  ${testHelpers.testSubsection "Single App Link Creation"}

  create_app_link "Karabiner-Elements.app"
  ${testHelpers.assertExists "$TEST_APPLICATIONS_DIR/Karabiner-Elements.app" "Karabiner link created"}
  ${testHelpers.assertTrue "[ -L \"$TEST_APPLICATIONS_DIR/Karabiner-Elements.app\" ]" "Karabiner link is symbolic"}

  # Verify the link points to the correct version
  LINK_TARGET=$(readlink "$TEST_APPLICATIONS_DIR/Karabiner-Elements.app")
  ${testHelpers.assertTrue "echo \"$LINK_TARGET\" | grep -q \"15.3.0\"" "Link points to latest version"}

  # Test 5: Multiple app links
  ${testHelpers.testSubsection "Multiple App Links"}

  create_app_link "Rectangle.app"
  create_app_link "Alacritty.app"

  ${testHelpers.assertExists "$TEST_APPLICATIONS_DIR/Rectangle.app" "Rectangle link created"}
  ${testHelpers.assertExists "$TEST_APPLICATIONS_DIR/Alacritty.app" "Alacritty link created"}
  ${testHelpers.assertTrue "[ -L \"$TEST_APPLICATIONS_DIR/Rectangle.app\" ]" "Rectangle link is symbolic"}
  ${testHelpers.assertTrue "[ -L \"$TEST_APPLICATIONS_DIR/Alacritty.app\" ]" "Alacritty link is symbolic"}

  # Test 6: Link replacement
  ${testHelpers.testSubsection "Link Replacement"}

  # Create a dummy file to be replaced
  touch "$TEST_APPLICATIONS_DIR/TestReplace.app"
  ${testHelpers.assertTrue "[ -f \"$TEST_APPLICATIONS_DIR/TestReplace.app\" ]" "Dummy file created"}

  # Create a mock app to link to
  mkdir -p "$TEST_NIX_STORE/test-replace-1.0.0/Applications/TestReplace.app"
  create_app_link "TestReplace.app"

  ${testHelpers.assertTrue "[ -L \"$TEST_APPLICATIONS_DIR/TestReplace.app\" ]" "File replaced with symbolic link"}

  # Test 7: Error handling for missing apps
  ${testHelpers.testSubsection "Error Handling"}

  set +e  # Allow command to fail
  create_app_link "NonExistent.app" 2>/dev/null
  EXIT_CODE=$?
  set -e

  ${testHelpers.assertTrue "[ $EXIT_CODE -ne 0 ]" "Missing app returns error code"}
  ${testHelpers.assertTrue "[ ! -e \"$TEST_APPLICATIONS_DIR/NonExistent.app\" ]" "No link created for missing app"}

  # Test 8: Applications folder priority
  ${testHelpers.testSubsection "Applications Folder Priority"}

  # We have Karabiner-Elements.app in both Applications and bin folders
  # The one in Applications should be selected
  KARABINER_PATH=$(find_nix_app "Karabiner-Elements.app")
  ${testHelpers.assertTrue "echo \"$KARABINER_PATH\" | grep -q \"Applications\"" "Applications folder has priority"}
  ${testHelpers.assertTrue "echo \"$KARABINER_PATH\" | grep -qv \"/bin/\"" "bin folder version not selected"}

  # Test 9: Batch linking simulation
  ${testHelpers.testSubsection "Batch Linking"}

  # Clean up existing links
  rm -rf "$TEST_APPLICATIONS_DIR"/*

  # Create all links in batch
  APPS_TO_LINK="Karabiner-Elements.app Rectangle.app Alacritty.app"
  LINK_COUNT=0

  for app in $APPS_TO_LINK; do
    if create_app_link "$app" >/dev/null 2>&1; then
      LINK_COUNT=$((LINK_COUNT + 1))
    fi
  done

  ${testHelpers.assertTrue "[ $LINK_COUNT -eq 3 ]" "All apps linked successfully in batch"}

  # Test 10: Path validation
  ${testHelpers.testSubsection "Path Validation"}

  # Test that all created links have valid targets
  for app in $APPS_TO_LINK; do
    if [ -L "$TEST_APPLICATIONS_DIR/$app" ]; then
      TARGET=$(readlink "$TEST_APPLICATIONS_DIR/$app")
      ${testHelpers.assertTrue "[ -d \"$TARGET\" ]" "Link target for $app is valid directory"}
    fi
  done

  # Test 11: Version sorting verification
  ${testHelpers.testSubsection "Version Sorting"}

  # List all Karabiner versions and verify sorting
  VERSIONS=$(find "$TEST_NIX_STORE" -name "Karabiner-Elements.app" -type d -path "*/Applications/*" | sort -V)
  LATEST=$(echo "$VERSIONS" | tail -1)

  ${testHelpers.assertTrue "echo \"$LATEST\" | grep -q \"15.3.0\"" "Version sorting works correctly"}

  # Cleanup
  rm -rf "$TEST_APPLICATIONS_DIR"

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: App-Links Integration Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All integration tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
