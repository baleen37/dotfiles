#!/usr/bin/env bash
# One-shot bootstrap for a fresh machine: ./install.sh [host-name]
#
# macOS: Xcode CLT -> Determinate Nix -> Homebrew -> local host -> first
#        nix-darwin activation (darwin-rebuild does not exist until then).
# Linux: Determinate Nix -> `make switch`.
#
# Safe to re-run: every step is skipped when already done, and once
# darwin-rebuild exists this is just `make switch`.
#
# host-name defaults to `hostname -s`, the name the Makefile uses, so plain
# `make` works afterwards. A host that flake-modules/hosts.nix does not declare
# is written to flake-modules/hosts.local.nix, which is gitignored: no tracked
# file changes. The Makefile reads the flake through `path:` while that file
# exists, because a git flake reference cannot see ignored files.
#
# Installers are pinned and verified before they run. To bump an installer:
# update the version/commit in its URL, then set the hash to the output of
#   curl -sSfL <url> | shasum -a 256

set -euo pipefail

NIX_INSTALLER_URL=https://install.determinate.systems/nix/tag/v3.24.1
NIX_INSTALLER_SHA256=1470fa510a9e3e8d8e03c7dc50f89c22003a0d7077a43486b6a3e97e3dde6160
BREW_INSTALLER_URL=https://raw.githubusercontent.com/Homebrew/install/959bdd728192d78c47287c177796c3d86d111f09/install.sh
BREW_INSTALLER_SHA256=5f333bbe53bc490e51e7ccb1df8779b3dd6ee73a1a7379efda216edb08ccb148

cd "$(dirname "${BASH_SOURCE[0]}")"
REPO_DIR=$PWD
FLAKE_REF="path:$REPO_DIR"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

[ "$(id -u)" -ne 0 ] || die "run as your normal user, not root (sudo is requested when needed)"

HOST=${1:-${NIXNAME:-$(hostname -s)}}
OS=$(uname -s)
TMP_DIR=$(mktemp -d)
SUDO_KEEPALIVE_PID=
NEEDS_SUDO=false
cleanup() {
  if [ -n "$SUDO_KEEPALIVE_PID" ]; then
    kill "$SUDO_KEEPALIVE_PID" 2> /dev/null || true
    wait "$SUDO_KEEPALIVE_PID" 2> /dev/null || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

authorize_install() {
  log "Authenticate once before installation (sudo access is refreshed until this script exits)"
  sudo -v || die "administrator authentication failed; nothing has been installed"
  (
    while kill -0 "$$" 2> /dev/null; do
      sudo -n -v 2> /dev/null || exit
      sleep 45 &
      wait "$!"
    done
  ) &
  SUDO_KEEPALIVE_PID=$!
}

# fetch_verified <url> <sha256>: download to a temp file, refuse to return it
# unless the hash matches. Callers run the file only after this succeeds.
fetch_verified() {
  local url=$1 want=$2 out="$TMP_DIR/$(basename "$1")" got
  curl --proto '=https' --tlsv1.2 -sSfL "$url" -o "$out" || die "download failed: $url"
  got=$(shasum -a 256 "$out" | cut -d' ' -f1)
  [ "$got" = "$want" ] || die "checksum mismatch for $url (expected $want, got $got)"
  printf '%s\n' "$out"
}

load_nix() {
  local f
  for f in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    # shellcheck disable=SC1090
    [ -r "$f" ] && . "$f" && return 0
  done
  return 0
}

nix_cmd() {
  nix --extra-experimental-features 'nix-command flakes' "$@"
}

preflight() {
  local cmd answer
  case "$OS" in
    Darwin)
      [ "$(uname -m)" = arm64 ] || die "this repository supports Apple Silicon Macs only"
      ;;
    Linux) ;;
    *) die "unsupported OS: $OS" ;;
  esac
  for cmd in curl shasum make; do
    command -v "$cmd" > /dev/null 2>&1 || die "required command missing: $cmd"
  done
  [[ $HOST =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || die "invalid host name: $HOST"
  [ -w "$REPO_DIR" ] || die "repository must be writable: $REPO_DIR"
  load_nix
  if [ "$OS" = Darwin ] || [ -e /etc/NIXOS ] || ! command -v nix > /dev/null 2>&1; then
    NEEDS_SUDO=true
    command -v sudo > /dev/null 2>&1 || die "required command missing: sudo"
  fi
  log "Preflight: $OS / $(uname -m), user $(id -un), host $HOST"
  if command -v nix > /dev/null 2>&1; then
    nix --version
  else
    log "Nix is not installed or not available on PATH"
  fi
  if [ "$OS" = Darwin ]; then
    xcode-select -p > /dev/null 2>&1 || log "Xcode Command Line Tools will require a GUI installation"
    [ ! -x /opt/homebrew/bin/brew ] || log "Homebrew is already installed"
    if ! command -v nix > /dev/null 2>&1 && diskutil info 'Nix Store' > /dev/null 2>&1; then
      log "Found a Nix Store volume without a usable Nix installation (possibly an interrupted install)."
      printf '%s\n' 'If Nix installation cannot recover, follow:' \
        'https://docs.determinate.systems/troubleshooting/installation-failed-macos/' \
        'Existing volumes and Keychain entries will not be deleted by this script.'
    fi
    printf '%s\n' \
      'Plan: install missing CLT, Nix (official shell installer), and Homebrew; register this host; activate nix-darwin.' \
      'Nix creates an APFS store volume. First activation backs up conflicting /etc files' \
      'to *.before-nix-darwin and applies the repository system and user configuration.' \
      'Administrator authentication happens before installation and is refreshed during this run.' \
      'Full Disk Access is not a blanket prerequisite. If a permission error occurs,' \
      'review the error before enabling it for the terminal app running this script.' \
      'macOS app permissions cannot be approved in bulk; individual apps request them separately.'
  else
    printf '%s\n' 'Plan: install Nix if missing, then run make switch for this system/user.'
  fi
  [ -t 0 ] || die "run interactively in a terminal to review installation and authenticate"
  read -r -p 'Continue with this plan? [y/N] ' answer
  case "$answer" in
    y | Y | yes | YES) ;;
    *)
      log "Cancelled before installation"
      exit 0
      ;;
  esac
}

install_clt() {
  xcode-select -p > /dev/null 2>&1 && return 0
  log "Installing Xcode Command Line Tools (finish the GUI dialog)"
  xcode-select --install > /dev/null 2>&1 || true
  log "Waiting for Command Line Tools; cancel this script with Ctrl-C if the GUI installation is cancelled"
  until xcode-select -p > /dev/null 2>&1; do
    sleep 5
  done
}

install_nix() {
  load_nix
  command -v nix > /dev/null 2>&1 && return 0
  if [ "$OS" = Darwin ] && [ ! -d /nix ] \
    && sudo -n grep -qx 'nix' /etc/synthetic.conf 2> /dev/null; then
    die "macOS has registered /nix but has not created it. Restart this Mac, then re-run ./install.sh. Repeating the installer before reboot will fail to mount Nix Store."
  fi
  log "Installing Determinate Nix"
  local installer install_log
  installer=$(fetch_verified "$NIX_INSTALLER_URL" "$NIX_INSTALLER_SHA256")
  install_log=$(mktemp "${TMPDIR:-/tmp}/dotfiles-nix-install.XXXXXX")
  log "Nix installation log: $install_log"
  if ! sh "$installer" install --no-confirm 2>&1 | tee "$install_log"; then
    if [ "$OS" = Darwin ]; then
      printf '%s\n' \
        'For macOS mount/permission errors, review the original error above.' \
        'Full Disk Access may be needed for the terminal app running this script;' \
        'enable it only if indicated, then restart the terminal and re-run ./install.sh.' \
        'Recovery: https://docs.determinate.systems/troubleshooting/installation-failed-macos/' >&2
    fi
    die "Nix installation failed; full log saved to $install_log"
  fi
  load_nix
  command -v nix > /dev/null 2>&1 || die "nix not on PATH after install; open a new terminal and re-run ./install.sh"
}

install_brew() {
  [ -x /opt/homebrew/bin/brew ] && return 0
  log "Installing Homebrew (nix-darwin's homebrew module needs it)"
  local installer
  installer=$(fetch_verified "$BREW_INSTALLER_URL" "$BREW_INSTALLER_SHA256")
  NONINTERACTIVE=1 /bin/bash "$installer"
}

host_declared() {
  nix_cmd eval --json "$FLAKE_REF#darwinConfigurations" --apply builtins.attrNames 2> /dev/null \
    | grep -q "\"$HOST\""
}

ensure_local_host() {
  host_declared && return 0
  local file=flake-modules/hosts.local.nix
  log "Host '$HOST' is not declared; writing $file (gitignored, user: $(id -un))"
  cat > "$file" << EOF
# Generated by install.sh; gitignored. Delete it to forget this machine.
{ ... }:
{
  config.dotfiles.hosts."$HOST" = {
    system = "aarch64-darwin";
    class = "darwin";
    user = "$(id -un)";
    machineModules = [ ../machines/darwin/common.nix ];
  };
}
EOF
  host_declared || die "host '$HOST' still not evaluable; run: nix flake show $FLAKE_REF"
}

# Stock /etc files make the first nix-darwin activation abort. Move them aside
# the way the nix-darwin error message instructs.
move_etc_aside() {
  local f
  # nix.custom.conf: the Determinate installer's stub; nix-darwin owns it after.
  for f in /etc/bashrc /etc/zshrc /etc/zprofile /etc/nix/nix.custom.conf; do
    if [ -f "$f" ] && [ ! -L "$f" ] && [ ! -e "$f.before-nix-darwin" ]; then
      log "Moving $f aside to $f.before-nix-darwin"
      sudo mv "$f" "$f.before-nix-darwin"
    fi
  done
}

darwin_install() {
  install_nix
  install_brew
  ensure_local_host

  if [ -x /run/current-system/sw/bin/darwin-rebuild ]; then
    log "nix-darwin already active; running make switch"
    make -C "$REPO_DIR" switch NIXNAME="$HOST"
    return
  fi

  move_etc_aside
  # accept-flake-config: until the first activation the flake's nixConfig is
  # not trusted, so without it Nix prompts and, on "no", ignores the binary
  # caches and builds everything from source. darwin-rebuild has no such
  # flag, so it goes in via NIX_CONFIG, which every nix it spawns reads.
  log "First activation of '$HOST' via nix-darwin"
  sudo -H env PATH="$PATH" NIX_CONFIG='accept-flake-config = true' \
    nix --extra-experimental-features 'nix-command flakes' \
    run --inputs-from "$FLAKE_REF" darwin -- \
    switch --flake "$FLAKE_REF#$HOST"
  log "Done. Open a new terminal; from now on just run: make"
}

preflight
if [ "$NEEDS_SUDO" = true ]; then
  authorize_install
fi
# Finish required GUI setup first, then continue without another Enter prompt.
if [ "$OS" = Darwin ]; then
  install_clt
fi

case "$OS" in
  Darwin) darwin_install ;;
  Linux)
    install_nix
    make -C "$REPO_DIR" switch NIXNAME="$HOST"
    ;;
  *) die "unsupported OS: $OS" ;;
esac
