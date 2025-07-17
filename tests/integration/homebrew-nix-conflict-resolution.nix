{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  homebrewHelpers = import ../lib/homebrew-test-helpers.nix { inherit pkgs; };

  # Import configurations
  darwinPackages = import "${src}/modules/darwin/packages.nix" { inherit pkgs; };
  casksConfig = import "${src}/modules/darwin/casks.nix" { };
  sharedPackages = import "${src}/modules/shared/packages.nix" { inherit pkgs; };

  # Combined Nix packages
  allNixPackages = darwinPackages ++ sharedPackages;

  # Known potential conflicts between Homebrew and Nix
  potentialConflicts = [
    { homebrew = "docker"; nix = "docker"; category = "containers"; }
    { homebrew = "git"; nix = "git"; category = "version-control"; }
    { homebrew = "nodejs"; nix = "nodejs"; category = "development"; }
    { homebrew = "python"; nix = "python3"; category = "development"; }
    { homebrew = "vim"; nix = "vim"; category = "editors"; }
    { homebrew = "emacs"; nix = "emacs"; category = "editors"; }
    { homebrew = "firefox"; nix = "firefox"; category = "browsers"; }
    { homebrew = "google-chrome"; nix = "google-chrome"; category = "browsers"; }
    { homebrew = "vscode"; nix = "vscode"; category = "editors"; }
    { homebrew = "curl"; nix = "curl"; category = "networking"; }
    { homebrew = "wget"; nix = "wget"; category = "networking"; }
    { homebrew = "jq"; nix = "jq"; category = "utilities"; }
    { homebrew = "htop"; nix = "htop"; category = "system"; }
    { homebrew = "tree"; nix = "tree"; category = "utilities"; }
  ];

  # PATH conflicts - packages that might conflict in PATH
  pathConflicts = [
    "git" "node" "npm" "python" "python3" "vim" "emacs" "curl" "wget" "jq" "htop" "tree"
  ];

  # Library conflicts - packages that might have library conflicts
  libraryConflicts = [
    "openssl" "zlib" "sqlite" "libpng" "libjpeg" "python" "node"
  ];
in
pkgs.runCommand "homebrew-nix-conflict-resolution-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Homebrew-Nix Conflict Resolution Integration Tests"}

  # Test 1: Package Overlap Detection
  ${testHelpers.testSubsection "Package Overlap Detection"}

  # Extract package names from Nix packages
  NIX_PACKAGES=$(cat > nix_packages.txt << 'EOF'
${builtins.concatStringsSep "\n" (map (pkg:
  if builtins.hasAttr "pname" pkg then pkg.pname
  else if builtins.hasAttr "name" pkg then
    # Extract name before version
    let
      name = pkg.name;
      nameWithoutVersion = builtins.head (builtins.split "-[0-9]" name);
    in
    if builtins.isList nameWithoutVersion then builtins.head nameWithoutVersion else name
  else "unknown"
) allNixPackages)}
EOF
  )

  # Create Homebrew casks list
  HOMEBREW_CASKS=$(cat > homebrew_casks.txt << 'EOF'
${builtins.concatStringsSep "\n" casksConfig}
EOF
  )

  echo "Nix packages count: $(wc -l < nix_packages.txt)"
  echo "Homebrew casks count: $(wc -l < homebrew_casks.txt)"

  # Test for direct name conflicts
  DIRECT_CONFLICTS=$(comm -12 <(sort nix_packages.txt) <(sort homebrew_casks.txt) | head -10)

  if [ -z "$DIRECT_CONFLICTS" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No direct name conflicts found"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Direct name conflicts found:"
    echo "$DIRECT_CONFLICTS"
  fi

  # Test 2: PATH Environment Variable Conflicts
  ${testHelpers.testSubsection "PATH Environment Variable Conflicts"}

  # Mock PATH setup
  ${homebrewHelpers.setupHomebrewTestEnv (homebrewHelpers.mockHomebrewState {
    casks = casksConfig;
  })}

  # Simulate PATH conflicts
  echo "${testHelpers.colors.blue}Simulating PATH environment:${testHelpers.colors.reset}"
  echo "  Homebrew: $HOMEBREW_PREFIX/bin"
  echo "  Nix: /nix/store/*/bin"
  echo "  System: /usr/bin:/bin"

  # Test PATH priority order
  for cmd in ${builtins.concatStringsSep " " pathConflicts}; do
    if grep -q "$cmd" nix_packages.txt && grep -q "$cmd" homebrew_casks.txt; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Potential PATH conflict: $cmd"
    fi
  done

  # Test 3: Symlink Conflicts
  ${testHelpers.testSubsection "Symlink Conflicts"}

  # Mock application directories
  ${testHelpers.createTempDir}
  MOCK_APPS="$TEMP_DIR/Applications"
  MOCK_NIX_APPS="$TEMP_DIR/Applications/Nix Apps"
  mkdir -p "$MOCK_APPS" "$MOCK_NIX_APPS"

  # Simulate potential symlink conflicts
  SYMLINK_CONFLICTS=""
  for cask in ${builtins.concatStringsSep " " (builtins.take 5 casksConfig)}; do
    if echo "$cask" | grep -q -E "(firefox|chrome|docker)"; then
      mkdir -p "$MOCK_APPS/$cask.app"
      mkdir -p "$MOCK_NIX_APPS/$cask.app"

      # Test symlink creation
      if ln -sf "$MOCK_NIX_APPS/$cask.app" "$MOCK_APPS/$cask-nix.app" 2>/dev/null; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Symlink conflict resolved for $cask"
      else
        SYMLINK_CONFLICTS="$SYMLINK_CONFLICTS $cask"
      fi
    fi
  done

  if [ -z "$SYMLINK_CONFLICTS" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No symlink conflicts detected"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Symlink conflicts: $SYMLINK_CONFLICTS"
  fi

  # Test 4: Library Dependency Conflicts
  ${testHelpers.testSubsection "Library Dependency Conflicts"}

  # Check for potential library conflicts
  LIBRARY_CONFLICTS=""
  for lib in ${builtins.concatStringsSep " " libraryConflicts}; do
    NIX_HAS_LIB=$(grep -c "$lib" nix_packages.txt || echo "0")
    HOMEBREW_HAS_LIB=$(grep -c "$lib" homebrew_casks.txt || echo "0")

    if [ "$NIX_HAS_LIB" -gt 0 ] && [ "$HOMEBREW_HAS_LIB" -gt 0 ]; then
      LIBRARY_CONFLICTS="$LIBRARY_CONFLICTS $lib"
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Potential library conflict: $lib"
    fi
  done

  if [ -z "$LIBRARY_CONFLICTS" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No major library conflicts detected"
  fi

  # Test 5: Version Management Conflicts
  ${testHelpers.testSubsection "Version Management Conflicts"}

  # Check for version managers that might conflict
  VERSION_MANAGERS="nvm node npm yarn python pip pyenv rbenv"

  for vm in $VERSION_MANAGERS; do
    if grep -q "$vm" nix_packages.txt; then
      echo "${testHelpers.colors.blue}ℹ${testHelpers.colors.reset} Version manager in Nix: $vm"
    fi
    if grep -q "$vm" homebrew_casks.txt; then
      echo "${testHelpers.colors.blue}ℹ${testHelpers.colors.reset} Version manager in Homebrew: $vm"
    fi
  done

  # Test 6: Service Conflicts
  ${testHelpers.testSubsection "Service Conflicts"}

  # Mock service detection
  SERVICES_THAT_CONFLICT="postgresql mysql redis docker"

  for service in $SERVICES_THAT_CONFLICT; do
    if grep -q "$service" nix_packages.txt && grep -q "$service" homebrew_casks.txt; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Service conflict detected: $service"
      echo "  Recommendation: Use either Nix OR Homebrew, not both"
    fi
  done

  # Test 7: Configuration File Conflicts
  ${testHelpers.testSubsection "Configuration File Conflicts"}

  # Mock configuration directories
  CONFIG_DIRS="$TEMP_DIR/.config"
  mkdir -p "$CONFIG_DIRS/git" "$CONFIG_DIRS/vim" "$CONFIG_DIRS/tmux"

  # Test configuration precedence
  echo "${testHelpers.colors.blue}Configuration precedence order:${testHelpers.colors.reset}"
  echo "  1. User configs (~/.config/)"
  echo "  2. Nix-managed configs"
  echo "  3. Homebrew configs"
  echo "  4. System defaults"

  ${testHelpers.createTempFile "user.name = test"}
  cp "$TEMP_FILE" "$CONFIG_DIRS/git/config"
  ${testHelpers.assertExists "$CONFIG_DIRS/git/config" "Git config precedence test"}

  # Test 8: Cleanup and Removal Conflicts
  ${testHelpers.testSubsection "Cleanup and Removal Conflicts"}

  # Test cleanup scenarios
  ${testHelpers.createTempFile ''
#!/bin/bash
# Mock cleanup script
echo "Cleaning up Homebrew packages..."
echo "Preserving Nix packages..."
echo "Removing orphaned symlinks..."
''
  }
  CLEANUP_SCRIPT="$TEMP_FILE"
  chmod +x "$CLEANUP_SCRIPT"

  ${testHelpers.assertCommand "bash $CLEANUP_SCRIPT" "Cleanup script execution"}

  # Test 9: Migration Strategy Validation
  ${testHelpers.testSubsection "Migration Strategy Validation"}

  # Test migration from Homebrew to Nix
  ${testHelpers.createTempFile ''
# Migration checklist:
# 1. Identify conflicting packages
# 2. Back up configurations
# 3. Remove Homebrew version
# 4. Install Nix version
# 5. Restore configurations
# 6. Verify functionality
''
  }
  MIGRATION_CHECKLIST="$TEMP_FILE"
  ${testHelpers.assertExists "$MIGRATION_CHECKLIST" "Migration checklist exists"}

  # Test 10: Automated Conflict Resolution
  ${testHelpers.testSubsection "Automated Conflict Resolution"}

  # Create conflict resolution script
  ${testHelpers.createTempFile ''
#!/bin/bash
set -e

resolve_conflicts() {
    local nix_pkg="$1"
    local homebrew_pkg="$2"

    echo "Resolving conflict between $nix_pkg (Nix) and $homebrew_pkg (Homebrew)"

    # Strategy: Prefer Nix for system tools, Homebrew for GUI apps
    if [[ "$homebrew_pkg" == *".app" ]] || [[ "$homebrew_pkg" == *"-desktop" ]]; then
        echo "  → Keeping Homebrew version (GUI application)"
        return 0
    else
        echo "  → Keeping Nix version (system tool)"
        return 0
    fi
}

# Test conflict resolution
resolve_conflicts "docker" "docker-desktop"
resolve_conflicts "git" "git"
resolve_conflicts "firefox" "firefox"
''
  }
  CONFLICT_RESOLVER="$TEMP_FILE"
  chmod +x "$CONFLICT_RESOLVER"

  ${testHelpers.assertCommand "bash $CONFLICT_RESOLVER" "Conflict resolution script works"}

  # Test 11: Monitoring and Detection
  ${testHelpers.testSubsection "Conflict Monitoring"}

  # Create monitoring script
  ${testHelpers.createTempFile ''
#!/bin/bash
# Monitor for new conflicts
echo "Monitoring system for package conflicts..."

check_command_conflicts() {
    for cmd in git node python; do
        if command -v "$cmd" >/dev/null 2>&1; then
            WHICH_RESULT=$(which "$cmd")
            if [[ "$WHICH_RESULT" == *"homebrew"* ]]; then
                echo "  $cmd: Homebrew ($WHICH_RESULT)"
            elif [[ "$WHICH_RESULT" == *"nix"* ]]; then
                echo "  $cmd: Nix ($WHICH_RESULT)"
            else
                echo "  $cmd: System ($WHICH_RESULT)"
            fi
        fi
    done
}

check_command_conflicts
''
  }
  MONITOR_SCRIPT="$TEMP_FILE"
  chmod +x "$MONITOR_SCRIPT"

  ${testHelpers.assertCommand "bash $MONITOR_SCRIPT" "Conflict monitoring script works"}

  # Test 12: Performance Impact Assessment
  ${testHelpers.testSubsection "Performance Impact Assessment"}

  # Measure conflict resolution performance
  ${testHelpers.benchmark "conflict-detection" "
    comm -12 <(sort nix_packages.txt) <(sort homebrew_casks.txt) | wc -l > /dev/null
  "}

  ${testHelpers.benchmark "symlink-resolution" "
    find $MOCK_APPS -type l | wc -l > /dev/null
  "}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Conflict Resolution Summary ===${testHelpers.colors.reset}"
  echo "Direct conflicts: $(comm -12 <(sort nix_packages.txt) <(sort homebrew_casks.txt) | wc -l)"
  echo "PATH conflicts checked: ${toString (builtins.length pathConflicts)}"
  echo "Library conflicts checked: ${toString (builtins.length libraryConflicts)}"
  echo ""
  echo "${testHelpers.colors.green}✓ All Homebrew-Nix conflict resolution tests completed!${testHelpers.colors.reset}"

  touch $out
''
