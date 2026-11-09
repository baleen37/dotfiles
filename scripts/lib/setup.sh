#!/usr/bin/env bash
# Sourced by bootstrap.sh and switch.sh.
log() { printf '==> %s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}
nix_cmd() { nix --extra-experimental-features 'nix-command flakes' --accept-flake-config "$@"; }
# NixOS always keeps its system backend, including when hosted inside WSL.
is_debian() {
  [ "$(uname -s)" = Linux ] && [ ! -e /etc/NIXOS ] && [ -r /etc/os-release ] && (
    . /etc/os-release
    [ "${ID:-}" = debian ]
  )
}
load_nix() {
  command -v nix > /dev/null 2>&1 && return 0
  local file
  for file in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    if [ -r "$file" ]; then
      . "$file"
    fi
    command -v nix > /dev/null 2>&1 && return 0
  done
  return 0
}
cleanup_flake() {
  [ -z "${SOURCE_DIR:-}" ] || rm -rf "$SOURCE_DIR"
}
prepare_flake() {
  local file source destination
  if [ -z "$SOURCE_DIR" ]; then
    git rev-parse --show-toplevel > /dev/null 2>&1 || die 'a Git checkout is required to safely select flake files'
    # Resolve symlinks: macOS /tmp -> private/tmp, and Nix rejects a path:
    # flake whose path goes through a symlink.
    SOURCE_DIR=$(cd "$(mktemp -d /tmp/dotfiles-source.XXXXXX)" && pwd -P)
    trap cleanup_flake EXIT
    source="$SOURCE_DIR/source"
    mkdir "$source"
    # Enumerate before copying: a Git failure must never produce a partial source.
    git ls-files -z --cached --others --exclude-standard > "$SOURCE_DIR/files" || die 'cannot select flake files'
    while IFS= read -r -d '' file; do
      [ -e "$file" ] || [ -L "$file" ] || continue
      destination="$source/$file"
      [ -d "${destination%/*}" ] || mkdir -p "${destination%/*}"
      # Preserve symlinks; following one could copy an ignored private target.
      cp -Pp "./$file" "$destination"
    done < "$SOURCE_DIR/files"
  fi
  source="$SOURCE_DIR/source"
  # The only intentionally ignored input. Never admit other ignored files.
  file=flake-modules/hosts.local.nix
  if [ -e "$file" ] || [ -L "$file" ]; then
    [ -f "$file" ] && [ ! -L "$file" ] || die 'local host registry must be a regular file'
    mkdir -p "$source/flake-modules"
    cp -p "$file" "$source/$file"
  fi
  FLAKE_REF="path:$source"
}
setup_context() {
  HOME_ONLY=${HOME_ONLY:-false}
  [ "$(id -u)" -ne 0 ] || die "run as your normal user; sudo is requested only where needed"
  REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
  cd "$REPO_DIR" || die "cannot enter repository"
  HOST=${HOST:-$(hostname -s)}
  [[ $HOST =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || die "invalid host name: $HOST"
  OS=$(uname -s)
  case "$OS/$(uname -m)" in
    Darwin/arm64) NIX_SYSTEM=aarch64-darwin ;;
    Linux/aarch64 | Linux/arm64) NIX_SYSTEM=aarch64-linux ;;
    Linux/x86_64) NIX_SYSTEM=x86_64-linux ;;
    *) die "unsupported platform: $OS/$(uname -m)" ;;
  esac
  SOURCE_DIR=
  prepare_flake
  TOOLS_LINK="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/bootstrap-tools"
  load_nix
  MACOS_PERMISSIONS_CHECKED=false
}
check_macos_permissions() {
  [ "$OS" = Darwin ] && [ "$HOME_ONLY" = false ] && [ "${BUILD_ONLY:-false}" = false ] || return 0
  [ "$MACOS_PERMISSIONS_CHECKED" = false ] || return 0
  # A fresh bootstrap can determine the selected host only after Nix is installed.
  if ! command -v nix > /dev/null 2>&1; then
    log 'App Management requirements will be checked after Nix is installed.'
    return
  fi
  local required status settings_url
  required=$(nix_cmd eval --json "$FLAKE_REF#darwinConfigurations" --apply "
    hosts: if builtins.hasAttr \"$HOST\" hosts then
      let c = hosts.\"$HOST\".config; in
      c.programs._1password-gui.enable ||
        (c.homebrew.enable && (c.homebrew.casks != [] || c.homebrew.masApps != {}))
    else false
  ") || die "cannot determine macOS permission requirements; no installation started"
  if [ "$required" = false ]; then
    MACOS_PERMISSIONS_CHECKED=true
    log 'App Management: not required by selected host.'
    return
  fi
  status=$(osascript -l JavaScript "$REPO_DIR/scripts/lib/macos-app-management.js" 2> /dev/null) || status=unknown
  if [ "$status" = granted ]; then
    MACOS_PERMISSIONS_CHECKED=true
    log 'App Management: granted for this terminal session.'
    return
  fi
  settings_url='x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles'
  printf '%s\n' \
    "App Management: $status. Installation has not started." \
    'Allow the app hosting this terminal (for example Herdr Core) in System Settings > Privacy & Security > App Management.' \
    'Quit and reopen that app, then rerun the same command. sudo does not grant this macOS permission.' \
    "Settings: $settings_url" >&2
  open "$settings_url" || log 'Could not open System Settings; open App Management manually.'
  die 'macOS permission preflight incomplete'
}
build_tools() {
  command -v nix > /dev/null 2>&1 || die "Nix missing: run ./bootstrap.sh"
  mkdir -p "$(dirname "$TOOLS_LINK")"
  nix_cmd build "$FLAKE_REF#packages.$NIX_SYSTEM.bootstrap-tools" \
    --out-link "$TOOLS_LINK"
  TOOLS=$(cd "$TOOLS_LINK" && pwd -P)
  export PATH="$TOOLS/bin:$PATH"
}
select_configuration() {
  local current_user configured_user configured_system
  current_user=$(id -un)
  if [ "$HOME_ONLY" = true ] || { [ "$OS" = Linux ] && [ ! -e /etc/NIXOS ]; }; then
    HOME_ONLY=true
    if [ -z "${HM_USER:-}" ]; then
      HM_USER=$(nix_cmd eval --raw "$FLAKE_REF#homeConfigurations" --apply "
        homes: let
          matches = builtins.filter (name:
            let h = builtins.getAttr name homes; in
            h.config.home.username == \"$current_user\" &&
            h.pkgs.stdenv.hostPlatform.system == \"$NIX_SYSTEM\"
          ) (builtins.attrNames homes);
        in if builtins.length matches == 1 then builtins.head matches
        else throw \"set HM_USER to a matching Home Manager profile\"
      ") || die "no unique Home Manager profile for $current_user on $NIX_SYSTEM; set HM_USER"
    fi
    [[ $HM_USER =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || die "invalid HM_USER"
    configured_system=$(nix_cmd eval --raw "$FLAKE_REF#homeConfigurations.\"$HM_USER\".pkgs.stdenv.hostPlatform.system")
    [ "$configured_system" = "$NIX_SYSTEM" ] \
      || die "Home Manager profile '$HM_USER' targets $configured_system; this machine is $NIX_SYSTEM"
    HOME_ATTR="homeConfigurations.\"$HM_USER\".config"
    SYSTEM_ATTR=
  else
    local registry declared
    if [ "$OS" = Darwin ]; then
      registry=darwinConfigurations
    else
      registry=nixosConfigurations
    fi
    SYSTEM_ATTR="$registry.\"$HOST\""
    HOME_ATTR="$SYSTEM_ATTR.config.home-manager.users.\"$current_user\""
    declared=$(nix_cmd eval --json "$FLAKE_REF#$registry" \
      --apply "hosts: builtins.hasAttr \"$HOST\" hosts")
    [ "$declared" = true ] || die "host '$HOST' is not registered in flake-modules/hosts.nix; register it before running ./bootstrap.sh"
  fi
  configured_user=$(nix_cmd eval --raw "$FLAKE_REF#$HOME_ATTR.home.username")
  [ "$configured_user" = "$current_user" ] || die "configuration belongs to another user: $configured_user"
}
secrets_check() {
  local check
  check=$(nix_cmd build "$FLAKE_REF#$HOME_ATTR.modules.secrets.preflight" \
    --no-link --print-out-paths)
  "$check/bin/dotfiles-secrets-check" "$@"
}
