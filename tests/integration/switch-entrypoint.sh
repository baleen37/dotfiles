#!/usr/bin/env bash
set -euo pipefail
repo=$1
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo/machines/debian" "$fixture/repo/scripts/lib" "$fixture/bin"
cp "$repo/switch.sh" "$repo/bootstrap.sh" "$fixture/repo/"
sed "s@/etc/os-release@$fixture/os-release@g" "$repo/scripts/lib/setup.sh" > "$fixture/repo/scripts/lib/setup.sh"
cp "$repo/scripts/lib/flake-source.sh" "$fixture/repo/scripts/lib/"
# Stop at Nix initialization; Debian must dispatch before this sentinel.
echo 'setup_context() { echo nix-backend; exit 29; }' >> "$fixture/repo/scripts/lib/setup.sh"
export SWITCH_LOG="$fixture/calls" SWITCH_OS=Linux
shell=$(command -v bash)
printf '#!%s\nprintf "%%s\\n" "$SWITCH_OS"\n' "$shell" > "$fixture/bin/uname"
printf '#!%s\necho 1000\n' "$shell" > "$fixture/bin/id"
printf 'ID=debian\n' > "$fixture/os-release"
{
  printf '#!%s\n' "$shell"
  cat << 'STUB'
printf '%s\n' "$@" > "$SWITCH_LOG"
exit "${SWITCH_FAILURE:-0}"
STUB
} > "$fixture/repo/machines/debian/apply.sh"
chmod +x "$fixture/bin/"* "$fixture/repo/machines/debian/apply.sh"
export PATH="$fixture/bin:$PATH"
for script in bootstrap switch; do
  status=0
  bash "$fixture/repo/$script.sh" --home > "$fixture/output" 2>&1 || status=$?
  [ "$status" -ne 0 ] && [ ! -e "$SWITCH_LOG" ]
  bash "$fixture/repo/$script.sh"
  grep -qx "$script" "$SWITCH_LOG"
  rm "$SWITCH_LOG"
done
bash "$fixture/repo/switch.sh" --build
[ "$(cat "$SWITCH_LOG")" = "$(printf 'switch\n--build')" ]
for argument in --check --age-key-file --help macbook-pro ''; do
  status=0
  bash "$fixture/repo/switch.sh" "$argument" > "$fixture/output" 2>&1 || status=$?
  [ "$status" -ne 0 ]
done
export SWITCH_FAILURE=23
status=0
bash "$fixture/repo/switch.sh" || status=$?
[ "$status" -eq 23 ]
printf 'ID=nixos\n' > "$fixture/os-release"
for platform in Linux Darwin; do
  export SWITCH_OS=$platform
  status=0
  bash "$fixture/repo/switch.sh" --build > "$fixture/output" || status=$?
  [ "$status" -eq 29 ]
  grep -qx nix-backend "$fixture/output"
done
echo 'PASS: public setup contract selects adapters, rejects old arguments and propagates failures.'
