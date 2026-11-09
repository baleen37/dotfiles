#!/usr/bin/env bash
# Apply the selected host through its Nix or Debian native backend.
set -euo pipefail
set +x
# Debian native setup runs before Nix bootstrap checks; --home keeps the existing
# standalone Home Manager path. NixOS continues through the Nix system backend.
home_only=false
for argument in "$@"; do
  case "$argument" in
    --home) home_only=true ;;
    --help | -h)
      echo 'Usage: ./switch.sh [host] [--home] [--build | --check]'
      echo 'macOS/NixOS: Nix switch; --build/--check builds without activation.'
      echo 'Debian: native packages and app settings; --build/--check prints the declaration.'
      echo 'Debian identity options: --age-key-file PATH, --age-key-ref op://vault/item/field'
      echo 'HM_USER selects standalone Home Manager with --home.'
      exit 0
      ;;
  esac
done
if [ "$home_only" = false ] && [ "$(uname -s)" = Linux ] && [ -f /etc/os-release ]; then
  debian_id=$(
    . /etc/os-release
    printf '%s' "$ID"
  )
  if [ "$debian_id" = debian ]; then
    args=()
    for argument in "$@"; do
      if [ "$argument" = --build ]; then
        args+=(--check)
      else
        args+=("$argument")
      fi
    done
    exec "$(dirname "${BASH_SOURCE[0]}")/machines/debian/apply.sh" "${args[@]}"
  fi
fi
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/setup.sh"
HOST=
HOME_ONLY=false
BUILD_ONLY=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --home) HOME_ONLY=true ;;
    --build | --check) BUILD_ONLY=true ;;
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
elif [ "$BUILD_ONLY" = true ]; then
  if [ "$OS" = Darwin ]; then
    build_attr="$SYSTEM_ATTR.system"
  else
    build_attr="$SYSTEM_ATTR.config.system.build.toplevel"
  fi
  nix_cmd build "$FLAKE_REF#$build_attr" --no-link
  log "System build finished; not activated."
  exit 0
elif [ "$OS" = Darwin ]; then
  homebrew_enabled=$(nix_cmd eval --json "$FLAKE_REF#$SYSTEM_ATTR.config.homebrew.enable") \
    || die 'cannot evaluate Homebrew requirements; no system activation started'
  if [ "$homebrew_enabled" = true ]; then
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
    # Keep rollback in the authenticated process, independent of sudo expiry.
    sudo -H /bin/bash -s -- "$system" "$FLAKE_REF#$HOST" << 'ACTIVATE'
set -euo pipefail
moved_files=()
restore_etc() {
  local status=$? file
  if [ "$status" -ne 0 ] && [ -n "${moved_files[*]:-}" ]; then
    for file in "${moved_files[@]}"; do
      if [ ! -e "$file" ] && [ ! -L "$file" ] && [ -f "$file.before-nix-darwin" ]; then
        mv "$file.before-nix-darwin" "$file" \
          || printf 'error: could not restore %s; original remains at %s.before-nix-darwin\n' "$file" "$file" >&2
      fi
    done
  fi
  return "$status"
}
trap restore_etc EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for file in /etc/bashrc /etc/zshrc /etc/zprofile /etc/nix/nix.custom.conf; do
  if [ -f "$file" ] && [ ! -L "$file" ] \
    && [ ! -e "$file.before-nix-darwin" ] && [ ! -L "$file.before-nix-darwin" ]; then
    moved_files+=("$file")
    mv "$file" "$file.before-nix-darwin"
  fi
done
"$1/sw/bin/darwin-rebuild" switch --flake "$2"
moved_files=()
ACTIVATE
  fi
  # Nix/Homebrew and user launch agents are ready before one-shot app settings.
  if [ -x /run/current-system/sw/bin/dotfiles-remote-apply ]; then
    /run/current-system/sw/bin/dotfiles-remote-apply
  fi
  if [ -x /run/current-system/sw/bin/nh ]; then
    mkdir -p "$HOME/Library/Logs"
    nohup sudo -n -H /run/current-system/sw/bin/nh clean all --keep 3 \
      > "$HOME/Library/Logs/nh-clean.log" 2>&1 &
    log 'Generation cleanup running; log: ~/Library/Logs/nh-clean.log'
  fi
else
  nix_cmd run --inputs-from "$FLAKE_REF" nixpkgs#nixos-rebuild -- \
    switch --sudo --flake "$FLAKE_REF#$HOST"
fi
log 'Configuration applied successfully.'
