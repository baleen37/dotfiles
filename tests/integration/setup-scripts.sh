#!/usr/bin/env bash
# Exercise the public CLI with synthetic secrets and external-command doubles.
set -euo pipefail
repo=$1
workspace=$(mktemp -d)
cleanup() {
  local status=$?
  if [ "$status" -ne 0 ] && [ -f "$workspace/output" ]; then cat "$workspace/output" >&2; fi
  rm -rf "$workspace"
  exit "$status"
}
trap cleanup EXIT
mkdir -p "$workspace/repo/scripts/lib" "$workspace/tools/bin" "$workspace/bin"
cp "$repo/bootstrap.sh" "$repo/switch.sh" "$workspace/repo/"
cp "$repo/scripts/lib/setup.sh" "$repo/scripts/lib/macos-app-management.js" "$workspace/repo/scripts/lib/"
for command in age-keygen sops jq; do
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
export NIXNAME=test-host
export TEST_TOOLS="$workspace/tools" TEST_STATE="$workspace"
export PATH="$workspace/bin:$PATH"
cat > "$workspace/bin/uname" << 'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = -m ]; then echo x86_64; else echo Linux; fi
STUB
cat > "$workspace/bin/id" << 'STUB'
#!/usr/bin/env bash
if [ "$1" = -u ]; then echo 1000; else echo testuser; fi
STUB
cp "$workspace/bin/id" "$workspace/tools/bin/id"
cat > "$workspace/bin/nix" << 'STUB'
#!/usr/bin/env bash
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
elif [[ "$*" == *'homebrew.enable'* ]]; then echo false
elif [[ "$*" == *'home.username'* ]]; then echo testuser
elif [[ "$*" == *'sops.age.keyFile'* ]]; then echo "$HOME/.config/sops/age/keys.txt"
elif [[ "$*" == *'modules.secrets.preflight'* ]]; then echo "$TEST_TOOLS"
elif [[ "$*" == *'activationPackage'* ]]; then echo "$TEST_STATE/activation"
elif [[ "$*" == *'.system'* ]]; then echo "$TEST_STATE/system"
else echo 'unexpected nix invocation' >&2; exit 19
fi
STUB
cat > "$workspace/tools/bin/op" << 'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = --version ]; then echo 'test-op'; exit 0; fi
[ "${TEST_OP_FAIL:-0}" = 0 ] || exit 17
[ "$1" != whoami ] || exit 0
[ "$1" = read ] || exit 18
while [ "$#" -gt 0 ]; do
  if [ "$1" = --out-file ]; then
    if [ "${TEST_EMPTY_KEY:-0}" = 1 ]; then : > "$2"; else cp "$TEST_IDENTITY" "$2"; fi
    exit 0
  fi
  shift
done
exit 19
STUB
cat > "$workspace/tools/bin/dotfiles-secrets-check" << 'STUB'
#!/usr/bin/env bash
set -euo pipefail
key=${1:-$HOME/.config/sops/age/keys.txt}
[ -s "$key" ] || { echo 'run ./bootstrap.sh' >&2; exit 1; }
age-keygen -y "$key" >/dev/null
SOPS_AGE_KEY_FILE="$key" SOPS_GPG_EXEC=false sops --decrypt "$TEST_STATE/secret.yaml" >/dev/null
STUB
mkdir -p "$workspace/activation"
cat > "$workspace/activation/activate" << 'STUB'
#!/usr/bin/env bash
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
expect_failure bash ./bootstrap.sh --home --skip-secrets
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
export TEST_BUILD_FAIL=0
mv "$workspace/tools/bin/op" "$workspace/tools/bin/op.disabled"
expect_failure bash ./bootstrap.sh --home --age-key-ref op://test/identity/key
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
mv "$workspace/tools/bin/op.disabled" "$workspace/tools/bin/op"
export TEST_EMPTY_KEY=1
expect_failure bash ./bootstrap.sh --home --age-key-ref op://test/identity/key
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
export TEST_EMPTY_KEY=0
# Failed op reads never leave an apparently installed key.
export TEST_OP_FAIL=1
expect_failure bash ./bootstrap.sh --home --age-key-ref op://test/identity/key
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
[ -z "$(find "$HOME" -name '.age-key.*' -print)" ]
export TEST_OP_FAIL=0
# A syntactically valid key for the wrong recipient must also fail.
age-keygen -o "$workspace/wrong-identity" 2> /dev/null
export TEST_IDENTITY="$workspace/wrong-identity"
expect_failure bash ./bootstrap.sh --home --age-key-ref op://test/identity/key
[ ! -e "$HOME/.config/sops/age/keys.txt" ]
export TEST_IDENTITY="$workspace/identity"
bash ./bootstrap.sh --home --age-key-ref op://test/identity/key > "$workspace/output" 2>&1
[ ! -e "$workspace/activated" ]
cmp "$workspace/identity" "$HOME/.config/sops/age/keys.txt"
[ "$(stat -c %a "$HOME/.config/sops/age/keys.txt" 2> /dev/null || stat -f %Lp "$HOME/.config/sops/age/keys.txt")" = 600 ]
# Existing valid keys work even when op is unavailable; they are never replaced.
export TEST_OP_FAIL=1
bash ./bootstrap.sh --home > "$workspace/output" 2>&1
cmp "$workspace/identity" "$HOME/.config/sops/age/keys.txt"
bash ./switch.sh --home --build > "$workspace/output" 2>&1
[ ! -e "$workspace/activated" ]
bash ./switch.sh --home > "$workspace/output" 2>&1
[ -f "$workspace/activated" ]
rm "$workspace/activated"
printf 'invalid\n' > "$HOME/.config/sops/age/keys.txt"
expect_failure bash ./bootstrap.sh --home
expect_failure bash ./switch.sh --home
[ ! -e "$workspace/activated" ]
# Explicit skip prepares tools but cannot bypass switch readiness checks.
bash ./bootstrap.sh --home --skip-secrets > "$workspace/output" 2>&1
expect_failure bash ./switch.sh --home
[ ! -e "$workspace/activated" ]
expect_failure bash ./bootstrap.sh --unknown
expect_failure bash ./switch.sh --age-key-ref op://test/identity/key
# Drive the Darwin system branch while sudo is a recording-only double.
cp "$workspace/identity" "$HOME/.config/sops/age/keys.txt"
cat > "$workspace/bin/uname" << 'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = -m ]; then echo arm64; else echo Darwin; fi
STUB
cat > "$workspace/bin/sudo" << 'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_STATE/sudo.log"
STUB
cat > "$workspace/bin/osascript" << 'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_STATE/permissions.log"
[ "${TEST_PERMISSION_STATUS:-granted}" != error ] || exit 9
printf '%s\n' "${TEST_PERMISSION_STATUS:-granted}"
STUB
cat > "$workspace/bin/open" << 'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_STATE/settings.log"
[ "${TEST_SETTINGS_FAIL:-0}" = 0 ]
STUB
chmod +x "$workspace/bin/"*
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
expect_failure bash ./bootstrap.sh test-host --skip-secrets
[ ! -e "$workspace/sudo.log" ]
! grep -q ' build ' "$workspace/nix.log"
# Build-only, standalone HM and minimal hosts need no app-management consent.
rm "$workspace/permissions.log" "$workspace/settings.log"
bash ./switch.sh test-host --build > "$workspace/output" 2>&1
bash ./switch.sh --home --build > "$workspace/output" 2>&1
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
[ ! -e "$workspace/activated" ]
[ ! -e "$(cat "$workspace/source-path")" ]
# The ignored exception may not point at an arbitrary private file.
mv "$workspace/repo/flake-modules/hosts.local.nix" "$workspace/registry.saved"
ln -s "$workspace/identity" "$workspace/repo/flake-modules/hosts.local.nix"
expect_failure bash ./switch.sh --home --build
grep -q 'local host registry must be a regular file' "$workspace/output"
echo 'PASS: bootstrap/switch secrets, filtered source, cleanup, build-only and permission scenarios'
