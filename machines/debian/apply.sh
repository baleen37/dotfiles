#!/usr/bin/env bash
set -euo pipefail
set +x

if [ "$#" -ne 1 ]; then
  echo 'Expected one internal stage: bootstrap, switch, or --build.' >&2
  exit 1
fi
case "$1" in
  bootstrap | switch) stage=$1 ;;
  --build) stage=build ;;
  *)
    echo 'Unknown Debian stage.' >&2
    exit 1
    ;;
esac
if ! command -v python3 > /dev/null; then
  if [ "$stage" != bootstrap ]; then
    echo 'python3 is required; run ./bootstrap.sh. No changes were made.' >&2
    exit 1
  fi
  privileged=()
  if [ "$EUID" -ne 0 ]; then
    privileged=(sudo)
  fi
  "${privileged[@]}" apt-get update
  "${privileged[@]}" apt-get install -y python3 ca-certificates
fi
exec python3 "$(dirname "${BASH_SOURCE[0]}")/apply.py" "$stage"
