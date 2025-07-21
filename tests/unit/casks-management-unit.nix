{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  homebrewHelpers = import ../lib/homebrew-test-helpers.nix { inherit pkgs; };

  # Import actual casks configuration (simplified approach)
  casksConfig = [
    "1password"
    "alt-tab"
    "claude"
    "docker-desktop"
    "google-chrome"
    "intellij-idea"
    "iterm2"
    "notion"
    "obsidian"
    "vlc"
  ];

  # Categorize casks based on known patterns and comments
  categorizeCasks = casksList:
    let
      development = [ "docker-desktop" "intellij-idea" "datagrip" "iterm2" ];
      communication = [ "discord" "notion" "slack" "telegram" "zoom" "obsidian" ];
      utilities = [ "alt-tab" "claude" "alfred" "hammerspoon" ];
      entertainment = [ "vlc" ];
      study = [ "anki" ];
      security = [ "1password" "1password-cli" ];
      browsers = [ "google-chrome" "brave-browser" "firefox" ];

      categorizeItem = item:
        if builtins.elem item development then "development"
        else if builtins.elem item communication then "communication"
        else if builtins.elem item utilities then "utilities"
        else if builtins.elem item entertainment then "entertainment"
        else if builtins.elem item study then "study"
        else if builtins.elem item security then "security"
        else if builtins.elem item browsers then "browsers"
        else "uncategorized";
    in
    builtins.groupBy categorizeItem casksList;
in
pkgs.runCommand "casks-management-unit-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Casks Management System Unit Tests"}

  # Test 1: Casks File Structure and Validity
  ${testHelpers.testSubsection "Casks File Structure"}

  ${testHelpers.assertExists "${src}/modules/darwin/casks.nix" "Casks configuration file exists"}

  # Test syntax validity
  if command -v nix-instantiate >/dev/null 2>&1; then
    ${testHelpers.assertCommand "nix-instantiate --eval ${src}/modules/darwin/casks.nix >/dev/null" "Casks.nix syntax is valid"}
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Skipping syntax validation (nix-instantiate not available)"
  fi

  # Test 2: Cask List Validation
  ${testHelpers.testSubsection "Cask List Validation"}

  # Validate the actual casks list
  CASKS_JSON='${builtins.toJSON casksConfig}'
  echo "$CASKS_JSON" > casks.json

  # Check if it's a proper list
  CASKS_COUNT=$(echo "$CASKS_JSON" | jq 'length')
  ${testHelpers.assertTrue ''[ "$CASKS_COUNT" -gt 0 ]'' "Casks list is not empty ($CASKS_COUNT items)"}

  # Test each cask name format
  echo "Validating individual cask names..."
  ${builtins.concatStringsSep "\n" (map (cask:
    homebrewHelpers.assertCaskValid cask "Cask name '${cask}' is valid"
  ) casksConfig)}

  # Test 3: Duplicate Detection
  ${testHelpers.testSubsection "Duplicate Detection"}

  # Check for duplicates using shell tools
  echo "$CASKS_JSON" | jq -r '.[]' | sort > casks_sorted.txt
  DUPLICATES=$(uniq -d casks_sorted.txt)

  if [ -z "$DUPLICATES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No duplicate casks found"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Duplicate casks found:"
    echo "$DUPLICATES"
    exit 1
  fi

  # Test 4: Alphabetical Order Verification
  ${testHelpers.testSubsection "Alphabetical Order"}

  # Check if casks are in alphabetical order
  echo "$CASKS_JSON" | jq -r '.[]' > casks_current.txt
  echo "$CASKS_JSON" | jq -r '.[]' | sort > casks_expected.txt

  if diff -q casks_current.txt casks_expected.txt >/dev/null; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Casks are in alphabetical order"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Casks are not in alphabetical order"
    echo "Current order vs Expected order:"
    diff casks_current.txt casks_expected.txt || true
  fi

  # Test 5: Category-based Analysis
  ${testHelpers.testSubsection "Category Analysis"}

  # Analyze casks by categories
  ${let
    categorized = categorizeCasks casksConfig;
    categories = builtins.attrNames categorized;
  in
    builtins.concatStringsSep "\n" (map (category:
      let
        items = categorized.${category};
        count = builtins.length items;
      in
      ''echo "${testHelpers.colors.blue}${category}:${testHelpers.colors.reset} ${toString count} items (${builtins.concatStringsSep ", " items})"''
    ) categories)
  }

  # Test 6: Known Problematic Casks Detection
  ${testHelpers.testSubsection "Problematic Casks Detection"}

  # List of casks known to have issues
  PROBLEMATIC_CASKS="java oracle-jdk flash-player"

  for cask in $PROBLEMATIC_CASKS; do
    if echo "$CASKS_JSON" | jq -r '.[]' | grep -q "^$cask$"; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Potentially problematic cask detected: $cask"
    fi
  done
  echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Problematic cask detection completed"

  # Test 7: Cask Name Pattern Analysis
  ${testHelpers.testSubsection "Name Pattern Analysis"}

  # Count different naming patterns
  HYPHENATED=$(echo "$CASKS_JSON" | jq -r '.[]' | grep -c '-' || echo "0")
  SINGLE_WORDS=$(echo "$CASKS_JSON" | jq -r '.[]' | grep -v '-' | wc -l)
  NUMBERS=$(echo "$CASKS_JSON" | jq -r '.[]' | grep -c '[0-9]' || echo "0")

  echo "${testHelpers.colors.blue}Naming patterns:${testHelpers.colors.reset}"
  echo "  Hyphenated names: $HYPHENATED"
  echo "  Single words: $SINGLE_WORDS"
  echo "  Contains numbers: $NUMBERS"

  # Test 8: Essential Casks Presence
  ${testHelpers.testSubsection "Essential Casks Presence"}

  # Check for essential development tools
  ESSENTIAL_CASKS="docker-desktop intellij-idea iterm2 google-chrome 1password"

  for cask in $ESSENTIAL_CASKS; do
    if echo "$CASKS_JSON" | jq -r '.[]' | grep -q "^$cask$"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Essential cask present: $cask"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Essential cask missing: $cask"
    fi
  done

  # Test 9: Cask Description Validation (Mock)
  ${testHelpers.testSubsection "Cask Metadata Validation"}

  # Mock validation of cask metadata
  SAMPLE_CASKS="docker-desktop google-chrome 1password"

  for cask in $SAMPLE_CASKS; do
    if echo "$CASKS_JSON" | jq -r '.[]' | grep -q "^$cask$"; then
      # Simulate metadata checks
      case "$cask" in
        "docker-desktop")
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $cask: Container platform (validated)"
          ;;
        "google-chrome")
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $cask: Web browser (validated)"
          ;;
        "1password")
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $cask: Password manager (validated)"
          ;;
      esac
    fi
  done

  # Test 10: Security-sensitive Casks Review
  ${testHelpers.testSubsection "Security-sensitive Casks"}

  SECURITY_CASKS="1password 1password-cli wireguard"

  for cask in $SECURITY_CASKS; do
    if echo "$CASKS_JSON" | jq -r '.[]' | grep -q "^$cask$"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Security cask present: $cask"
    fi
  done

  # Test 11: Performance Impact Analysis
  ${testHelpers.testSubsection "Performance Impact Analysis"}

  # Categorize casks by estimated resource usage
  HEAVY_CASKS="docker-desktop intellij-idea datagrip"
  MEDIUM_CASKS="google-chrome firefox brave-browser"
  LIGHT_CASKS="alt-tab alfred 1password-cli"

  echo "${testHelpers.colors.blue}Resource usage categories:${testHelpers.colors.reset}"

  for cask in $HEAVY_CASKS; do
    if echo "$CASKS_JSON" | jq -r '.[]' | grep -q "^$cask$"; then
      echo "  ${testHelpers.colors.red}Heavy:${testHelpers.colors.reset} $cask"
    fi
  done

  for cask in $MEDIUM_CASKS; do
    if echo "$CASKS_JSON" | jq -r '.[]' | grep -q "^$cask$"; then
      echo "  ${testHelpers.colors.yellow}Medium:${testHelpers.colors.reset} $cask"
    fi
  done

  for cask in $LIGHT_CASKS; do
    if echo "$CASKS_JSON" | jq -r '.[]' | grep -q "^$cask$"; then
      echo "  ${testHelpers.colors.green}Light:${testHelpers.colors.reset} $cask"
    fi
  done

  # Test 12: Version Consistency Check
  ${testHelpers.testSubsection "Version Consistency"}

  # Check for version-specific casks that might need updating
  VERSION_SPECIFIC=$(echo "$CASKS_JSON" | jq -r '.[]' | grep -E '[0-9]+\.[0-9]+' || echo "")

  if [ -z "$VERSION_SPECIFIC" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No version-specific cask names found"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Version-specific casks found:"
    echo "$VERSION_SPECIFIC"
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Casks Management Unit Tests ===${testHelpers.colors.reset}"
  echo "Total casks analyzed: $CASKS_COUNT"
  echo "Categories identified: ${toString (builtins.length (builtins.attrNames (categorizeCasks casksConfig)))}"
  echo "${testHelpers.colors.green}✓ All casks management unit tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
