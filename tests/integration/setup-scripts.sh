#!/usr/bin/env bash
# Exercise the public CLI with synthetic secrets and external-command doubles.
set -euo pipefail
repo=$1
workspace=$(mktemp -d)
cleanup() {
  local status=$?
  if [ "$status" -ne 0 ] && [ -f "$workspace/output" ]; then
    cat "$workspace/output" >&2
  fi
  rm -rf "$workspace"
  exit "$status"
}
trap cleanup EXIT
mkdir -p "$workspace/repo/scripts/lib" "$workspace/tools/bin" "$workspace/bin"
cp "$repo/bootstrap.sh" "$repo/switch.sh" "$workspace/repo/"
cp "$repo/scripts/lib/setup.sh" "$repo/scripts/lib/macos-app-management.js" "$workspace/repo/scripts/lib/"
for command in age-keygen sops jq ln; do
  ln -s "$(command -v "$command")" "$workspace/tools/bin/$command"
done
# Use an actual Git index: source filtering is part of the public CLI contract.
printf 'keys.txt\nbackup.tar.gz\nprivate/\nflake-modules/hosts.local.nix\n' > "$workspace/repo/.gitignore"
git init --quiet "$workspace/repo"
git -C "$workspace/repo" add .
printf 'synthetic ignored identity\n' > "$workspace/repo/keys.txt"
printf 'synthetic ignored backup\n' > "$workspace/repo/backup.tar.gz"
mkdir -p "$workspace/repo/private" "$workspace/repo/flake-modules"
printf 'synthetic private data\n' > "$workspace/repo/private/token"
printf '{ ... }: {}\n' > "$workspace/repo/flake-modules/hosts.local.nix"
printf '{ ... }: {}\n' > "$workspace/repo/new-module.nix"
ln -s keys.txt "$workspace/repo/ignored-target-link"
export DOTFILES_AGE_KEY_REF=op://test/identity/key
export TEST_TOOLS="$workspace/tools" TEST_STATE="$workspace"
export PATH="$workspace/bin:$PATH"
stub_shell=$(command -v bash)
write_stub() {
  {
    printf '#!%s\n' "$stub_shell"
    cat
  } > "$1"
  chmod +x "$1"
}
write_stub "$workspace/bin/uname" << 'STUB'
if [ "${1:-}" = -m ]; then echo x86_64; else echo Linux; fi
STUB
write_stub "$workspace/bin/id" << 'STUB'
if [ "$1" = -u ]; then echo 1000; else echo testuser; fi
STUB
write_stub "$workspace/bin/hostname" << 'STUB'
echo test-host
STUB
cp "$workspace/bin/id" "$workspace/tools/bin/id"
write_stub "$workspace/bin/nix" << 'STUB'
set -euo pipefail
printf '%s\n' "$*" >> "$TEST_STATE/nix.log"
for arg in "$@"; do
  if [[ "$arg" = path:*#* ]]; then
    source=${arg#path:}
    source=${source%%#*}
    [ "$source" != "$TEST_STATE/repo" ]
    [ ! -e "$source/keys.txt" ] && [ ! -e "$source/backup.tar.gz" ] && [ ! -e "$source/private" ]
    [ -f "$source/new-module.nix" ] && [ -f "$source/flake-modules/hosts.local.nix" ]
    [ -L "$source/ignored-target-link" ]
    printf '%s\n' "$source" > "$TEST_STATE/source-path"
  fi
done
if [[ "$*" == *'bootstrap-tools'* ]]; then
  [ "${TEST_BUILD_FAIL:-0}" = 0 ] || exit 23
  while [ "$#" -gt 0 ]; do
    if [ "$1" = --out-link ]; then ln -sfn "$TEST_TOOLS" "$2"; break; fi
    shift
  done
elif [[ "$*" == *'programs._1password-gui.enable'* ]]; then echo "${TEST_APP_MANAGEMENT_REQUIRED:-true}"
elif [[ "$*" == *'homebrew.enable'* ]]; then
  [ "${TEST_HOMEBREW_EVAL_FAIL:-0}" = 0 ] || exit 23
  echo false
elif [[ "$*" == *'builtins.hasAttr'* ]]; then echo true
elif [[ "$*" == *'#homeConfigurations --apply'* ]]; then echo testuser-linux
elif [[ "$*" == *'.pkgs.stdenv.hostPlatform.system'* ]]; then
  if [ -n "${TEST_HOME_SYSTEM:-}" ]; then echo "$TEST_HOME_SYSTEM"
  elif [ "$(uname -s)" = Darwin ]; then echo aarch64-darwin
  else echo x86_64-linux
  fi
elif [[ "$*" == *'home.username'* ]]; then echo testuser
elif [[ "$*" == *'sops.age.keyFile'* ]]; then echo "$HOME/.config/sops/age/keys.txt"
elif [[ "$*" == *'modules.secrets.preflight'* ]]; then echo "$TEST_TOOLS"
elif [[ "$*" == *'activationPackage'* ]]; then echo "$TEST_STATE/activation"
elif [[ "$*" == *'.system'* ]]; then echo "$TEST_STATE/system"
else echo 'unexpected nix invocation' >&2; exit 19
fi
STUB
write_stub "$workspace/tools/bin/op" << 'STUB'
set -euo pipefail
if [ "$1" = --version ]; then echo 'test-op'; exit 0; fi
[ "${TEST_OP_FAIL:-0}" = 0 ] || exit 17
[ "$1" != whoami ] || exit 0
[ "$1" = read ] || exit 18
while [ "$#" -gt 0 ]; do
  if [ "$1" = --out-file ]; then
    if [ "${TEST_EMPTY_KEY:-0}" = 1 ]; then : > "$2"; else cp "$TEST_IDENTITY" "$2"; fi
    case "${TEST_KEY_RACE:-}" in
      directory) mkdir "$HOME/.config/sops/age/keys.txt" ;;
      symlink) ln -s "$TEST_STATE" "$HOME/.config/sops/age/keys.txt" ;;
      file) printf 'competing identity\n' > "$HOME/.config/sops/age/keys.txt" ;;
    esac
    exit 0
  fi
  shift
done
exit 19
STUB
write_stub "$workspace/tools/bin/dotfiles-secrets-check" << 'STUB'
set -euo pipefail
key=${1:-$HOME/.config/sops/age/keys.txt}
[ -s "$key" ] || { echo 'run ./bootstrap.sh' >&2; exit 1; }
age-keygen -y "$key" >/dev/null
SOPS_AGE_KEY_FILE="$key" SOPS_GPG_EXEC=false sops --decrypt "$TEST_STATE/secret.yaml" >/dev/null
STUB
mkdir -p "$workspace/activation"
write_stub "$workspace/activation/activate" << 'STUB'
touch "$TEST_STATE/activated"
STUB
chmod +x "$workspace/bin/"* "$workspace/tools/bin/id" "$workspace/tools/bin/op" "$workspace/tools/bin/dotfiles-secrets-check" "$workspace/activation/activate"
age-keygen -o "$workspace/identity" 2> /dev/null
recipient=$(age-keygen -y "$workspace/identity")
printf 'token: synthetic-value\n' > "$workspace/plain.yaml"
sops --encrypt --age "$recipient" --input-type yaml --output-type yaml "$workspace/plain.yaml" > "$workspace/secret.yaml"
export TEST_IDENTITY="$workspace/identity"
export HOME="$workspace/home" XDG_CACHE_HOME="$workspace/cache" HM_USER=testuser
mkdir -p "$HOME"
cd "$workspace/repo"
expect_failure() {
  if "$@" > "$workspace/output" 2>&1; then
    echo "unexpected success: $*" >&2
    exit 1
  fi
}
# A missing bootstrap must not reach activation.
expect_failure bash ./switch.sh --home
[ ! -e "$workspace/activated" ]
# Dependency installation failure and a missing op never report readiness.
export TEST_BUILD_FAIL=1
expect_failure bash ./bootstrap.sh
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
export TEST_BUILD_FAIL=0
mv "$workspace/tools/bin/op" "$workspace/tools/bin/op.disabled"
expect_failure bash ./bootstrap.sh
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
mv "$workspace/tools/bin/op.disabled" "$workspace/tools/bin/op"
export TEST_EMPTY_KEY=1
expect_failure bash ./bootstrap.sh
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
export TEST_EMPTY_KEY=0
# Failed op reads never leave an apparently installed key.
export TEST_OP_FAIL=1
expect_failure bash ./bootstrap.sh
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
[ -z "$(find "$HOME" -name '.age-key.*' -print)" ]
export TEST_OP_FAIL=0
# A syntactically valid key for the wrong recipient must also fail.
age-keygen -o "$workspace/wrong-identity" 2> /dev/null
export TEST_IDENTITY="$workspace/wrong-identity"
expect_failure bash ./bootstrap.sh
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
export TEST_IDENTITY="$workspace/identity"
# A competing directory, symlink or file must never become a successful restore.
for race in directory symlink file; do
  export TEST_KEY_RACE=$race
  expect_failure bash ./bootstrap.sh
  grep -q 'age key destination now exists' "$workspace/output"
  [ -z "$(find "$HOME" -name '.age-key.*' -print)" ]
  [ -z "$(find "$workspace" -maxdepth 1 -name '.age-key.*' -print)" ]
  if [ "$race" = directory ]; then
    rmdir "$HOME/.config/sops/age/keys.txt"
  else
    if [ "$race" = file ]; then
      grep -qx 'competing identity' "$HOME/.config/sops/age/keys.txt"
    fi
    rm "$HOME/.config/sops/age/keys.txt"
  fi
done
unset TEST_KEY_RACE
bash ./bootstrap.sh > "$workspace/output" 2>&1
[ ! -e "$workspace/activated" ]
cmp "$workspace/identity" "$HOME/.config/sops/age/keys.txt"
[ "$(stat -c %a "$HOME/.config/sops/age/keys.txt" 2> /dev/null || stat -f %Lp "$HOME/.config/sops/age/keys.txt")" = 600 ]
# Existing valid keys work even when op is unavailable; they are never replaced.
export TEST_OP_FAIL=1
bash ./bootstrap.sh > "$workspace/output" 2>&1
cmp "$workspace/identity" "$HOME/.config/sops/age/keys.txt"
bash ./switch.sh --home --check > "$workspace/output" 2>&1
[ ! -e "$workspace/activated" ]
bash ./switch.sh --home > "$workspace/output" 2>&1
[ -f "$workspace/activated" ]
rm "$workspace/activated"
# Standalone defaults must follow the platform, not just the login name.
unset HM_USER
: > "$workspace/nix.log"
bash ./bootstrap.sh > "$workspace/output" 2>&1
bash ./switch.sh --home --build > "$workspace/output" 2>&1
grep -q 'homeConfigurations\."testuser-linux"\.activationPackage' "$workspace/nix.log"
export HM_USER=testuser TEST_HOME_SYSTEM=aarch64-darwin
: > "$workspace/nix.log"
expect_failure bash ./bootstrap.sh
grep -q 'targets aarch64-darwin' "$workspace/output"
expect_failure bash ./switch.sh --home --build
grep -q 'targets aarch64-darwin' "$workspace/output"
! grep -q 'activationPackage' "$workspace/nix.log"
unset TEST_HOME_SYSTEM
printf 'invalid\n' > "$HOME/.config/sops/age/keys.txt"
expect_failure bash ./bootstrap.sh
expect_failure bash ./switch.sh --home
[ ! -e "$workspace/activated" ]
expect_failure bash ./bootstrap.sh --unknown
expect_failure bash ./switch.sh --age-key-ref op://test/identity/key
# Drive the Darwin system branch while sudo is a recording-only double.
cp "$workspace/identity" "$HOME/.config/sops/age/keys.txt"
cp switch.sh "$workspace/switch.platform-saved"
chmod u+w switch.sh
sed "s@/run/current-system@$workspace/current-system@g" "$workspace/switch.platform-saved" > switch.sh
mkdir -p "$workspace/current-system/sw/bin"
write_stub "$workspace/current-system/sw/bin/darwin-rebuild" << 'STUB'
exit 0
STUB
write_stub "$workspace/bin/uname" << 'STUB'
if [ "${1:-}" = -m ]; then echo arm64; else echo Darwin; fi
STUB
write_stub "$workspace/bin/sudo" << 'STUB'
printf '%s\n' "$*" >> "$TEST_STATE/sudo.log"
[ "${TEST_SUDO_FAIL:-0}" = 0 ] || exit 1
if [ "${TEST_SUDO_EXECUTE:-0}" = 1 ]; then
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -v) exit 0 ;;
      -H | -n) shift ;;
      *) exec "$@" ;;
    esac
  done
fi
STUB
write_stub "$workspace/bin/osascript" << 'STUB'
printf '%s\n' "$*" >> "$TEST_STATE/permissions.log"
[ "${TEST_PERMISSION_STATUS:-granted}" != error ] || exit 9
printf '%s\n' "${TEST_PERMISSION_STATUS:-granted}"
STUB
write_stub "$workspace/bin/open" << 'STUB'
printf '%s\n' "$*" >> "$TEST_STATE/settings.log"
[ "${TEST_SETTINGS_FAIL:-0}" = 0 ]
STUB
chmod +x "$workspace/bin/"*
write_stub "$workspace/bin/xcode-select" << 'STUB'
[ "$1" = -p ] && [ "${TEST_CLT_MISSING:-0}" = 0 ]
STUB
chmod +x "$workspace/bin/xcode-select"
# With prerequisites installed, repeated bootstrap must never request sudo.
export TEST_APP_MANAGEMENT_REQUIRED=false
bash ./bootstrap.sh > "$workspace/output" 2>&1
[ ! -e "$workspace/sudo.log" ]
cmp "$workspace/identity" "$HOME/.config/sops/age/keys.txt"
# A genuinely missing prerequisite still requires authentication before install.
export TEST_CLT_MISSING=1 TEST_SUDO_FAIL=1
expect_failure bash ./bootstrap.sh
grep -q 'administrator authentication failed' "$workspace/output"
grep -q -- '-v' "$workspace/sudo.log"
rm "$workspace/sudo.log"
export TEST_CLT_MISSING=0 TEST_SUDO_FAIL=0
export TEST_APP_MANAGEMENT_REQUIRED=true
# Required macOS consent is checked before any build, secret read or sudo.
for status in denied unknown error; do
  export TEST_PERMISSION_STATUS=$status
  : > "$workspace/nix.log"
  expect_failure bash ./switch.sh test-host
  grep -q 'macOS permission preflight incomplete' "$workspace/output"
  grep -q 'Privacy_AppBundles' "$workspace/settings.log"
  [ ! -e "$workspace/sudo.log" ]
  ! grep -q ' build ' "$workspace/nix.log"
  [ ! -e "$workspace/activated" ]
done
# A settings-launch failure must retain the manual instructions and stop.
export TEST_SETTINGS_FAIL=1
expect_failure bash ./switch.sh test-host
grep -q 'Could not open System Settings' "$workspace/output"
grep -q 'Privacy_AppBundles' "$workspace/output"
[ ! -e "$workspace/sudo.log" ]
export TEST_SETTINGS_FAIL=0
# Bootstrap checks an existing Nix host before sudo, CLT or downloads.
: > "$workspace/nix.log"
expect_failure bash ./bootstrap.sh
[ ! -e "$workspace/sudo.log" ]
! grep -q ' build ' "$workspace/nix.log"
# Build-only, standalone HM and minimal hosts need no app-management consent.
write_stub "$workspace/current-system/sw/bin/dotfiles-remote-apply" << 'STUB'
grep -q 'darwin-rebuild.*switch --flake' "$TEST_STATE/sudo.log"
touch "$TEST_STATE/remote-applied"
[ "${TEST_REMOTE_FAIL:-0}" = 0 ]
STUB
rm "$workspace/permissions.log" "$workspace/settings.log"
bash ./switch.sh test-host --build > "$workspace/output" 2>&1
bash ./switch.sh --home --build > "$workspace/output" 2>&1
[ ! -e "$workspace/remote-applied" ]
[ ! -e "$workspace/permissions.log" ]
[ ! -e "$workspace/settings.log" ]
export TEST_APP_MANAGEMENT_REQUIRED=false
bash ./switch.sh test-host > "$workspace/output" 2>&1
[ ! -e "$workspace/permissions.log" ]
[ ! -e "$workspace/settings.log" ]
rm "$workspace/sudo.log"
export TEST_APP_MANAGEMENT_REQUIRED=true TEST_PERMISSION_STATUS=granted
bash ./switch.sh test-host > "$workspace/output" 2>&1
grep -q 'darwin-rebuild.*switch --flake' "$workspace/sudo.log"
[ -e "$workspace/remote-applied" ]
[ ! -e "$workspace/activated" ]
[ ! -e "$(cat "$workspace/source-path")" ]
# App settings must finish before the CLI reports a successful switch.
export TEST_REMOTE_FAIL=1
expect_failure bash ./switch.sh test-host
! grep -q 'Configuration applied successfully' "$workspace/output"
export TEST_REMOTE_FAIL=0
# Evaluation failures must not be mistaken for a disabled Homebrew module.
rm "$workspace/sudo.log"
export TEST_HOMEBREW_EVAL_FAIL=1
expect_failure bash ./bootstrap.sh
grep -q 'cannot evaluate Homebrew requirements' "$workspace/output"
expect_failure bash ./switch.sh test-host
grep -q 'cannot evaluate Homebrew requirements' "$workspace/output"
[ ! -e "$workspace/sudo.log" ]
export TEST_HOMEBREW_EVAL_FAIL=0
# First installation must restore only its own backups if activation fails.
cp switch.sh "$workspace/switch.saved"
chmod u+w switch.sh
sed -e "s@$workspace/current-system@$workspace/absent-system@g" \
  -e "s@/etc/@$workspace/etc/@g" \
  -e "s@/bin/bash -s@$stub_shell -s@g" "$workspace/switch.saved" > switch.sh
mkdir -p "$workspace/etc/nix" "$workspace/system/sw/bin"
for file in bashrc zshrc zprofile nix/nix.custom.conf; do
  printf 'original %s\n' "$file" > "$workspace/etc/$file"
done
printf 'pre-existing backup\n' > "$workspace/etc/zprofile.before-nix-darwin"
write_stub "$workspace/system/sw/bin/darwin-rebuild" << 'STUB'
[ "${TEST_ACTIVATION_FAIL:-0}" = 0 ] || exit 42
STUB
chmod +x "$workspace/system/sw/bin/darwin-rebuild"
export TEST_SUDO_EXECUTE=1 TEST_ACTIVATION_FAIL=1
: > "$workspace/sudo.log"
expect_failure bash ./switch.sh test-host
[ "$(wc -l < "$workspace/sudo.log" | tr -d ' ')" = 1 ]
for file in bashrc zshrc zprofile nix/nix.custom.conf; do
  grep -qx "original $file" "$workspace/etc/$file"
done
grep -qx 'pre-existing backup' "$workspace/etc/zprofile.before-nix-darwin"
for file in bashrc zshrc nix/nix.custom.conf; do
  [ ! -e "$workspace/etc/$file.before-nix-darwin" ]
done
# Existing backups can leave the rollback list empty, including on Bash 3.2.
for file in bashrc zshrc nix/nix.custom.conf; do
  cp "$workspace/etc/$file" "$workspace/etc/$file.before-nix-darwin"
done
expect_failure bash ./switch.sh test-host
! grep -q 'unbound variable' "$workspace/output"
[ ! -e "$(cat "$workspace/source-path")" ]
# A successful activation retains backups instead of rolling back.
for file in bashrc zshrc zprofile nix/nix.custom.conf; do
  rm "$workspace/etc/$file.before-nix-darwin"
done
export TEST_ACTIVATION_FAIL=0
bash ./switch.sh test-host > "$workspace/output" 2>&1
for file in bashrc zshrc zprofile nix/nix.custom.conf; do
  grep -qx "original $file" "$workspace/etc/$file.before-nix-darwin"
done
export TEST_SUDO_EXECUTE=0
cp "$workspace/switch.saved" switch.sh
# The ignored exception may not point at an arbitrary private file.
mv "$workspace/repo/flake-modules/hosts.local.nix" "$workspace/registry.saved"
ln -s "$workspace/identity" "$workspace/repo/flake-modules/hosts.local.nix"
expect_failure bash ./switch.sh --home --build
grep -q 'local host registry must be a regular file' "$workspace/output"
echo 'PASS: bootstrap/switch secrets, filtered source, cleanup, build-only and permission scenarios'
