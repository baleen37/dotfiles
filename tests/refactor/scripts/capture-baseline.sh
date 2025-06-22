#!/usr/bin/env bash
set -euo pipefail

# Capture baseline configuration state for refactoring validation
# This script captures the current system configuration state to use as a baseline
# for ensuring the refactored configuration produces identical results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BASELINE_DIR="$PROJECT_ROOT/tests/refactor/baselines"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $*${RESET}"
}

success() {
    echo -e "${GREEN}✓ $*${RESET}"
}

warning() {
    echo -e "${YELLOW}⚠ $*${RESET}"
}

error() {
    echo -e "${RED}✗ $*${RESET}"
}

# Function to capture current system state
capture_baseline() {
    log "Capturing configuration baseline..."

    mkdir -p "$BASELINE_DIR"

    BASELINE_PREFIX="$BASELINE_DIR/baseline-$TIMESTAMP"

    # Capture basic system information
    {
        echo "=== System Information ==="
        echo "Timestamp: $TIMESTAMP"
        echo "User: ${USER:-$(whoami)}"
        echo "System: $(uname -a)"
        echo "Current directory: $(pwd)"
        echo "Project root: $PROJECT_ROOT"
        echo ""
    } > "$BASELINE_PREFIX.info"

    # Check if we're in a valid nix flake directory
    if [ ! -f "$PROJECT_ROOT/flake.nix" ]; then
        error "Not in a valid Nix flake directory. Expected flake.nix at $PROJECT_ROOT"
        exit 1
    fi

    cd "$PROJECT_ROOT"

    # Capture current flake information
    log "Capturing flake information..."
    {
        echo "=== Flake Information ==="
        if nix flake show --impure 2>&1; then
            success "Flake show completed"
        else
            warning "Flake show failed"
        fi
        echo ""
    } >> "$BASELINE_PREFIX.info"

    # Capture flake outputs in structured format
    if nix flake show --impure --json > "$BASELINE_PREFIX.flake-outputs.json" 2>/dev/null; then
        success "Flake outputs captured (JSON)"
    else
        warning "Failed to capture flake outputs in JSON format"
    fi

    # Capture current system configuration evaluation
    CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo "unknown")

    log "Capturing system configuration for: $CURRENT_SYSTEM"
    {
        echo "=== System Configuration ==="
        echo "Current system: $CURRENT_SYSTEM"
        echo ""
    } >> "$BASELINE_PREFIX.info"

    # Capture system-specific configuration paths
    case "$CURRENT_SYSTEM" in
        *-darwin)
            log "Capturing Darwin configuration..."
            if nix eval --impure ".#darwinConfigurations.\"$CURRENT_SYSTEM\".system.build.toplevel.drvPath" \
               > "$BASELINE_PREFIX.system-drv" 2>&1; then
                success "Darwin system derivation captured"
            else
                warning "Failed to capture Darwin system derivation"
            fi

            # Capture Darwin-specific package list
            if nix eval --impure ".#darwinConfigurations.\"$CURRENT_SYSTEM\".system.build.toplevel.buildInputs" \
               --json > "$BASELINE_PREFIX.darwin-packages.json" 2>&1; then
                success "Darwin package list captured"
            else
                warning "Failed to capture Darwin package list"
            fi
            ;;
        *-linux)
            log "Capturing NixOS configuration..."
            if nix eval --impure ".#nixosConfigurations.\"$CURRENT_SYSTEM\".config.system.build.toplevel.drvPath" \
               > "$BASELINE_PREFIX.system-drv" 2>&1; then
                success "NixOS system derivation captured"
            else
                warning "Failed to capture NixOS system derivation"
            fi

            # Capture NixOS-specific package list
            if nix eval --impure ".#nixosConfigurations.\"$CURRENT_SYSTEM\".config.environment.systemPackages" \
               --json > "$BASELINE_PREFIX.nixos-packages.json" 2>&1; then
                success "NixOS package list captured"
            else
                warning "Failed to capture NixOS package list"
            fi
            ;;
        *)
            warning "Unknown system type: $CURRENT_SYSTEM"
            ;;
    esac

    # Capture home manager configuration if available
    log "Capturing Home Manager configuration..."
    case "$CURRENT_SYSTEM" in
        *-darwin)
            HM_CONFIG_PATH=".#darwinConfigurations.\"$CURRENT_SYSTEM\".config.home-manager.users"
            ;;
        *-linux)
            HM_CONFIG_PATH=".#nixosConfigurations.\"$CURRENT_SYSTEM\".config.home-manager.users"
            ;;
    esac

    if nix eval --impure "$HM_CONFIG_PATH" --json > "$BASELINE_PREFIX.home-manager.json" 2>&1; then
        success "Home Manager configuration captured"
    else
        warning "Failed to capture Home Manager configuration"
    fi

    # Capture current file tree structure
    log "Capturing file structure..."
    {
        echo "=== File Structure ==="
        find "$PROJECT_ROOT" -type f -name "*.nix" | \
            grep -E "(modules|hosts|lib|overlays)" | \
            sort
    } > "$BASELINE_PREFIX.file-structure"

    # Capture git state
    log "Capturing git state..."
    {
        echo "=== Git State ==="
        echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo "Commit: $(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
        echo "Status:"
        git status --porcelain 2>/dev/null || echo "Git not available"
        echo ""
    } >> "$BASELINE_PREFIX.info"

    # Capture current test results for comparison
    log "Capturing current test state..."
    if cd "$PROJECT_ROOT" && make test >/dev/null 2>&1; then
        success "All tests currently pass"
        echo "Tests: PASSING" >> "$BASELINE_PREFIX.info"
    else
        warning "Some tests currently fail"
        echo "Tests: FAILING" >> "$BASELINE_PREFIX.info"
    fi

    # Create manifest file listing all captured files
    {
        echo "=== Baseline Manifest ==="
        echo "Baseline ID: baseline-$TIMESTAMP"
        echo "Captured files:"
        for file in "$BASELINE_PREFIX".*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                size=$(wc -c < "$file")
                echo "  - $filename ($size bytes)"
            fi
        done
        echo ""
        echo "Total files: $(ls -1 "$BASELINE_PREFIX".* 2>/dev/null | wc -l)"
    } > "$BASELINE_PREFIX.manifest"

    # Final summary
    echo ""
    success "Baseline capture completed!"
    echo ""
    echo "Baseline ID: baseline-$TIMESTAMP"
    echo "Location: $BASELINE_DIR/"
    echo "Files captured:"
    ls -la "$BASELINE_PREFIX".* | awk '{print "  " $9 " (" $5 " bytes)"}'
    echo ""
    echo "To compare against this baseline later, use:"
    echo "  ./tests/refactor/scripts/compare-configs.sh baseline-$TIMESTAMP"
    echo ""

    # Return the baseline ID for use in other scripts
    echo "baseline-$TIMESTAMP"
}

# Function to validate that baseline capture was successful
validate_baseline() {
    local baseline_id="$1"
    local baseline_prefix="$BASELINE_DIR/$baseline_id"

    log "Validating baseline: $baseline_id"

    # Check that required files exist
    required_files=(
        "$baseline_prefix.info"
        "$baseline_prefix.manifest"
        "$baseline_prefix.file-structure"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            success "Required file exists: $(basename "$file")"
        else
            error "Missing required file: $(basename "$file")"
            return 1
        fi
    done

    # Check that system derivation was captured
    if [ -f "$baseline_prefix.system-drv" ]; then
        success "System derivation captured"
    else
        warning "System derivation not captured"
    fi

    # Check file sizes are reasonable
    for file in "$baseline_prefix".*; do
        if [ -f "$file" ]; then
            size=$(wc -c < "$file")
            if [ "$size" -eq 0 ]; then
                warning "Empty file: $(basename "$file")"
            fi
        fi
    done

    success "Baseline validation completed"
}

# Main execution
main() {
    case "${1:-capture}" in
        capture)
            baseline_id=$(capture_baseline)
            validate_baseline "$baseline_id"
            ;;
        validate)
            if [ -z "${2:-}" ]; then
                error "Please provide baseline ID to validate"
                exit 1
            fi
            validate_baseline "$2"
            ;;
        list)
            log "Available baselines:"
            if [ -d "$BASELINE_DIR" ]; then
                for baseline in "$BASELINE_DIR"/baseline-*.manifest; do
                    if [ -f "$baseline" ]; then
                        baseline_id=$(basename "$baseline" .manifest)
                        timestamp=$(echo "$baseline_id" | sed 's/baseline-//')
                        echo "  - $baseline_id (captured: $timestamp)"
                    fi
                done
            else
                echo "  No baselines found"
            fi
            ;;
        help|--help|-h)
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  capture          Capture current configuration as baseline (default)"
            echo "  validate <id>    Validate existing baseline"
            echo "  list             List available baselines"
            echo "  help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Capture current state"
            echo "  $0 validate baseline-20240622_143000"
            echo "  $0 list"
            ;;
        *)
            error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
