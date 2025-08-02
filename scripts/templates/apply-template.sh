#!/usr/bin/env bash
# Apply Template - Common logic for all platform apply scripts
# This template replaces the duplicated logic across all apply scripts

VERSION=1.0

# Get script directory for module loading
SCRIPT_DIR="$(dirname "$(dirname "$0")")"
LIB_DIR="$SCRIPT_DIR/scripts/lib"

# Load all utility modules
. "$LIB_DIR/ui-utils.sh"
. "$LIB_DIR/user-input.sh"
. "$LIB_DIR/token-replacement.sh"
. "$LIB_DIR/platform-config.sh"

# Main apply logic
main() {
  _print "${GREEN}=== Apply Script v$VERSION ===${NC}"

  # Setup platform environment
  setup_platform_environment

  # Collect user information
  collect_user_info

  # Platform-specific star request (only for x86_64 platforms)
  if [ "$ARCH" = "x86_64" ]; then
    ask_for_star
  fi

  _print "${GREEN}Apply completed successfully${NC}"
}

# Only run main if this script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
