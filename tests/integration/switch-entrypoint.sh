#!/usr/bin/env bash
set -euo pipefail
repo=$1
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo/machines/debian" "$fixture/repo/scripts/lib" "$fixture/bin"
sed "s@/etc/os-release@$fixture/os-release@g" "$repo/switch.sh" > "$fixture/repo/switch.sh"
export SWITCH_LOG="$fixture/calls" SWITCH_OS=Linux
shell=$(command -v bash)
printf '#!%s\nprintf "%%s\\n" "$SWITCH_OS"\n' "$shell" > "$fixture/bin/uname"
printf 'ID=debian\n' > "$fixture/os-release"
{
  printf '#!%s\n' "$shell"
  cat << 'STUB'
printf '%s\n' "$0" "$@" > "$SWITCH_LOG"
exit "${SWITCH_FAILURE:-0}"
STUB
} > "$fixture/repo/machines/debian/apply.sh"
chmod +x "$fixture/bin/uname" "$fixture/repo/machines/debian/apply.sh"
# A sentinel proves --home and NixOS retain the Nix backend, without activation.
echo 'echo nix-backend; exit 29' > "$fixture/repo/scripts/lib/setup.sh"
export PATH="$fixture/bin:$PATH"
bash "$fixture/repo/switch.sh" --help > /dev/null
[ ! -e "$SWITCH_LOG" ]
bash "$fixture/repo/switch.sh" --check --age-key-file '/path with space/identity'
grep -qx "$fixture/repo/machines/debian/apply.sh" "$SWITCH_LOG"
grep -qx -- --check "$SWITCH_LOG"
grep -qx '/path with space/identity' "$SWITCH_LOG"
bash "$fixture/repo/switch.sh" --build
grep -qx -- --check "$SWITCH_LOG"
export SWITCH_FAILURE=23
status=0
bash "$fixture/repo/switch.sh" || status=$?
[ "$status" -eq 23 ]
status=0
bash "$fixture/repo/switch.sh" --home --check > "$fixture/output" || status=$?
[ "$status" -eq 29 ]
grep -qx nix-backend "$fixture/output"
printf 'ID=nixos\n' > "$fixture/os-release"
status=0
bash "$fixture/repo/switch.sh" --check > "$fixture/output" || status=$?
[ "$status" -eq 29 ]
export SWITCH_OS=Darwin
status=0
bash "$fixture/repo/switch.sh" macbook-pro --check > "$fixture/output" || status=$?
[ "$status" -eq 29 ]
echo 'PASS: switch dispatches Debian, preserves Nix backends and arguments, and propagates failure.'
