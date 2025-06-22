{ pkgs }:
let
  # Utilities for comparing Nix configurations and detecting differences
  inherit (pkgs) lib writeShellScript;

  # Compare two configuration files and return true if they're equivalent
  compareConfigs = writeShellScript "compare-configs" ''
    set -euo pipefail

    CONFIG1="$1"
    CONFIG2="$2"

    if [ ! -f "$CONFIG1" ] || [ ! -f "$CONFIG2" ]; then
      echo "Error: Configuration file not found" >&2
      exit 1
    fi

    # Compare the actual content after normalizing whitespace
    NORMALIZED1=$(cat "$CONFIG1" | sed 's/[[:space:]]*//g' | sort)
    NORMALIZED2=$(cat "$CONFIG2" | sed 's/[[:space:]]*//g' | sort)

    if [ "$NORMALIZED1" = "$NORMALIZED2" ]; then
      exit 0  # Configurations are identical
    else
      exit 1  # Configurations are different
    fi
  '';

  # Extract package list from a configuration file
  extractPackageList = writeShellScript "extract-package-list" ''
    set -euo pipefail

    CONFIG_FILE="$1"

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "Error: Configuration file not found" >&2
      exit 1
    fi

    # Extract package names from systemPackages or home.packages
    grep -E "(systemPackages|home\.packages)" "$CONFIG_FILE" | \
      sed -E 's/.*\[(.*)\].*/\1/' | \
      sed 's/pkgs\.//g' | \
      tr ' ;' '\n' | \
      grep -v '^$' | \
      sort | \
      uniq
  '';

  # Validate that a configuration can be built successfully
  validateConfig = writeShellScript "validate-config" ''
    set -euo pipefail

    CONFIG_FILE="$1"

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "Error: Configuration file not found" >&2
      exit 1
    fi

    # Try to instantiate the configuration to check for syntax errors
    if command -v nix-instantiate >/dev/null 2>&1; then
      nix-instantiate --parse "$CONFIG_FILE" >/dev/null 2>&1
    else
      # Fallback: basic syntax check
      if ! ${pkgs.bash}/bin/bash -n "$CONFIG_FILE" 2>/dev/null; then
        exit 1
      fi
    fi
  '';

  # Evaluate and compare two configurations
  evalAndCompare = writeShellScript "eval-and-compare" ''
    set -euo pipefail

    CONFIG1="$1"
    CONFIG2="$2"

    if [ ! -f "$CONFIG1" ] || [ ! -f "$CONFIG2" ]; then
      echo "Error: Configuration file not found" >&2
      exit 1
    fi

    # For now, use file comparison as a proxy for evaluation comparison
    # This will be enhanced when we have actual nix evaluation capabilities
    if diff -u "$CONFIG1" "$CONFIG2" >/dev/null 2>&1; then
      exit 0  # Configurations evaluate to the same result
    else
      exit 1  # Configurations evaluate differently
    fi
  '';

  # Compare Home Manager configurations specifically
  compareHomeManagerConfigs = writeShellScript "compare-hm-configs" ''
    set -euo pipefail

    HM_CONFIG1="$1"
    HM_CONFIG2="$2"

    if [ ! -f "$HM_CONFIG1" ] || [ ! -f "$HM_CONFIG2" ]; then
      echo "Error: Home Manager configuration file not found" >&2
      exit 1
    fi

    # Extract home manager specific sections and compare
    HM_SECTIONS1=$(grep -E "(home\.|programs\.|services\.)" "$HM_CONFIG1" | sort)
    HM_SECTIONS2=$(grep -E "(home\.|programs\.|services\.)" "$HM_CONFIG2" | sort)

    if [ "$HM_SECTIONS1" = "$HM_SECTIONS2" ]; then
      exit 0  # Home Manager configs are equivalent
    else
      exit 1  # Home Manager configs are different
    fi
  '';

  # Generate configuration diff report
  generateConfigDiff = writeShellScript "generate-config-diff" ''
    set -euo pipefail

    CONFIG1="$1"
    CONFIG2="$2"
    OUTPUT_FILE="''${3:-/dev/stdout}"

    if [ ! -f "$CONFIG1" ] || [ ! -f "$CONFIG2" ]; then
      echo "Error: Configuration file not found" >&2
      exit 1
    fi

    echo "=== Configuration Comparison Report ===" > "$OUTPUT_FILE"
    echo "Config 1: $CONFIG1" >> "$OUTPUT_FILE"
    echo "Config 2: $CONFIG2" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Generate unified diff
    echo "--- Differences ---" >> "$OUTPUT_FILE"
    if ! diff -u "$CONFIG1" "$CONFIG2" >> "$OUTPUT_FILE" 2>/dev/null; then
      echo "Configurations are different" >> "$OUTPUT_FILE"
    else
      echo "Configurations are identical" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"
    echo "--- Package Differences ---" >> "$OUTPUT_FILE"

    # Compare package lists
    TEMP_PKG1=$(mktemp)
    TEMP_PKG2=$(mktemp)

    ${extractPackageList} "$CONFIG1" > "$TEMP_PKG1" 2>/dev/null || echo "Failed to extract packages" > "$TEMP_PKG1"
    ${extractPackageList} "$CONFIG2" > "$TEMP_PKG2" 2>/dev/null || echo "Failed to extract packages" > "$TEMP_PKG2"

    if ! diff -u "$TEMP_PKG1" "$TEMP_PKG2" >> "$OUTPUT_FILE" 2>/dev/null; then
      echo "Package lists differ" >> "$OUTPUT_FILE"
    else
      echo "Package lists are identical" >> "$OUTPUT_FILE"
    fi

    rm -f "$TEMP_PKG1" "$TEMP_PKG2"
  '';

  # Capture current system configuration as baseline
  captureBaseline = writeShellScript "capture-baseline" ''
    set -euo pipefail

    OUTPUT_DIR="''${1:-$(pwd)/tests/refactor/baselines}"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$OUTPUT_DIR"

    echo "Capturing configuration baseline at $TIMESTAMP"

    # Capture current configuration evaluation
    if command -v nix >/dev/null 2>&1; then
      CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo "unknown")

      echo "Current system: $CURRENT_SYSTEM" > "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
      echo "Timestamp: $TIMESTAMP" >> "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
      echo "USER: ''${USER:-unknown}" >> "$OUTPUT_DIR/baseline-$TIMESTAMP.info"

      # Try to evaluate current flake outputs
      if nix flake show --impure > "$OUTPUT_DIR/baseline-$TIMESTAMP.flake-outputs" 2>&1; then
        echo "Flake outputs captured" >> "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
      else
        echo "Failed to capture flake outputs" >> "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
      fi

      # Try to capture current system derivation path
      case "$CURRENT_SYSTEM" in
        *-darwin)
          if nix eval --impure '.#darwinConfigurations."'$CURRENT_SYSTEM'".system.build.toplevel.drvPath' \
             > "$OUTPUT_DIR/baseline-$TIMESTAMP.system-drv" 2>&1; then
            echo "Darwin system derivation captured" >> "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
          fi
          ;;
        *-linux)
          if nix eval --impure '.#nixosConfigurations."'$CURRENT_SYSTEM'".config.system.build.toplevel.drvPath' \
             > "$OUTPUT_DIR/baseline-$TIMESTAMP.system-drv" 2>&1; then
            echo "NixOS system derivation captured" >> "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
          fi
          ;;
      esac
    else
      echo "Nix not available, capturing basic system info only" > "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
      uname -a >> "$OUTPUT_DIR/baseline-$TIMESTAMP.info"
    fi

    echo "Baseline captured to: $OUTPUT_DIR/baseline-$TIMESTAMP.*"
    echo "$OUTPUT_DIR/baseline-$TIMESTAMP"
  '';

in
{
  inherit compareConfigs extractPackageList validateConfig;
  inherit evalAndCompare compareHomeManagerConfigs;
  inherit generateConfigDiff captureBaseline;
}
