#!/usr/bin/env bash
# Apply only after bootstrap; never downloads a private key or authenticates op.
set -euo pipefail
set +x
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/setup.sh"
HOST=
HOME_ONLY=false
BUILD_ONLY=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --help | -h)
      echo 'Usage: ./switch.sh [host] [--home] [--build]  (HM_USER selects standalone Home Manager)'
      exit 0
      ;;
    --home) HOME_ONLY=true ;;
    --build) BUILD_ONLY=true ;;
    -*) die "unknown option: $1" ;;
    *)
      [ -z "$HOST" ] || die 'only one host may be supplied'
      HOST=$1
      ;;
  esac
  shift
done
setup_context
command -v nix > /dev/null 2>&1 || die 'run ./bootstrap.sh first'
[ -x "$TOOLS_LINK/bin/sops" ] || die 'bootstrap tools missing: run ./bootstrap.sh first'
TOOLS=$(cd "$TOOLS_LINK" && pwd -P)
export PATH="$TOOLS/bin:$PATH"
select_configuration
check_macos_permissions
# This runs before any system or Home Manager activation.
if [ "$BUILD_ONLY" = false ]; then
  secrets_check
fi

if [ "$HOME_ONLY" = true ]; then
  activation=$(nix_cmd build "$FLAKE_REF#homeConfigurations.\"$HM_USER\".activationPackage" \
    --no-link --print-out-paths)
  if [ "$BUILD_ONLY" = true ]; then
    log "Built: $activation"
    exit 0
  fi
  "$activation/activate"
elif [ "$OS" = Darwin ]; then
  if [ "$BUILD_ONLY" = true ]; then
    nix_cmd build "$FLAKE_REF#$SYSTEM_ATTR.system" --no-link
    log "System build finished; not activated."
    exit 0
  fi
  if [ "$(nix_cmd eval --json "$FLAKE_REF#$SYSTEM_ATTR.config.homebrew.enable")" = true ]; then
    [ -x /opt/homebrew/bin/brew ] || die 'Homebrew required by selected apps: run ./bootstrap.sh'
  fi
  if [ -x /run/current-system/sw/bin/darwin-rebuild ]; then
    # Preserve the exact work-host sudoers allowlist when no local registration
    # is needed; other sources use the filtered snapshot, never the raw directory.
    darwin_ref=.
    if [ -f flake-modules/hosts.local.nix ] || [ -n "$(git ls-files --others --exclude-standard)" ]; then
      darwin_ref="$FLAKE_REF"
    fi
    sudo -H /run/current-system/sw/bin/darwin-rebuild switch --flake "$darwin_ref#$HOST"
  else
    # Build as the user before moving conflicting stock /etc files aside.
    system=$(nix_cmd build "$FLAKE_REF#$SYSTEM_ATTR.system" --no-link --print-out-paths)
    sudo -v
    for file in /etc/bashrc /etc/zshrc /etc/zprofile /etc/nix/nix.custom.conf; do
      if [ -f "$file" ] && [ ! -L "$file" ] && [ ! -e "$file.before-nix-darwin" ]; then
        sudo mv "$file" "$file.before-nix-darwin"
      fi
    done
    sudo -H "$system/sw/bin/darwin-rebuild" switch --flake "$FLAKE_REF#$HOST"
  fi
  if [ -x /run/current-system/sw/bin/nh ]; then
    mkdir -p "$HOME/Library/Logs"
    nohup sudo -n -H /run/current-system/sw/bin/nh clean all --keep 3 \
      > "$HOME/Library/Logs/nh-clean.log" 2>&1 &
    log 'Generation cleanup running; log: ~/Library/Logs/nh-clean.log'
  fi
else
  if [ "$BUILD_ONLY" = true ]; then
    nix_cmd build "$FLAKE_REF#$SYSTEM_ATTR.config.system.build.toplevel" --no-link
    log "System build finished; not activated."
    exit 0
  fi
  nix_cmd run --inputs-from "$FLAKE_REF" nixpkgs#nixos-rebuild -- \
    switch --sudo --flake "$FLAKE_REF#$HOST"
fi
log 'Configuration applied successfully.'
