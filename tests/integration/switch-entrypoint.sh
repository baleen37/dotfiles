#!/usr/bin/env bash
set -euo pipefail
repo=$1
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo/machines/debian" "$fixture/repo/scripts/lib" "$fixture/bin"
cp "$repo/switch.sh" "$repo/bootstrap.sh" "$fixture/repo/"
sed "s@/etc/os-release@$fixture/os-release@g" "$repo/scripts/lib/setup.sh" > "$fixture/repo/scripts/lib/setup.sh"
cp "$repo/scripts/lib/flake-source.sh" "$fixture/repo/scripts/lib/"
# Every platform now prepares Nix before native activation can start.
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
  status=0
  bash "$fixture/repo/$script.sh" > "$fixture/output" || status=$?
  [ "$status" -eq 29 ] && [ ! -e "$SWITCH_LOG" ]
  grep -qx nix-backend "$fixture/output"
done
status=0
bash "$fixture/repo/switch.sh" --build > "$fixture/output" || status=$?
[ "$status" -eq 29 ] && [ ! -e "$SWITCH_LOG" ]
grep -qx nix-backend "$fixture/output"
for argument in --check --age-key-file --help macbook-pro ''; do
  status=0
  bash "$fixture/repo/switch.sh" "$argument" > "$fixture/output" 2>&1 || status=$?
  [ "$status" -ne 0 ]
done
printf 'ID=nixos\n' > "$fixture/os-release"
for platform in Linux Darwin; do
  export SWITCH_OS=$platform
  status=0
  bash "$fixture/repo/switch.sh" --build > "$fixture/output" || status=$?
  [ "$status" -eq 29 ]
  grep -qx nix-backend "$fixture/output"
done
echo 'PASS: public setup contract prepares Nix on Debian and rejects old arguments before setup.'
