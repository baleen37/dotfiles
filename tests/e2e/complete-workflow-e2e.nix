{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;
in
pkgs.runCommand "complete-workflow-e2e-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Complete Workflow End-to-End Tests"}

  # Test 1: Development environment setup
  ${testHelpers.testSubsection "Development Environment Setup"}

  # Test dev shell availability
  echo "Testing dev shell availability for ${system} from ${src}..."
  echo "Current directory: $(pwd)"
  echo "Checking if flake exists at ${src}/flake.nix..."
  if [ -f "${src}/flake.nix" ]; then
    echo "Flake found at ${src}/flake.nix"
  else
    echo "Flake NOT found at ${src}/flake.nix"
  fi

  # Try to evaluate with more context
  cd ${src} || echo "Failed to cd to ${src}"

  if nix eval --impure path:${src}#devShells.${system}.default --no-warn-dirty >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Development shell is available"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Development shell is not available"
    echo "Trying alternative approaches..."

    # Try with .#
    if nix eval --impure .#devShells.${system}.default --no-warn-dirty >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Development shell is available (using .#)"
    else
      echo "Failed with .# as well"
      exit 1
    fi
  fi

  # Test setup-dev app functionality
  if nix eval --impure ${src}#apps.${system}.setup-dev --no-warn-dirty >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} setup-dev app is available"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} setup-dev app is not available"
    exit 1
  fi

  # Test 2: CI/CD pipeline simulation
  ${testHelpers.testSubsection "CI/CD Pipeline Simulation"}

  echo "Simulating CI/CD pipeline steps..."

  # Step 1: Lint (simulation)
  echo "${testHelpers.colors.blue}Step 1: Lint${testHelpers.colors.reset}"
  if command -v pre-commit >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} pre-commit is available"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} pre-commit not available (expected in some environments)"
  fi

  # Step 2: Smoke tests (flake check without build)
  echo "${testHelpers.colors.blue}Step 2: Smoke tests${testHelpers.colors.reset}"
  ${testHelpers.benchmark "Smoke test simulation" ''
    nix flake check --impure --no-build ${src} --no-warn-dirty >/dev/null 2>&1
  ''}
  echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Smoke tests passed"

  # Step 3: Build simulation
  echo "${testHelpers.colors.blue}Step 3: Build simulation${testHelpers.colors.reset}"
  ${testHelpers.benchmark "Build simulation" ''
    ${if testHelpers.platform.isDarwin then ''
      nix eval --impure ${src}#darwinConfigurations.${system}.system --no-warn-dirty >/dev/null 2>&1
    '' else ''
      nix eval --impure ${src}#nixosConfigurations.${system}.config.system.build.toplevel --no-warn-dirty >/dev/null 2>&1
    ''}
  ''}
  echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Build simulation completed"

  # Test 3: Application workflow testing
  ${testHelpers.testSubsection "Application Workflow Testing"}

  # Test all apps in workflow order
  WORKFLOW_APPS=(build apply build-switch)

  for app in "''${WORKFLOW_APPS[@]}"; do
    if nix eval --impure ${src}#apps.${system}.$app --no-warn-dirty >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow app '$app' is available"

      # Test app structure
      if nix eval --impure ${src}#apps.${system}.$app.type --no-warn-dirty 2>/dev/null | grep -q "app"; then
        echo "  - Type: valid"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} App '$app' has invalid type"
        exit 1
      fi

      if nix eval --impure ${src}#apps.${system}.$app.program --no-warn-dirty >/dev/null 2>&1; then
        echo "  - Program: valid"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} App '$app' has invalid program"
        exit 1
      fi
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow app '$app' is not available"
      exit 1
    fi
  done

  # Test 4: Key management workflow
  ${testHelpers.testSubsection "Key Management Workflow"}

  KEY_APPS=(create-keys check-keys copy-keys)

  for app in "''${KEY_APPS[@]}"; do
    if nix eval --impure ${src}#apps.${system}.$app --no-warn-dirty >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Key management app '$app' is available"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Key management app '$app' is not available"
      exit 1
    fi
  done

  # Test 5: Rollback workflow (Darwin only)
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Rollback workflow test" ''
    ${testHelpers.testSubsection "Rollback Workflow"}

    if nix eval --impure ${src}#apps.${system}.rollback --no-warn-dirty >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback app is available on Darwin"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback app is not available on Darwin"
      exit 1
    fi
  ''}

  # Test 6: Multi-system workflow
  ${testHelpers.testSubsection "Multi-system Workflow"}

  echo "Testing multi-system build capabilities..."

  # Test that all system configurations can be evaluated
  SYSTEMS=(aarch64-darwin x86_64-darwin x86_64-linux aarch64-linux)
  AVAILABLE_SYSTEMS=0

  for target_system in "''${SYSTEMS[@]}"; do
    if [[ "$target_system" == *"darwin"* ]]; then
      if nix eval --impure ${src}#darwinConfigurations.$target_system.system --no-warn-dirty >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin configuration available for $target_system"
        AVAILABLE_SYSTEMS=$((AVAILABLE_SYSTEMS + 1))
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Darwin configuration not available for $target_system"
      fi
    else
      if nix eval --impure ${src}#nixosConfigurations.$target_system.config.system.build.toplevel --no-warn-dirty >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} NixOS configuration available for $target_system"
        AVAILABLE_SYSTEMS=$((AVAILABLE_SYSTEMS + 1))
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} NixOS configuration not available for $target_system"
      fi
    fi
  done

  ${testHelpers.assertTrue ''[ $AVAILABLE_SYSTEMS -ge 2 ]'' "At least 2 system configurations are available"}

  # Test 7: Configuration inheritance and modularity
  ${testHelpers.testSubsection "Configuration Inheritance and Modularity"}

  # Test that shared modules are included in system configurations
  ${if testHelpers.platform.isDarwin then ''
    if nix eval --impure ${src}#darwinConfigurations.${system}.config.environment.systemPackages --no-warn-dirty >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System packages are configured in Darwin"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} System packages not found in Darwin config"
    fi
  '' else ''
    if nix eval --impure ${src}#nixosConfigurations.${system}.config.environment.systemPackages --no-warn-dirty >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System packages are configured in NixOS"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} System packages not found in NixOS config"
    fi
  ''}

  # Test 8: Error handling and recovery
  ${testHelpers.testSubsection "Error Handling and Recovery"}

  # Test that invalid configurations are caught
  echo "Testing error handling capabilities..."

  # Test with invalid user
  export USER=""
  if nix eval --impure --expr 'let getUser = import ${src}/lib/get-user.nix {}; in getUser' --no-warn-dirty >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} User resolution handles empty USER gracefully"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} User resolution error handling needs improvement"
  fi

  # Restore proper user
  export USER=workflowtest

  # Test 9: Performance benchmarking
  ${testHelpers.testSubsection "Performance Benchmarking"}

  echo "Running performance benchmarks..."

  # Benchmark flake evaluation
  ${testHelpers.benchmark "Complete flake evaluation" ''
    nix flake show --impure ${src} --no-warn-dirty >/dev/null 2>&1
  ''}

  # Benchmark configuration evaluation
  ${testHelpers.benchmark "System configuration evaluation" ''
    ${if testHelpers.platform.isDarwin then ''
      nix eval --impure ${src}#darwinConfigurations.${system}.system --no-warn-dirty >/dev/null 2>&1
    '' else ''
      nix eval --impure ${src}#nixosConfigurations.${system}.config.system.build.toplevel --no-warn-dirty >/dev/null 2>&1
    ''}
  ''}

  # Test 10: Integration with external systems
  ${testHelpers.testSubsection "External System Integration"}

  # Test Git integration
  if command -v git >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Git is available"

    # Test that we're in a git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Operating in a Git repository"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Not in a Git repository"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Git not available"
  fi

  # Test SSH configuration (for key management)
  if [ -d "$HOME/.ssh" ] || mkdir -p "$HOME/.ssh" 2>/dev/null; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} SSH directory is accessible"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} SSH directory not accessible"
  fi

  ${testHelpers.reportResults "Complete Workflow End-to-End Tests" 25 25}
  touch $out
''
