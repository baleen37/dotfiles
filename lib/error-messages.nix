# Standardized error messages for better user experience
{ lib }:

let
  # Color codes for terminal output (when supported)
  colors = {
    red = "\\033[0;31m";
    yellow = "\\033[1;33m";
    green = "\\033[0;32m";
    blue = "\\033[0;34m";
    reset = "\\033[0m";
  };

  # Format error message with consistent styling
  formatError = { type, message, hint ? null, command ? null }:
    let
      header = "[${type}] ${message}";
      hintText = if hint != null then "\nHint: ${hint}" else "";
      commandText = if command != null then "\n\nRun: ${command}" else "";
    in
      "${header}${hintText}${commandText}";

in
{
  # Common error messages
  errors = {
    userNotSet = formatError {
      type = "ENVIRONMENT";
      message = "USER environment variable is not set";
      hint = "This is required for determining user-specific configurations";
      command = ''
        export USER=$(whoami)
        # Or use the detect-user script:
        ./scripts/detect-user
      '';
    };

    buildFailed = { system }: formatError {
      type = "BUILD";
      message = "Build failed for ${system}";
      hint = "Check the build log above for specific errors";
      command = ''
        # Show detailed trace:
        nix build --impure --show-trace .#${system}

        # Clear cache and retry:
        nix store gc && nix build --impure .#${system}
      '';
    };

    platformMismatch = { expected, actual }: formatError {
      type = "PLATFORM";
      message = "Platform mismatch: expected ${expected}, but running on ${actual}";
      hint = "Cross-platform builds may require additional setup";
      command = ''
        # Build for current platform instead:
        nix build --impure .#$(nix eval --impure --expr 'builtins.currentSystem')
      '';
    };

    permissionDenied = { operation }: formatError {
      type = "PERMISSION";
      message = "Permission denied for ${operation}";
      hint = "Some operations require administrative privileges";
      command = ''
        # If you need sudo:
        sudo ${operation}

        # For build-switch:
        sudo nix run --impure .#build-switch
      '';
    };

    dependencyMissing = { package }: formatError {
      type = "DEPENDENCY";
      message = "Required dependency '${package}' is missing";
      hint = "Ensure all dependencies are properly declared in the flake";
      command = ''
        # Add to appropriate packages.nix:
        # - modules/shared/packages.nix (cross-platform)
        # - modules/darwin/packages.nix (macOS only)
        # - modules/nixos/packages.nix (Linux only)
      '';
    };

    testFailed = { category, test }: formatError {
      type = "TEST";
      message = "Test failed: ${category}/${test}";
      hint = "Review the test output for specific failures";
      command = ''
        # Run specific test with details:
        nix build --impure --show-trace .#checks.$(nix eval --impure --expr 'builtins.currentSystem').${test}

        # Run all ${category} tests:
        nix run --impure .#test-${category}
      '';
    };

    configurationInvalid = { file, error }: formatError {
      type = "CONFIG";
      message = "Invalid configuration in ${file}";
      hint = "Error: ${error}";
      command = ''
        # Validate configuration:
        nix flake check --impure --show-trace

        # Check specific file syntax:
        nix-instantiate --parse ${file}
      '';
    };

    networkError = { url }: formatError {
      type = "NETWORK";
      message = "Failed to fetch ${url}";
      hint = "Check your internet connection and proxy settings";
      command = ''
        # Test connectivity:
        curl -I ${url}

        # Retry with fallback substituters:
        nix build --substituters https://cache.nixos.org --impure .#build
      '';
    };
  };

  # Helper functions
  helpers = {
    # Print error and exit
    throwError = error: builtins.throw error;

    # Print warning but continue
    printWarning = warning: builtins.trace warning;

    # Conditional error based on environment
    requireEnv = var: default:
      let value = builtins.getEnv var;
      in if value == "" && default == null
         then throwError (errors.userNotSet)
         else if value == "" then default else value;
  };

  # Progress indicators
  progress = {
    starting = phase: "Starting ${phase}...";
    completed = phase: "✓ ${phase} completed successfully";
    failed = phase: "✗ ${phase} failed";
    skipped = phase: "- ${phase} skipped";
  };
}
