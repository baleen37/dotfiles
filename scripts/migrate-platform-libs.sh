#!/bin/bash
# Migration script to consolidate platform-specific lib files
# This script identifies outdated platform libs and updates references

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[MIGRATE]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[MIGRATE]${NC} $1"
}

print_error() {
    echo -e "${RED}[MIGRATE]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[MIGRATE]${NC} $1"
}

# Configuration
PLATFORMS=(aarch64-darwin x86_64-linux aarch64-linux x86_64-darwin)
COMMON_LIB_DIR="scripts/lib"
PLATFORM_OVERRIDE_DIR="scripts/platform"

# Check if common lib files are newer than platform-specific ones
check_lib_versions() {
    local lib_file="$1"
    local common_file="$COMMON_LIB_DIR/$lib_file"
    local outdated_platforms=()

    if [ ! -f "$common_file" ]; then
        print_warning "Common lib file not found: $common_file"
        return 1
    fi

    print_info "Checking $lib_file across platforms..."

    for platform in "${PLATFORMS[@]}"; do
        local platform_file="apps/$platform/lib/$lib_file"

        if [ -f "$platform_file" ]; then
            # Check if files are different
            if ! diff -q "$common_file" "$platform_file" >/dev/null 2>&1; then
                local common_size=$(wc -c < "$common_file")
                local platform_size=$(wc -c < "$platform_file")

                print_warning "  $platform: Different from common (common: ${common_size}B, platform: ${platform_size}B)"
                outdated_platforms+=("$platform")
            else
                print_status "  $platform: Identical to common"
            fi
        else
            print_info "  $platform: No platform-specific version"
        fi
    done

    if [ ${#outdated_platforms[@]} -gt 0 ]; then
        print_warning "Outdated platforms for $lib_file: ${outdated_platforms[*]}"
        return 1
    else
        print_status "All platforms up to date for $lib_file"
        return 0
    fi
}

# Update platform-specific lib files to use common version
update_platform_lib() {
    local lib_file="$1"
    local platform="$2"
    local common_file="$COMMON_LIB_DIR/$lib_file"
    local platform_file="apps/$platform/lib/$lib_file"

    if [ ! -f "$common_file" ]; then
        print_error "Common lib file not found: $common_file"
        return 1
    fi

    if [ -f "$platform_file" ]; then
        # Backup original
        cp "$platform_file" "$platform_file.backup"
        print_info "Backed up $platform_file to $platform_file.backup"
    fi

    # Copy common version to platform
    cp "$common_file" "$platform_file"
    print_status "Updated $platform_file with common version"
}

# Main migration function
migrate_libs() {
    local lib_files=(
        "sudo-management.sh"
        "logging.sh"
        "performance.sh"
        "token-replacement.sh"
        "ui-utils.sh"
        "user-input.sh"
        "platform-config.sh"
        "progress.sh"
        "build-logic.sh"
    )

    print_status "Starting lib migration process..."

    local total_outdated=0
    local total_updated=0

    # Check all lib files
    for lib_file in "${lib_files[@]}"; do
        if ! check_lib_versions "$lib_file"; then
            total_outdated=$((total_outdated + 1))

            print_info "Updating outdated platforms for $lib_file..."
            for platform in "${PLATFORMS[@]}"; do
                local platform_file="apps/$platform/lib/$lib_file"
                local common_file="$COMMON_LIB_DIR/$lib_file"

                if [ -f "$platform_file" ] && [ -f "$common_file" ]; then
                    if ! diff -q "$common_file" "$platform_file" >/dev/null 2>&1; then
                        update_platform_lib "$lib_file" "$platform"
                        total_updated=$((total_updated + 1))
                    fi
                fi
            done
        fi
    done

    print_status "Migration completed:"
    print_info "  Total outdated lib files: $total_outdated"
    print_info "  Total platform files updated: $total_updated"

    if [ $total_updated -gt 0 ]; then
        print_warning "Please test the updated platform files before committing"
        print_info "Backups were created with .backup extension"
    fi
}

# Main execution
main() {
    print_info "Platform lib migration tool"
    print_info "This script consolidates platform-specific lib files with common versions"

    # Verify directories exist
    if [ ! -d "$COMMON_LIB_DIR" ]; then
        print_error "Common lib directory not found: $COMMON_LIB_DIR"
        exit 1
    fi

    if [ ! -d "$PLATFORM_OVERRIDE_DIR" ]; then
        print_warning "Platform override directory not found: $PLATFORM_OVERRIDE_DIR"
        print_info "Platform overrides are available for platform-specific customizations"
    fi

    migrate_libs
}

# Show usage if requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0"
    echo ""
    echo "Migrates platform-specific lib files to use common versions."
    echo "Creates backups of original files before updating."
    echo ""
    echo "This script:"
    echo "  1. Compares common lib files with platform-specific versions"
    echo "  2. Identifies outdated platform-specific files"
    echo "  3. Updates platform files with common versions"
    echo "  4. Creates backups of original files"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    exit 0
fi

# Run main function
main "$@"
