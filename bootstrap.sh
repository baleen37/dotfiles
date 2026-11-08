#!/usr/bin/env bash
# Prepare tools and the age identity. Never applies the full host configuration.
set -euo pipefail
set +x
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/setup.sh"
HOST=
HOME_ONLY=false
SKIP_SECRETS=false
# Private / dotfiles/sops / age-key; IDs keep renames from breaking bootstrap.
AGE_KEY_REF=${DOTFILES_AGE_KEY_REF:-op://vwt2ko2iqk466x7vo2rb46bl5e/djrgof76gd5luaqr63vasbowlu/age-key}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --help | -h)
      echo "Usage: ./bootstrap.sh [host] [--home] [--age-key-ref op://vault/item/field] [--skip-secrets]"
      echo "Default age identity: Private / dotfiles/sops / age-key (override with --age-key-ref)"
      exit 0
      ;;
    --home) HOME_ONLY=true ;;
    --skip-secrets) SKIP_SECRETS=true ;;
    --age-key-ref)
      [ "$#" -ge 2 ] || die "--age-key-ref needs a reference"
      AGE_KEY_REF=$2
      shift
      ;;
    -*) die "unknown option: $1" ;;
    *)
      [ -z "$HOST" ] || die "only one host may be supplied"
      HOST=$1
      ;;
  esac
  shift
done
[[ $AGE_KEY_REF == op://* ]] || die "expected an op:// reference, never the private key itself"
setup_context
check_macos_permissions
NIX_INSTALLER_URL=https://install.determinate.systems/nix/tag/v3.24.1
NIX_INSTALLER_SHA256=1470fa510a9e3e8d8e03c7dc50f89c22003a0d7077a43486b6a3e97e3dde6160
BREW_INSTALLER_URL=https://raw.githubusercontent.com/Homebrew/install/959bdd728192d78c47287c177796c3d86d111f09/install.sh
BREW_INSTALLER_SHA256=5f333bbe53bc490e51e7ccb1df8779b3dd6ee73a1a7379efda216edb08ccb148

TMP_DIR=$(mktemp -d)
KEY_TEMP=
SUDO_KEEPALIVE_PID=
cleanup() {
  if [ -n "$SUDO_KEEPALIVE_PID" ]; then
    kill "$SUDO_KEEPALIVE_PID" 2> /dev/null || true
    wait "$SUDO_KEEPALIVE_PID" 2> /dev/null || true
  fi
  [ -z "$KEY_TEMP" ] || rm -f "$KEY_TEMP"
  rm -rf "$TMP_DIR"
  cleanup_flake
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
authorize_install() {
  [ -z "$SUDO_KEEPALIVE_PID" ] || return 0
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
  local url=$1 want=$2 out got
  out="$TMP_DIR/$(basename "$1")"
  curl --proto '=https' --tlsv1.2 -sSfL "$url" -o "$out" || die "download failed: $url"
  got=$(shasum -a 256 "$out" | cut -d' ' -f1)
  [ "$got" = "$want" ] || die "checksum mismatch for $url (expected $want, got $got)"
  printf '%s\n' "$out"
}

install_clt() {
  xcode-select -p > /dev/null 2>&1 && return 0
  authorize_install
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
  if [ "$OS" = Darwin ]; then
    authorize_install
  fi
  if [ "$OS" = Darwin ] && [ ! -d /nix ] \
    && sudo -n grep -qx 'nix' /etc/synthetic.conf 2> /dev/null; then
    die "macOS has registered /nix but has not created it. Restart this Mac, then re-run ./bootstrap.sh. Repeating the installer before reboot will fail to mount Nix Store."
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
        'enable it only if indicated, then restart the terminal and re-run ./bootstrap.sh.' \
        'Recovery: https://docs.determinate.systems/troubleshooting/installation-failed-macos/' >&2
    fi
    die "Nix installation failed; full log saved to $install_log"
  fi
  load_nix
  command -v nix > /dev/null 2>&1 || die "nix not on PATH after install; open a new terminal and re-run ./bootstrap.sh"
}

install_brew() {
  [ -x /opt/homebrew/bin/brew ] && return 0
  authorize_install
  log "Installing Homebrew (nix-darwin's homebrew module needs it)"
  local installer
  installer=$(fetch_verified "$BREW_INSTALLER_URL" "$BREW_INSTALLER_SHA256")
  NONINTERACTIVE=1 /bin/bash "$installer"
}

host_declared() {
  local declared
  declared=$(nix_cmd eval --json "$FLAKE_REF#darwinConfigurations" \
    --apply "hosts: builtins.hasAttr \"$HOST\" hosts") \
    || die "cannot evaluate host registry; fix the evaluation error before registering a host"
  [ "$declared" = true ]
}

ensure_local_host() {
  host_declared && return 0
  local file=flake-modules/hosts.local.nix
  log "Host '$HOST' is not declared; writing $file (gitignored, user: $(id -un))"
  [ ! -e "$file" ] || die "local registry already exists; add this host there explicitly"
  cat > "$file" << EOF
# Generated by bootstrap.sh; gitignored. Delete it to forget this machine.
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
  prepare_flake
  host_declared || die "host '$HOST' still not evaluable; check $file and rerun bootstrap"
}

prepare_identity() {
  local key_file
  key_file=$(nix_cmd eval --raw "$FLAKE_REF#$HOME_ATTR.sops.age.keyFile")
  if [ -e "$key_file" ]; then
    [ -f "$key_file" ] && [ ! -L "$key_file" ] && [ -s "$key_file" ] || die "existing age key is empty, a symlink, or not a file: $key_file"
    "$TOOLS/bin/age-keygen" -y "$key_file" > /dev/null || die "existing age key is invalid; it was not replaced"
    secrets_check "$key_file"
    chmod 600 "$key_file"
    log "Existing age key validated; preserved."
    return
  fi
  local op_bin="$TOOLS/bin/op" accounts
  # Enable app integration for this run; fall back to terminal authentication.
  # An explicit false still supports machines without a desktop app.
  export OP_BIOMETRIC_UNLOCK_ENABLED=${OP_BIOMETRIC_UNLOCK_ENABLED:-true}
  "$op_bin" --version > /dev/null || die "1Password CLI cannot run"
  if ! "$op_bin" whoami > /dev/null 2>&1 \
    && [ "$OP_BIOMETRIC_UNLOCK_ENABLED" = true ]; then
    # whoami only reports state; signin requests desktop authorization.
    "$op_bin" signin > /dev/null || log 'Desktop authentication unavailable; trying terminal authentication.'
  fi
  if ! "$op_bin" whoami > /dev/null 2>&1; then
    export OP_BIOMETRIC_UNLOCK_ENABLED=false
    if ! "$op_bin" whoami > /dev/null 2>&1; then
      [ -t 0 ] || die "1Password CLI authentication required; rerun bootstrap in a terminal"
      accounts=$("$op_bin" account list --format=json) || die "cannot list 1Password CLI accounts"
      if [ "$(printf '%s' "$accounts" | "$TOOLS/bin/jq" 'length')" -eq 0 ]; then
        log 'Add your 1Password account in this terminal (address, email, Secret Key and account password).'
        "$op_bin" account add || die "1Password account registration failed"
      fi
      OP_SESSION=$("$op_bin" signin --raw) || die "1Password CLI sign-in failed"
      [ -n "$OP_SESSION" ] || die "1Password CLI returned an empty session"
      export OP_SESSION
      "$op_bin" whoami > /dev/null || die "1Password CLI authentication failed"
    fi
  fi
  (
    umask 077
    mkdir -p "$(dirname "$key_file")"
  )
  chmod 700 "$(dirname "$key_file")"
  KEY_TEMP=$(mktemp "$(dirname "$key_file")/.age-key.XXXXXX")
  chmod 600 "$KEY_TEMP"
  "$op_bin" read "$AGE_KEY_REF" --out-file "$KEY_TEMP" --file-mode 0600 --force || die "1Password key read failed; rerun bootstrap after authentication"
  [ -s "$KEY_TEMP" ] || die "1Password returned an empty key"
  "$TOOLS/bin/age-keygen" -y "$KEY_TEMP" > /dev/null || die "1Password item is not a valid age identity"
  secrets_check "$KEY_TEMP"
  # Hard-link on the same filesystem: atomically create without overwriting a
  # key installed by another process while the user was authenticating.
  "$TOOLS/bin/ln" -T "$KEY_TEMP" "$key_file" || die "age key destination now exists; it was not replaced"
  rm -f "$KEY_TEMP"
  KEY_TEMP=
  log "Age key supplied and validated."
}

if [ "$OS" = Darwin ]; then
  install_clt
fi
install_nix
if [ "$OS" = Darwin ] && [ "$HOME_ONLY" = false ]; then
  ensure_local_host
fi
check_macos_permissions
build_tools
select_configuration
if [ "$OS" = Darwin ]; then
  # Existing machine selections still use Homebrew for other GUI applications.
  if [ "$HOME_ONLY" = false ]; then
    homebrew_enabled=$(nix_cmd eval --json "$FLAKE_REF#$SYSTEM_ATTR.config.homebrew.enable") \
      || die 'cannot evaluate Homebrew requirements; no Homebrew installation started'
    if [ "$homebrew_enabled" = true ]; then
      install_brew
    fi
  fi
fi
if [ "$SKIP_SECRETS" = true ]; then
  log 'Tools ready; secret restoration explicitly skipped.'
else
  prepare_identity
fi
if [ "$HOME_ONLY" = true ]; then
  log "Bootstrap finished. Apply separately: HM_USER=$HM_USER ./switch.sh --home"
else
  log "Bootstrap finished. Apply separately: ./switch.sh $HOST"
fi
