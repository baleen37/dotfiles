#!/usr/bin/env bash
# Write this Mac's Syncthing device ID into its flake-modules/hosts.nix entry,
# generating the key first if there is none. Needs `syncthing` on PATH; run it
# through `make syncthing-id`. The steps after it are in CLAUDE.md.
#
# Usage: scripts/syncthing-register.sh <host>
set -euo pipefail

host=$1
dir="$HOME/Library/Application Support/Syncthing"
hosts=flake-modules/hosts.nix

[ -f "$dir/cert.pem" ] || syncthing generate --config="$dir" --data="$dir" > /dev/null
id=$(syncthing device-id --config="$dir" --data="$dir")

# Inside the host's block, drop any old syncthingId and add one after `user =`.
awk -v host="$host" -v id="$id" '
  $0 == "    " host " = {" { inblk = 1; found = 1 }
  inblk && /^      syncthingId = / { next }
  { print }
  inblk && /^      user = / { print "      syncthingId = \"" id "\";" }
  inblk && $0 == "    };" { inblk = 0 }
  END { exit !found }
' "$hosts" > "$hosts.tmp" || {
  rm -f "$hosts.tmp"
  echo "error: host '$host' is not declared in $hosts" >&2
  exit 1
}
mv "$hosts.tmp" "$hosts"

echo "$host: syncthingId = $id"
echo "Next: commit, make switch, then add the device on the hub (see CLAUDE.md)."
