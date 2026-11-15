#!/usr/bin/env bash
# Select the same local configuration as switch, but only build and upload it.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/setup.sh"
setup_context
select_configuration
if [ -z "$SYSTEM_ATTR" ]; then
  attr="homeConfigurations.\"$HM_USER\".activationPackage"
elif [ "$OS" = Darwin ]; then
  attr="$SYSTEM_ATTR.system"
else
  attr="$SYSTEM_ATTR.config.system.build.toplevel"
fi
nix_cmd build "$FLAKE_REF#$attr" --json --no-link \
  | jq -r '.[].outputs | to_entries[].value' \
  | cachix push baleen-nix
