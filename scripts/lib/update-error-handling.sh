#!/bin/sh
# update-error-handling.sh - Batch update script for unified error handling migration
# Automatically updates all scripts to use the unified error handling system

SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="${SCRIPTS_DIR}/lib"

# Files to update (excluding those already processed)
FILES_TO_UPDATE="
${SCRIPTS_DIR}/enhanced-test.sh
${SCRIPTS_DIR}/build-switch-common.sh
${SCRIPTS_DIR}/platform/common-interface.sh
${LIB_DIR}/sudo-management.sh
${LIB_DIR}/state-persistence.sh
${LIB_DIR}/scenario-orchestrator.sh
${LIB_DIR}/pre-validation.sh
${LIB_DIR}/performance-monitor.sh
${LIB_DIR}/performance-dashboard.sh
${LIB_DIR}/notification-auto-recovery.sh
${LIB_DIR}/flake-evaluation.sh
${LIB_DIR}/cache-optimization.sh
${LIB_DIR}/audit-logger.sh
${LIB_DIR}/alternative-execution.sh
"

echo "Starting batch update for unified error handling..."

for file in $FILES_TO_UPDATE; do
    if [ -f "$file" ]; then
        echo "Processing: $file"

        # Check if file already imports unified-error-handling
        if ! grep -q "unified-error-handling.sh" "$file"; then
            # Add import after the shebang line
            sed -i '2i\
# Import unified error handling system\
SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(dirname "$0")")}"  \
. "${SCRIPTS_DIR}/lib/unified-error-handling.sh"' "$file"
        fi

        # Replace all log_error calls with unified_log_error
        sed -i 's/\blog_error\b/unified_log_error/g' "$file"
        sed -i 's/\bprint_error\b/unified_log_error/g' "$file"

        # Replace common color variables with unified colors
        sed -i 's/\bRED=/# &/g' "$file"
        sed -i 's/\bGREEN=/# &/g' "$file"
        sed -i 's/\bYELLOW=/# &/g' "$file"
        sed -i 's/\bBLUE=/# &/g' "$file"
        sed -i 's/\bNC=/# &/g' "$file"

        echo "  ✓ Updated $file"
    else
        echo "  ⚠ File not found: $file"
    fi
done

echo "Batch update completed!"
