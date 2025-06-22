#!/usr/bin/env bash
set -euo pipefail

# Compare current configuration against a captured baseline
# This script validates that refactored configurations produce identical results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BASELINE_DIR="$PROJECT_ROOT/tests/refactor/baselines"

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

# Function to compare current state against baseline
compare_against_baseline() {
    local baseline_id="$1"
    local baseline_prefix="$BASELINE_DIR/$baseline_id"

    if [ ! -f "$baseline_prefix.manifest" ]; then
        error "Baseline not found: $baseline_id"
        exit 1
    fi

    log "Comparing current configuration against baseline: $baseline_id"

    # Create temporary capture of current state
    local temp_baseline
    temp_baseline=$(mktemp -d)
    local current_timestamp=$(date +%Y%m%d_%H%M%S)
    local current_prefix="$temp_baseline/current-$current_timestamp"

    # Capture current state (reuse logic from capture-baseline.sh)
    cd "$PROJECT_ROOT"

    # Capture current flake outputs
    if nix flake show --impure --json > "$current_prefix.flake-outputs.json" 2>/dev/null; then
        success "Current flake outputs captured"
    else
        warning "Failed to capture current flake outputs"
    fi

    # Compare flake outputs
    if [ -f "$baseline_prefix.flake-outputs.json" ] && [ -f "$current_prefix.flake-outputs.json" ]; then
        if diff -u "$baseline_prefix.flake-outputs.json" "$current_prefix.flake-outputs.json" > /dev/null 2>&1; then
            success "Flake outputs are identical"
        else
            error "Flake outputs differ from baseline"
            echo "Differences:"
            diff -u "$baseline_prefix.flake-outputs.json" "$current_prefix.flake-outputs.json" || true
            return 1
        fi
    else
        warning "Cannot compare flake outputs (files missing)"
    fi

    # Compare system derivations
    CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo "unknown")

    case "$CURRENT_SYSTEM" in
        *-darwin)
            log "Comparing Darwin system derivation..."
            if nix eval --impure ".#darwinConfigurations.\"$CURRENT_SYSTEM\".system.build.toplevel.drvPath" \
               > "$current_prefix.system-drv" 2>&1; then
                if [ -f "$baseline_prefix.system-drv" ]; then
                    if diff -u "$baseline_prefix.system-drv" "$current_prefix.system-drv" > /dev/null 2>&1; then
                        success "Darwin system derivation is identical"
                    else
                        error "Darwin system derivation differs from baseline"
                        echo "Baseline: $(cat "$baseline_prefix.system-drv")"
                        echo "Current:  $(cat "$current_prefix.system-drv")"
                        return 1
                    fi
                else
                    warning "No baseline system derivation to compare against"
                fi
            else
                error "Failed to evaluate current Darwin system derivation"
                return 1
            fi
            ;;
        *-linux)
            log "Comparing NixOS system derivation..."
            if nix eval --impure ".#nixosConfigurations.\"$CURRENT_SYSTEM\".config.system.build.toplevel.drvPath" \
               > "$current_prefix.system-drv" 2>&1; then
                if [ -f "$baseline_prefix.system-drv" ]; then
                    if diff -u "$baseline_prefix.system-drv" "$current_prefix.system-drv" > /dev/null 2>&1; then
                        success "NixOS system derivation is identical"
                    else
                        error "NixOS system derivation differs from baseline"
                        echo "Baseline: $(cat "$baseline_prefix.system-drv")"
                        echo "Current:  $(cat "$current_prefix.system-drv")"
                        return 1
                    fi
                else
                    warning "No baseline system derivation to compare against"
                fi
            else
                error "Failed to evaluate current NixOS system derivation"
                return 1
            fi
            ;;
        *)
            warning "Unknown system type for comparison: $CURRENT_SYSTEM"
            ;;
    esac

    # Compare file structure
    {
        find "$PROJECT_ROOT" -type f -name "*.nix" | \
            grep -E "(modules|hosts|lib|overlays)" | \
            sort
    } > "$current_prefix.file-structure"

    if [ -f "$baseline_prefix.file-structure" ]; then
        if diff -u "$baseline_prefix.file-structure" "$current_prefix.file-structure" > /dev/null 2>&1; then
            success "File structure is identical"
        else
            warning "File structure differs from baseline"
            echo "Differences:"
            diff -u "$baseline_prefix.file-structure" "$current_prefix.file-structure" || true
        fi
    else
        warning "No baseline file structure to compare against"
    fi

    # Test that current configuration still builds successfully
    log "Verifying current configuration builds..."
    if nix flake check --impure --no-build >/dev/null 2>&1; then
        success "Current configuration passes flake check"
    else
        error "Current configuration fails flake check"
        return 1
    fi

    # Test that current configuration can be evaluated
    case "$CURRENT_SYSTEM" in
        *-darwin)
            if nix eval --impure ".#darwinConfigurations.\"$CURRENT_SYSTEM\".system.build.toplevel.drvPath" >/dev/null 2>&1; then
                success "Current Darwin configuration evaluates successfully"
            else
                error "Current Darwin configuration evaluation failed"
                return 1
            fi
            ;;
        *-linux)
            if nix eval --impure ".#nixosConfigurations.\"$CURRENT_SYSTEM\".config.system.build.toplevel.drvPath" >/dev/null 2>&1; then
                success "Current NixOS configuration evaluates successfully"
            else
                error "Current NixOS configuration evaluation failed"
                return 1
            fi
            ;;
    esac

    # Cleanup temporary files
    rm -rf "$temp_baseline"

    success "Configuration comparison completed successfully"
    echo ""
    echo "✅ Current configuration is equivalent to baseline: $baseline_id"
    echo ""
}

# Function to list available baselines
list_baselines() {
    log "Available baselines:"

    if [ ! -d "$BASELINE_DIR" ]; then
        echo "  No baselines directory found"
        return 0
    fi

    local count=0
    for baseline in "$BASELINE_DIR"/baseline-*.manifest; do
        if [ -f "$baseline" ]; then
            baseline_id=$(basename "$baseline" .manifest)
            timestamp=$(echo "$baseline_id" | sed 's/baseline-//')

            # Read some info from the baseline
            info_file="$BASELINE_DIR/$baseline_id.info"
            if [ -f "$info_file" ]; then
                user=$(grep "^User:" "$info_file" | cut -d: -f2 | xargs)
                system=$(grep "^Current system:" "$info_file" | cut -d: -f2 | xargs)
                echo "  - $baseline_id"
                echo "    Captured: $timestamp"
                echo "    User: ${user:-unknown}"
                echo "    System: ${system:-unknown}"
            else
                echo "  - $baseline_id (captured: $timestamp)"
            fi
            ((count++))
            echo ""
        fi
    done

    if [ $count -eq 0 ]; then
        echo "  No baselines found"
        echo ""
        echo "To create a baseline, run:"
        echo "  ./tests/refactor/scripts/capture-baseline.sh"
    else
        echo "Total baselines: $count"
    fi
}

# Function to generate detailed comparison report
generate_report() {
    local baseline_id="$1"
    local output_file="${2:-comparison-report.txt}"
    local baseline_prefix="$BASELINE_DIR/$baseline_id"

    if [ ! -f "$baseline_prefix.manifest" ]; then
        error "Baseline not found: $baseline_id"
        exit 1
    fi

    log "Generating detailed comparison report..."

    {
        echo "=================================="
        echo "Configuration Comparison Report"
        echo "=================================="
        echo "Generated: $(date)"
        echo "Baseline: $baseline_id"
        echo "Current directory: $(pwd)"
        echo ""

        echo "=== Baseline Information ==="
        if [ -f "$baseline_prefix.info" ]; then
            cat "$baseline_prefix.info"
        else
            echo "Baseline info not available"
        fi
        echo ""

        echo "=== Current System Information ==="
        echo "Timestamp: $(date +%Y%m%d_%H%M%S)"
        echo "User: ${USER:-$(whoami)}"
        echo "System: $(uname -a)"
        echo "Current system: $(nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo "unknown")"
        echo ""

        echo "=== Comparison Results ==="

        # This will be populated by running the comparison
        if compare_against_baseline "$baseline_id" 2>&1; then
            echo "RESULT: PASS - Configuration is equivalent to baseline"
        else
            echo "RESULT: FAIL - Configuration differs from baseline"
        fi

    } > "$output_file"

    success "Report generated: $output_file"
}

# Main execution
main() {
    case "${1:-help}" in
        compare)
            if [ -z "${2:-}" ]; then
                error "Please provide baseline ID to compare against"
                echo "Available baselines:"
                list_baselines
                exit 1
            fi
            compare_against_baseline "$2"
            ;;
        list)
            list_baselines
            ;;
        report)
            if [ -z "${2:-}" ]; then
                error "Please provide baseline ID for report generation"
                exit 1
            fi
            generate_report "$2" "${3:-}"
            ;;
        help|--help|-h)
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  compare <baseline_id>           Compare current config against baseline"
            echo "  list                           List available baselines"
            echo "  report <baseline_id> [file]    Generate detailed comparison report"
            echo "  help                           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 compare baseline-20240622_143000"
            echo "  $0 list"
            echo "  $0 report baseline-20240622_143000 my-report.txt"
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
